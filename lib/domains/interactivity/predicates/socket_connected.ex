# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.SocketConnected do
  @moduledoc """
  Socket connected predicate for interactivity domain.

  Represents a connection between sockets:
  - Value socket connections: from_node:from_socket -> to_node:to_socket
  - Flow socket connections: from_node:from_flow -> to_node:to_flow
  """

  @doc """
  Checks if a socket connection exists in state.
  """
  @spec connected?(
          state :: map(),
          from_node :: String.t(),
          from_socket :: String.t(),
          to_node :: String.t(),
          to_socket :: String.t()
        ) :: boolean()
  def connected?(state, from_node, from_socket, to_node, to_socket) do
    key = {:socket_connected, from_node, from_socket, to_node, to_socket}
    Map.get(state, key, false)
  end

  @doc """
  Creates a socket connection in state.
  """
  @spec connect(
          state :: map(),
          from_node :: String.t(),
          from_socket :: String.t(),
          to_node :: String.t(),
          to_socket :: String.t()
        ) :: map()
  def connect(state, from_node, from_socket, to_node, to_socket) do
    key = {:socket_connected, from_node, from_socket, to_node, to_socket}
    Map.put(state, key, true)
  end

  @doc """
  Removes a socket connection from state.
  """
  @spec disconnect(
          state :: map(),
          from_node :: String.t(),
          from_socket :: String.t(),
          to_node :: String.t(),
          to_socket :: String.t()
        ) :: map()
  def disconnect(state, from_node, from_socket, to_node, to_socket) do
    key = {:socket_connected, from_node, from_socket, to_node, to_socket}
    Map.delete(state, key)
  end
end
