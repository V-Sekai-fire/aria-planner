# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp.Predicates.VehicleCapacity do
  @moduledoc """
  Vehicle Capacity predicate for tiny-cvrp domain.
  
  Represents the remaining capacity of a vehicle.
  """

  @doc """
  Gets the remaining capacity of a vehicle from state.
  """
  @spec get(state :: map(), vehicle :: integer()) :: integer()
  def get(state, vehicle) do
    Map.get(state.vehicle_capacity, vehicle, 0)
  end

  @doc """
  Sets the capacity of a vehicle in state.
  """
  @spec set(state :: map(), vehicle :: integer(), capacity :: integer()) :: map()
  def set(state, vehicle, capacity) do
    new_vehicle_capacity = Map.put(state.vehicle_capacity, vehicle, capacity)
    Map.put(state, :vehicle_capacity, new_vehicle_capacity)
  end
end

