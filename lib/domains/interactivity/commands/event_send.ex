# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.EventSend do
  @moduledoc """
  Command: c_event_send(node_id, ...)

  Executes event/send operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

<<<<<<< HEAD
  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted
  }
=======
  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_event_send(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_event_send(state, node_id, a_socket, _b_socket, _value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, _event_name} ->
            # Send event to external target
            alias AriaPlanner.Domains.Interactivity.Predicates.EventTriggered
            state = EventTriggered.set(state, node_id, "send", true)
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
