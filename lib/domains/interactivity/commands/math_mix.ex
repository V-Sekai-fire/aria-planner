# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathMix do
  @moduledoc """
<<<<<<< HEAD
  Command: c_math_mix(node_id, ...)

  Executes math/mix operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

=======
  Command: c_math_mix(node_id, a_socket, b_socket, c_socket, value_socket)

  Executes math/mix operation: value = mix(a, b, c)
  Performs linear interpolation between a and b using factor c using MathHelpers.mix_op.

  Preconditions:
  - Graph must be active
  - Input sockets a, b, and c must have values

  Effects:
  - Output socket value is set to mix(a, b, c)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  @spec c_math_mix(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          c_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
<<<<<<< HEAD
  def c_math_mix(_state, node_id, a_socket, b_socket, c_socket, _value_socket) do
    # FIXME: use state and value_socket parameters
    # Mix: linear interpolation between values
    result = {node_id, a_socket, b_socket, c_socket}
    {:ok, result}
=======
  def c_math_mix(state, node_id, a_socket, b_socket, c_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
         {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket),
         {:ok, c} <- MathHelpers.get_socket_value(state, node_id, c_socket) do
      # Compute mix (linear interpolation) using MathHelpers for component-wise operation
      result = MathHelpers.mix_op(a, b, c)

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
