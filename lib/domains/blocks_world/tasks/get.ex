# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Tasks.Get do
  @moduledoc """
  Task: t_get(block)

  Get a block (pickup or unstack).

  Generate either a pickup or an unstack subtask for a block.

  Returns:
  - [{"c_pickup", block}] if block is on the table
  - [{"c_unstack", block, from_block}] if block is on another block
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.Pos
  alias AriaPlanner.Repo

  @spec t_get(block_id :: String.t()) :: [tuple()] | []
  def t_get(block_id) do
    case get_pos(block_id) do
      "table" ->
        [{"c_pickup", block_id}]

      from_block when is_binary(from_block) ->
        [{"c_unstack", block_id, from_block}]

      _ ->
        []
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
