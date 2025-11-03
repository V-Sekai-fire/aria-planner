# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Commands.CreateHolding do
  @moduledoc """
  Command: c_create_holding(x)

  Creates a new holding predicate for 'hand'.
  """
  alias AriaPlanner.Domains.BlocksWorld.Predicates.Holding
  alias AriaPlanner.Repo

  defstruct x: nil # x will represent the object being held, or "false" if nothing.

  @spec c_create_holding(x :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_create_holding(x) do
    # We will assume "hand" is the entity_id for holding predicates
    case Repo.insert(%Holding{entity_id: "hand", value: x}) do
      {:ok, _holding} -> {:ok, %{command: "c_create_holding", x: x}}
      {:error, changeset} -> {:error, "Failed to create holding predicate: #{inspect(changeset)}"}
    end
  end
end
