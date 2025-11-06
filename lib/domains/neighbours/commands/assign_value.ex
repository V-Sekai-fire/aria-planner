# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Neighbours.Commands.AssignValue do
  @moduledoc """
  Command: c_assign_value(row, col, value)
  
  Assign a value to a grid cell.
  
  Preconditions:
  - Cell is unassigned (value == 0)
  - Value is between 1 and 5
  - If value > 1, cell must have neighbors with values 1..value-1
  
  Effects:
  - grid_value[row, col] = value
  """

  alias AriaPlanner.Domains.Neighbours
  alias AriaPlanner.Domains.Neighbours.Predicates.GridValue

  defstruct row: nil, col: nil, value: nil

  @spec c_assign_value(state :: map(), row :: integer(), col :: integer(), value :: integer()) ::
          {:ok, map()} | {:error, String.t()}
  def c_assign_value(state, row, col, value) when value >= 1 and value <= 5 do
    with :ok <- check_unassigned(state, row, col),
         :ok <- check_neighbor_constraint(state, row, col, value) do
      new_state = GridValue.set(state, row, col, value)
      {:ok, new_state}
    else
      error -> error
    end
  end

  def c_assign_value(_state, _row, _col, value) do
    {:error, "Value must be between 1 and 5, got #{value}"}
  end

  # Private helper functions

  defp check_unassigned(state, row, col) do
    current_value = GridValue.get(state, row, col)

    if current_value == 0 do
      :ok
    else
      {:error, "Cell (#{row}, #{col}) is already assigned value #{current_value}"}
    end
  end

  defp check_neighbor_constraint(state, row, col, value) do
    if value == 1 do
      :ok
    else
      required_values = 1..(value - 1)

      if Neighbours.has_neighbors_with_values(state, row, col, required_values) do
        :ok
      else
        {:error, "Cell (#{row}, #{col}) cannot have value #{value} without neighbors having values #{inspect(required_values)}"}
      end
    end
  end
end

