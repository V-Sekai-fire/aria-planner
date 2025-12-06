# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp.Tasks.RouteVehicles do
  @moduledoc """
  Task: t_route_vehicles(state)

  Route all vehicles to visit all customers.

  Returns a list of subtasks to execute.
  """

  alias AriaPlanner.Domains.TinyCvrp
  alias AriaPlanner.Domains.TinyCvrp.Predicates.{CustomerVisited, VehicleAt, VehicleCapacity}

  @spec t_route_vehicles(state :: map()) :: [tuple()]
  def t_route_vehicles(state) do
    if TinyCvrp.all_customers_visited?(state) do
      []
    else
      # Find unvisited customer and available vehicle
      case find_unvisited_customer(state) do
        nil ->
          []

        customer ->
          case find_available_vehicle(state, customer) do
            nil ->
              []

            vehicle ->
              [{"c_visit_customer", vehicle, customer}, {"t_route_vehicles", state}]
          end
      end
    end
  end

  defp find_unvisited_customer(state) do
    Enum.find(2..state.total_places, fn customer ->
      not CustomerVisited.get(state, customer)
    end)
  end

  defp find_available_vehicle(state, customer) do
    demand = get_customer_demand(state, customer)

    Enum.find(1..state.num_vehicles, fn vehicle ->
      _current_location = VehicleAt.get(state, vehicle)
      capacity = VehicleCapacity.get(state, vehicle)

      # Vehicle must have sufficient capacity
      capacity >= demand
    end)
  end

  defp get_customer_demand(state, customer) do
    demands = state.predicted_demands || []
    # Customer IDs: 1=depot, 2+=customers
    # Demands array: [depot_demand, customer_2_demand, customer_3_demand, ...]
    if customer == 1 do
      # Depot has no demand
      0
    else
      Enum.at(demands, customer - 1, 0)
    end
  end
end
