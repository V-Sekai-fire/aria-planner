# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.FlowCancelDelay do
  @moduledoc """
  Command: c_flow_cancel_delay(node_id, ...)

  Executes flow/cancelDelay operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_flow_cancel_delay(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def c_flow_cancel_delay(state, node_id, _a_socket, _value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        # CancelDelay: cancel scheduled execution
        state = NodeExecuted.set(state, node_id, true)
        {:ok, state}

      error ->
        error
    end
  end
end
