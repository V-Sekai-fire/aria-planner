# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathAtan2 do
  @moduledoc """
<<<<<<< HEAD
  Command: c_math_atan2(node_id, ...)

  Executes math/atan2 operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

=======
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

>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  @spec c_math_atan2(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
<<<<<<< HEAD
  def c_math_atan2(_state, _node_id, _a_socket, _b_socket, _value_socket) do
    # FIXME: implement math/atan2 operation
    {:ok, %{}}
=======
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
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  end
end
