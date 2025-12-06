# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Predicates.EastFox do
  @moduledoc """
  East Fox predicate for fox-geese-corn domain.

  Represents the number of foxes on the east side of the river.
  """

  # Test-only: Simple in-memory state
  # In a full implementation, this would use Ecto.Schema like blocks_world

  @doc """
  Gets the current value of east_fox from state.
  """
  @spec get(state :: map()) :: integer()
  def get(state), do: Map.get(state, :east_fox, 0)

  @doc """
  Sets the value of east_fox in state.
  """
  @spec set(state :: map(), value :: integer()) :: map()
  def set(state, value) do
    Map.put(state, :east_fox, value)
  end
end
