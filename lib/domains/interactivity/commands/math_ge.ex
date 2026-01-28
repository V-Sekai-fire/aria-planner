# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathGe do
  @moduledoc """
<<<<<<< HEAD
  Command: c_math_ge(node_id, ...)

  Executes math/ge operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

=======
  Command: c_math_ge(node_id, a_socket, b_socket, value_socket)

  Executes math/ge operation: value = a >= b
  Compares a >= b component-wise using MathHelpers.ge_op.

  Preconditions:
  - Graph must be active
  - Input sockets a and b must have values

  Effects:
  - Output socket value is set to a >= b (boolean result)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  @spec c_math_ge(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
<<<<<<< HEAD
  def c_math_ge(_state, _node_id, _a_socket, _b_socket, _value_socket) do
  end
end

# TODO: a_socket parameter for future implementation
# TODO: b_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
=======
  def c_math_ge(state, node_id, a_socket, b_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
         {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
      # Compare a >= b using MathHelpers.ge_op for component-wise operation
      result = MathHelpers.apply_binary_op(a, b, &MathHelpers.ge_op/2)

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
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
