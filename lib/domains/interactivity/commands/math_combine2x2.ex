# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathCombine2x2 do
  @moduledoc """
  Command: c_math_combine2x2(node_id, ...)

  Executes math/combine2x2 operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_combine2x2(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          c_socket :: String.t(),
          d_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_combine2x2(state, node_id, a_socket, b_socket, c_socket, d_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket),
             {:ok, c} <- MathHelpers.get_socket_value(state, node_id, c_socket),
             {:ok, d} <- MathHelpers.get_socket_value(state, node_id, d_socket) do
          result = {a, b, c, d}
          state = SocketValue.set(state, node_id, value_socket, result)
          state = NodeExecuted.set(state, node_id, true)
          {:ok, state}
        else
          error -> error
        end

      error ->
        error
    end
  end
end
<<<<<<< HEAD

# TODO: a_socket parameter for future implementation
# TODO: b_socket parameter for future implementation
# TODO: c_socket parameter for future implementation
# TODO: d_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
=======
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
