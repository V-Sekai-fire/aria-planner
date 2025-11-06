# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Predicates.WestFox do
  @moduledoc """
  West Fox predicate for fox-geese-corn domain.
  
  Represents the number of foxes on the west side of the river.
  """

  @doc """
  Gets the current value of west_fox from state.
  """
  @spec get(state :: map()) :: integer()
  def get(state), do: Map.get(state, :west_fox, 0)

  @doc """
  Sets the value of west_fox in state.
  """
  @spec set(state :: map(), value :: integer()) :: map()
  def set(state, value) do
    Map.put(state, :west_fox, value)
  end
end

