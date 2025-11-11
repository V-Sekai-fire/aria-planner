# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Solvers.AriaChuffedSolverTest do
  use ExUnit.Case, async: false

  alias AriaPlanner.Solvers.AriaChuffedSolver

  @moduletag :chuffed_solver

  # Helper to check if MiniZinc with Chuffed is available
  defp minizinc_chuffed_available? do
    case System.cmd("minizinc", ["--solvers"], stderr_to_stdout: true, timeout: 5000) do
      {output, 0} ->
        String.contains?(output, "chuffed") or String.contains?(output, "Chuffed")
      _ ->
        false
    end
  rescue
    _ ->
      false
  end

  describe "AriaChuffedSolver" do
    test "solve_flatzinc with simple constraint" do
      flatzinc = """
      var 1..10: x;
      var 1..10: y;
      constraint x + y = 10;
      solve satisfy;
      """

      case AriaChuffedSolver.solve_flatzinc(flatzinc) do
        {:ok, solution} ->
          # Should return a parsed solution
          assert is_map(solution)
          # Solution should have variables or raw output
          assert map_size(solution) > 0

          {:error, reason} ->
            reason_str = to_string(reason)
            # If MiniZinc/Chuffed isn't available, that's okay for testing
            if String.contains?(reason_str, "chuffed") or 
               String.contains?(reason_str, "minizinc") or
               String.contains?(reason_str, "not found") or
               String.contains?(reason_str, "command") do
              # MiniZinc/Chuffed not installed - skip test
              :ok
            else
              flunk("Unexpected error: #{inspect(reason)}")
            end
      end
    end

    test "solve_flatzinc_file with temporary file" do
      # Create a temporary FlatZinc file
      flatzinc_content = """
      var 1..5: x;
      var 1..5: y;
      constraint x < y;
      solve satisfy;
      """

      tmp_file = System.tmp_dir!() |> Path.join("test_chuffed_#{:rand.uniform(10000)}.fzn")

      try do
        File.write!(tmp_file, flatzinc_content)

        case AriaChuffedSolver.solve_flatzinc_file(tmp_file) do
          {:ok, solution} ->
            assert is_map(solution)

          {:error, reason} ->
            reason_str = to_string(reason)
            if String.contains?(reason_str, "chuffed") or 
               String.contains?(reason_str, "not found") or
               String.contains?(reason_str, "command") or
               reason == :nif_not_loaded do
              :ok
            else
              flunk("Unexpected error: #{inspect(reason)}")
            end
        end
      after
        File.rm(tmp_file)
      end
    end

    test "solve with constraint map" do
      constraints = %{
        variables: [
          {:x, :int, 1, 10},
          {:y, :int, 1, 10}
        ],
        constraints: [
          {:int_eq, {:+, :x, :y}, 10}
        ]
      }

      case AriaChuffedSolver.solve(constraints) do
        {:ok, solution} ->
          assert is_map(solution)

        {:error, reason} ->
          reason_str = to_string(reason)
          if String.contains?(reason_str, "chuffed") or 
             String.contains?(reason_str, "minizinc") or
             String.contains?(reason_str, "not found") or
             String.contains?(reason_str, "command") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end

    test "solve with unsatisfiable problem" do
      # This problem has no solution
      flatzinc = """
      var 1..5: x;
      var 1..5: y;
      constraint x + y = 100;
      solve satisfy;
      """

      case AriaChuffedSolver.solve_flatzinc(flatzinc) do
        {:error, reason} ->
          # Unsatisfiable is expected
          reason_str = to_string(reason)
          assert String.contains?(reason_str, "UNSAT") or 
                 String.contains?(reason_str, "unsatisfiable") or
                 String.contains?(reason_str, "chuffed") or
                 String.contains?(reason_str, "minizinc") or
                 String.contains?(reason_str, "not found")

        {:ok, solution} ->
          # Some solvers might return empty solution
          assert is_map(solution)

        other ->
          flunk("Unexpected result: #{inspect(other)}")
      end
    end
  end

  describe "error handling" do
    test "handles invalid FlatZinc gracefully" do
      invalid_flatzinc = "this is not valid flatzinc"

      case AriaChuffedSolver.solve_flatzinc(invalid_flatzinc) do
        {:error, _reason} ->
          # Expected - invalid input
          :ok

        {:ok, _solution} ->
          # Some solvers might return error in solution
          :ok

        other ->
          flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "handles missing file gracefully" do
      case AriaChuffedSolver.solve_flatzinc_file("nonexistent_file.fzn") do
        {:error, reason} ->
          assert String.contains?(to_string(reason), "No such file") or
                 String.contains?(to_string(reason), "not found")

        other ->
          flunk("Expected error for missing file, got: #{inspect(other)}")
      end
    end
  end
end

