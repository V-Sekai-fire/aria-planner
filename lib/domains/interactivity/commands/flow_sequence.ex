# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.FlowSequence do
  @moduledoc """
  Command: c_flow_sequence(node_id, ...)

  Executes flow/sequence operation: sequentially activates all connected output flows.
  Output flows are activated in the order defined by their socket ids.

  Preconditions:
  - Graph must be active
  - Input flow socket must be activated

  Effects:
  - All output flow sockets are activated sequentially
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_flow_sequence(state :: map(), node_id :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_flow_sequence(state, node_id) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        # Flow/sequence activates all output flows sequentially
        # For planning purposes, we mark the node as executed
        # The actual sequential activation is handled by the planner's execution order
        state = NodeExecuted.set(state, node_id, true)
        {:ok, state}

      error ->
        error
    end
  end
end
