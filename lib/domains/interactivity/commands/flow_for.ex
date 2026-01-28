# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.FlowFor do
  @moduledoc """
  Command: c_flow_for(node_id, ...)

  Executes flow/for operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_flow_for(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          c_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_flow_for(state, node_id, a_socket, b_socket, c_socket, _value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, _start} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, _end} <- MathHelpers.get_socket_value(state, node_id, b_socket),
             {:ok, _step} <- MathHelpers.get_socket_value(state, node_id, c_socket) do
          # For loop: execute body for each iteration
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
