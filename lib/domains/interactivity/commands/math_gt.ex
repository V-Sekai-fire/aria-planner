# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathGt do
  @moduledoc """
  Command: c_math_gt(node_id, ...)

  Executes math/gt operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  @spec c_math_gt(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_gt(_state, _node_id, _a_socket, _b_socket, _value_socket) do
  end
end

# TODO: a_socket parameter for future implementation
# TODO: b_socket parameter for future implementation
# TODO: value_socket parameter for future implementation
