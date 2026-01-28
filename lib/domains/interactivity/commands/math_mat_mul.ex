# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathMatMul do
  @moduledoc """
  Command: c_math_mat_mul(node_id, ...)

  Executes math/matMul operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted
  alias AriaPlanner.Domains.Interactivity.Predicates.SocketValue

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_mat_mul(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_mat_mul(state, node_id, a_socket, b_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
          # Compute matrix multiplication
          result = MathHelpers.mat_mul_op(a, b)

          # Set output socket value
          state = SocketValue.set(state, node_id, value_socket, result)

          # Mark node as executed
          state = NodeExecuted.set(state, node_id, true)

          {:ok, state}
        else
          error -> error
        end

      error ->
        error
    end
  end
end
<<<<<<< HEAD

# TODO: a_socket parameter for future implementation
# TODO: b_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
=======
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
