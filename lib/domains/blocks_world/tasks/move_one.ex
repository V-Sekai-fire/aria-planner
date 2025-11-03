# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Tasks.MoveOne do
  @moduledoc """
  Task: t_move_one(block, destination)

  Move a single block to a destination.

  Generate subtasks to get a block and put it at a destination.

  Returns: [{"t_get", block}, {"t_put", block, destination}]
  """

  @spec t_move_one(block_id :: String.t(), destination :: String.t()) :: [tuple()]
  def t_move_one(block_id, destination) do
    [{"t_get", block_id}, {"t_put", block_id, destination}]
  end
end
