# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathFract do
  @moduledoc """
  Command: c_math_fract(node_id, a_socket, value_socket)

  Executes math/fract operation: value = fract(a)
  Computes fractional part of a using MathHelpers.fract_op.

  Preconditions:
  - Graph must be active
  - Input socket a must have a value

  Effects:
  - Output socket value is set to fract(a)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_fract(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_fract(state, node_id, a_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket) do
      # Compute fractional part using MathHelpers for component-wise operation
      result = MathHelpers.apply_unary_op(a, &MathHelpers.fract_op/1)

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
