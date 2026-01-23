# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Verify all objective calculations match expected values
alias AriaPlanner.HDDL
alias AriaPlanner.Domains.FoxGeeseCorn

all_expected_solutions = Jason.decode!(File.read!("test/fixtures/minizinc_expected_solutions.json"))

# Verify fox-geese-corn
fox_geese_corn_solutions = all_expected_solutions["fox_geese_corn"] || %{}
problem_files = Path.wildcard("test/fixtures/hddl/fox_geese_corn_problem*.hddl")

IO.puts("Verifying objective calculations:\n")
IO.puts("=== FOX-GEESE-CORN ===\n")

Enum.each(problem_files, fn problem_file ->
  problem_name = Path.basename(problem_file, ".hddl")
  expected = fox_geese_corn_solutions[problem_name]

  if expected do
    {:ok, content} = File.read(problem_file)
    {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

    # Extract facts
    {:problem, _name, elements} = ast
    {:aria_initial_state, state_elements} = Enum.find(elements, fn {k, _} -> k == :aria_initial_state end)
    facts = Keyword.get(state_elements, :facts, [])

    # Get values with safe extraction
    get_fact = fn pred ->
      case Enum.find(facts, fn %{predicate: p} -> p == pred end) do
        %{value: val} when is_binary(val) -> String.to_integer(val)
        %{value: val} when is_integer(val) -> val
        nil -> nil
      end
    end

    # Try both formats: f/g/c or west_fox/west_geese/west_corn
    f = get_fact.(:f) || get_fact.(:west_fox)
    g = get_fact.(:g) || get_fact.(:west_geese)
    c = get_fact.(:c) || get_fact.(:west_corn)
    pf = get_fact.(:pf)
    pg = get_fact.(:pg)
    pc = get_fact.(:pc)

    if f == nil or g == nil or c == nil or pf == nil or pg == nil or pc == nil do
      IO.puts("⚠️  #{problem_name}: Missing required facts")
      IO.puts("   f=#{inspect(f)}, g=#{inspect(g)}, c=#{inspect(c)}, pf=#{inspect(pf)}, pg=#{inspect(pg)}, pc=#{inspect(pc)}")
    else

    # Calculate objective
    final_state = %{
      east_fox: f,
      east_geese: g,
      east_corn: c,
      pf: pf,
      pg: pg,
      pc: pc
    }

    calculated = FoxGeeseCorn.calculate_objective(final_state)
    expected_obj = expected["expected_objective"]

    status = if calculated == expected_obj, do: "✅", else: "❌"
    IO.puts("#{status} #{problem_name}")
    IO.puts("   f=#{f}, g=#{g}, c=#{c}, pf=#{pf}, pg=#{pg}, pc=#{pc}")
    IO.puts("   Calculated: #{calculated}, Expected: #{expected_obj}")

      if calculated != expected_obj do
        IO.puts("   ⚠️  MISMATCH!")
      end
      IO.puts("")
    end
  else
    IO.puts("⚠️  #{problem_name}: No expected solution found")
  end
end)

# Verify neighbours
IO.puts("\n=== NEIGHBOURS ===\n")
neighbours_solutions = all_expected_solutions["neighbours"] || %{}
neighbours_files = Path.wildcard("test/fixtures/hddl/neighbours_problem*.hddl")

Enum.each(neighbours_files, fn problem_file ->
  problem_name = Path.basename(problem_file, ".hddl")
  expected = neighbours_solutions[problem_name]

  if expected do
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

    if n && m do
      max_possible = expected["max_possible"]
      IO.puts("✅ #{problem_name}")
      IO.puts("   n=#{n}, m=#{m}")
      IO.puts("   Max possible objective: #{max_possible} (5 * #{n} * #{m})")
      IO.puts("   Expected objective: #{expected["expected_objective"] || "Requires solving"}")
      IO.puts("")
    else
      IO.puts("⚠️  #{problem_name}: Missing n or m")
    end
  else
    IO.puts("⚠️  #{problem_name}: No expected solution found")
  end
end)

IO.puts("\n=== OTHER DOMAINS ===\n")
IO.puts("Note: Other domains (tiny_cvrp, aircraft_disassembly, etc.) require")
IO.puts("      solving to get exact objective values. Parameter verification")
IO.puts("      is handled by domain-specific tests.\n")
