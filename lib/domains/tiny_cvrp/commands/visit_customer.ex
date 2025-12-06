# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp.Commands.VisitCustomer do
  @moduledoc """
  Command: c_visit_customer(vehicle, customer)

  Visit a customer with a vehicle.

  Preconditions:
  - Customer has not been visited
  - Vehicle has sufficient capacity
  - Vehicle is at a valid location

  Effects:
  - vehicle_at[vehicle] = customer
  - customer_visited[customer] = true
  - vehicle_capacity[vehicle] decreases by customer demand
  """

  alias AriaPlanner.Domains.TinyCvrp.Predicates.{
    VehicleAt,
    CustomerVisited,
    VehicleCapacity
  }

  defstruct vehicle: nil, customer: nil

  @spec c_visit_customer(state :: map(), vehicle :: integer(), customer :: integer()) ::
          {:ok, map()} | {:error, String.t()}
  def c_visit_customer(state, vehicle, customer) do
    with :ok <- check_customer_not_visited(state, customer),
         :ok <- check_vehicle_capacity(state, vehicle, customer) do
      demand = get_customer_demand(state, customer)

      new_state =
        state
        |> VehicleAt.set(vehicle, customer)
        |> CustomerVisited.set(customer, true)
        |> VehicleCapacity.set(vehicle, VehicleCapacity.get(state, vehicle) - demand)

      {:ok, new_state}
    else
      error -> error
    end
  end

  # Private helper functions

  defp check_customer_not_visited(state, customer) do
    if CustomerVisited.get(state, customer) do
      {:error, "Customer #{customer} has already been visited"}
    else
      :ok
    end
  end

  defp check_vehicle_capacity(state, vehicle, customer) do
    current_capacity = VehicleCapacity.get(state, vehicle)
    demand = get_customer_demand(state, customer)

    if current_capacity >= demand do
      :ok
    else
      {:error, "Vehicle #{vehicle} has insufficient capacity (#{current_capacity} < #{demand})"}
    end
  end

  defp get_customer_demand(state, customer) do
    demands = state.predicted_demands || []
    # Customer IDs: 1=depot, 2+=customers
    # Demands array: [depot_demand, customer_2_demand, customer_3_demand, ...]
    # So customer N is at index N-1
    if customer == 1 do
      # Depot has no demand
      0
    else
      Enum.at(demands, customer - 1, 0)
    end
  end
end
