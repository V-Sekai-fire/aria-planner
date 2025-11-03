# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Commands.Putdown do
  @moduledoc """
  Command: c_putdown(block)

  Put down a block on the table.

  Preconditions:
  - block is in hand

  Effects:
  - block is now on the table
  - block is clear
  - hand is empty
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.{Pos, Clear, Holding}
  alias AriaPlanner.Repo

  defstruct obj: nil

  @spec c_putdown(block_id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_putdown(block_id) do
    with {:ok, pos} <- get_pos(block_id),
         {:ok, clear} <- get_clear(block_id),
         {:ok, holding} <- get_holding(),
         true <- pos.value == "hand" do
      # Update state
      {:ok, _} = Pos.update(pos, %{value: "table"})
      {:ok, _} = Clear.update(clear, %{value: true})
      {:ok, _} = Holding.update(holding, %{value: "false"})

      {:ok, %{command: "c_putdown", block: block_id}}
    else
      false -> {:error, "Preconditions not met for c_putdown(#{block_id})"}
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
