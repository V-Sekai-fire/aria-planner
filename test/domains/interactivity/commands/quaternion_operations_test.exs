# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.QuaternionOperationsTest do
  @moduledoc """
  Tests for quaternion operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathQuatConjugate,
    MathQuatFromAxisAngle,
    MathQuatMul,
    MathQuatSlerp
  }

  describe "quaternion operations" do
    test "quaternion conjugate", %{state: state} do
      quat = {1.0, 2.0, 3.0, 4.0}
      state = SocketValue.set(state, "node1", "a", quat)

      {:ok, result_state} = MathQuatConjugate.c_math_quat_conjugate(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Conjugate: {-x, -y, -z, w} (glTF order: {x, y, z, w})
      assert result == {-1.0, -2.0, -3.0, 4.0}
    end

    test "quaternion multiplication", %{state: state} do
      # Identity (glTF order: {x, y, z, w})
      q1 = {0.0, 0.0, 0.0, 1.0}
      # i (glTF order: {x, y, z, w})
      q2 = {1.0, 0.0, 0.0, 0.0}
      state = SocketValue.set(state, "node1", "a", q1)
      state = SocketValue.set(state, "node1", "b", q2)

      {:ok, result_state} = MathQuatMul.c_math_quat_mul(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Identity * i = i (glTF order: {x, y, z, w})
      assert result == {1.0, 0.0, 0.0, 0.0}
    end

    test "quaternion from axis-angle", %{state: state} do
      # 90 degree rotation around Z-axis
      axis = {0.0, 0.0, 1.0}
      angle = :math.pi() / 2.0
      state = SocketValue.set(state, "node1", "a", axis)
      state = SocketValue.set(state, "node1", "b", angle)

      {:ok, result_state} = MathQuatFromAxisAngle.c_math_quat_from_axis_angle(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Should be approximately {0, 0, 0.707, 0.707} (glTF order: {x, y, z, w})
      assert_in_delta elem(result, 2), 0.707, 0.01
      assert_in_delta elem(result, 3), 0.707, 0.01
    end

    test "quaternion slerp", %{state: state} do
      # Identity quaternion
      q1 = {0.0, 0.0, 0.0, 1.0}
      # 90 degree rotation around Z-axis
      q2 = {0.0, 0.0, 0.707, 0.707}
      state = SocketValue.set(state, "node1", "a", q1)
      state = SocketValue.set(state, "node1", "b", q2)
      state = SocketValue.set(state, "node1", "c", 0.5)

      {:ok, result_state} = MathQuatSlerp.c_math_quat_slerp(state, "node1", "a", "b", "c", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Slerp at t=0.5 should be halfway between identity and q2
      assert tuple_size(result) == 4
    end
  end
end
