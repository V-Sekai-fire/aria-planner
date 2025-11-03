# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Tasks.Put do
  @moduledoc """
  Task: t_put(block, destination)

  Put a block down (putdown or stack).

  Generate either a putdown or a stack subtask for a block.

  Returns:
  - [{"c_putdown", block}] if destination is the table
  - [{"c_stack", block, destination}] if destination is another block
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.Holding
  alias AriaPlanner.Repo

  @spec t_put(block_id :: String.t(), destination :: String.t()) :: [tuple()] | []
  def t_put(block_id, destination) do
    case get_holding() do
      ^block_id ->
        case destination do
          "table" ->
            [{"c_putdown", block_id}]

          _ ->
            [{"c_stack", block_id, destination}]
        end

      _ ->
        []
    end
  end

  # Private helper functions

  @spec get_holding() :: String.t() | nil
  defp get_holding do
    case Repo.get_by(Holding, entity_id: "hand") do
      %Holding{value: value} -> value
      nil -> nil
    end
  end
end
