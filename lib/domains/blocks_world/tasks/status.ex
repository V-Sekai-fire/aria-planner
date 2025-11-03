# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Tasks.Status do
  @moduledoc """
  Task: t_status(block, goal)

  Return the status of a block:
  - 'done' - block is in final position
  - 'inaccessible' - block has something on top of it
  - 'move-to-table' - block needs to move to table
  - 'move-to-block' - block can move to its final position
  - 'waiting' - block needs to move but can't yet
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.Clear
  alias AriaPlanner.Domains.BlocksWorld.Tasks.IsDone
  alias AriaPlanner.Repo

  @spec t_status(block_id :: String.t(), goal_state :: map()) :: String.t()
  def t_status(block_id, goal_state) do
    cond do
      IsDone.t_is_done(block_id, goal_state) ->
        "done"

      not is_clear(block_id) ->
        "inaccessible"

      not Map.has_key?(goal_state, block_id) or Map.get(goal_state, block_id) == "table" ->
        "move-to-table"

      true ->
        goal_pos = Map.get(goal_state, block_id)

        if IsDone.t_is_done(goal_pos, goal_state) and is_clear(goal_pos) do
          "move-to-block"
        else
          "waiting"
        end
    end
  end

  # Private helper functions

  @spec is_clear(block_id :: String.t()) :: boolean()
  defp is_clear(block_id) do
    case Repo.get_by(Clear, entity_id: block_id) do
      %Clear{value: value} -> value
      nil -> false
    end
  end
end
