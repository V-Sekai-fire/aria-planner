# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.GraphActive do
  @moduledoc """
  Graph active predicate for interactivity domain.

  Represents whether the behavior graph is currently active and executing.
  When a glTF asset contains a behavior graph, animations are controlled by the graph.
  """

  @doc """
  Checks if the graph is active in state.
  """
  @spec active?(state :: map()) :: boolean()
  def active?(state) do
    Map.get(state, :graph_active, false)
  end

  @doc """
  Sets the graph as active in state.
  """
  @spec activate(state :: map()) :: map()
  def activate(state) do
    Map.put(state, :graph_active, true)
  end

  @doc """
  Sets the graph as inactive in state.
  """
  @spec deactivate(state :: map()) :: map()
  def deactivate(state) do
    Map.put(state, :graph_active, false)
  end
end
