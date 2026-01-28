# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathLog10 do
  @moduledoc """
  Command: c_math_log10(node_id, a_socket, value_socket)

  Executes math/log10 operation: value = log10(a)
  Computes base-10 logarithm of a using MathHelpers.log10_op.

  Preconditions:
  - Graph must be active
  - Input socket a must have a value

  Effects:
  - Output socket value is set to log10(a)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_log10(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_log10(state, node_id, a_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket) do
      # Compute base-10 logarithm using MathHelpers for component-wise operation
      result = MathHelpers.apply_unary_op(a, &MathHelpers.log10_op/1)

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
