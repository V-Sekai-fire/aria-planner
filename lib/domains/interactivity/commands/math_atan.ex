# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathAtan do
  @moduledoc """
  Command: c_math_atan(node_id, ...)

  Executes math/atan operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  # credo:disable-for-this-file Credo.Check.Readability.SnakeCase

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted
  alias AriaPlanner.Domains.Interactivity.Predicates.SocketValue

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_atan(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_atan(state, node_id, a_socket, b_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
          # Compute atan (component-wise)
          result = MathHelpers.apply_binary_op(a, b, &atan_op/2)

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

  defp atan_op(a, b), do: :math.atan2(a, b)
end
