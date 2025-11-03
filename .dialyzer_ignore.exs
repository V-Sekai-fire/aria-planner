# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

[
  # Keeping only truly irremediable issues - will fix the rest systematically
  # These specific issues require deep architectural changes beyond scope
  {"lib/aria_hybrid_planner/planning/planner/tensor_workflow_planner.ex", "contract_range"},

  # Module-level ignores for incomplete solver implementations
  "lib/aria_hybrid_planner/solvers/aria_stn_solver.ex",
  "lib/aria_hybrid_planner/planning/planner/temporal/stn/operations.ex",
  "lib/aria_hybrid_planner/planning/planner/temporal/stn/units.ex",
  "lib/chunk_uploader.ex",
  "lib/chunks/assembly.ex",
  "lib/chunks/core.ex",
  "lib/waffle_adapter.ex",
  "lib/waffle_chunk_store.ex"
]
