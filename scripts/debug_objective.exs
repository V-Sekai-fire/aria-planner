# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# Debug objective calculation
alias AriaPlanner.HDDL
alias AriaPlanner.Domains.FoxGeeseCorn

problem_file = "test/fixtures/hddl/fox_geese_corn_problem_fgc_20_20_22_00.hddl"
{:ok, content} = File.read(problem_file)
{:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

# Extract facts manually
{:problem, _name, elements} = ast
{:aria_initial_state, state_elements} = Enum.find(elements, fn {k, _} -> k == :aria_initial_state end)
facts = Keyword.get(state_elements, :facts, [])

IO.inspect(facts, label: "Facts")

# Get point values
pf = facts |> Enum.find(fn %{predicate: p} -> p == :pf end) |> Map.get(:value) |> String.to_integer()
pg = facts |> Enum.find(fn %{predicate: p} -> p == :pg end) |> Map.get(:value) |> String.to_integer()
pc = facts |> Enum.find(fn %{predicate: p} -> p == :pc end) |> Map.get(:value) |> String.to_integer()

IO.puts("pf=#{pf}, pg=#{pg}, pc=#{pc}")

# Calculate with expected final state
final_state = %{
  east_fox: 20,
  east_geese: 20,
  east_corn: 22,
  pf: pf,
  pg: pg,
  pc: pc
}

objective = FoxGeeseCorn.calculate_objective(final_state)
IO.puts("Objective: #{objective}")
