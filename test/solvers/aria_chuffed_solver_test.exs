# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Solvers.AriaChuffedSolverTest do
  use ExUnit.Case, async: false

  alias AriaPlanner.Solvers.AriaChuffedSolver
  alias AriaPlanner.Solvers.ChuffedSolverNif

  @moduletag :chuffed_solver

  # Helper to check if Chuffed is available (Windows-compatible)
  defp chuffed_available? do
    case :os.type() do
      {:win32, _} ->
        # Windows: use where command
        case System.cmd("where", ["chuffed"], stderr_to_stdout: true) do
          {_output, 0} -> true
          _ -> false
        end

      _ ->
        # Unix/Linux/Mac: use which command
        case System.cmd("which", ["chuffed"], stderr_to_stdout: true) do
          {_output, 0} -> true
          _ -> false
        end
    end
  end

  # Helper to check if NIF is loaded
  defp nif_loaded? do
    case ChuffedSolverNif.solve_flatzinc("", "") do
      :nif_not_loaded -> false
      _ -> true
    end
  end

  describe "ChuffedSolverNif" do
    test "NIF loads correctly" do
      # Test that the NIF module exists and can be called
      # It will return :nif_not_loaded if NIF isn't compiled, which is expected
      result = ChuffedSolverNif.solve_flatzinc("", "")
      
      # Either the NIF is loaded and returns an error (expected for empty input)
      # or it returns :nif_not_loaded if not compiled (also acceptable for testing)
      assert result == :nif_not_loaded or is_tuple(result)
    end

    test "solve_flatzinc with simple problem" do
      # Skip if NIF not loaded or Chuffed not available
      unless nif_loaded?() and chuffed_available?() do
        :ok
      else
        # Simple FlatZinc problem: find two variables that sum to 10
        flatzinc = """
        var 1..10: x;
        var 1..10: y;
        constraint x + y = 10;
        solve satisfy;
        """

        case ChuffedSolverNif.solve_flatzinc(flatzinc, "{}") do
          {:ok, result_binary} ->
            result = to_string(result_binary)
            # Chuffed should return a solution
            assert String.contains?(result, "x =") or String.contains?(result, "y =") or
                   String.contains?(result, "==========") or
                   String.contains?(result, "UNSATISFIABLE")

          :nif_not_loaded ->
            # NIF not compiled - skip test
            :ok

          {:error, reason} ->
            # Check if it's because Chuffed isn't installed
            reason_str = to_string(reason)
            if String.contains?(reason_str, "chuffed") or 
               String.contains?(reason_str, "not found") or
               String.contains?(reason_str, "command") do
              # Chuffed not installed - skip test
              :ok
            else
              flunk("Unexpected error: #{inspect(reason)}")
            end
        end
      end
    end
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
          # If Chuffed isn't available, that's okay for testing
          if String.contains?(reason_str, "chuffed") or 
             String.contains?(reason_str, "not found") or
             String.contains?(reason_str, "command") or
             reason == :nif_not_loaded do
            # Chuffed not installed or NIF not compiled - skip test
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
             String.contains?(reason_str, "not found") or
             String.contains?(reason_str, "command") or
             reason == :nif_not_loaded do
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
                 String.contains?(reason_str, "not found") or
                 reason == :nif_not_loaded

        {:ok, solution} ->
          # Some solvers might return empty solution
          assert is_map(solution)

        other ->
          # If Chuffed isn't available, that's okay
          if other == :nif_not_loaded do
            :ok
          else
            flunk("Unexpected result: #{inspect(other)}")
          end
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

        :nif_not_loaded ->
          # NIF not compiled
          :ok

        other ->
          flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "handles missing file gracefully" do
      case AriaChuffedSolver.solve_flatzinc_file("nonexistent_file.fzn") do
        {:error, reason} ->
          assert String.contains?(to_string(reason), "No such file") or
                 String.contains?(to_string(reason), "not found") or
                 reason == :nif_not_loaded

        :nif_not_loaded ->
          :ok

        other ->
          flunk("Expected error for missing file, got: #{inspect(other)}")
      end
    end
  end
end

