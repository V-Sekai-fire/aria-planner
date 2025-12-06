# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Predicates.WestCorn do
  @moduledoc """
  West Corn predicate for fox-geese-corn domain.

  Represents the number of corn on the west side of the river.
  """

  @doc """
  Gets the current value of west_corn from state.
  """
  @spec get(state :: map()) :: integer()
  def get(state), do: Map.get(state, :west_corn, 0)

  @doc """
  Sets the value of west_corn in state.
  """
  @spec set(state :: map(), value :: integer()) :: map()
  def set(state, value) do
    Map.put(state, :west_corn, value)
  end
end
