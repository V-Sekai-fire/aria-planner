# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Neighbours.Tasks.MaximizeGrid do
  @moduledoc """
  Task: t_maximize_grid(state)

  Assign values to all grid cells to maximize the sum.

  Returns a list of subtasks to execute.
  """

  alias AriaPlanner.Domains.Neighbours
  alias AriaPlanner.Domains.Neighbours.Predicates.GridValue

  @spec t_maximize_grid(state :: map()) :: [tuple()]
  def t_maximize_grid(state) do
    if Neighbours.is_complete?(state) do
      []
    else
      # Find first unassigned cell
      case find_unassigned_cell(state) do
        nil ->
          []

        {row, col} ->
          # Try to assign maximum possible value
          max_value = find_max_assignable_value(state, row, col)

          if max_value > 0 do
            [{"c_assign_value", row, col, max_value}, {"t_maximize_grid", state}]
          else
            []
          end
      end
    end
  end

  defp find_unassigned_cell(state) do
    Enum.find_value(1..state.n, fn row ->
      Enum.find_value(1..state.m, fn col ->
        if GridValue.get(state, row, col) == 0 do
          {row, col}
        else
          nil
        end
      end)
    end)
  end

  defp find_max_assignable_value(state, row, col) do
    # Try values from 5 down to 1
    Enum.find_value(5..1//-1, fn value ->
      if value == 1 do
        1
      else
        required_values = 1..(value - 1)

        if Neighbours.has_neighbors_with_values(state, row, col, required_values) do
          value
        else
          nil
        end
      end
    end) || 0
  end
end
