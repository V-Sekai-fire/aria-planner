# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathTrunc do
  @moduledoc """
  Command: c_math_trunc(node_id, ...)

  Executes math/trunc operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  @spec c_math_trunc(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          value_socket :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def c_math_trunc(_state, _node_id, _a_socket, _value_socket) do
    # FIXME: implement math/trunc operation
    {:ok, %{}}
  end
end
