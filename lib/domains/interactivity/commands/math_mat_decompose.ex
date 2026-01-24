# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathMatDecompose do
  @moduledoc """
  Command: c_math_mat_decompose(node_id, ...)

  Executes math/matDecompose operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  # credo:disable-for-this-file Credo.Check.Readability.SnakeCase

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_mat_decompose(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def c_math_mat_decompose(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, matrix} ->
            {translation, rotation, scale, is_valid} = MathHelpers.mat_decompose_op(matrix)

            # Store decomposition results (glTF spec requires separate output sockets)
            # For now, store as tuple; domain registration should define separate output sockets
            state =
              SocketValue.set(state, node_id, value_socket, {translation, rotation, scale, is_valid})

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
