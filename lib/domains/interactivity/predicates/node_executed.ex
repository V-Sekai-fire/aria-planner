# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted do
  @moduledoc """
  Node executed predicate for interactivity domain.

  Represents whether a node has been executed in the behavior graph.
  """

  @doc """
  Gets the execution status of a node from state.
  """
  @spec get(state :: map(), node_id :: String.t()) :: boolean()
  def get(state, node_id) do
    Map.get(state, {:node_executed, node_id}, false)
  end

  @doc """
  Sets the execution status of a node in state.
  """
  @spec set(state :: map(), node_id :: String.t(), executed :: boolean()) :: map()
  def set(state, node_id, executed) do
    Map.put(state, {:node_executed, node_id}, executed)
  end
end
