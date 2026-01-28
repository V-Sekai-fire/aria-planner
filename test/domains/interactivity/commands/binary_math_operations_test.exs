# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.BinaryMathOperationsTest do
  @moduledoc """
  Tests for binary math operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathAtan2,
    MathClamp,
    MathMax,
    MathMin,
    MathMix,
    MathPow,
    MathRem,
    MathSelect
  }

  describe "binary math operations" do
    test "power operation", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 2.0)
      state = SocketValue.set(state, "node1", "b", 3.0)

      {:ok, result_state} = MathPow.c_math_pow(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 8.0, 0.001
    end

    test "minimum of two numbers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5.0)
      state = SocketValue.set(state, "node1", "b", 3.0)

      {:ok, result_state} = MathMin.c_math_min(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 3.0
    end

    test "maximum of two numbers", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5.0)
      state = SocketValue.set(state, "node1", "b", 8.0)

      {:ok, result_state} = MathMax.c_math_max(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 8.0
    end

    test "remainder operation", %{state: state} do
      # rem/2 works on integers
      state = SocketValue.set(state, "node1", "a", 10)
      state = SocketValue.set(state, "node1", "b", 3)

      {:ok, result_state} = MathRem.c_math_rem(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 1
    end

    test "mix operation", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 0.0)
      state = SocketValue.set(state, "node1", "b", 10.0)
      state = SocketValue.set(state, "node1", "c", 0.5)

      {:ok, result_state} = MathMix.c_math_mix(state, "node1", "a", "b", "c", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 5.0, 0.001
    end

    test "select operation true", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)
      state = SocketValue.set(state, "node1", "b", 10.0)
      state = SocketValue.set(state, "node1", "c", 20.0)

      {:ok, result_state} = MathSelect.c_math_select(state, "node1", "a", "b", "c", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 10.0
    end

    test "select operation false", %{state: state} do
      state = SocketValue.set(state, "node1", "a", false)
      state = SocketValue.set(state, "node1", "b", 10.0)
      state = SocketValue.set(state, "node1", "c", 20.0)

      {:ok, result_state} = MathSelect.c_math_select(state, "node1", "a", "b", "c", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 20.0
    end

    test "clamp operation", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 15.0)
      state = SocketValue.set(state, "node1", "b", 5.0)
      state = SocketValue.set(state, "node1", "c", 10.0)

      {:ok, result_state} = MathClamp.c_math_clamp(state, "node1", "a", "b", "c", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 10.0
    end

    test "atan2 operation", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 1.0)
      state = SocketValue.set(state, "node1", "b", 0.0)

      {:ok, result_state} = MathAtan2.c_math_atan2(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, :math.pi() / 2.0, 0.001
    end
  end
end
