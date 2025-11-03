# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.CreateAtom do
  @moduledoc """
  Command: c_create_atom(name)

  Creates a new atom (e.g., a task in PERT).
  """
  alias AriaPlanner.Domains.PertPlanner.Predicates.Atom
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
