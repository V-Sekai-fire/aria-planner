# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathQuatFromUpForward do
  @moduledoc """
  Command: c_math_quat_from_up_forward(node_id, ...)

  Executes math/quatFromUpForward operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  # credo:disable-for-this-file Credo.Check.Readability.SnakeCase

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_quat_from_up_forward(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_quat_from_up_forward(state, node_id, a_socket, b_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, up} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, forward} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
          result = MathHelpers.quat_from_up_forward_op(up, forward)
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

# TODO: a_socket parameter for future implementation
# TODO: b_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
