# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Unigoals.Put do
  @moduledoc """
  Unigoal Method: u_put(block, destination)

  Put a block down (putdown or stack).

  If goal is ('pos', block, destination) and we're holding block,
  generate either a putdown or a stack subtask for block.

  Returns:
  - [{"c_putdown", block}] if destination is the table
  - [{"c_stack", block, destination}] if destination is another block and it's clear
  - nil otherwise
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.{Clear, Pos}
  alias AriaPlanner.Repo

  @spec u_put(block_id :: String.t(), destination :: String.t()) :: [tuple()] | nil
  def u_put(block_id, destination) do
    if destination != "hand" and get_pos(block_id) == "hand" do
      case destination do
        "table" ->
          [{"c_putdown", block_id}]

        _ ->
          if is_clear(destination) do
            [{"c_stack", block_id, destination}]
          end
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
end
