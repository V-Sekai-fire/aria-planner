# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.UnaryMathOperationsTest do
  @moduledoc """
  Tests for unary math operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathAbs,
    MathCbrt,
    MathCeil,
    MathCos,
    MathDeg,
    MathExp,
    MathFloor,
    MathFract,
    MathIsInf,
    MathIsNaN,
    MathLog,
    MathLog10,
    MathLog2,
    MathNeg,
    MathRad,
    MathRound,
    MathSaturate,
    MathSign,
    MathSin,
    MathSqrt,
    MathTan,
    MathTrunc
  }

  describe "unary math operations" do
    test "absolute value", %{state: state} do
      state = SocketValue.set(state, "node1", "a", -5.0)

      {:ok, result_state} = MathAbs.c_math_abs(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 5.0
    end

    test "sign operation", %{state: state} do
      state = SocketValue.set(state, "node1", "a", -3.0)

      {:ok, result_state} = MathSign.c_math_sign(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == -1.0
    end

    test "square root", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 16.0)

      {:ok, result_state} = MathSqrt.c_math_sqrt(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 4.0, 0.001
    end

    test "sine", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 0.0)

      {:ok, result_state} = MathSin.c_math_sin(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 0.0, 0.001
    end

    test "cosine", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 0.0)

      {:ok, result_state} = MathCos.c_math_cos(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 1.0, 0.001
    end

    test "tangent", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 0.0)

      {:ok, result_state} = MathTan.c_math_tan(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 0.0, 0.001
    end

    test "floor", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3.7)

      {:ok, result_state} = MathFloor.c_math_floor(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 3.0
    end

    test "ceil", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3.2)

      {:ok, result_state} = MathCeil.c_math_ceil(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 4.0
    end

    test "trunc", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3.7)

      {:ok, result_state} = MathTrunc.c_math_trunc(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 3.0
    end

    test "round", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3.5)

      {:ok, result_state} = MathRound.c_math_round(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 4.0
    end

    test "fract", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3.7)

      {:ok, result_state} = MathFract.c_math_fract(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 0.7, 0.001
    end

    test "negate", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5.0)

      {:ok, result_state} = MathNeg.c_math_neg(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == -5.0
    end

    test "saturate", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 1.5)

      {:ok, result_state} = MathSaturate.c_math_saturate(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 1.0
    end

    test "exponential", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 0.0)

      {:ok, result_state} = MathExp.c_math_exp(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 1.0, 0.001
    end

    test "natural logarithm", %{state: state} do
      state = SocketValue.set(state, "node1", "a", :math.exp(1))

      {:ok, result_state} = MathLog.c_math_log(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 1.0, 0.001
    end

    test "log base 2", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 8.0)

      {:ok, result_state} = MathLog2.c_math_log2(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 3.0, 0.001
    end

    test "log base 10", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 100.0)

      {:ok, result_state} = MathLog10.c_math_log10(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 2.0, 0.001
    end

    test "cube root", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 8.0)

      {:ok, result_state} = MathCbrt.c_math_cbrt(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 2.0, 0.001
    end

    test "radians to degrees", %{state: state} do
      state = SocketValue.set(state, "node1", "a", :math.pi())

      {:ok, result_state} = MathDeg.c_math_deg(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 180.0, 0.001
    end

    test "degrees to radians", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 180.0)

      {:ok, result_state} = MathRad.c_math_rad(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, :math.pi(), 0.001
    end

    test "is NaN with finite value", %{state: state} do
      # Elixir doesn't support NaN creation easily, test with finite value
      state = SocketValue.set(state, "node1", "a", 1.0)

      {:ok, result_state} = MathIsNaN.c_math_is_nan(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Finite value should not be NaN
      assert result == false
    end

    test "is infinity with finite value", %{state: state} do
      # Test with a finite value
      state = SocketValue.set(state, "node1", "a", 1.0)

      {:ok, result_state} = MathIsInf.c_math_is_inf(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Finite value should not be infinity
      assert result == false
    end
  end
end
