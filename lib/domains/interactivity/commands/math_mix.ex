# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathMix do
  @moduledoc """
  Command: c_math_mix(node_id, ...)

  Executes math/mix operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  @spec c_math_mix(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          c_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_mix(_state, node_id, a_socket, b_socket, c_socket, _value_socket) do
    # FIXME: use state and value_socket parameters
    # Mix: linear interpolation between values
    result = {node_id, a_socket, b_socket, c_socket}
    {:ok, result}
  end
end
