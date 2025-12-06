# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Predicates.Precedence do
  @moduledoc """
  Precedence predicate for aircraft-disassembly domain.

  Represents precedence relationships between activities (predecessor -> successor).
  """

  @doc """
  Checks if a precedence relationship exists (pred is predecessor of succ).
  """
  @spec exists?(state :: map(), pred :: integer(), succ :: integer()) :: boolean()
  def exists?(state, pred, succ) do
    Map.get(state.precedence, {pred, succ}, false)
  end

  @doc """
  Sets a precedence relationship in state.
  """
  @spec set(state :: map(), pred :: integer(), succ :: integer(), exists :: boolean()) :: map()
  def set(state, pred, succ, exists) do
    new_precedence = Map.put(state.precedence, {pred, succ}, exists)
    Map.put(state, :precedence, new_precedence)
  end
end
