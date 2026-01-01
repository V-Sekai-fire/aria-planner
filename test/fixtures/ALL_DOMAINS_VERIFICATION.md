# All Domains Solution Verification

This document tracks verification of HDDL domain solutions against expected MiniZinc results for all domains.

## Verification Status

### ✅ Fully Verified (Objective Calculations)

**Fox-Geese-Corn** (6 problems):

- All objective values verified against MiniZinc formula
- Formula: `objective = east_fox * pf + east_geese * pg + east_corn * pc`
- All 6 problems passing verification

### ✅ Parameter Verified (Requires Solving for Objectives)

**Neighbours** (5 problems):

- Grid dimensions (n, m) verified
- Max possible objective calculated: `5 * n * m`
- Objective calculation function verified
- Note: Optimal objective requires solving

**Tiny CVRP**:

- Problem parameters verified (num_vehicles, num_customers)
- Note: Objective (total ETA) requires solving

### 📋 Documented (Parameter Verification Ready)

**Other Domains** (require solving for objectives):

- **Aircraft Disassembly**: Total disassembly time (minimize)
- **Cable Tree Wiring**: Total wiring cost (minimize)
- **Train Scheduling**: Total delay (minimize)
- **Hoist Benchmark**: Makespan (minimize)
- **Graph Clear**: Total actions (minimize)
- **Portal**: Total time (minimize)
- **Yumi Dynamic**: Total time (minimize)

## Verification Infrastructure

### Files Created

1. **`test/fixtures/minizinc_expected_solutions.json`**
   - Expected solutions for all domains
   - Problem parameters and objective values
   - Notes on what requires solving

2. **`scripts/verify_all_objectives.exs`**
   - Comprehensive verification script
   - Handles fox-geese-corn objective calculations
   - Verifies neighbours grid dimensions
   - Documents other domains

3. **`test/hddl/domains/all_domains_solution_test.exs`**
   - Automated tests for all domains
   - Parameter verification
   - Objective calculation verification
   - Problem parsing verification

4. **`test/hddl/domains/fox_geese_corn_solution_test.exs`**
   - Specific tests for fox-geese-corn
   - Objective value verification
   - Classic problem verification

## Running Verification

```bash
# Run comprehensive verification script
mix run scripts/verify_all_objectives.exs

# Run all domain tests
mix test test/hddl/domains/

# Run specific domain tests
mix test test/hddl/domains/fox_geese_corn_solution_test.exs
mix test test/hddl/domains/all_domains_solution_test.exs
```

## Verification Results

### Fox-Geese-Corn: ✅ All Verified

- 6 problems, all objectives match expected MiniZinc values

### Neighbours: ✅ Parameters Verified

- 5 problems, all grid dimensions verified
- Max possible objectives calculated correctly

### Other Domains: 📋 Ready for Solving

- Problem files parse correctly
- Parameters can be extracted
- Objective functions exist in domain modules
- Ready for solution verification once problems are solved

## Next Steps

1. **Solve remaining domains**: Run planner on problems to get actual solutions
2. **Extract MiniZinc solutions**: Run MiniZinc on problems to get expected values
3. **Compare solutions**: Verify planner solutions match MiniZinc results
4. **Update expected solutions**: Add actual objective values to JSON file
5. **Expand verification**: Add solution plan verification (not just objectives)

## Notes

- Objective verification is complete for fox-geese-corn
- Parameter verification is complete for neighbours and tiny_cvrp
- Other domains need actual solving to get objective values
- Solution plan verification (sequence of actions) is future work
