#!/usr/bin/env elixir

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Script to run MiniZinc on problems and extract expected solutions
# This generates solution files that can be used to verify our planner

defmodule MinizincSolutionExtractor do
  @minizinc_base "thirdparty/mznc2024_probs"
  @solutions_dir "test/fixtures/minizinc_solutions"

  def extract_all do
    IO.puts("Extracting MiniZinc solutions...\n")
    File.mkdir_p!(@solutions_dir)

    # Process each problem type
    problem_types = [
      "fox-geese-corn",
      "tiny-cvrp",
      "neighbours",
      "train-scheduling",
      "hoist-benchmark"
    ]

    Enum.each(problem_types, &process_problem_type/1)

    IO.puts("\n✅ Solution extraction complete!")
  end

  defp process_problem_type(problem_type) do
    domain_dir = Path.join(@minizinc_base, problem_type)

    if File.exists?(domain_dir) do
      IO.puts("Processing: #{problem_type}")

      # Find model file
      model_file = Path.join(domain_dir, "#{String.replace(problem_type, "-", "")}.mzn")
      model_file = if File.exists?(model_file), do: model_file, else: Path.join(domain_dir, "*.mzn") |> Path.wildcard() |> List.first()

      if model_file do
        # Find all .dzn files
        dzn_files = Path.wildcard("#{domain_dir}/*.dzn")

        Enum.each(dzn_files, fn dzn_file ->
          extract_solution(problem_type, model_file, dzn_file)
        end)

        IO.puts("  ✅ Processed #{length(dzn_files)} instances")
      else
        IO.puts("  ⚠️  No model file found")
      end
    end
  end

  defp extract_solution(problem_type, model_file, dzn_file) do
    problem_name = Path.basename(dzn_file, ".dzn")
    solution_file = Path.join(@solutions_dir, "#{problem_type}_#{problem_name}.txt")

    # Run MiniZinc
    cmd = "minizinc --solver Gecode #{model_file} #{dzn_file} 2>&1"

    case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true) do
      {output, 0} ->
        # Parse output for objective and solution
        solution_data = parse_minizinc_output(output, problem_type)
        File.write!(solution_file, Jason.encode!(solution_data, pretty: true))
        IO.puts("    ✅ #{problem_name}")

      {output, _code} ->
        # Check if it's just a timeout or no solution
        if String.contains?(output, "UNSATISFIABLE") or String.contains?(output, "=====UNSATISFIABLE=====") do
          solution_data = %{status: "unsatisfiable", problem: problem_name}
          File.write!(solution_file, Jason.encode!(solution_data, pretty: true))
          IO.puts("    ⚠️  #{problem_name} - UNSATISFIABLE")
        else
          IO.puts("    ❌ #{problem_name} - Error: #{String.slice(output, 0, 100)}")
        end
    end
  end

  defp parse_minizinc_output(output, problem_type) do
    base = %{
      status: "solved",
      output: output
    }

    case problem_type do
      "fox-geese-corn" ->
        parse_fox_geese_corn_output(output, base)

      "tiny-cvrp" ->
        parse_tiny_cvrp_output(output, base)

      _ ->
        base
    end
  end

  defp parse_fox_geese_corn_output(output, base) do
    # Extract objective value
    objective = Regex.run(~r/objective = (\d+)/, output)
      |> case do
        [_, val] -> String.to_integer(val)
        _ -> nil
      end

    # Extract trips
    trips = Regex.run(~r/trips = (\d+)/, output)
      |> case do
        [_, val] -> String.to_integer(val)
        _ -> nil
      end

    # Extract fox, geese, corn arrays
    fox = extract_array(output, "fox")
    geese = extract_array(output, "geese")
    corn = extract_array(output, "corn")

    Map.merge(base, %{
      objective: objective,
      trips: trips,
      fox: fox,
      geese: geese,
      corn: corn
    })
  end

  defp parse_tiny_cvrp_output(output, base) do
    # Extract objective (total distance/ETA)
    objective = Regex.run(~r/objective = (\d+)/, output)
      |> case do
        [_, val] -> String.to_integer(val)
        _ -> nil
      end

    Map.merge(base, %{
      objective: objective
    })
  end

  defp extract_array(output, name) do
    Regex.run(~r/#{name} = \[([^\]]+)\]/, output)
      |> case do
        [_, values] ->
          values
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)
        _ -> nil
      end
  end
end

MinizincSolutionExtractor.extract_all()
