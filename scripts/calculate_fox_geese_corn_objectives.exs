# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Calculate expected objectives for fox-geese-corn problems
# Formula: objective = east_fox * pf + east_geese * pg + east_corn * pc

problems = [
  %{name: "fox_geese_corn_problem", f: 1, g: 1, c: 1, pf: 4, pg: 4, pc: 3},
  %{name: "fox_geese_corn_problem_fgc_06_26_08_00", f: 6, g: 26, c: 8, pf: 4, pg: 4, pc: 3},
  %{name: "fox_geese_corn_problem_fgc_20_20_22_00", f: 20, g: 20, c: 22, pf: 4, pg: 4, pc: 3},
  %{name: "fox_geese_corn_problem_17", f: 17, g: 17, c: 17, pf: 4, pg: 4, pc: 3},
  %{name: "fox_geese_corn_problem_19", f: 19, g: 19, c: 19, pf: 4, pg: 4, pc: 3},
  %{name: "fox_geese_corn_problem_61", f: 61, g: 61, c: 61, pf: 4, pg: 4, pc: 3}
]

Enum.each(problems, fn p ->
  # When all items are transported, final state has all items on east
  objective = p.f * p.pf + p.g * p.pg + p.c * p.pc
  IO.puts("#{p.name}: #{p.f}*#{p.pf} + #{p.g}*#{p.pg} + #{p.c}*#{p.pc} = #{objective}")
end)
