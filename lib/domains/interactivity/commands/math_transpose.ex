# SPDX-License-Identifier:: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathTranspose do
  @moduledoc """
  Command: c_math_transpose(node_id, ...)

  Executes math/transpose operation.

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

  @spec c_math_transpose(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_transpose(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, matrix} ->
            # Compute transpose
            result = MathHelpers.transpose_op(matrix)

            # Set output socket value
            state = SocketValue.set(state, node_id, value_socket, result)

            # Mark node as executed
            state = NodeExecuted.set(state, node_id, true)

            {:ok, state}

          error ->
            error
        end

      error ->
        error
    end
  end
end
