# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathFloor do
  @moduledoc """
  Command: c_math_floor(node_id, ...)

  Executes math/floor operation.

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

  @spec c_math_floor(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def c_math_floor(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, a} ->
            # Compute floor (component-wise)
            result = MathHelpers.apply_unary_op(a, &floor_op/1)

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

  defp floor_op(x), do: Kernel.floor(x)
end
