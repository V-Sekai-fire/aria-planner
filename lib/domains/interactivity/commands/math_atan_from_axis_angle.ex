# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathAtanFromAxisAngle do
  @moduledoc """
  Command: c_math_atan_from_axis_angle(node_id, ...)

  Executes math/atanFromAxisAngle operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.NodeExecuted
  alias AriaPlanner.Domains.Interactivity.Predicates.SocketValue

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_atan_from_axis_angle(
          state :: map(),
          node_id :: String.t(),
          axis_socket :: String.t(),
          angle_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_atan_from_axis_angle(state, node_id, axis_socket, angle_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, axis} <- MathHelpers.get_socket_value(state, node_id, axis_socket),
             {:ok, angle} <- MathHelpers.get_socket_value(state, node_id, angle_socket) do
          result = MathHelpers.quat_from_axis_angle_op(axis, angle)

          state = SocketValue.set(state, node_id, value_socket, result)
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
