# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathCtz do
  @moduledoc """
  Command: c_math_ctz(node_id, ...)

  Executes math/ctz operation.

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

  @spec c_math_ctz(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_math_ctz(state, node_id, a_socket, value_socket) do
    with :ok <- MathHelpers.check_graph_active(state),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket) do
      # Compute ctz (component-wise)
      result = MathHelpers.apply_unary_op(a, &ctz_op/1)

      # Set output socket value
      state = SocketValue.set(state, node_id, value_socket, result)

      # Mark node as executed
      state = NodeExecuted.set(state, node_id, true)

      {:ok, state}
    else
      error -> error
    end
  end

<<<<<<< HEAD
  # FIXME: implement ctz operation
  defp ctz_op(a), do: Kernel.trunc(:math.log2(Bitwise.band(Bitwise.bnot(a), a - 1)))
=======
  defp ctz_op(a) when is_number(a) do
    # Count trailing zeros - convert to integer first
    int_a = trunc(a)

    if int_a == 0 do
      32
    else
      # Use bitwise operations to count trailing zeros
      unsigned = if int_a < 0, do: int_a + 0x100000000, else: int_a
      bits = Integer.digits(unsigned, 2) |> Enum.reverse()
      # Count trailing zeros (from right)
      Enum.take_while(bits, &(&1 == 0)) |> length()
    end
  end
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
end
