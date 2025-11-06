# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp do
  @moduledoc """
  Tiny CVRP (Capacitated Vehicle Routing Problem) planning domain.
  
  Vehicle routing problem where:
  - Multiple vehicles start at a depot
  - Each vehicle has a capacity
  - Each customer has a demand
  - Each customer must be visited exactly once
  - Goal: Minimize total distance/ETA
  """

  alias AriaPlanner.Domains.TinyCvrp.Predicates.{
    VehicleAt,
    CustomerVisited,
    VehicleCapacity,
    Distance
  }

  @doc """
  Creates and registers the tiny-cvrp planning domain.
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
       type: "tiny_cvrp",
       predicates: ["vehicle_at", "customer_visited", "vehicle_capacity", "distance"],
       actions: [],
       methods: [],
       goal_methods: [],
       created_at: DateTime.utc_now()
     }}
  end

  defp register_actions(domain) do
    actions = [
      %{
        name: "a_visit_customer",
        arity: 2,
        preconditions: [
          "vehicle_at[vehicle] == current_location",
          "customer_visited[customer] == false",
          "vehicle_capacity[vehicle] >= predicted_demands[customer]",
          "distance[current_location, customer] is defined"
        ],
        effects: [
          "vehicle_at[vehicle] = customer",
          "customer_visited[customer] = true",
          "vehicle_capacity[vehicle] = vehicle_capacity[vehicle] - predicted_demands[customer]"
        ]
      },
      %{
        name: "a_return_to_depot",
        arity: 1,
        preconditions: [
          "vehicle_at[vehicle] != 1 (depot)"
        ],
        effects: [
          "vehicle_at[vehicle] = 1",
          "vehicle_capacity[vehicle] = initial_capacity[vehicle]"
        ]
      }
    ]

    Map.put(domain, :actions, actions)
  end

  defp register_task_methods(domain) do
    methods = [
      %{
        name: "route_vehicles",
        type: "task",
        arity: 1,
        decomposition: "route all vehicles to visit all customers"
      }
    ]

    Map.update(domain, :methods, methods, &(&1 ++ methods))
  end

  defp register_goal_methods(domain) do
    goal_methods = [
      %{
        name: "route_vehicles",
        type: "multigoal",
        arity: 1,
        predicate: nil,
        decomposition: "route all vehicles to visit all customers (goal-based)"
      }
    ]

    Map.update(domain, :goal_methods, goal_methods, &(&1 ++ goal_methods))
  end

  @doc """
  Initializes the CVRP state with given parameters.
  """
  @spec initialize_state(params :: map()) :: {:ok, map()} | {:error, String.t()}
  def initialize_state(params) do
    try do
      num_vehicles = params.num_vehicles || 1
      num_customers = params.num_customers || 0
      total_places = num_customers + 1

      # Initialize vehicle positions (all at depot = 1)
      vehicle_at = for v <- 1..num_vehicles, into: %{} do
        {v, 1}
      end

      # Initialize customer visited status (all false)
      customer_visited = for c <- 2..total_places, into: %{} do
        {c, false}
      end

      # Initialize vehicle capacities
      vehicle_capacities = params.vehicle_capacities || [500]

      vehicle_capacity = for {capacity, v} <- Enum.with_index(vehicle_capacities, 1), into: %{} do
        {v, capacity}
      end

      state = %{
        num_vehicles: num_vehicles,
        num_customers: num_customers,
        total_places: total_places,
        vehicle_at: vehicle_at,
        customer_visited: customer_visited,
        vehicle_capacity: vehicle_capacity,
        predicted_demands: Map.get(params, :predicted_demands) || [],
        predicted_ETAs: Map.get(params, :predicted_ETAs) || %{},
        initial_capacities: vehicle_capacity
      }

      {:ok, state}
    rescue
      e ->
        {:error, "Failed to initialize state: #{inspect(e)}"}
    end
  end

  @doc """
  Calculates the total ETA for all vehicle routes.
  """
  @spec calculate_total_eta(state :: map()) :: integer()
  def calculate_total_eta(state) do
    # This is a simplified calculation
    # In a full implementation, we'd track the actual route sequence
    0
  end

  @doc """
  Checks if all customers have been visited.
  """
  @spec all_customers_visited?(state :: map()) :: boolean()
  def all_customers_visited?(state) do
    state.customer_visited
    |> Map.values()
    |> Enum.all?(& &1)
  end

  @doc """
  Parses a MiniZinc .dzn data file.
  """
  @spec parse_dzn_file(path :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse_dzn_file(path) do
    case File.read(path) do
      {:ok, content} ->
        params = %{}
        params = parse_dzn_line(content, "num_vehicles", params, :num_vehicles)
        params = parse_dzn_line(content, "num_customers", params, :num_customers)
        params = parse_array_line(content, "vehicle_capacities", params, :vehicle_capacities)
        params = parse_array_line(content, "predicted_demands", params, :predicted_demands)
        params = parse_matrix_line(content, "predicted_ETAs", params, :predicted_ETAs)
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

  defp parse_array_line(content, key, params, param_key) do
    regex = ~r/#{key}\s*=\s*\[([^\]]+)\];/
    case Regex.run(regex, content) do
      [_, values] ->
        array_values = values
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.to_integer/1)
        Map.put(params, param_key, array_values)
      nil ->
        params
    end
  end

  defp parse_matrix_line(content, key, params, param_key) do
    # Simplified matrix parsing - would need more complex regex for full matrix
    # For now, return empty map
    params
  end
end

