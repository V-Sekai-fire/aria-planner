# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Predicates.EastGeese do
  @moduledoc """
  East Geese predicate for fox-geese-corn domain.
  
  Represents the number of geese on the east side of the river.
  """

  @doc """
  Gets the current value of east_geese from state.
  """
  @spec get(state :: map()) :: integer()
  def get(state), do: Map.get(state, :east_geese, 0)

  @doc """
  Sets the value of east_geese in state.
  """
  @spec set(state :: map(), value :: integer()) :: map()
  def set(state, value) do
    Map.put(state, :east_geese, value)
  end
end

