# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Commands.Stack do
  @moduledoc """
  Command: c_stack(block, on_block)

  Stack a block on another block.

  Preconditions:
  - block is in hand
  - on_block is clear

  Effects:
  - block is now on top of on_block
  - block is clear
  - on_block is no longer clear
  - hand is empty
  """

  alias AriaPlanner.Domains.BlocksWorld.Predicates.{Pos, Clear, Holding}
  alias AriaPlanner.Repo

  defstruct obj_a: nil, obj_b: nil

  @spec c_stack(block_id :: String.t(), on_block_id :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_stack(block_id, on_block_id) do
    with {:ok, pos} <- get_pos(block_id),
         {:ok, clear} <- get_clear(block_id),
         {:ok, on_clear} <- get_clear(on_block_id),
         {:ok, holding} <- get_holding(),
         true <- pos.value == "hand",
         true <- on_clear.value == true do
      # Update state
      {:ok, _} = Pos.update(pos, %{value: on_block_id})
      {:ok, _} = Clear.update(clear, %{value: true})
      {:ok, _} = Clear.update(on_clear, %{value: false})
      {:ok, _} = Holding.update(holding, %{value: "false"})

      {:ok, %{command: "c_stack", block: block_id, on: on_block_id}}
    else
      false -> {:error, "Preconditions not met for c_stack(#{block_id}, #{on_block_id})"}
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
