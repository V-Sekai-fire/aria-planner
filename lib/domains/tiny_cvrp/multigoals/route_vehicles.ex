# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp.Multigoals.RouteVehicles do
  @moduledoc """
  Multigoal Method: m_route_vehicles(state)

  Route all vehicles to visit all customers (goal-based).

  Returns a list of goals to achieve.
  """

  alias AriaPlanner.Domains.TinyCvrp
  alias AriaPlanner.Domains.TinyCvrp.Predicates.CustomerVisited

  @spec m_route_vehicles(state :: map()) :: [tuple()]
  def m_route_vehicles(state) do
    if TinyCvrp.all_customers_visited?(state) do
      []
    else
      # Generate goals for all unvisited customers
      goals =
        for customer <- 2..state.total_places,
            not CustomerVisited.get(state, customer) do
          {"customer_visited", [customer, true]}
        end

      goals
    end
  end
end
