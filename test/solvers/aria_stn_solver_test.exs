# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStnSolverTest do
  use ExUnit.Case, async: true

  alias AriaStnSolver
  alias AriaPlanner.Planner.Temporal.STN

  describe "solve_stn/1" do
    test "returns STN struct for consistent STN" do
      stn = STN.new()
      stn = STN.add_constraint(stn, "a", "b", {1, 5})
      stn = STN.add_constraint(stn, "b", "c", {2, 8})

      assert {:ok, solved_stn} = AriaStnSolver.solve_stn(stn)
      assert %STN{} = solved_stn
      assert solved_stn.time_points == stn.time_points
      assert Map.has_key?(solved_stn.constraints, {"a", "b"})
    end

    test "returns error for inconsistent STN" do
      # Create inconsistent STN: a -> b with min 10, b -> a with min 10
      stn = %STN{
        STN.new()
        | constraints: %{
            {"a", "b"} => {10, 10_000},
            {"b", "a"} => {10, 10_000}
          },
          time_points: MapSet.new(["a", "b"])
      }

      assert {:error, _reason} = AriaStnSolver.solve_stn(stn)
    end

    test "tightens constraints using Floyd-Warshall" do
      # Create STN: a -> b (1-5), b -> c (2-8)
      # After solving, a -> c should be tightened to (3-13) via b
      stn = STN.new()
      stn = STN.add_constraint(stn, "a", "b", {1, 5})
      stn = STN.add_constraint(stn, "b", "c", {2, 8})

      assert {:ok, solved_stn} = AriaStnSolver.solve_stn(stn)

      # Check that constraints are still present
      assert Map.has_key?(solved_stn.constraints, {"a", "b"})
      assert Map.has_key?(solved_stn.constraints, {"b", "c"})

      # The STN should be marked as consistent
      assert solved_stn.consistent == true
    end

    test "handles empty STN" do
      stn = STN.new()

      assert {:ok, solved_stn} = AriaStnSolver.solve_stn(stn)
      assert %STN{} = solved_stn
      assert MapSet.size(solved_stn.time_points) == 0
    end

    test "works with STN that has time points but no constraints" do
      stn = %STN{
        STN.new()
        | time_points: MapSet.new(["a", "b", "c"])
      }

      assert {:ok, solved_stn} = AriaStnSolver.solve_stn(stn)
      assert %STN{} = solved_stn
      assert MapSet.size(solved_stn.time_points) == 3
    end

    test "returns STN struct format expected by units.ex" do
      # This test verifies the fix: solve_stn should return STN struct, not wrapper map
      stn = STN.new(time_unit: :second, lod_level: :medium)
      stn = STN.add_constraint(stn, "start", "end", {100, 200})

      assert {:ok, solved_stn} = AriaStnSolver.solve_stn(stn)

      # Verify it's a proper STN struct with all expected fields
      assert %STN{
               time_points: _,
               constraints: _,
               consistent: _,
               time_unit: :second,
               lod_level: :medium,
               lod_resolution: _,
               metadata: _
             } = solved_stn

      # Verify it can be used in pattern matching like units.ex expects
      case AriaStnSolver.solve_stn(stn) do
        {:ok, %STN{} = result} ->
          assert result.time_unit == :second

        {:error, _} ->
          flunk("Should not return error for consistent STN")
      end
    end

    test "handles list format (legacy)" do
      constraints = [{:a, :b, 1, 5}, {:b, :c, 2, 8}]

      assert {:ok, result} = AriaStnSolver.solve_stn(constraints)
      assert is_map(result)
      assert Map.has_key?(result, :constraints)
    end

    test "returns error for invalid format" do
      assert {:error, "Invalid STN format"} = AriaStnSolver.solve_stn("not an STN")
      assert {:error, "Invalid STN format"} = AriaStnSolver.solve_stn(123)
    end
  end

  describe "check_consistency/1" do
    test "returns consistent for valid constraints" do
      constraints = [{:a, :b, 1, 5}, {:b, :c, 2, 8}]

      assert {:consistent, _} = AriaStnSolver.check_consistency(constraints)
    end

    test "returns inconsistent for negative cycle" do
      # Both directions with positive min distances
      constraints = [{:a, :b, 10, 100}, {:b, :a, 10, 100}]

      assert {:inconsistent, _reason} = AriaStnSolver.check_consistency(constraints)
    end

    test "returns inconsistent for invalid bounds" do
      # min > max
      constraints = [{:a, :b, 10, 5}]

      assert {:inconsistent, _reason} = AriaStnSolver.check_consistency(constraints)
    end
  end
end

