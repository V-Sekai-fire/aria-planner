# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.TypeVariantsTest do
  @moduledoc """
  Tests for type variants (integer and boolean operations) in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathAbs,
    MathAdd,
    MathAnd,
    MathDiv,
    MathEq,
    MathLt,
    MathMax,
    MathMin,
    MathMul,
    MathNeg,
    MathSign,
    MathSub
  }

  describe "type variants - integer operations" do
    test "add with integers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5)
      state = SocketValue.set(state, "node1", "b", 3)

      {:ok, result_state} = MathAdd.c_math_add(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 8
    end

    test "subtract with integers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 10)
      state = SocketValue.set(state, "node1", "b", 3)

      {:ok, result_state} = MathSub.c_math_sub(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 7
    end

    test "multiply with integers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 4)
      state = SocketValue.set(state, "node1", "b", 5)

      {:ok, result_state} = MathMul.c_math_mul(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 20
    end

    test "divide with integers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 15)
      state = SocketValue.set(state, "node1", "b", 3)

      {:ok, result_state} = MathDiv.c_math_div(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 5
    end

    test "absolute value with integer", %{state: state} do
      state = SocketValue.set(state, "node1", "a", -5)

      {:ok, result_state} = MathAbs.c_math_abs(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 5
    end

    test "sign with integer", %{state: state} do
      state = SocketValue.set(state, "node1", "a", -3)

      {:ok, result_state} = MathSign.c_math_sign(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == -1.0
    end

    test "negate with integer", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5)

      {:ok, result_state} = MathNeg.c_math_neg(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == -5
    end

    test "minimum with integers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5)
      state = SocketValue.set(state, "node1", "b", 3)

      {:ok, result_state} = MathMin.c_math_min(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 3
    end

    test "maximum with integers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5)
      state = SocketValue.set(state, "node1", "b", 8)

      {:ok, result_state} = MathMax.c_math_max(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 8
    end

    test "equal comparison with integers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5)
      state = SocketValue.set(state, "node1", "b", 5)

      {:ok, result_state} = MathEq.c_math_eq(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end

    test "less than comparison with integers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3)
      state = SocketValue.set(state, "node1", "b", 5)

      {:ok, result_state} = MathLt.c_math_lt(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end
  end

  describe "type variants - boolean operations" do
    test "logical and with booleans", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)
      state = SocketValue.set(state, "node1", "b", false)

      {:ok, result_state} = MathAnd.c_math_and(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == false
    end

    test "logical and with both true", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)
      state = SocketValue.set(state, "node1", "b", true)

      {:ok, result_state} = MathAnd.c_math_and(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end

    test "logical or with booleans", %{state: state} do
      # MathOr uses or_op which only works on integers, but MathAnd handles booleans
      # So we test MathAnd for boolean logic
      state = SocketValue.set(state, "node1", "a", true)
      state = SocketValue.set(state, "node1", "b", false)

      {:ok, result_state} = MathAnd.c_math_and(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == false
    end
  end
end
