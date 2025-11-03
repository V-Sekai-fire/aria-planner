# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Tasks.MoveBlocks do
  @moduledoc """
  Task: t_move_blocks(goal)

  Move all blocks to their goal positions.

  This task implements the following block-stacking algorithm:
  1. If there's a block that can be moved to its final position, do so and recurse
  2. Otherwise, if there's a block that needs to be moved and can be moved to the table, do so and recurse
  3. Otherwise, if there's a block waiting to be moved, move it to the table and recurse
  4. Otherwise, no blocks need to be moved (return empty task list)

  Returns a list of subtasks to execute.
  """

  alias AriaPlanner.Domains.BlocksWorld.Tasks.{Status, AllBlocks, FindIf}

  @spec t_move_blocks(goal_state :: map()) :: [tuple()]
  def t_move_blocks(goal_state) do
    blocks = AllBlocks.t_all_blocks()

    # Check each block for its status
    case Enum.find_value(blocks, fn block ->
      status = Status.t_status(block, goal_state)

      case status do
        "move-to-table" ->
          [{"t_move_one", block, "table"}, {"t_move_blocks", goal_state}]

        "move-to-block" ->
          goal_pos = Map.get(goal_state, block)
          [{"t_move_one", block, goal_pos}, {"t_move_blocks", goal_state}]

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
            blocks
          )

        if waiting_block do
          [{"t_move_one", waiting_block, "table"}, {"t_move_blocks", goal_state}]
        else
          # No blocks need moving
          []
        end

      subtasks ->
        subtasks
    end
  end
end
