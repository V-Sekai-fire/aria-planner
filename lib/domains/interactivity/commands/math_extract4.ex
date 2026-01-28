# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathExtract4 do
  @moduledoc """
  Command: c_math_extract4(node_id, ...)

  Executes math/extract4 operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_extract4(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_extract4(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, vector} ->
            {x, y, z, w} = vector
            result = {x, y, z, w}
            state = SocketValue.set(state, node_id, value_socket, result)
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
