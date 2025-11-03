# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Unigoals.Move1 do
  @moduledoc """
  Unigoal Method: u_move1(block, destination)

  Move a block to a destination.

  If block is clear, we're holding nothing, and destination is either the table or clear,
  then assert goals to get block and put it on destination.

  Returns:
  - [{"pos", block, "hand"}, {"pos", block, destination}] if conditions met
  - nil otherwise
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.{Clear, Holding}
  alias AriaPlanner.Repo

  @spec u_move1(block_id :: String.t(), destination :: String.t()) :: [tuple()] | nil
  def u_move1(block_id, destination) do
    if destination != "hand" and is_clear(block_id) and get_holding() == "false" do
      if destination == "table" or is_clear(destination) do
        [{"pos", block_id, "hand"}, {"pos", block_id, destination}]
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

  @spec get_holding() :: String.t() | nil
  defp get_holding do
    case Repo.get_by(Holding, entity_id: "hand") do
      %Holding{value: value} -> value
      nil -> "false"
    end
  end
end
