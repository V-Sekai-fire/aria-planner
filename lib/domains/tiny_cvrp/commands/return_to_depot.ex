# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp.Commands.ReturnToDepot do
  @moduledoc """
  Command: c_return_to_depot(vehicle)
  
  Return a vehicle to the depot and reset its capacity.
  
  Preconditions:
  - Vehicle is not already at depot
  
  Effects:
  - vehicle_at[vehicle] = 1 (depot)
  - vehicle_capacity[vehicle] = initial_capacity[vehicle]
  """

  alias AriaPlanner.Domains.TinyCvrp.Predicates.{VehicleAt, VehicleCapacity}

  defstruct vehicle: nil

  @spec c_return_to_depot(state :: map(), vehicle :: integer()) ::
          {:ok, map()} | {:error, String.t()}
  def c_return_to_depot(state, vehicle) do
    current_location = VehicleAt.get(state, vehicle)

    if current_location == 1 do
      {:error, "Vehicle #{vehicle} is already at depot"}
    else
      initial_capacity = Map.get(state.initial_capacities, vehicle, 0)

      new_state =
        state
        |> VehicleAt.set(vehicle, 1)
        |> VehicleCapacity.set(vehicle, initial_capacity)

      {:ok, new_state}
    end
  end
end

