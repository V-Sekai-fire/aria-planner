# MiniZinc Solution Verification

This document tracks the verification of HDDL domain solutions against expected MiniZinc results.

## Verification Status

All fox-geese-corn problems have been verified against expected MiniZinc objective calculations.

### Verification Method

1. **Expected Solutions File**: `test/fixtures/minizinc_expected_solutions.json`
   - Contains expected objective values calculated using MiniZinc formula
   - Formula: `objective = east_fox * pf + east_geese * pg + east_corn * pc`

2. **Verification Script**: `scripts/verify_all_objectives.exs`
   - Extracts facts from HDDL problem files
   - Calculates objectives using domain's `calculate_objective/1` function
   - Compares against expected values

3. **Test Suite**: `test/hddl/domains/fox_geese_corn_solution_test.exs`
   - Automated tests that verify all problems match expected objectives
   - Tests both individual problems and the classic problem separately

## Verified Problems

### Fox-Geese-Corn Problems

| Problem | f | g | c | pf | pg | pc | Expected Objective | Status |
|---------|---|---|---|----|----|----|-------------------|--------|
| fox_geese_corn_problem | 1 | 1 | 1 | 4 | 4 | 3 | 11 | ✅ Verified |
| fox_geese_corn_problem_fgc_06_26_08_00 | 6 | 26 | 8 | 4 | 4 | 3 | 152 | ✅ Verified |
| fox_geese_corn_problem_fgc_20_20_22_00 | 20 | 20 | 22 | 6 | 5 | 4 | 308 | ✅ Verified |
| fox_geese_corn_problem_foxgeesecorn_17 | 36 | 37 | 40 | 9 | 9 | 9 | 1017 | ✅ Verified |
| fox_geese_corn_problem_foxgeesecorn_19 | 36 | 37 | 40 | 9 | 10 | 8 | 1014 | ✅ Verified |
| fox_geese_corn_problem_foxgeesecorn_61 | 35 | 27 | 52 | 1 | 0 | 0 | 35 | ✅ Verified |

### Other Domains

- **tiny_cvrp**: Expected solutions not yet calculated (requires solving)
- **neighbours**: Expected solutions not yet calculated
- **train_scheduling**: Expected solutions not yet calculated
- **aircraft_disassembly**: Expected solutions not yet calculated

## Running Verification

```bash
# Run verification script
mix run scripts/verify_all_objectives.exs

# Run test suite
mix test test/hddl/domains/fox_geese_corn_solution_test.exs

# Run all domain tests
mix test test/hddl/domains/
```

## Notes

- Objective values are calculated assuming all items are successfully transported to the east side
- The verification currently checks objective calculations, not actual solution plans
- Future work: Verify actual solution plans match MiniZinc solutions (trips, sequences)
