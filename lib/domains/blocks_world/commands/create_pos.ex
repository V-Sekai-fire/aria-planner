# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Commands.CreatePos do
  @moduledoc """
  Command: c_create_pos(x, y)

  Creates a new position predicate.
  """
  alias AriaPlanner.Domains.BlocksWorld.Predicates.Pos
  alias AriaPlanner.Repo

  defstruct x: nil, y: nil

  @spec c_create_pos(x :: String.t(), y :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_create_pos(x, y) do
    case Repo.insert(%Pos{entity_id: x, value: y}) do
      {:ok, _pos} -> {:ok, %{command: "c_create_pos", x: x, y: y}}
      {:error, changeset} -> {:error, "Failed to create position: #{inspect(changeset)}"}
    end
  end
end
