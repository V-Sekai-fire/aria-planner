# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathRotate3D do
  @moduledoc """
  Command: c_math_rotate_3d(node_id, ...)

  Executes math/rotate3D operation.

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

  @spec c_math_rotate_3d(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_rotate_3d(state, node_id, a_socket, b_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, vector} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, quaternion} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
          result = MathHelpers.rotate3d_op(vector, quaternion)
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
<<<<<<< HEAD

# TODO: a_socket parameter for future implementation
# TODO: b_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
=======
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
