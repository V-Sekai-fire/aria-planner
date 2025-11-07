# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.StateInitialization do
  @moduledoc """
  Handles state initialization for the aircraft disassembly domain.
  """

  @type params :: %{
    optional(:num_activities) => non_neg_integer(),
    optional(:nActs) => non_neg_integer(),
    optional(:num_resources) => non_neg_integer(),
    optional(:nResources) => non_neg_integer(),
    optional(:durations) => [non_neg_integer()],
    optional(:dur) => [non_neg_integer()],
    optional(:precedences) => [{non_neg_integer(), non_neg_integer()}],
    optional(:locations) => [non_neg_integer()],
    optional(:loc) => [non_neg_integer()],
    optional(:location_capacities) => [non_neg_integer()],
    optional(:loc_cap) => [non_neg_integer()],
    optional(:nSkills) => non_neg_integer(),
    optional(:nUnavailable) => non_neg_integer(),
    optional(:nUnrels) => non_neg_integer(),
    optional(:maxt) => non_neg_integer(),
    optional(:sreq) => [term()],
    optional(:mastery) => [term()],
    optional(:mass) => [term()],
    optional(:maxDiff) => [term()],
    optional(:M) => MapSet.t() | [term()] | non_neg_integer() | nil,
    optional(:comp_prod) => [term()],
    optional(:useful_res) => [MapSet.t() | term()],
    optional(:potential_act) => [MapSet.t() | term()],
    optional(:resource_cost) => [term()],
    optional(:unavailable_resource) => [term()],
    optional(:unavailable_start) => [term()],
    optional(:unavailable_end) => [term()],
    optional(:unrelated) => [{non_neg_integer(), non_neg_integer()}],
    optional(:occupancy) => [term()]
  }

  # State type - required fields are always present, optional fields may be present
  @type state :: map()

  @doc """
  Initializes the aircraft disassembly state with given parameters.
  """
  @spec initialize_state(params()) :: {:ok, state()} | {:error, String.t()}
  def initialize_state(params) when is_map(params) do
    try do
      num_activities = extract_integer(params, [:num_activities, :nActs], 0)
      num_resources = extract_integer(params, [:num_resources, :nResources], 0)
      
      durations = extract_list(params, [:durations, :dur], [])
      precedences = extract_list(params, [:precedences], [])
      locations = extract_list(params, [:locations, :loc], [])
      location_capacities = extract_list(params, [:location_capacities, :loc_cap], [])

      activity_status_facts = build_activity_status_facts(num_activities)
      facts = %{"activity_status" => activity_status_facts}
      precedence = build_precedence_map(precedences)
      resource_assigned = build_resource_assigned_map(num_activities, num_resources)
      location_capacity = build_location_capacity_map(location_capacities)

      # Extract additional fields with meaningful defaults
      n_skills = extract_integer(params, [:nSkills], 3)
      n_unavailable = extract_integer(params, [:nUnavailable], 0)
      n_unrels = extract_integer(params, [:nUnrels], 0)
      maxt = extract_integer(params, [:maxt], 1920)
      
      # Extract optional fields (return nil if not present)
      sreq = extract_list(params, [:sreq], nil)
      mastery = extract_list(params, [:mastery], nil)
      mass = extract_list(params, [:mass], nil)
      max_diff = extract_list(params, [:maxDiff], nil)
      mapset_m = extract_mapset(params, :M)
      comp_prod = extract_list(params, [:comp_prod], nil)
      useful_res = extract_useful_res(params)
      potential_act = extract_potential_act(params)
      resource_cost = extract_list(params, [:resource_cost], nil)
      unavailable_resource = extract_list(params, [:unavailable_resource], nil)
      unavailable_start = extract_list(params, [:unavailable_start], nil)
      unavailable_end = extract_list(params, [:unavailable_end], nil)
      unrelated = extract_list(params, [:unrelated], nil)
      occupancy = extract_list(params, [:occupancy], nil)

      # Build base state with required fields
      state = %{
        num_activities: num_activities,
        durations: durations,
        precedences: precedences,
        num_resources: num_resources,
        locations: locations,
        num_locations: length(location_capacities),
        facts: facts,
        precedence: precedence,
        resource_assigned: resource_assigned,
        location_capacity: location_capacity,
        current_time: 0,
        nSkills: n_skills,
        nUnavailable: n_unavailable,
        nUnrels: n_unrels,
        maxt: maxt
      }
      |> maybe_put(:sreq, sreq)
      |> maybe_put(:mastery, mastery)
      |> maybe_put(:mass, mass)
      |> maybe_put(:maxDiff, max_diff)
      |> maybe_put(:M, mapset_m)
      |> maybe_put(:comp_prod, comp_prod)
      |> maybe_put(:useful_res, useful_res)
      |> maybe_put(:potential_act, potential_act)
      |> maybe_put(:resource_cost, resource_cost)
      |> maybe_put(:unavailable_resource, unavailable_resource)
      |> maybe_put(:unavailable_start, unavailable_start)
      |> maybe_put(:unavailable_end, unavailable_end)
      |> maybe_put(:unrelated, unrelated)
      |> maybe_put(:occupancy, occupancy)

      {:ok, state}
    rescue
      e ->
        error_msg = case e do
          %MatchError{term: term} ->
            "MatchError with term: #{inspect(term)}. This usually means a pattern match failed. Check if all required params are provided."
          %KeyError{key: key} ->
            "KeyError: missing key #{inspect(key)}. Available keys: #{inspect(Map.keys(params))}"
          _ ->
            "#{inspect(e.__struct__)}: #{Exception.message(e)}"
        end
        {:error, "Failed to initialize state: #{error_msg}"}
    end
  end

  # Helper functions with type specs

  @spec extract_integer(map(), [atom()], non_neg_integer()) :: non_neg_integer()
  defp extract_integer(params, keys, default) do
    value = Enum.reduce_while(keys, nil, fn key, acc ->
      case Map.get(params, key) do
        nil -> {:cont, acc}
        val -> {:halt, val}
      end
    end) || default
    
    if is_integer(value) and value >= 0, do: value, else: default
  end

  @spec extract_list(map(), [atom()], [term()] | nil) :: [term()] | nil
  defp extract_list(params, keys, default) do
    value = Enum.reduce_while(keys, nil, fn key, acc ->
      case Map.get(params, key) do
        nil -> {:cont, acc}
        val -> {:halt, val}
      end
    end)
    
    cond do
      is_nil(value) -> default
      is_list(value) -> value
      match?(%MapSet{}, value) -> MapSet.to_list(value)
      true -> default
    end
  end

  @spec extract_mapset(map(), atom()) :: MapSet.t() | nil
  defp extract_mapset(params, key) do
    value = Map.get(params, key)
    cond do
      is_nil(value) -> nil
      match?(%MapSet{}, value) -> value
      is_list(value) -> MapSet.new(value)
      is_integer(value) -> MapSet.new([value])
      true -> nil
    end
  end

  @spec extract_useful_res(map()) :: [term()] | nil
  defp extract_useful_res(params) do
    value = Map.get(params, :useful_res)
    cond do
      is_nil(value) -> nil
      is_list(value) ->
        Enum.map(value, fn
          nil -> nil
          m -> 
            if match?(%MapSet{}, m) do
              MapSet.to_list(m)
            else
              m
            end
        end)
      match?(%MapSet{}, value) -> [MapSet.to_list(value)]
      true -> nil
    end
  end

  @spec extract_potential_act(map()) :: [term()] | nil
  defp extract_potential_act(params) do
    value = Map.get(params, :potential_act)
    cond do
      is_nil(value) -> nil
      is_list(value) ->
        Enum.map(value, fn
          nil -> nil
          m -> 
            if match?(%MapSet{}, m) do
              MapSet.to_list(m)
            else
              m
            end
        end)
      match?(%MapSet{}, value) -> [MapSet.to_list(value)]
      true -> nil
    end
  end

  @spec build_activity_status_facts(non_neg_integer()) :: %{String.t() => String.t()}
  defp build_activity_status_facts(num_activities) when num_activities > 0 do
    for activity <- 1..num_activities, into: %{} do
      activity_id = "activity_#{activity}"
      {activity_id, "not_started"}
    end
  end
  defp build_activity_status_facts(_), do: %{}

  @spec build_precedence_map([{non_neg_integer(), non_neg_integer()}]) :: %{{non_neg_integer(), non_neg_integer()} => boolean()}
  defp build_precedence_map(precedences) when is_list(precedences) do
    precedences
    |> Enum.filter(fn
      {_pred, _succ} -> true
      _ -> false
    end)
    |> Enum.reduce(%{}, fn {pred, succ}, acc ->
      key = {pred, succ}
      Map.put(acc, key, true)
    end)
  end
  defp build_precedence_map(_), do: %{}

  @spec build_resource_assigned_map(non_neg_integer(), non_neg_integer()) :: %{{non_neg_integer(), non_neg_integer()} => boolean()}
  defp build_resource_assigned_map(num_activities, num_resources) 
       when num_activities > 0 and num_resources > 0 do
    for activity <- 1..num_activities,
        resource <- 1..num_resources,
        into: %{} do
      {{activity, resource}, false}
    end
  end
  defp build_resource_assigned_map(_, _), do: %{}

  @spec build_location_capacity_map([non_neg_integer()]) :: %{non_neg_integer() => non_neg_integer()}
  defp build_location_capacity_map(location_capacities) when length(location_capacities) > 0 do
    for idx <- 0..(length(location_capacities) - 1), into: %{} do
      location = idx + 1
      capacity = Enum.at(location_capacities, idx, 1)
      {location, capacity}
    end
  end
  defp build_location_capacity_map(_), do: %{}

  # Helper to conditionally add fields to map
  @spec maybe_put(map(), atom(), term() | nil) :: map()
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end

