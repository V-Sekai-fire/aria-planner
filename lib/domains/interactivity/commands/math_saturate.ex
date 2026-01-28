# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathSaturate do
  @moduledoc """
<<<<<<< HEAD
  Command: c_math_saturate(node_id, ...)

  Executes math/saturate operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

=======
  Command: c_math_saturate(node_id, a_socket, value_socket)

  Executes math/saturate operation: value = saturate(a)
  Clamps a to the range [0, 1] using MathHelpers.saturate_op.

  Preconditions:
  - Graph must be active
  - Input socket a must have a value

  Effects:
  - Output socket value is set to saturate(a)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  @spec c_math_saturate(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
<<<<<<< HEAD
  def c_math_saturate(_state, _node_id, _a_socket, _value_socket) do
    # FIXME: implement math/saturate operation
    {:ok, %{}}
=======
  def c_math_saturate(state, node_id, a_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket) do
      # Compute saturate (clamp to [0, 1]) using MathHelpers for component-wise operation
      result = MathHelpers.apply_unary_op(a, &MathHelpers.saturate_op/1)

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
