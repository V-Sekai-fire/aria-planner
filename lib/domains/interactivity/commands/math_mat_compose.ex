# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathMatCompose do
  @moduledoc """
  Command: c_math_mat_compose(node_id, ...)

  Executes math/matCompose operation.

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

  @spec c_math_mat_compose(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          c_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_mat_compose(state, node_id, a_socket, b_socket, c_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, translation} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, rotation} <- MathHelpers.get_socket_value(state, node_id, b_socket),
             {:ok, scale} <- MathHelpers.get_socket_value(state, node_id, c_socket) do
          result = MathHelpers.mat_compose_op(translation, rotation, scale)
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
# TODO: c_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
