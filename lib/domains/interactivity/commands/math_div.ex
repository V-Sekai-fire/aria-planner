# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathDiv do
  @moduledoc """
  Command: c_math_div(node_id, a_socket, b_socket, value_socket)

  Executes math/div operation: value = a / b
  Operates component-wise for floatN and floatNxN types.

  Preconditions:
  - Graph must be active
  - Input sockets a and b must have values

  Effects:
  - Output socket value is set to a / b
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    GraphActive,
    NodeExecuted,
    SocketValue
  }

  @spec c_math_div(
          state :: map(),
          node_id :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_div(state, node_id, a_socket, b_socket, value_socket) do
    with :ok <- check_graph_active(state),
         {:ok, a} <- get_socket_value(state, node_id, a_socket),
         {:ok, b} <- get_socket_value(state, node_id, b_socket) do
      # Compute result
      result = divide_values(a, b)

      # Set output socket value
      state = SocketValue.set(state, node_id, value_socket, result)

      # Mark node as executed
      state = NodeExecuted.set(state, node_id, true)

      {:ok, state}
    else
      error -> error
    end
  end

  defp check_graph_active(state) do
    if GraphActive.active?(state) do
      :ok
    else
      {:error, "Graph must be active to execute math operations"}
    end
  end

  defp get_socket_value(state, node_id, socket_id) do
    value = SocketValue.get(state, node_id, socket_id)

    if value != nil do
      {:ok, value}
    else
      {:error, "Socket #{socket_id} on node #{node_id} has no value"}
    end
  end

  defp divide_values(a, b) when is_number(a) and is_number(b), do: a / b
  defp divide_values({a1, a2}, {b1, b2}), do: {a1 / b1, a2 / b2}
  defp divide_values({a1, a2, a3}, {b1, b2, b3}), do: {a1 / b1, a2 / b2, a3 / b3}
  defp divide_values({a1, a2, a3, a4}, {b1, b2, b3, b4}), do: {a1 / b1, a2 / b2, a3 / b3, a4 / b4}

  defp divide_values(a, b) when is_tuple(a) and is_tuple(b) do
    # Handle matrix types (per-element division)
    Tuple.to_list(a)
    |> Enum.zip(Tuple.to_list(b))
    |> Enum.map(fn {x, y} -> x / y end)
    |> List.to_tuple()
  end

  defp divide_values(a, b) do
    # Fallback: try to divide as numbers
    a / b
  rescue
    _ -> {:error, "Cannot divide values of incompatible types"}
  end
end
