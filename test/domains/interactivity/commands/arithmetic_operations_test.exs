# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.ArithmeticOperationsTest do
  @moduledoc """
  Tests for arithmetic operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathAdd,
    MathDiv,
    MathMul,
    MathSub
  }

  describe "arithmetic operations" do
    test "add two numbers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5.0)
      state = SocketValue.set(state, "node1", "b", 3.0)

      {:ok, result_state} = MathAdd.c_math_add(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 8.0
    end

    test "add two vectors", %{state: state} do
      state = SocketValue.set(state, "node1", "a", {1.0, 2.0, 3.0})
      state = SocketValue.set(state, "node1", "b", {4.0, 5.0, 6.0})

      {:ok, result_state} = MathAdd.c_math_add(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == {5.0, 7.0, 9.0}
    end

    test "subtract two numbers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 10.0)
      state = SocketValue.set(state, "node1", "b", 3.0)

      {:ok, result_state} = MathSub.c_math_sub(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 7.0
    end

    test "multiply two numbers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 4.0)
      state = SocketValue.set(state, "node1", "b", 5.0)

      {:ok, result_state} = MathMul.c_math_mul(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 20.0
    end

    test "divide two numbers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 15.0)
      state = SocketValue.set(state, "node1", "b", 3.0)

      {:ok, result_state} = MathDiv.c_math_div(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 5.0
    end
  end
end
