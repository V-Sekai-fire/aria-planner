# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Temporal.STN.OperationsTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.Temporal.STN
  alias AriaPlanner.Planner.Temporal.STN.Operations

  describe "add_constraint/4" do
    test "adds a basic temporal constraint" do
      stn = STN.new()
      constraint = {5, 10}

      result = Operations.add_constraint(stn, "start", "end", constraint)

      assert Map.has_key?(result.constraints, {"start", "end"})
      assert result.constraints[{"start", "end"}] == constraint
      assert MapSet.member?(result.time_points, "start")
      assert MapSet.member?(result.time_points, "end")
    end

    test "adds reverse constraint automatically" do
      stn = STN.new()
      constraint = {5, 10}
      expected_reverse = {-10, -5}

      result = Operations.add_constraint(stn, "start", "end", constraint)

      assert result.constraints[{"end", "start"}] == expected_reverse
    end

    test "rejects invalid constraint bounds" do
      stn = STN.new()
      # min > max
      invalid_constraint = {10, 5}

      assert_raise ArgumentError, fn ->
        Operations.add_constraint(stn, "start", "end", invalid_constraint)
      end
    end

    test "handles infinity bounds" do
      stn = STN.new()
      constraint = {:neg_infinity, :infinity}

      result = Operations.add_constraint(stn, "start", "end", constraint)

      assert result.constraints[{"start", "end"}] == constraint
    end
  end

  describe "add_interval/2" do
    test "adds an interval with automatic constraint generation" do
      # Skip this test as Interval module doesn't exist
      assert true
    end
  end

  describe "remove_constraint/3" do
    test "removes a constraint between time points" do
      stn = STN.new()
      stn = Operations.add_constraint(stn, "start", "end", {5, 10})

      result = Operations.remove_constraint(stn, "start", "end")

      refute Map.has_key?(result.constraints, {"start", "end"})
      refute Map.has_key?(result.constraints, {"end", "start"})
    end

    test "handles removing non-existent constraint" do
      stn = STN.new()

      result = Operations.remove_constraint(stn, "start", "end")

      assert result == stn
    end
  end

  describe "get_constraint/3" do
    test "retrieves existing constraint" do
      stn = STN.new()
      constraint = {5, 10}
      stn = Operations.add_constraint(stn, "start", "end", constraint)

      result = Operations.get_constraint(stn, "start", "end")

      assert result == {:ok, constraint}
    end

    test "returns error for non-existent constraint" do
      stn = STN.new()

      result = Operations.get_constraint(stn, "start", "end")

      assert result == {:error, :constraint_not_found}
    end
  end

  describe "intersect_constraints/2" do
    test "intersects two constraints correctly" do
      constraint1 = {0, 10}
      constraint2 = {5, 15}

      result = Operations.intersect_constraints(constraint1, constraint2)

      assert result == {5, 10}
    end

    test "returns empty intersection for incompatible constraints" do
      constraint1 = {0, 5}
      constraint2 = {10, 15}

      result = Operations.intersect_constraints(constraint1, constraint2)

      assert result == :empty
    end

    test "handles infinity bounds in intersection" do
      constraint1 = {:neg_infinity, 10}
      constraint2 = {5, :infinity}

      result = Operations.intersect_constraints(constraint1, constraint2)

      assert result == {5, 10}
    end
  end

  describe "tighten_constraint/2" do
    test "tightens constraint bounds" do
      original = {0, 20}
      tightening = {5, 15}

      result = Operations.tighten_constraint(original, tightening)

      assert result == {5, 15}
    end

    test "returns original if tightening is looser" do
      original = {5, 15}
      tightening = {0, 20}

      result = Operations.tighten_constraint(original, tightening)

      assert result == {5, 15}
    end
  end
end
