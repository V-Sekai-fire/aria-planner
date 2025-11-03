# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Multigoals.MoveBlocks do
  @moduledoc """
  Multigoal Method: m_move_blocks(multigoal)

  Move all blocks to their goal positions.

  This method implements the following block-stacking algorithm:
  1. If there's a clear block that can be moved to its final position, do so and recurse
  2. Otherwise, if there's a clear block that needs to be moved out of the way, move it to table and recurse
  3. Otherwise, no blocks need to be moved

  Returns a list of goals to achieve.
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.Clear
  alias AriaPlanner.Domains.BlocksWorld.Tasks.{Status, AllBlocks, FindIf}
  alias AriaPlanner.Repo

  @spec m_move_blocks(goal_state :: map()) :: [tuple()]
  def m_move_blocks(goal_state) do
    clear_blocks = all_clear_blocks()

    # Check each clear block for its status
    case Enum.find_value(clear_blocks, fn block ->
      status = Status.t_status(block, goal_state)

      case status do
        "move-to-block" ->
          destination = Map.get(goal_state, block)
          [{"pos", block, destination}, goal_state]

        "move-to-table" ->
          [{"pos", block, "table"}, goal_state]

        _ ->
          nil
      end
    end) do
      nil ->
        # No blocks can be moved to their final locations
        # Check if there's a waiting block
        waiting_block =
          FindIf.t_find_if(
            fn block -> Status.t_status(block, goal_state) == "waiting" end,
            clear_blocks
          )

        if waiting_block do
          [{"pos", waiting_block, "table"}, goal_state]
        else
          # No blocks need moving
          []
        end

      goals ->
        goals
    end
  end

  # Private helper functions

  @spec all_clear_blocks() :: [String.t()]
  defp all_clear_blocks do
    AllBlocks.t_all_blocks()
    |> Enum.filter(&is_clear/1)
  end

  @spec is_clear(block_id :: String.t()) :: boolean()
  defp is_clear(block_id) do
    case Repo.get_by(Clear, entity_id: block_id) do
      %Clear{value: value} -> value
      nil -> false
    end
  end
end
