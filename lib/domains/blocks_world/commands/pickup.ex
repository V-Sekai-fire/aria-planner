# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Commands.Pickup do
  @moduledoc """
  Command: c_pickup(block)

  Pick up a block from the table.

  Preconditions:
  - block is on the table
  - block is clear (nothing on top)
  - hand is empty

  Effects:
  - block is now in hand
  - block is no longer clear
  - hand is holding the block
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.{Pos, Clear, Holding}
  alias AriaPlanner.Repo

  defstruct obj: nil

  @spec c_pickup(block_id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_pickup(block_id) do
    with {:ok, pos} <- get_pos(block_id),
         {:ok, clear} <- get_clear(block_id),
         {:ok, holding} <- get_holding(),
         true <- pos.value == "table",
         true <- clear.value == true,
         true <- holding.value == "false" or is_nil(holding.value) do
      # Update state
      {:ok, _} = Pos.update(pos, %{value: "hand"})
      {:ok, _} = Clear.update(clear, %{value: false})
      {:ok, _} = Holding.update(holding, %{value: block_id})

      {:ok, %{command: "c_pickup", block: block_id}}
    else
      false -> {:error, "Preconditions not met for c_pickup(#{block_id})"}
      error -> error
    end
  end

  # Private helper functions

  @spec get_pos(block_id :: String.t()) :: {:ok, Pos.t()} | {:error, String.t()}
  defp get_pos(block_id) do
    case Repo.get_by(Pos, entity_id: block_id) do
      %Pos{} = pos -> {:ok, pos}
      nil -> {:error, "Position not found for block #{block_id}"}
    end
  end

  @spec get_clear(block_id :: String.t()) :: {:ok, Clear.t()} | {:error, String.t()}
  defp get_clear(block_id) do
    case Repo.get_by(Clear, entity_id: block_id) do
      %Clear{} = clear -> {:ok, clear}
      nil -> {:error, "Clear state not found for block #{block_id}"}
    end
  end

  @spec get_holding() :: {:ok, Holding.t()} | {:error, String.t()}
  defp get_holding do
    case Repo.get_by(Holding, entity_id: "hand") do
      %Holding{} = holding -> {:ok, holding}
      nil -> {:error, "Holding state not found"}
    end
  end
end
