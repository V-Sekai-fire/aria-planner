# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathE do
  @moduledoc """
  Command: c_math_e(node_id, value_socket)

  Executes math/E operation: outputs Euler's number (2.718281828459045).

  Preconditions:
  - Graph must be active

  Effects:
  - Output socket value is set to Euler's number
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    GraphActive,
    NodeExecuted,
    SocketValue
  }

  @euler_number 2.718281828459045

  @spec c_math_e(state :: map(), node_id :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_e(state, node_id, value_socket) do
    case check_graph_active(state) do
      :ok ->
        # Set output socket value to Euler's number
        state = SocketValue.set(state, node_id, value_socket, @euler_number)

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
      {:error, "Graph must be active to execute math/E"}
    end
  end
end
