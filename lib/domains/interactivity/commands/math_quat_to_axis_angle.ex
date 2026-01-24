# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathQuatToAxisAngle do
  @moduledoc """
  Command: c_math_quat_to_axis_angle(node_id, ...)

  Executes math/quatToAxisAngle operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  # credo:disable-for-this-file Credo.Check.Readability.SnakeCase

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted
  alias AriaPlanner.Domains.Interactivity.Predicates.SocketValue

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_quat_to_axis_angle(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_quat_to_axis_angle(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, quat} ->
            {axis, angle} = MathHelpers.quat_to_axis_angle_op(quat)
            # Store as tuple (glTF spec may require separate output sockets)
            state = SocketValue.set(state, node_id, value_socket, {axis, angle})
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
