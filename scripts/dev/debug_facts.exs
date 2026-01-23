# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Debug fact extraction for classic problem
alias AriaPlanner.HDDL

problem_file = "test/fixtures/hddl/fox_geese_corn_problem.hddl"
{:ok, content} = File.read(problem_file)
{:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

IO.inspect(ast, label: "AST")

# Extract facts manually
{:problem, _name, elements} = ast
IO.inspect(elements, label: "Elements")

{:aria_initial_state, state_elements} = Enum.find(elements, fn {k, _} -> k == :aria_initial_state end)
IO.inspect(state_elements, label: "State Elements")

facts = Keyword.get(state_elements, :facts, [])
IO.inspect(facts, label: "Facts")
