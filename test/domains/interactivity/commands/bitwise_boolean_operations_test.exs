# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.BitwiseBooleanOperationsTest do
  @moduledoc """
  Tests for bitwise and boolean operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathAnd,
    MathNot,
    MathOr,
    MathXor
  }

  describe "bitwise and boolean operations" do
    test "bitwise not on integer", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 0)

      {:ok, result_state} = MathNot.c_math_not(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Bitwise not of 0 is -1 (all bits set)
      assert result == -1
    end

    test "logical and on booleans", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)
      state = SocketValue.set(state, "node1", "b", false)

      {:ok, result_state} = MathAnd.c_math_and(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == false
    end

    test "bitwise or on integers", %{state: state} do
      # MathOr uses or_op which only works on integers
      state = SocketValue.set(state, "node1", "a", 5)
      state = SocketValue.set(state, "node1", "b", 3)

      {:ok, result_state} = MathOr.c_math_or(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # 5 | 3 = 7
      assert result == 7
    end

    test "bitwise xor on integers", %{state: state} do
      # MathXor uses xor_op which only works on integers
      state = SocketValue.set(state, "node1", "a", 5)
      state = SocketValue.set(state, "node1", "b", 3)

      {:ok, result_state} = MathXor.c_math_xor(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # 5 ^ 3 = 6
      assert result == 6
    end
  end
end
