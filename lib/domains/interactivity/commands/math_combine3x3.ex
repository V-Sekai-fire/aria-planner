# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathCombine3x3 do
  # credo:disable-for-this-file Credo.Check.Refactor.FunctionArity
  @moduledoc """
  Command: c_math_combine3x3(node_id, ...)

  Executes math/combine3x3 operation.

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

<<<<<<< HEAD
  # Fixme disconnected arguments
=======
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  @spec c_math_combine3x3(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          c_socket :: String.t(),
          d_socket :: String.t(),
          e_socket :: String.t(),
          f_socket :: String.t(),
          g_socket :: String.t(),
          h_socket :: String.t(),
          i_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_combine3x3(
        state,
        node_id,
        a_socket,
        b_socket,
        c_socket,
        _d_socket,
        _e_socket,
        _f_socket,
        _g_socket,
        _h_socket,
        _i_socket,
        value_socket
      ) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket),
             {:ok, c} <- MathHelpers.get_socket_value(state, node_id, c_socket) do
          result = {a, b, c}
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
