# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.TransformOperationsTest do
  @moduledoc """
  Tests for transform operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathRotate2D,
    MathRotate3D,
    MathTransform
  }

  describe "transform operations" do
    test "2D rotation", %{state: state} do
      vector = {1.0, 0.0}
      # 90 degrees
      angle = :math.pi() / 2.0
      state = SocketValue.set(state, "node1", "a", vector)
      state = SocketValue.set(state, "node1", "b", angle)

      {:ok, result_state} = MathRotate2D.c_math_rotate_2d(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Rotate (1,0) by 90° -> (0,1)
      assert_in_delta elem(result, 0), 0.0, 0.001
      assert_in_delta elem(result, 1), 1.0, 0.001
    end

    test "3D rotation with quaternion", %{state: state} do
      vector = {1.0, 0.0, 0.0}
      # Identity quaternion (glTF order: {x, y, z, w})
      quat = {0.0, 0.0, 0.0, 1.0}
      state = SocketValue.set(state, "node1", "a", vector)
      state = SocketValue.set(state, "node1", "b", quat)

      {:ok, result_state} = MathRotate3D.c_math_rotate_3d(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Identity rotation should preserve vector
      assert result == {1.0, 0.0, 0.0}
    end

    test "transform point with 4x4 matrix", %{state: state} do
      # Identity matrix should preserve point
      point = {1.0, 2.0, 3.0}
      identity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      state = SocketValue.set(state, "node1", "a", point)
      state = SocketValue.set(state, "node1", "b", identity)

      {:ok, result_state} = MathTransform.c_math_transform(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta elem(result, 0), 1.0, 0.001
      assert_in_delta elem(result, 1), 2.0, 0.001
      assert_in_delta elem(result, 2), 3.0, 0.001
    end
  end
end
