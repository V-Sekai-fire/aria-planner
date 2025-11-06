# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Neighbours.Predicates.GridValue do
  @moduledoc """
  Grid Value predicate for neighbours domain.
  
  Represents the value assigned to a cell at position (row, col).
  """

  @doc """
  Gets the current value at (row, col) from state.
  """
  @spec get(state :: map(), row :: integer(), col :: integer()) :: integer()
  def get(state, row, col) do
    Map.get(state.grid, {row, col}, 0)
  end

  @doc """
  Sets the value at (row, col) in state.
  """
  @spec set(state :: map(), row :: integer(), col :: integer(), value :: integer()) :: map()
  def set(state, row, col, value) when value >= 1 and value <= 5 do
    new_grid = Map.put(state.grid, {row, col}, value)
    Map.put(state, :grid, new_grid)
  end
end

