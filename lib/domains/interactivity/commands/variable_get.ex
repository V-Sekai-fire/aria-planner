# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.VariableGet do
  @moduledoc """
  Command: c_variable_get(node_id, ...)

  Executes variable/get operation.

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

  @spec c_variable_get(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_variable_get(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, var_name} ->
            alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue
            value = VariableValue.get(state, var_name)

            if value != nil do
              state = SocketValue.set(state, node_id, value_socket, value)
              state = NodeExecuted.set(state, node_id, true)
              {:ok, state}
            else
              {:error, "Variable #{var_name} not found"}
            end

          error ->
            error
        end

      error ->
        error
    end
  end
end
