# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathAtan2 do
  @moduledoc """
  Command: c_math_atan2(node_id, a_socket, b_socket, value_socket)

  Executes math/atan2 operation: value = atan2(a, b)
  Computes atan2(a, b) using Elixir's :math.atan2.

  Preconditions:
  - Graph must be active
  - Input sockets a and b must have values

  Effects:
  - Output socket value is set to atan2(a, b)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_atan2(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_atan2(state, node_id, a_socket, b_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
         {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
      # Compute atan2 using Elixir's :math.atan2 for component-wise operation
      result = MathHelpers.apply_binary_op(a, b, &:math.atan2/2)

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
