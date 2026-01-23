# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Test neighbours verification
alias AriaPlanner.HDDL

expected_solutions = Jason.decode!(File.read!("test/fixtures/minizinc_expected_solutions.json"))
neighbours_solutions = expected_solutions["neighbours"] || %{}

problem_file = "test/fixtures/hddl/neighbours_problem_neightbours_new_2.hddl"
problem_name = Path.basename(problem_file, ".hddl")
expected = neighbours_solutions[problem_name]

IO.puts("Problem: #{problem_name}")
IO.puts("Expected found: #{if expected, do: "YES", else: "NO"}")

if expected do
  IO.puts("Expected n: #{expected["n"]}")
  IO.puts("Expected m: #{expected["m"]}")

  {:ok, content} = File.read(problem_file)
  {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

  {:problem, _name, elements} = ast
  {:aria_initial_state, state_elements} = Enum.find(elements, fn {k, _} -> k == :aria_initial_state end)
  facts = Keyword.get(state_elements, :facts, [])

  get_fact = fn pred ->
    case Enum.find(facts, fn %{predicate: p} -> p == pred end) do
      %{value: val} when is_binary(val) -> String.to_integer(val)
      %{value: val} when is_integer(val) -> val
      nil -> nil
    end
  end

  n = get_fact.(:n)
  m = get_fact.(:m)

  IO.puts("Actual n: #{n}")
  IO.puts("Actual m: #{m}")
  IO.puts("Match: n=#{n == expected["n"]}, m=#{m == expected["m"]}")
end
