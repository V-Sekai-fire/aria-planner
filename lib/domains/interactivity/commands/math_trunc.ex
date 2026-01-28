# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathTrunc do
  @moduledoc """
<<<<<<< HEAD
  Command: c_math_trunc(node_id, ...)

  Executes math/trunc operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

=======
  Command: c_math_trunc(node_id, a_socket, value_socket)

  Executes math/trunc operation: value = trunc(a)
  Truncates a towards zero using Kernel.trunc.

  Preconditions:
  - Graph must be active
  - Input socket a must have a value

  Effects:
  - Output socket value is set to trunc(a)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  @spec c_math_trunc(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
<<<<<<< HEAD
  def c_math_trunc(_state, _node_id, _a_socket, _value_socket) do
    # FIXME: implement math/trunc operation
    {:ok, %{}}
=======
  def c_math_trunc(state, node_id, a_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket) do
      # Truncate towards zero using Kernel.trunc for component-wise operation
      result = MathHelpers.apply_unary_op(a, &trunc/1)

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
