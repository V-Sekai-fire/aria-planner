# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Predicates.LocationCapacity do
  @moduledoc """
  Location Capacity predicate for aircraft-disassembly domain.

  Represents the capacity of a location (maximum number of activities that can run simultaneously).
  """

  @doc """
  Gets the capacity of a location from state.
  """
  @spec get(state :: map(), location :: integer()) :: integer()
  def get(state, location) do
    Map.get(state.location_capacity, location, 1)
  end

  @doc """
  Sets the capacity of a location in state.
  """
  @spec set(state :: map(), location :: integer(), capacity :: integer()) :: map()
  def set(state, location, capacity) do
    new_location_capacity = Map.put(state.location_capacity, location, capacity)
    Map.put(state, :location_capacity, new_location_capacity)
  end
end
