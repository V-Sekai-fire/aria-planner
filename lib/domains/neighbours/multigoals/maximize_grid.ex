# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Neighbours.Multigoals.MaximizeGrid do
  @moduledoc """
  Multigoal Method: m_maximize_grid(state)
  
  Assign values to all grid cells to maximize the sum (goal-based).
  
  Returns a list of goals to achieve.
  """

  alias AriaPlanner.Domains.Neighbours
  alias AriaPlanner.Domains.Neighbours.Predicates.GridValue

  @spec m_maximize_grid(state :: map()) :: [tuple()]
  def m_maximize_grid(state) do
    if Neighbours.is_complete?(state) do
      []
    else
      # Generate goals for all unassigned cells
      goals =
        for row <- 1..state.n, col <- 1..state.m, GridValue.get(state, row, col) == 0 do
          max_value = find_max_assignable_value(state, row, col)
          # Use tuple as subject_id for grid position
          {"grid_value", [{row, col}, max_value]}
        end

      goals
    end
  end

  defp find_max_assignable_value(state, row, col) do
    # Try values from 5 down to 1
    Enum.find_value(5..1, fn value ->
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
    end) || 1
  end
end

