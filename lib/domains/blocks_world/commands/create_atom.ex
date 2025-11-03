# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Commands.CreateAtom do
  @moduledoc """
  Command: c_create_atom(name)

  Creates a new atom (block or table).
  """
  alias AriaPlanner.Domains.BlocksWorld.Predicates.Atom
  alias AriaPlanner.Repo

  defstruct name: nil

  @spec c_create_atom(name :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_create_atom(name) do
    case Repo.insert(%Atom{name: name}) do
      {:ok, _atom} -> {:ok, %{command: "c_create_atom", name: name}}
      {:error, changeset} -> {:error, "Failed to create atom: #{inspect(changeset)}"}
    end
  end
end
