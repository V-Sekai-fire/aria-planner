# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathDeg do
  @moduledoc """
  Command: c_math_deg(node_id, a_socket, value_socket)

  Executes math/deg operation: value = deg(a)
  Converts radians to degrees: value = a * 180 / π

  Preconditions:
  - Graph must be active
  - Input socket a must have a value

  Effects:
  - Output socket value is set to degrees(a)
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_deg(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_deg(state, node_id, a_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket) do
      # Convert radians to degrees using MathHelpers.deg_op for component-wise operation
      result = MathHelpers.apply_unary_op(a, &MathHelpers.deg_op/1)

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
