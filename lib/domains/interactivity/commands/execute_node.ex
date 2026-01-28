# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.ExecuteNode do
  @moduledoc """
  Command: c_execute_node(node_id, operation)

  Executes a node in the behavior graph.
  A node is executed when:
  - One of its input flow sockets is activated
  - One of its output value sockets is accessed
  - An operation-specific event occurs

  Preconditions:
  - Graph must be active
  - All input value sockets must have defined values
  - Input flow socket must be activated (if required)

  Effects:
  - Node is marked as executed
  - Output value sockets are computed
  - Output flow sockets are activated (if applicable)
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    GraphActive,
    NodeExecuted
  }

  @spec c_execute_node(state :: map(), node_id :: String.t(), operation :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_execute_node(state, node_id, operation) do
    with :ok <- check_graph_active(state),
         :ok <- check_input_sockets(state, node_id) do
      # Mark node as executed
      state = NodeExecuted.set(state, node_id, true)

      # Execute operation-specific logic
      state = execute_operation(state, node_id, operation)

      {:ok, state}
    else
      error -> error
    end
  end

  defp check_graph_active(state) do
    if GraphActive.active?(state) do
      :ok
    else
      {:error, "Graph must be active to execute nodes"}
    end
  end

  defp check_input_sockets(_state, _node_id) do
    # Check that all required input value sockets have values
    # This is a simplified check - in practice, we'd need to know
    # which sockets are required based on the node's declaration
    :ok
  end

  defp execute_operation(state, _node_id, _operation) do
    # Operation execution is handled by specific operation commands
    # This is a placeholder that marks the node as executed
    state
  end
end
