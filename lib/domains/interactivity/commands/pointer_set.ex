# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.PointerSet do
  @moduledoc """
  Command: c_pointer_set(node_id, ...)

  Executes pointer/set operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_pointer_set(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_pointer_set(state, node_id, a_socket, b_socket, _value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, pointer_path} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, value} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
          # Pointer access writes to nested structure (simplified: treat as variable)
          alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue
          state = VariableValue.set(state, pointer_path, value)
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
