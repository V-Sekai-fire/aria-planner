# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MatrixOperationsTest do
  @moduledoc """
  Tests for matrix operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    MathDeterminant,
    MathInverse,
    MathMatMul,
    MathTranspose
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

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

    test "transpose 3x3 matrix", %{state: state} do
      # glTF column-major: [[1,2,3],[4,5,6],[7,8,9]] = {1,4,7, 2,5,8, 3,6,9}
      # Transpose: [[1,4,7],[2,5,8],[3,6,9]] = {1,2,3, 4,5,6, 7,8,9}
      matrix = {1.0, 4.0, 7.0, 2.0, 5.0, 8.0, 3.0, 6.0, 9.0}
      state = SocketValue.set(state, "node1", "a", matrix)

      {:ok, result_state} = MathTranspose.c_math_transpose(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0}
    end

    test "transpose 4x4 matrix", %{state: state} do
      # glTF column-major: [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]
      # = {1,5,9,13, 2,6,10,14, 3,7,11,15, 4,8,12,16}
      # Transpose: [[1,5,9,13],[2,6,10,14],[3,7,11,15],[4,8,12,16]]
      # = {1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16}
      matrix = {1.0, 5.0, 9.0, 13.0, 2.0, 6.0, 10.0, 14.0, 3.0, 7.0, 11.0, 15.0, 4.0, 8.0, 12.0, 16.0}
      state = SocketValue.set(state, "node1", "a", matrix)

      {:ok, result_state} = MathTranspose.c_math_transpose(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0}
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

    test "determinant of 3x3 matrix", %{state: state} do
      # glTF column-major: [[1,2,3],[4,5,6],[7,8,9]] = {1,4,7, 2,5,8, 3,6,9}
      # Determinant: 1*(5*9-6*8) - 2*(4*9-6*7) + 3*(4*8-5*7)
      # = 1*(45-48) - 2*(36-42) + 3*(32-35) = 1*(-3) - 2*(-6) + 3*(-3) = -3 + 12 - 9 = 0
      matrix = {1.0, 4.0, 7.0, 2.0, 5.0, 8.0, 3.0, 6.0, 9.0}
      state = SocketValue.set(state, "node1", "a", matrix)

      {:ok, result_state} = MathDeterminant.c_math_determinant(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 0.0, 0.001
    end

    test "determinant of 4x4 identity matrix", %{state: state} do
      # Identity matrix: [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
      # Column-major: {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
      # Determinant should be 1.0
      matrix = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      state = SocketValue.set(state, "node1", "a", matrix)

      {:ok, result_state} = MathDeterminant.c_math_determinant(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert_in_delta result, 1.0, 0.001
    end

    test "matrix multiplication 2x2", %{state: state} do
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

    test "matrix multiplication 3x3", %{state: state} do
      # glTF column-major: a = [[1,2,3],[4,5,6],[7,8,9]] = {1,4,7, 2,5,8, 3,6,9}
      # b = [[1,0,0],[0,1,0],[0,0,1]] (identity) = {1,0,0, 0,1,0, 0,0,1}
      # a * b = a (identity multiplication)
      a = {1.0, 4.0, 7.0, 2.0, 5.0, 8.0, 3.0, 6.0, 9.0}
      b = {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0}
      state = SocketValue.set(state, "node1", "a", a)
      state = SocketValue.set(state, "node1", "b", b)

      {:ok, result_state} = MathMatMul.c_math_mat_mul(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == a
    end

    test "matrix multiplication 4x4", %{state: state} do
      # Identity * Identity = Identity
      # Identity: {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
      identity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      state = SocketValue.set(state, "node1", "a", identity)
      state = SocketValue.set(state, "node1", "b", identity)

      {:ok, result_state} = MathMatMul.c_math_mat_mul(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == identity
    end

    test "inverse of 2x2 matrix", %{state: state} do
      # glTF column-major: [[1,2],[3,4]] = {1,3,2,4}
      # Determinant = -2, so inverse exists
      # Inverse should be: [[-2,1],[1.5,-0.5]] in row-major
      # In column-major: {-2,1.5,1,-0.5}
      matrix = {1.0, 3.0, 2.0, 4.0}
      state = SocketValue.set(state, "node1", "a", matrix)

      {:ok, result_state} = MathInverse.c_math_inverse(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result_value = SocketValue.get(result_state, "node1", "value")
      # Result is stored as {matrix, is_valid} tuple
      {result_matrix, is_valid} = result_value
      assert is_valid == true
      # Verify: matrix * inverse should be identity (approximately)
      identity_check = MathHelpers.mat_mul_op(matrix, result_matrix)
      # Check diagonal elements are close to 1, off-diagonal close to 0
      assert_in_delta elem(identity_check, 0), 1.0, 0.001
      assert_in_delta elem(identity_check, 3), 1.0, 0.001
      assert_in_delta elem(identity_check, 1), 0.0, 0.001
      assert_in_delta elem(identity_check, 2), 0.0, 0.001
    end

    test "inverse of singular 2x2 matrix", %{state: state} do
      # Singular matrix (determinant = 0): [[1,2],[2,4]] = {1,2,2,4}
      matrix = {1.0, 2.0, 2.0, 4.0}
      state = SocketValue.set(state, "node1", "a", matrix)

      {:ok, result_state} = MathInverse.c_math_inverse(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      {result_matrix, is_valid} = SocketValue.get(result_state, "node1", "value")
      assert is_valid == false
      # Should return zero matrix
      assert result_matrix == {0.0, 0.0, 0.0, 0.0}
    end

    test "inverse of 4x4 identity matrix", %{state: state} do
      # Identity matrix inverse is itself
      identity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      state = SocketValue.set(state, "node1", "a", identity)

      {:ok, result_state} = MathInverse.c_math_inverse(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      {result_matrix, is_valid} = SocketValue.get(result_state, "node1", "value")
      assert is_valid == true
      # Inverse of identity is identity
      assert result_matrix == identity
    end
  end
end
