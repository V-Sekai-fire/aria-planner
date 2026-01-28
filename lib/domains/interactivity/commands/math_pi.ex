# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathPi do
  @moduledoc """
  Command: c_math_pi(node_id, value_socket)

  Executes math/Pi operation: outputs ratio of circle's circumference to diameter (3.141592653589793).

  Preconditions:
  - Graph must be active

  Effects:
  - Output socket value is set to Pi
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    GraphActive,
    NodeExecuted,
    SocketValue
  }

  @pi_value :math.pi()

  @spec c_math_pi(state :: map(), node_id :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_pi(state, node_id, value_socket) do
    case check_graph_active(state) do
      :ok ->
        # Set output socket value to Pi
        state = SocketValue.set(state, node_id, value_socket, @pi_value)

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
      {:error, "Graph must be active to execute math/Pi"}
    end
  end
end
