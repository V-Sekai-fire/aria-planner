# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Unigoals.Get do
  @moduledoc """
  Unigoal Method: u_get(block, destination)

  Get a block (pickup or unstack).

  If goal is ('pos', block, 'hand') and block is clear and we're holding nothing,
  generate either a pickup or an unstack subtask for block.

  Returns:
  - [{"c_pickup", block}] if block is on the table
  - [{"c_unstack", block, from_block}] if block is on another block
  - nil otherwise
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.{Pos, Clear, Holding}
  alias AriaPlanner.Repo

  @spec u_get(block_id :: String.t(), destination :: String.t()) :: [tuple()] | nil
  def u_get(block_id, destination) do
    if destination == "hand" and is_clear(block_id) and get_holding() == "false" do
      case get_pos(block_id) do
        "table" ->
          [{"c_pickup", block_id}]

        from_block when is_binary(from_block) ->
          [{"c_unstack", block_id, from_block}]

        _ ->
          nil
      end
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

  @spec is_clear(block_id :: String.t()) :: boolean()
  defp is_clear(block_id) do
    case Repo.get_by(Clear, entity_id: block_id) do
      %Clear{value: value} -> value
      nil -> false
    end
  end

  @spec get_holding() :: String.t() | nil
  defp get_holding do
    case Repo.get_by(Holding, entity_id: "hand") do
      %Holding{value: value} -> value
      nil -> "false"
    end
  end
end
