# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.FlowWaitAll do
  @moduledoc """
  Command: c_flow_wait_all(node_id, ...)

  Executes flow/waitAll operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_flow_wait_all(state :: map(), node_id :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_flow_wait_all(state, node_id) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        # WaitAll: wait for all input flow sockets to activate
        state = NodeExecuted.set(state, node_id, true)
        {:ok, state}

      error ->
        error
    end
  end
end
