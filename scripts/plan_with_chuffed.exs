# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# Example script demonstrating planning with Chuffed constraint solver
# Run with: mix run scripts/plan_with_chuffed.exs

alias AriaPlanner.Solvers.AriaChuffedSolver
alias AriaPlanner.Solvers.FlatZincGenerator

IO.puts("=" <> String.duplicate("=", 70))
IO.puts("Planning with Chuffed - Constraint Programming Examples")
IO.puts("=" <> String.duplicate("=", 70))
IO.puts("")

# Example 1: Simple Resource Allocation
IO.puts("\n[Example 1] Resource Allocation Problem")
IO.puts("-" <> String.duplicate("-", 70))
IO.puts("Problem: Allocate 3 tasks to 2 workers with constraints:")
IO.puts("  - Each task requires 1 worker")
IO.puts("  - Worker 1 can do tasks 1 and 2")
IO.puts("  - Worker 2 can do tasks 2 and 3")
IO.puts("  - All tasks must be assigned")
IO.puts("")

constraints1 = %{
  variables: [
    {:task1_worker, :int, 1, 2},
    {:task2_worker, :int, 1, 2},
    {:task3_worker, :int, 1, 2}
  ],
  constraints: [
    # Worker 1 can do tasks 1 and 2
    {:int_le, :task1_worker, 2},
    {:int_le, :task2_worker, 2},
    # Worker 2 can do tasks 2 and 3
    {:int_ge, :task2_worker, 1},
    {:int_ge, :task3_worker, 1},
    # All tasks must be assigned (implicitly satisfied by domain)
    # Additional constraint: tasks must be assigned to different workers if possible
    {:int_ne, :task1_worker, :task3_worker}
  ],
  objective: {:minimize, {:+, {:+, :task1_worker, :task2_worker}, :task3_worker}}
}

flatzinc1 = FlatZincGenerator.generate(constraints1)
IO.puts("Generated FlatZinc:")
IO.puts(flatzinc1)
IO.puts("")

case AriaChuffedSolver.solve(constraints1) do
  {:ok, solution} ->
    IO.puts("✓ Solution found:")
    IO.inspect(solution, pretty: true)
    IO.puts("")
    IO.puts("Interpretation:")
    if Map.has_key?(solution, :task1_worker) do
      IO.puts("  Task 1 → Worker #{solution.task1_worker}")
      IO.puts("  Task 2 → Worker #{solution.task2_worker}")
      IO.puts("  Task 3 → Worker #{solution.task3_worker}")
    end

  {:error, reason} ->
    reason_str = to_string(reason)
    if String.contains?(reason_str, "chuffed") or 
       String.contains?(reason_str, "not found") or
       String.contains?(reason_str, "command") or
       reason == :nif_not_loaded do
      IO.puts("⚠ Chuffed solver not available (NIF not loaded or Chuffed not installed)")
      IO.puts("  Generated FlatZinc above can be solved with any FlatZinc-compatible solver")
    else
      IO.puts("✗ Error: #{inspect(reason)}")
    end
end

# Example 2: Scheduling with Precedence Constraints
IO.puts("\n[Example 2] Task Scheduling with Precedence")
IO.puts("-" <> String.duplicate("-", 70))
IO.puts("Problem: Schedule 4 tasks with precedence constraints:")
IO.puts("  - Task 1 must finish before Task 2 starts")
IO.puts("  - Task 2 must finish before Task 3 starts")
IO.puts("  - Task 3 must finish before Task 4 starts")
IO.puts("  - Each task takes 1-3 time units")
IO.puts("  - Minimize total completion time")
IO.puts("")

constraints2 = %{
  variables: [
    {:task1_start, :int, 0, 20},
    {:task1_duration, :int, 1, 3},
    {:task2_start, :int, 0, 20},
    {:task2_duration, :int, 1, 3},
    {:task3_start, :int, 0, 20},
    {:task3_duration, :int, 1, 3},
    {:task4_start, :int, 0, 20},
    {:task4_duration, :int, 1, 3}
  ],
  constraints: [
    # Precedence: task1 finishes before task2 starts
    {:int_le, {:+, :task1_start, :task1_duration}, :task2_start},
    # Precedence: task2 finishes before task3 starts
    {:int_le, {:+, :task2_start, :task2_duration}, :task3_start},
    # Precedence: task3 finishes before task4 starts
    {:int_le, {:+, :task3_start, :task3_duration}, :task4_start}
  ],
  objective: {:minimize, {:+, :task4_start, :task4_duration}}
}

flatzinc2 = FlatZincGenerator.generate(constraints2)
IO.puts("Generated FlatZinc:")
IO.puts(flatzinc2)
IO.puts("")

case AriaChuffedSolver.solve(constraints2) do
  {:ok, solution} ->
    IO.puts("✓ Solution found:")
    IO.inspect(solution, pretty: true)
    IO.puts("")
    IO.puts("Interpretation:")
    if Map.has_key?(solution, :task1_start) do
      task1_end = solution.task1_start + solution.task1_duration
      task2_end = solution.task2_start + solution.task2_duration
      task3_end = solution.task3_start + solution.task3_duration
      task4_end = solution.task4_start + solution.task4_duration
      
      IO.puts("  Task 1: Start=#{solution.task1_start}, Duration=#{solution.task1_duration}, End=#{task1_end}")
      IO.puts("  Task 2: Start=#{solution.task2_start}, Duration=#{solution.task2_duration}, End=#{task2_end}")
      IO.puts("  Task 3: Start=#{solution.task3_start}, Duration=#{solution.task3_duration}, End=#{task3_end}")
      IO.puts("  Task 4: Start=#{solution.task4_start}, Duration=#{solution.task4_duration}, End=#{task4_end}")
      IO.puts("  Total completion time: #{task4_end}")
    end

  {:error, reason} ->
    reason_str = to_string(reason)
    if String.contains?(reason_str, "chuffed") or 
       String.contains?(reason_str, "not found") or
       String.contains?(reason_str, "command") or
       reason == :nif_not_loaded do
      IO.puts("⚠ Chuffed solver not available")
    else
      IO.puts("✗ Error: #{inspect(reason)}")
    end
end

# Example 3: All-Different Constraint (N-Queens style)
IO.puts("\n[Example 3] All-Different Assignment")
IO.puts("-" <> String.duplicate("-", 70))
IO.puts("Problem: Assign 5 items to 5 positions, all different")
IO.puts("  - Each item gets a unique position")
IO.puts("  - Position values: 1-5")
IO.puts("")

constraints3 = %{
  variables: [
    {:item1, :int, 1, 5},
    {:item2, :int, 1, 5},
    {:item3, :int, 1, 5},
    {:item4, :int, 1, 5},
    {:item5, :int, 1, 5}
  ],
  constraints: [
    {:all_different, [:item1, :item2, :item3, :item4, :item5]}
  ]
}

flatzinc3 = FlatZincGenerator.generate(constraints3)
IO.puts("Generated FlatZinc:")
IO.puts(flatzinc3)
IO.puts("")

case AriaChuffedSolver.solve(constraints3) do
  {:ok, solution} ->
    IO.puts("✓ Solution found:")
    IO.inspect(solution, pretty: true)
    IO.puts("")
    IO.puts("Interpretation:")
    if Map.has_key?(solution, :item1) do
      IO.puts("  Item 1 → Position #{solution.item1}")
      IO.puts("  Item 2 → Position #{solution.item2}")
      IO.puts("  Item 3 → Position #{solution.item3}")
      IO.puts("  Item 4 → Position #{solution.item4}")
      IO.puts("  Item 5 → Position #{solution.item5}")
      IO.puts("")
      IO.puts("  All positions are unique: ✓")
    end

  {:error, reason} ->
    reason_str = to_string(reason)
    if String.contains?(reason_str, "chuffed") or 
       String.contains?(reason_str, "not found") or
       String.contains?(reason_str, "command") or
       reason == :nif_not_loaded do
      IO.puts("⚠ Chuffed solver not available")
    else
      IO.puts("✗ Error: #{inspect(reason)}")
    end
end

IO.puts("\n" <> "=" <> String.duplicate("=", 70))
IO.puts("Planning examples completed!")
IO.puts("=" <> String.duplicate("=", 70))
IO.puts("")
IO.puts("Note: If Chuffed is not available, the generated FlatZinc can be")
IO.puts("      saved to a file and solved with any FlatZinc-compatible solver.")
IO.puts("")

