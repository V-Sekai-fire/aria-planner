# SPDX-License-Identifier: MIT
# Standalone test script for Chuffed/FlatZinc functionality
# Run with: elixir test_chuffed_standalone.exs

# Test FlatZinc Generator
IO.puts("=== Testing FlatZinc Generator ===")

# Load the module (assuming it's compiled)
Code.ensure_loaded(AriaPlanner.Solvers.FlatZincGenerator)

constraints = %{
  variables: [
    {:x, :int, 1, 10},
    {:y, :int, 1, 10}
  ],
  constraints: [
    {:int_eq, {:+, :x, :y}, 10}
  ],
  objective: {:minimize, :x}
}

try do
  flatzinc = AriaPlanner.Solvers.FlatZincGenerator.generate(constraints)
  
  IO.puts("\nGenerated FlatZinc:")
  IO.puts("=" <> String.duplicate("=", 50))
  IO.puts(flatzinc)
  IO.puts("=" <> String.duplicate("=", 50))
  
  # Verify it contains expected elements
  assert String.contains?(flatzinc, "var 1..10: x;"), "Missing x variable"
  assert String.contains?(flatzinc, "var 1..10: y;"), "Missing y variable"
  assert String.contains?(flatzinc, "constraint"), "Missing constraint"
  assert String.contains?(flatzinc, "solve minimize x;"), "Missing objective"
  
  IO.puts("\n✓ FlatZinc generator test PASSED")
rescue
  e ->
    IO.puts("\n✗ FlatZinc generator test FAILED: #{inspect(e)}")
    System.halt(1)
end

# Test Chuffed Solver (if available)
IO.puts("\n=== Testing Chuffed Solver ===")

Code.ensure_loaded(AriaPlanner.Solvers.ChuffedSolverNif)
Code.ensure_loaded(AriaPlanner.Solvers.AriaChuffedSolver)

# Simple FlatZinc problem
test_flatzinc = """
var 1..10: x;
var 1..10: y;
constraint x + y = 10;
solve satisfy;
"""

IO.puts("Testing with FlatZinc problem:")
IO.puts(test_flatzinc)

case AriaPlanner.Solvers.AriaChuffedSolver.solve_flatzinc(test_flatzinc) do
  {:ok, solution} ->
    IO.puts("\n✓ Chuffed solver returned solution:")
    IO.inspect(solution, pretty: true)
    
  {:error, :nif_not_loaded} ->
    IO.puts("\n⚠ NIF not loaded (expected if C++ NIF not compiled)")
    IO.puts("  This is OK - the FlatZinc generator still works!")
    
  {:error, reason} ->
    reason_str = to_string(reason)
    if String.contains?(reason_str, "chuffed") or 
       String.contains?(reason_str, "not found") or
       String.contains?(reason_str, "command") do
      IO.puts("\n⚠ Chuffed executable not found (expected if Chuffed not installed)")
      IO.puts("  This is OK - the FlatZinc generator still works!")
    else
      IO.puts("\n✗ Unexpected error: #{inspect(reason)}")
    end
end

IO.puts("\n=== All tests completed ===")


