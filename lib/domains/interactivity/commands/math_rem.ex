# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathRem do
  @moduledoc """
<<<<<<< HEAD
  Command: c_math_rem(node_id, ...)

  Executes math/rem operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

=======
  Command: c_math_rem(node_id, a_socket, b_socket, value_socket)

  Executes math/rem operation: value = rem(a, b)
  Computes remainder of a divided by b using Elixir's rem/2.

  Preconditions:
  - Graph must be active
  - Input sockets a and b must have values

  Effects:
  - Output socket value is set to rem(a, b)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  @spec c_math_rem(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
<<<<<<< HEAD
  def c_math_rem(_state, _node_id, _a_socket, _b_socket, _value_socket) do
  end
end

# TODO: a_socket parameter for future implementation
# TODO: b_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
=======
  def c_math_rem(state, node_id, a_socket, b_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
         {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
      # Compute remainder using rem/2 for component-wise operation
      result = MathHelpers.apply_binary_op(a, b, &rem/2)

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
