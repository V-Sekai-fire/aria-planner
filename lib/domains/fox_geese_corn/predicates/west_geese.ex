# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Predicates.WestGeese do
  @moduledoc """
  West Geese predicate for fox-geese-corn domain.
  
  Represents the number of geese on the west side of the river.
  """

  @doc """
  Gets the current value of west_geese from state.
  """
  @spec get(state :: map()) :: integer()
  def get(state), do: Map.get(state, :west_geese, 0)

  @doc """
  Sets the value of west_geese in state.
  """
  @spec set(state :: map(), value :: integer()) :: map()
  def set(state, value) do
    Map.put(state, :west_geese, value)
  end
end

