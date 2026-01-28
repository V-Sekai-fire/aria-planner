# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathCbrt do
  @moduledoc """
<<<<<<< HEAD
  Command: c_math_cbrt(node_id, ...)

  Executes math/cbrt operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  @spec c_math_cbrt(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_cbrt(_state, _node_id, _a_socket, _value_socket) do
=======
  Command: c_math_cbrt(node_id, a_socket, value_socket)

  Executes math/cbrt operation: value = cbrt(a)
  Computes cube root of a using :math.pow(a, 1/3).

  Preconditions:
  - Graph must be active
  - Input socket a must have a value

  Effects:
  - Output socket value is set to cbrt(a)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_cbrt(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_cbrt(state, node_id, a_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket) do
      # Compute cube root using MathHelpers.cbrt_op for component-wise operation
      result = MathHelpers.apply_unary_op(a, &MathHelpers.cbrt_op/1)

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
