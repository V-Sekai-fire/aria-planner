# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.PointerInterpolate do
  @moduledoc """
  Command: c_pointer_interpolate(node_id, ...)

  Executes pointer/interpolate operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_pointer_interpolate(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          c_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_pointer_interpolate(state, node_id, a_socket, b_socket, c_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, pointer_path} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, a} <- MathHelpers.get_socket_value(state, node_id, b_socket),
             {:ok, b} <- MathHelpers.get_socket_value(state, node_id, c_socket),
             {:ok, t} <- MathHelpers.get_socket_value(state, node_id, value_socket) do
          alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue

          result =
            if is_number(a) and is_number(b),
              do: (1.0 - t) * a + t * b,
              else: {:error, "Cannot interpolate non-numeric values"}

          case result do
            {:error, reason} ->
              {:error, reason}

            _ ->
              state = VariableValue.set(state, pointer_path, result)
              state = NodeExecuted.set(state, node_id, true)
              {:ok, state}
          end
        else
          error -> error
        end

      error ->
        error
    end
  end
end
