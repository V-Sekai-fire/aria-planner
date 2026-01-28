# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.ComparisonOperationsTest do
  @moduledoc """
  Tests for comparison operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathEq,
    MathGe,
    MathGt,
    MathLe,
    MathLt
  }

  describe "comparison operations" do
    test "equal comparison", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5.0)
      state = SocketValue.set(state, "node1", "b", 5.0)

      {:ok, result_state} = MathEq.c_math_eq(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end

    test "less than comparison", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3.0)
      state = SocketValue.set(state, "node1", "b", 5.0)

      {:ok, result_state} = MathLt.c_math_lt(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end

    test "greater than comparison", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 7.0)
      state = SocketValue.set(state, "node1", "b", 5.0)

      {:ok, result_state} = MathGt.c_math_gt(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end

    test "less than or equal comparison", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5.0)
      state = SocketValue.set(state, "node1", "b", 5.0)

      {:ok, result_state} = MathLe.c_math_le(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end

    test "greater than or equal comparison", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 5.0)
      state = SocketValue.set(state, "node1", "b", 5.0)

      {:ok, result_state} = MathGe.c_math_ge(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end
  end
end
