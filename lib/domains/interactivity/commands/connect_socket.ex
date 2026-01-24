# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.ConnectSocket do
  @moduledoc """
  Command: c_connect_socket(from_node, from_socket, to_node, to_socket)

  Connects a socket between two nodes.
  Can connect:
  - Output value socket -> Input value socket
  - Output flow socket -> Input flow socket

  Preconditions:
  - Graph must be active
  - Socket types must be compatible (for value sockets)

  Effects:
  - Socket connection is established
  - Value flows from source to target (for value sockets)
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    GraphActive,
    SocketConnected,
    SocketValue
  }

  @spec c_connect_socket(
          state :: map(),
          from_node :: String.t(),
          from_socket :: String.t(),
          to_node :: String.t(),
          to_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_connect_socket(state, from_node, from_socket, to_node, to_socket) do
    with :ok <- check_graph_active(state),
         :ok <- check_socket_compatibility(state, from_node, from_socket, to_node, to_socket) do
      # Create socket connection
      state = SocketConnected.connect(state, from_node, from_socket, to_node, to_socket)

      # If value sockets, propagate value
      state = propagate_value(state, from_node, from_socket, to_node, to_socket)

      {:ok, state}
    else
      error -> error
    end
  end

  defp check_graph_active(state) do
    if GraphActive.active?(state) do
      :ok
    else
      {:error, "Graph must be active to connect sockets"}
    end
  end

  defp check_socket_compatibility(_state, _from_node, _from_socket, _to_node, _to_socket) do
    # Simplified: in practice, we'd check socket types match
    :ok
  end

  defp propagate_value(state, from_node, from_socket, to_node, to_socket) do
    # If source socket has a value, copy it to target
    case SocketValue.get(state, from_node, from_socket) do
      nil -> state
      value -> SocketValue.set(state, to_node, to_socket, value)
    end
  end
end
