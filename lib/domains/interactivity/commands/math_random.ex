# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathRandom do
  @moduledoc """
  Command: c_math_random(node_id, ...)

  Executes math/random operation.

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

  @spec c_math_random(state :: map(), node_id :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_random(state, node_id, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        # Generate random float in [0, 1)
        # Note: Per spec, value is initialized on first access and remains same
        # until flow socket activation. For now, generate new value each time.
        result = :rand.uniform_real()

        # Set output socket value
        state = SocketValue.set(state, node_id, value_socket, result)

        # Mark node as executed
        state = NodeExecuted.set(state, node_id, true)

        {:ok, state}

      error ->
        error
    end
  end
end
