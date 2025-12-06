# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn do
  @moduledoc """
  Fox-Geese-Corn planning domain.

  This is a classic river crossing puzzle where:
  - Fox cannot be left alone with geese (fox eats geese)
  - Geese cannot be left alone with corn (geese eats corn)
  - Boat has limited capacity
  - Goal: Transport all items to the east side, maximizing points
  """

  # Aliases removed - not currently used in this module

  @doc """
  Creates and registers the fox-geese-corn planning domain.
  """
  @spec create_domain() :: {:ok, map()} | {:error, String.t()}
  def create_domain do
    case create_planning_domain() do
      {:ok, domain} ->
        domain = register_actions(domain)
        domain = register_task_methods(domain)
        domain = register_goal_methods(domain)
        {:ok, domain}

      error ->
        error
    end
  end

  @doc """
  Creates the base planning domain structure.
  """
  @spec create_planning_domain() :: {:ok, map()} | {:error, String.t()}
  def create_planning_domain do
    {:ok,
     %{
       type: "fox_geese_corn",
       predicates: ["east_fox", "east_geese", "east_corn", "west_fox", "west_geese", "west_corn", "boat_location"],
       actions: [],
       methods: [],
       goal_methods: [],
       created_at: DateTime.utc_now()
     }}
  end

  defp register_actions(domain) do
    actions = [
      %{
        name: "a_cross_east",
        arity: 3,
        preconditions: [
          "boat_location == 'west'",
          "west_fox >= fox_count",
          "west_geese >= geese_count",
          "west_corn >= corn_count",
          "fox_count + geese_count + corn_count <= boat_capacity",
          "fox_count + geese_count + corn_count > 0"
        ],
        effects: [
          "west_fox = west_fox - fox_count",
          "west_geese = west_geese - geese_count",
          "west_corn = west_corn - corn_count",
          "east_fox = east_fox + fox_count",
          "east_geese = east_geese + geese_count",
          "east_corn = east_corn + corn_count",
          "boat_location = 'east'"
        ]
      },
      %{
        name: "a_cross_west",
        arity: 3,
        preconditions: [
          "boat_location == 'east'",
          "east_fox >= fox_count",
          "east_geese >= geese_count",
          "east_corn >= corn_count",
          "fox_count + geese_count + corn_count <= boat_capacity"
        ],
        effects: [
          "east_fox = east_fox - fox_count",
          "east_geese = east_geese - geese_count",
          "east_corn = east_corn - corn_count",
          "west_fox = west_fox + fox_count",
          "west_geese = west_geese + geese_count",
          "west_corn = west_corn + corn_count",
          "boat_location = 'west'"
        ]
      }
    ]

    Map.put(domain, :actions, actions)
  end

  defp register_task_methods(domain) do
    methods = [
      %{
        name: "transport_all",
        type: "task",
        arity: 1,
        decomposition: "transport all items to east side"
      }
    ]

    Map.update(domain, :methods, methods, &(&1 ++ methods))
  end

  defp register_goal_methods(domain) do
    goal_methods = [
      %{
        name: "transport_all",
        type: "multigoal",
        arity: 1,
        predicate: nil,
        decomposition: "transport all items to east side (goal-based)"
      }
    ]

    Map.update(domain, :goal_methods, goal_methods, &(&1 ++ goal_methods))
  end

  @doc """
  Initializes the fox-geese-corn state with given parameters.
  """
  @spec initialize_state(params :: map()) :: {:ok, map()} | {:error, String.t()}
  def initialize_state(params) do
    try do
      state = %{
        west_fox: params.f || 0,
        west_geese: params.g || 0,
        west_corn: params.c || 0,
        east_fox: 0,
        east_geese: 0,
        east_corn: 0,
        boat_location: "west",
        boat_capacity: params.k || 2,
        pf: params.pf || 1,
        pg: params.pg || 1,
        pc: params.pc || 1
      }

      {:ok, state}
    rescue
      e ->
        {:error, "Failed to initialize state: #{inspect(e)}"}
    end
  end

  @doc """
  Checks if a state is safe (no fox with geese alone, no geese with corn alone).
  """
  @spec is_safe?(state :: map()) :: boolean()
  def is_safe?(state) do
    west_safe = check_side_safe(state.west_fox, state.west_geese, state.west_corn)
    east_safe = check_side_safe(state.east_fox, state.east_geese, state.east_corn)
    west_safe and east_safe
  end

  defp check_side_safe(fox, geese, corn) do
    cond do
      # Only one type present - always safe
      (fox > 0 and geese == 0 and corn == 0) or
        (fox == 0 and geese > 0 and corn == 0) or
          (fox == 0 and geese == 0 and corn > 0) ->
        true

      # All together - safe
      fox > 0 and geese > 0 and corn > 0 ->
        true

      # Fox and geese alone - unsafe
      fox > 0 and geese > 0 and corn == 0 ->
        false

      # Geese and corn alone - unsafe
      fox == 0 and geese > 0 and corn > 0 ->
        false

      # Empty - safe
      fox == 0 and geese == 0 and corn == 0 ->
        true

      true ->
        true
    end
  end

  @doc """
  Calculates the objective value (points) for a state.
  """
  @spec calculate_objective(state :: map()) :: integer()
  def calculate_objective(state) do
    state.east_fox * state.pf + state.east_geese * state.pg + state.east_corn * state.pc
  end

  @doc """
  Parses a MiniZinc .dzn data file.
  """
  @spec parse_dzn_file(path :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse_dzn_file(path) do
    case File.read(path) do
      {:ok, content} ->
        params = %{}
        params = parse_dzn_line(content, "f", params, :f)
        params = parse_dzn_line(content, "g", params, :g)
        params = parse_dzn_line(content, "c", params, :c)
        params = parse_dzn_line(content, "k", params, :k)
        params = parse_dzn_line(content, "t", params, :t)
        params = parse_dzn_line(content, "pf", params, :pf)
        params = parse_dzn_line(content, "pg", params, :pg)
        params = parse_dzn_line(content, "pc", params, :pc)
        {:ok, params}

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  defp parse_dzn_line(content, key, params, param_key) do
    regex = ~r/#{key}\s*=\s*(\d+);/

    case Regex.run(regex, content) do
      [_, value] ->
        Map.put(params, param_key, String.to_integer(value))

      nil ->
        params
    end
  end
end
