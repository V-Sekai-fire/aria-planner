# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.PointerGet do
  @moduledoc """
  Command: c_pointer_get(node_id, ...)

  Executes pointer/get operation.

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

  @spec c_pointer_get(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_pointer_get(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, pointer_path} ->
            # Pointer access reads from nested structure (simplified: treat as variable)
            alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue
            value = VariableValue.get(state, pointer_path)

            if value != nil do
              state = SocketValue.set(state, node_id, value_socket, value)
              state = NodeExecuted.set(state, node_id, true)
              {:ok, state}
            else
              {:error, "Pointer #{pointer_path} not found"}
            end

          error ->
            error
        end

      error ->
        error
    end
  end
end
