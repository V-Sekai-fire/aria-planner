# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Predicates.BoatLocation do
  @moduledoc """
  Boat Location predicate for fox-geese-corn domain.
  
  Represents where the boat is: "west" or "east".
  """

  @doc """
  Gets the current value of boat_location from state.
  """
  @spec get(state :: map()) :: String.t()
  def get(state), do: Map.get(state, :boat_location, "west")

  @doc """
  Sets the value of boat_location in state.
  """
  @spec set(state :: map(), value :: String.t()) :: map()
  def set(state, value) when value in ["west", "east"] do
    Map.put(state, :boat_location, value)
  end
end

