# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.CommandsTest do
  @moduledoc """
  Tests for Interactivity domain command implementations.
  """

  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.Interactivity.Commands.{
    FlowBranch,
    MathDeterminant,
    MathMatMul,
    MathQuatConjugate,
    MathQuatMul,
    MathRotate2D,
    MathRotate3D,
    MathTranspose,
    TypeBoolToFloat,
    TypeFloatToInt,
    VariableGet
  }

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    GraphActive,
    NodeExecuted,
    SocketValue,
    VariableValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

  setup do
    # Create initial state with active graph
    state = %{}
    state = GraphActive.activate(state)
    {:ok, state: state}
  end

  describe "matrix operations" do
    test "transpose 2x2 matrix", %{state: state} do
      # glTF column-major: [[1,2],[3,4]] = {1,3,2,4} (col0: [1,3], col1: [2,4])
      # Transpose: [[1,3],[2,4]] = {1,2,3,4} (col0: [1,2], col1: [3,4])
      matrix = {1.0, 3.0, 2.0, 4.0}
      state = SocketValue.set(state, "node1", "a", matrix)

      {:ok, result_state} = MathTranspose.c_math_transpose(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Input: {1,3,2,4} = [[1,2],[3,4]], Transpose: [[1,3],[2,4]] = {1,2,3,4}
      assert result == {1.0, 2.0, 3.0, 4.0}
    end

    test "determinant of 2x2 matrix", %{state: state} do
      # glTF column-major: [[1,2],[3,4]] = {1,3,2,4} (col0: [1,3], col1: [2,4])
      # Determinant: 1*4 - 2*3 = -2.0
      matrix = {1.0, 3.0, 2.0, 4.0}
      state = SocketValue.set(state, "node1", "a", matrix)

      {:ok, result_state} = MathDeterminant.c_math_determinant(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == -2.0
    end

    test "matrix multiplication", %{state: state} do
      # glTF column-major: a = [[1,2],[3,4]] = {1,3,2,4}, b = [[5,6],[7,8]] = {5,7,6,8}
      # a * b = [[19,22],[43,50]] = {19,43,22,50} (col0: [19,43], col1: [22,50])
      a = {1.0, 3.0, 2.0, 4.0}
      b = {5.0, 7.0, 6.0, 8.0}
      state = SocketValue.set(state, "node1", "a", a)
      state = SocketValue.set(state, "node1", "b", b)

      {:ok, result_state} = MathMatMul.c_math_mat_mul(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      # Matrix multiplication: a * b where a={1,3,2,4} and b={5,7,6,8}
      # a = [[1,2],[3,4]], b = [[5,6],[7,8]]
      # a*b = [[1*5+2*7, 1*6+2*8], [3*5+4*7, 3*6+4*8]] = [[19,22],[43,50]]
      # In column-major: {19,43,22,50}
      assert result == {19.0, 43.0, 22.0, 50.0}
    end
  end

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
  end

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
  end

  describe "type conversions" do
    test "bool to float", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)

      {:ok, result_state} = TypeBoolToFloat.c_type_bool_to_float(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 1.0
    end

    test "float to int", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3.7)

      {:ok, result_state} = TypeFloatToInt.c_type_float_to_int(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 3
    end
  end

  describe "variable operations" do
    test "get variable value", %{state: state} do
      state = VariableValue.set(state, "my_var", 42.0)
      state = SocketValue.set(state, "node1", "a", "my_var")

      {:ok, result_state} = VariableGet.c_variable_get(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 42.0
    end
  end

  describe "flow control operations" do
    test "flow branch", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)

      {:ok, result_state} = FlowBranch.c_flow_branch(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
    end
  end

  describe "MathHelpers operations" do
    test "transpose_op for 2x2 matrix" do
      # glTF column-major: [[1,2],[3,4]] = {1,3,2,4} (col0: [1,3], col1: [2,4])
      # Transpose: [[1,3],[2,4]] = {1,2,3,4} (col0: [1,2], col1: [3,4])
      matrix = {1.0, 3.0, 2.0, 4.0}
      result = MathHelpers.transpose_op(matrix)
      assert result == {1.0, 2.0, 3.0, 4.0}
    end

    test "determinant_op for 2x2 matrix" do
      matrix = {1.0, 2.0, 3.0, 4.0}
      result = MathHelpers.determinant_op(matrix)
      assert result == -2.0
    end

    test "quat_conjugate_op" do
      # glTF order: {x, y, z, w}
      quat = {1.0, 2.0, 3.0, 4.0}
      result = MathHelpers.quat_conjugate_op(quat)
      # Conjugate: {-x, -y, -z, w}
      assert result == {-1.0, -2.0, -3.0, 4.0}
    end

    test "quat_mul_op with identity" do
      # glTF order: {x, y, z, w}
      # Identity
      q1 = {0.0, 0.0, 0.0, 1.0}
      # i
      q2 = {1.0, 0.0, 0.0, 0.0}
      result = MathHelpers.quat_mul_op(q1, q2)
      # Identity * i = i
      assert result == {1.0, 0.0, 0.0, 0.0}
    end

    test "rotate2d_op" do
      vector = {1.0, 0.0}
      angle = :math.pi() / 2.0
      result = MathHelpers.rotate2d_op(vector, angle)
      assert_in_delta elem(result, 0), 0.0, 0.001
      assert_in_delta elem(result, 1), 1.0, 0.001
    end
  end
end
