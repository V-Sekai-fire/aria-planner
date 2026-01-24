# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathInf do
  @moduledoc """
  Command: c_math_inf(node_id, value_socket)

  Executes math/Inf operation: outputs positive infinity.

  Preconditions:
  - Graph must be active

  Effects:
  - Output socket value is set to positive infinity
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    GraphActive,
    NodeExecuted,
    SocketValue
  }

  @spec c_math_inf(state :: map(), node_id :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_inf(state, node_id, value_socket) do
    case check_graph_active(state) do
      :ok ->
        # Set output socket value to positive infinity
        state = SocketValue.set(state, node_id, value_socket, :infinity)

        # Mark node as executed
        state = NodeExecuted.set(state, node_id, true)

        {:ok, state}

      error ->
        error
    end
  end

  defp check_graph_active(state) do
    if GraphActive.active?(state) do
      :ok
    else
      {:error, "Graph must be active to execute math/Inf"}
    end
  end
end
