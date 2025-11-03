# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Temporal.STN.Consistency do
  @moduledoc """
  STN consistency validation using AriaStnSolver.

  This module provides a simple, unified interface for STN consistency checking.
  All constraint validation goes through AriaStnSolver for reliability and consistency.
  """

  alias AriaPlanner.Planner.Temporal.STN

  @doc """
  Checks if the STN is temporally consistent.

  Uses AriaStnSolver for all constraint validation - simple and reliable.
  """
  @spec consistent?(STN.t() | {:error, String.t()}) :: boolean()
  def consistent?({:error, _reason}), do: false

  def consistent?(stn) when is_struct(stn) do
    # For ALL STNs, use AriaStnSolver for consistent constraint validation
    # Convert STN format to AriaStnSolver format first
    stn_list = stn_to_constraints_list(stn)

    case AriaStnSolver.check_consistency(stn_list) do
      {:consistent, _} -> true
      {:inconsistent, _} -> false
    end
  end

  def consistent?(_), do: false

  # Convert STN struct constraints to list format for AriaStnSolver
  # STN format: %{"a", "b"} => {min, max}
  # AriaStnSolver format: [{:a, :b, min, max}, ...]
  @spec stn_to_constraints_list(STN.t()) :: [AriaStnSolver.constraint()]
  defp stn_to_constraints_list(stn) do
    for {{from, to}, {min, max}} <- stn.constraints do
      # Convert string keys to atoms (safe conversion)
      from_atom = String.to_atom(from)
      to_atom = String.to_atom(to)
      {from_atom, to_atom, min, max}
    end
  end
end
