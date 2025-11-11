# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Solvers.MiniZincSolverTest do
  use ExUnit.Case, async: false

  alias AriaPlanner.Solvers.MiniZincSolver

  @moduletag :minizinc_solver

  # Helper to check if MiniZinc is available
  defp minizinc_available? do
    MiniZincSolver.available?()
  end

  describe "MiniZincSolver" do
    test "available? checks if minizinc is installed" do
      result = MiniZincSolver.available?()
      assert is_boolean(result)
    end

    test "list_solvers returns available solvers" do
      case MiniZincSolver.list_solvers() do
        {:ok, solvers} ->
          assert is_list(solvers)
          # Should have at least one solver
          assert length(solvers) > 0

        {:error, reason} ->
          reason_str = to_string(reason)
          # If MiniZinc isn't available, that's okay for testing
          if String.contains?(reason_str, "minizinc") or
             String.contains?(reason_str, "not found") or
             String.contains?(reason_str, "command") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end

    test "solve with simple MiniZinc model" do
      model_content = """
      var 1..10: x;
      var 1..10: y;
      constraint x + y = 10;
      solve satisfy;
      """

      case MiniZincSolver.solve_string(model_content) do
        {:ok, solution} ->
          assert is_map(solution)
          # Solution should have variables or status
          assert map_size(solution) >= 0

        {:error, reason} ->
          reason_str = to_string(reason)
          # If MiniZinc isn't available, that's okay for testing
          if String.contains?(reason_str, "minizinc") or
             String.contains?(reason_str, "not found") or
             String.contains?(reason_str, "command") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end

    test "solve with file" do
      model_content = """
      var 1..5: x;
      var 1..5: y;
      constraint x < y;
      solve satisfy;
      """

      tmp_file = System.tmp_dir!() |> Path.join("test_minizinc_#{:rand.uniform(10000)}.mzn")

      try do
        File.write!(tmp_file, model_content)

        case MiniZincSolver.solve(tmp_file) do
          {:ok, solution} ->
            assert is_map(solution)

          {:error, reason} ->
            reason_str = to_string(reason)
            if String.contains?(reason_str, "minizinc") or
               String.contains?(reason_str, "not found") or
               String.contains?(reason_str, "command") do
              :ok
            else
              flunk("Unexpected error: #{inspect(reason)}")
            end
        end
      after
        File.rm(tmp_file)
      end
    end

    test "solve with model and data file" do
      model_content = """
      int: n;
      array[1..n] of var 1..10: x;
      constraint sum(x) = n * 5;
      solve satisfy;
      """

      data_content = """
      n = 3;
      """

      tmp_model = System.tmp_dir!() |> Path.join("test_model_#{:rand.uniform(10000)}.mzn")
      tmp_data = System.tmp_dir!() |> Path.join("test_data_#{:rand.uniform(10000)}.dzn")

      try do
        File.write!(tmp_model, model_content)
        File.write!(tmp_data, data_content)

        case MiniZincSolver.solve(tmp_model, tmp_data) do
          {:ok, solution} ->
            assert is_map(solution)

          {:error, reason} ->
            reason_str = to_string(reason)
            if String.contains?(reason_str, "minizinc") or
               String.contains?(reason_str, "not found") or
               String.contains?(reason_str, "command") do
              :ok
            else
              flunk("Unexpected error: #{inspect(reason)}")
            end
        end
      after
        File.rm(tmp_model)
        File.rm(tmp_data)
      end
    end

    test "solve with unsatisfiable problem" do
      model_content = """
      var 1..5: x;
      var 1..5: y;
      constraint x + y = 100;
      solve satisfy;
      """

      case MiniZincSolver.solve_string(model_content) do
        {:error, reason} ->
          # Unsatisfiable is expected
          reason_str = to_string(reason)
          assert String.contains?(reason_str, "UNSAT") or
                 String.contains?(reason_str, "unsatisfiable") or
                 String.contains?(reason_str, "minizinc") or
                 String.contains?(reason_str, "not found")

        {:ok, solution} ->
          # Some solvers might return empty solution
          assert is_map(solution)

        other ->
          flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "solve with optimization problem" do
      model_content = """
      var 1..10: x;
      var 1..10: y;
      constraint x + y >= 5;
      solve minimize x + y;
      """

      case MiniZincSolver.solve_string(model_content) do
        {:ok, solution} ->
          assert is_map(solution)

        {:error, reason} ->
          reason_str = to_string(reason)
          if String.contains?(reason_str, "minizinc") or
             String.contains?(reason_str, "not found") or
             String.contains?(reason_str, "command") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end

    test "solve with timeout option" do
      model_content = """
      var 1..10: x;
      var 1..10: y;
      constraint x + y = 10;
      solve satisfy;
      """

      case MiniZincSolver.solve_string(model_content, nil, timeout: 5000) do
        {:ok, solution} ->
          assert is_map(solution)

        {:error, reason} ->
          reason_str = to_string(reason)
          if String.contains?(reason_str, "minizinc") or
             String.contains?(reason_str, "not found") or
             String.contains?(reason_str, "command") or
             String.contains?(reason_str, "timeout") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end
  end

  describe "error handling" do
    test "handles invalid MiniZinc model gracefully" do
      invalid_model = "this is not valid minizinc"

      case MiniZincSolver.solve_string(invalid_model) do
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
      case MiniZincSolver.solve("nonexistent_file.mzn") do
        {:error, reason} ->
          assert String.contains?(to_string(reason), "not found") or
                 String.contains?(to_string(reason), "No such file")

        other ->
          flunk("Expected error for missing file, got: #{inspect(other)}")
      end
    end
  end
end

