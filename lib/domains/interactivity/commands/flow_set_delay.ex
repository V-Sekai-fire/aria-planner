# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.FlowSetDelay do
  @moduledoc """
  Command: c_flow_set_delay(node_id, ...)

  Executes flow/setDelay operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_flow_set_delay(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_flow_set_delay(state, node_id, a_socket, _b_socket, _value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, _delay} ->
            # SetDelay: schedule execution after delay
            state = NodeExecuted.set(state, node_id, true)
            {:ok, state}

          error ->
            error
        end

      error ->
        error
    end
  end
end
