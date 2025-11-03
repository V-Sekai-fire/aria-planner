# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Tasks.IsDone do
  @moduledoc """
  Task: t_is_done(block, goal)

  Check if a block is in its final position according to the goal.

  Returns true if:
  - block is 'table' (always done)
  - block is not in goal (done if on table)
  - block's position matches goal position and all blocks below it are done
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.Pos
  alias AriaPlanner.Repo

  @spec t_is_done(block_id :: String.t(), goal_state :: map()) :: boolean()
  def t_is_done(block_id, goal_state) do
    cond do
      block_id == "table" ->
        true

      Map.has_key?(goal_state, block_id) ->
        goal_pos = Map.get(goal_state, block_id)
        current_pos = get_pos(block_id)

        if goal_pos != current_pos do
          false
        else
          # Check if all blocks below this one are done
          if current_pos == "table" do
            true
          else
            t_is_done(current_pos, goal_state)
          end
        end

      true ->
        # Block not in goal, so it's done if on table
        get_pos(block_id) == "table"
    end
  end

  # Private helper functions

  @spec get_pos(block_id :: String.t()) :: String.t() | nil
  defp get_pos(block_id) do
    case Repo.get_by(Pos, entity_id: block_id) do
      %Pos{value: value} -> value
      nil -> nil
    end
  end
end
