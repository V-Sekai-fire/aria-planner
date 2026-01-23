# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Debug neighbours lookup
alias AriaPlanner.HDDL

expected_solutions = Jason.decode!(File.read!("test/fixtures/minizinc_expected_solutions.json"))
neighbours_solutions = expected_solutions["neighbours"] || %{}

IO.puts("Expected keys in JSON:")
Enum.each(Map.keys(neighbours_solutions), fn k -> IO.puts("  #{k}") end)

IO.puts("\nActual problem files:")
neighbours_files = Path.wildcard("test/fixtures/hddl/neighbours_problem*.hddl")
Enum.each(neighbours_files, fn problem_file ->
  problem_name = Path.basename(problem_file, ".hddl")
  IO.puts("  #{problem_name}")
  expected = neighbours_solutions[problem_name]
  IO.puts("    Found in JSON: #{if expected, do: "YES", else: "NO"}")
end)
