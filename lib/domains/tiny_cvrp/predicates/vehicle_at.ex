# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp.Predicates.VehicleAt do
  @moduledoc """
  Vehicle At predicate for tiny-cvrp domain.
  
  Represents the current location of a vehicle (depot = 1, customers = 2..total_places).
  """

  @doc """
  Gets the current location of a vehicle from state.
  """
  @spec get(state :: map(), vehicle :: integer()) :: integer()
  def get(state, vehicle) do
    Map.get(state.vehicle_at, vehicle, 1)
  end

  @doc """
  Sets the location of a vehicle in state.
  """
  @spec set(state :: map(), vehicle :: integer(), location :: integer()) :: map()
  def set(state, vehicle, location) do
    new_vehicle_at = Map.put(state.vehicle_at, vehicle, location)
    Map.put(state, :vehicle_at, new_vehicle_at)
  end
end

