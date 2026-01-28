# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.VariableSet do
  @moduledoc """
  Command: c_variable_set(node_id, a_socket, value_socket)

  Executes variable/set operation: sets the value of a custom variable.
  Variables retain their values until graph execution terminates.

  Preconditions:
  - Graph must be active
  - Variable name socket must have a value
  - Value socket must have a value

  Effects:
  - Variable value is updated in graph state
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted,
    VariableValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_variable_set(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_variable_set(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, var_name} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, value} <- MathHelpers.get_socket_value(state, node_id, value_socket) do
          # Set variable value
          state = VariableValue.set(state, var_name, value)

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
