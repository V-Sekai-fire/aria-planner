# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Commands.CreateClear do
  @moduledoc """
  Command: c_create_clear(x)

  Creates a new clear predicate.
  """
  alias AriaPlanner.Domains.BlocksWorld.Predicates.Clear
  alias AriaPlanner.Repo

  defstruct x: nil

  @spec c_create_clear(x :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_create_clear(x) do
    case Repo.insert(%Clear{entity_id: x, value: true}) do
      {:ok, _clear} -> {:ok, %{command: "c_create_clear", x: x}}
      {:error, changeset} -> {:error, "Failed to create clear: #{inspect(changeset)}"}
    end
  end
end
