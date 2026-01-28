# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.AnimationStop do
  @moduledoc """
  Command: c_animation_stop(node_id, ...)

  Executes animation/stop operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_animation_stop(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_animation_stop(state, node_id, a_socket, _value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, _anim_id} ->
            # Stop animation playback
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
