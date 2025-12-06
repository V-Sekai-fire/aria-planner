# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Predicates.EastCorn do
  @moduledoc """
  East Corn predicate for fox-geese-corn domain.

  Represents the number of corn on the east side of the river.
  """

  @doc """
  Gets the current value of east_corn from state.
  """
  @spec get(state :: map()) :: integer()
  def get(state), do: Map.get(state, :east_corn, 0)

  @doc """
  Sets the value of east_corn in state.
  """
  @spec set(state :: map(), value :: integer()) :: map()
  def set(state, value) do
    Map.put(state, :east_corn, value)
  end
end
