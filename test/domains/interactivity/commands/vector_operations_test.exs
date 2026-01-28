# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.VectorOperationsTest do
  @moduledoc """
  Tests for vector operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathCross,
    MathDot,
    MathLength,
    MathNormalize
  }

  describe "vector operations" do
    test "dot product", %{state: state} do
      state = SocketValue.set(state, "node1", "a", {1.0, 2.0, 3.0})
      state = SocketValue.set(state, "node1", "b", {4.0, 5.0, 6.0})

      {:ok, result_state} = MathDot.c_math_dot(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
      assert result == 32.0
    end

    test "cross product", %{state: state} do
      # Cross product of (1,0,0) and (0,1,0) should be (0,0,1)
      state = SocketValue.set(state, "node1", "a", {1.0, 0.0, 0.0})
      state = SocketValue.set(state, "node1", "b", {0.0, 1.0, 0.0})

      {:ok, result_state} = MathCross.c_math_cross(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta elem(result, 0), 0.0, 0.001
      assert_in_delta elem(result, 1), 0.0, 0.001
      assert_in_delta elem(result, 2), 1.0, 0.001
    end

    test "vector length", %{state: state} do
      # Length of (3, 4) should be 5
      state = SocketValue.set(state, "node1", "a", {3.0, 4.0})

      {:ok, result_state} = MathLength.c_math_length(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 5.0, 0.001
    end

    test "vector normalize", %{state: state} do
      # Normalize (3, 4) should give (0.6, 0.8)
      state = SocketValue.set(state, "node1", "a", {3.0, 4.0})

      {:ok, result_state} = MathNormalize.c_math_normalize(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      {result, is_valid} = SocketValue.get(result_state, "node1", "value")
      assert is_valid == true
      assert_in_delta elem(result, 0), 0.6, 0.001
      assert_in_delta elem(result, 1), 0.8, 0.001
    end
  end
end
