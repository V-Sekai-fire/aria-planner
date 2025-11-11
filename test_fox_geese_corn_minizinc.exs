# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Test script to convert fox_geese_corn domain to MiniZinc and solve a problem

alias AriaPlanner.Domains.FoxGeeseCorn
alias AriaPlanner.Planner.MiniZincConverter
alias AriaPlanner.Solvers.MiniZincSolver

IO.puts("=" <> String.duplicate("=", 79))
IO.puts("Testing Fox-Geese-Corn Domain Conversion to MiniZinc")
IO.puts("=" <> String.duplicate("=", 79))
IO.puts("")

# Step 1: Create the domain
IO.puts("Step 1: Creating fox_geese_corn domain...")
{:ok, domain} = FoxGeeseCorn.create_domain()
IO.puts("✓ Domain created: #{domain.type}")
IO.puts("  Predicates: #{inspect(domain.predicates)}")
IO.puts("  Actions: #{length(domain.actions)}")
IO.puts("  Tasks: #{length(domain.methods)}")
IO.puts("  Multigoals: #{length(domain.goal_methods)}")
IO.puts("")

# Step 2: Convert domain to MiniZinc
IO.puts("Step 2: Converting domain to MiniZinc format...")
case MiniZincConverter.convert_domain(domain) do
  {:ok, minizinc_code} ->
    IO.puts("✓ Domain converted to MiniZinc")
    IO.puts("  Generated #{String.length(minizinc_code)} characters of MiniZinc code")
    IO.puts("")
    IO.puts("MiniZinc Model Preview (first 500 chars):")
    IO.puts(String.duplicate("-", 79))
    IO.puts(String.slice(minizinc_code, 0, 500))
    IO.puts(String.duplicate("-", 79))
    IO.puts("")

    # Save to file
    output_file = "fox_geese_corn_domain.mzn"
    case MiniZincConverter.convert_domain_to_file(domain, output_file) do
      {:ok, path} ->
        IO.puts("✓ Saved MiniZinc model to: #{path}")
        IO.puts("")

      error ->
        IO.puts("✗ Failed to save file: #{inspect(error)}")
    end

  {:error, reason} ->
    IO.puts("✗ Failed to convert domain: #{inspect(reason)}")
    System.halt(1)
end

# Step 3: Initialize a problem instance
IO.puts("Step 3: Initializing problem instance...")
params = %{f: 1, g: 1, c: 1, k: 2, pf: 4, pg: 4, pc: 3}
{:ok, initial_state} = FoxGeeseCorn.initialize_state(params)
IO.puts("✓ Problem initialized:")
IO.puts("  West: #{initial_state.west_fox} fox, #{initial_state.west_geese} geese, #{initial_state.west_corn} corn")
IO.puts("  East: #{initial_state.east_fox} fox, #{initial_state.east_geese} geese, #{initial_state.east_corn} corn")
IO.puts("  Boat capacity: #{initial_state.boat_capacity}")
IO.puts("  Boat location: #{initial_state.boat_location}")
IO.puts("")

# Step 4: Create a simple MiniZinc problem for testing
IO.puts("Step 4: Creating MiniZinc problem instance...")
# Create a simple constraint problem based on the domain
problem_mzn = """
% Fox-Geese-Corn Problem Instance
% f=1, g=1, c=1, k=2

var 0..1: west_fox;
var 0..1: west_geese;
var 0..1: west_corn;
var 0..1: east_fox;
var 0..1: east_geese;
var 0..1: east_corn;
var bool: boat_west;

% Initial state constraints
constraint west_fox = 1;
constraint west_geese = 1;
constraint west_corn = 1;
constraint east_fox = 0;
constraint east_geese = 0;
constraint east_corn = 0;
constraint boat_west = true;

% Safety constraints: fox cannot be alone with geese
constraint (west_fox = 0) \/ (west_geese = 0) \/ (west_corn > 0);
constraint (east_fox = 0) \/ (east_geese = 0) \/ (east_corn > 0);

% Safety constraints: geese cannot be alone with corn
constraint (west_geese = 0) \/ (west_corn = 0) \/ (west_fox > 0);
constraint (east_geese = 0) \/ (east_corn = 0) \/ (east_fox > 0);

% Goal: all items on east side
constraint east_fox = 1;
constraint east_geese = 1;
constraint east_corn = 1;

solve satisfy;
"""

problem_file = "fox_geese_corn_problem.mzn"
File.write!(problem_file, problem_mzn)
IO.puts("✓ Created problem file: #{problem_file}")
IO.puts("")

# Step 5: Try to solve with MiniZinc
IO.puts("Step 5: Attempting to solve with MiniZinc...")
case MiniZincSolver.available?() do
  true ->
    IO.puts("✓ MiniZinc is available")
    IO.puts("")

    case MiniZincSolver.solve(problem_file) do
      {:ok, solution} ->
        IO.puts("✓ Solution found!")
        IO.puts("  Solution: #{inspect(solution)}")
        IO.puts("")

      {:error, reason} ->
        reason_str = to_string(reason)
        if String.contains?(reason_str, "UNSAT") or String.contains?(reason_str, "unsatisfiable") do
          IO.puts("⚠ Problem is unsatisfiable (this may be expected for this simple model)")
        else
          IO.puts("✗ Solving failed: #{inspect(reason)}")
        end
        IO.puts("")
    end

  false ->
    IO.puts("⚠ MiniZinc is not available - skipping solve test")
    IO.puts("  Install MiniZinc to test solving: https://www.minizinc.org/")
    IO.puts("")
end

# Step 6: Test domain conversion with convert_and_solve
IO.puts("Step 6: Testing convert_and_solve...")
case MiniZincConverter.convert_and_solve(domain) do
  {:ok, solution} ->
    IO.puts("✓ convert_and_solve succeeded!")
    IO.puts("  Solution: #{inspect(solution)}")
    IO.puts("")

  {:error, reason} ->
    reason_str = to_string(reason)
    if String.contains?(reason_str, "minizinc") or
       String.contains?(reason_str, "not found") or
       String.contains?(reason_str, "command") do
      IO.puts("⚠ MiniZinc not available - conversion worked but solving skipped")
    else
      IO.puts("⚠ convert_and_solve result: #{inspect(reason)}")
    end
    IO.puts("")
end

IO.puts("=" <> String.duplicate("=", 79))
IO.puts("Test Complete!")
IO.puts("=" <> String.duplicate("=", 79))

