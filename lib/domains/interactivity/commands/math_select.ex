# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathSelect do
  @moduledoc """
  Command: c_math_select(node_id, ...)

  Executes math/select operation.

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

  @spec c_math_select(
          state :: map(),
          node_id :: String.t(),
          condition_socket :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_select(state, node_id, condition_socket, a_socket, b_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, condition} <- MathHelpers.get_socket_value(state, node_id, condition_socket),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
         {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
      # Compute result: select based on condition
      result = MathHelpers.select_op(condition, a, b)

      # Set output socket value
      state = SocketValue.set(state, node_id, value_socket, result)

      # Mark node as executed
      state = NodeExecuted.set(state, node_id, true)

      {:ok, state}
    else
      error -> error
    end
  end
end

# TODO: condition_socket parameter for future implementation
# TODO: a_socket parameter for future implementation
# TODO: b_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
