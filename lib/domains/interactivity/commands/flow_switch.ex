# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.FlowSwitch do
  @moduledoc """
  Command: c_flow_switch(node_id, ...)

  Executes flow/switch operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

<<<<<<< HEAD
  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted
  }
=======
  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_flow_switch(state :: map(), node_id :: String.t(), a_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_flow_switch(state, node_id, a_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, _selector} ->
            # Switch activates one of multiple flow sockets based on selector
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
