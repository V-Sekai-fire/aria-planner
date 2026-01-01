# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# Create verification infrastructure for all domains
# This script analyzes domains and creates expected solutions

domains = [
  %{name: "neighbours", objective_fn: "sum_of_grid_values", optimize: "maximize"},
  %{name: "tiny_cvrp", objective_fn: "total_distance", optimize: "minimize"},
  %{name: "aircraft_disassembly", objective_fn: "total_time", optimize: "minimize"},
  %{name: "cable_tree_wiring", objective_fn: "total_cost", optimize: "minimize"},
  %{name: "train_scheduling", objective_fn: "total_delay", optimize: "minimize"},
  %{name: "hoist_benchmark", objective_fn: "makespan", optimize: "minimize"},
  %{name: "graph_clear", objective_fn: "total_actions", optimize: "minimize"},
  %{name: "portal", objective_fn: "total_time", optimize: "minimize"},
  %{name: "yumi_dynamic", objective_fn: "total_time", optimize: "minimize"}
]

IO.puts("Domains to verify:")
Enum.each(domains, fn d ->
  IO.puts("  - #{d.name}: #{d.objective_fn} (#{d.optimize})")
end)

IO.puts("\nNote: Expected solutions will be calculated based on:")
IO.puts("  1. MiniZinc model objectives")
IO.puts("  2. Domain-specific calculate_objective functions")
IO.puts("  3. Problem parameters from .dzn files")
