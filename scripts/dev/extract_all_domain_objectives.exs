# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Extract objective information for all domains from MiniZinc models and HDDL files

alias AriaPlanner.HDDL

# Neighbours: maximize sum of grid values
# Formula: objective = sum of all grid cell values (1-5 each)
# For n×m grid, maximum possible = 5 * n * m

# Tiny CVRP: minimize total ETA
# Formula: objective = sum of ETAs for all vehicle routes

domains = [
  %{
    name: "neighbours",
    objective_type: "maximize",
    formula: "sum of all grid values",
    note: "Maximum possible = 5 * n * m for n×m grid"
  },
  %{
    name: "tiny_cvrp",
    objective_type: "minimize",
    formula: "total ETA across all vehicle routes",
    note: "Requires solving to get exact value"
  },
  %{
    name: "aircraft_disassembly",
    objective_type: "minimize",
    formula: "total disassembly time",
    note: "Requires solving to get exact value"
  },
  %{
    name: "cable_tree_wiring",
    objective_type: "minimize",
    formula: "total wiring cost",
    note: "Requires solving to get exact value"
  },
  %{
    name: "train_scheduling",
    objective_type: "minimize",
    formula: "total delay",
    note: "Requires solving to get exact value"
  },
  %{
    name: "hoist_benchmark",
    objective_type: "minimize",
    formula: "makespan",
    note: "Requires solving to get exact value"
  },
  %{
    name: "graph_clear",
    objective_type: "minimize",
    formula: "total actions",
    note: "Requires solving to get exact value"
  },
  %{
    name: "portal",
    objective_type: "minimize",
    formula: "total time",
    note: "Requires solving to get exact value"
  },
  %{
    name: "yumi_dynamic",
    objective_type: "minimize",
    formula: "total time",
    note: "Requires solving to get exact value"
  }
]

IO.puts("Domain Objectives:\n")
Enum.each(domains, fn d ->
  IO.puts("#{d.name}:")
  IO.puts("  Type: #{d.objective_type}")
  IO.puts("  Formula: #{d.formula}")
  IO.puts("  Note: #{d.note}")
  IO.puts("")
end)
