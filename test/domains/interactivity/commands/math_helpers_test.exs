# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathHelpersTest do
  @moduledoc """
  Tests for MathHelpers operations in the Interactivity domain.
  """

  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

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

    test "transpose_op for 3x3 matrix" do
      # glTF column-major: [[1,2,3],[4,5,6],[7,8,9]] = {1,4,7, 2,5,8, 3,6,9}
      # Transpose: [[1,4,7],[2,5,8],[3,6,9]] = {1,2,3, 4,5,6, 7,8,9}
      matrix = {1.0, 4.0, 7.0, 2.0, 5.0, 8.0, 3.0, 6.0, 9.0}
      result = MathHelpers.transpose_op(matrix)
      assert result == {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0}
    end

    test "transpose_op for 4x4 matrix" do
      # glTF column-major: [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]
      # = {1,5,9,13, 2,6,10,14, 3,7,11,15, 4,8,12,16}
      # Transpose: [[1,5,9,13],[2,6,10,14],[3,7,11,15],[4,8,12,16]]
      # = {1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16}
      matrix = {1.0, 5.0, 9.0, 13.0, 2.0, 6.0, 10.0, 14.0, 3.0, 7.0, 11.0, 15.0, 4.0, 8.0, 12.0, 16.0}
      result = MathHelpers.transpose_op(matrix)
      assert result == {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0}
    end

    test "determinant_op for 3x3 matrix" do
      # glTF column-major: [[1,2,3],[4,5,6],[7,8,9]] = {1,4,7, 2,5,8, 3,6,9}
      # Determinant = 0 (singular matrix)
      matrix = {1.0, 4.0, 7.0, 2.0, 5.0, 8.0, 3.0, 6.0, 9.0}
      result = MathHelpers.determinant_op(matrix)
      assert_in_delta result, 0.0, 0.001
    end

    test "determinant_op for 4x4 identity matrix" do
      identity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      result = MathHelpers.determinant_op(identity)
      assert_in_delta result, 1.0, 0.001
    end

    test "mat_mul_op for 3x3 matrices" do
      # Identity * Identity = Identity
      identity = {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0}
      result = MathHelpers.mat_mul_op(identity, identity)
      assert result == identity
    end

    test "mat_mul_op for 4x4 matrices" do
      # Identity * Identity = Identity
      identity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      result = MathHelpers.mat_mul_op(identity, identity)
      assert result == identity
    end
  end
end
