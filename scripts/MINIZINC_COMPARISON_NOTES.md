# MiniZinc vs Our Planner Comparison - Issues and Findings

## Summary

Attempted to compare MiniZinc solutions with our planner's solutions for aircraft disassembly problems, but encountered several issues:

## Issues Found

### 1. MiniZinc Solver Availability

**Problem**: Only MIP (Mixed Integer Programming) solvers are available, not CP (Constraint Programming) solvers.

**Available Solvers**:
- COIN-BC 2.10.12/1.17.10 (MIP solver)
- CPLEX (MIP solver)
- Gurobi (MIP solver)
- HiGHS (MIP solver)
- SCIP (MIP solver)
- Xpress (MIP solver)

**Missing**: Gecode or other CP solvers that would be better suited for this constraint programming problem.

**Impact**: The aircraft disassembly problem is a CP problem with:
- Precedence constraints
- Resource skill requirements
- Location capacity constraints
- Mass balance constraints
- Unrelated activity overlap constraints

MIP solvers may not handle these constraints as effectively as CP solvers.

### 2. Our Planner Resource Assignment Issue

**Problem**: `c_start_activity` is being called with empty `assigned_resources` list `[]`, but the function requires resources to be assigned to satisfy skill requirements.

**Error**: `"Insufficient resources with required skills for activity 1"`

**Root Cause**: The test/solver code calls:
```elixir
StartActivity.c_start_activity(state, activity, start_time_hours, [])
```

But `check_resource_skill_requirements` expects resources to be provided:
```elixir
defp check_resource_skill_requirements(state, activity, assigned_resources) do
  # Checks if assigned_resources have the required skills
  # Fails if assigned_resources is empty []
end
```

**Solution Needed**: The solver needs to:
1. Find resources with required skills using `find_resources_with_skills_ego/2` (from `schedule_activities.ex`)
2. Assign those resources to the activity
3. Then call `c_start_activity` with the assigned resources

### 3. Problem Instance Details

**Smallest Problem**: `B737NG-600-01-Anon.json.dzn`
- Activities: 16
- Resources: 21
- Skills: 3
- Precedences: 0 (no precedence constraints in this instance)

This should be solvable by both MiniZinc and our planner.

## Comparison Approach

### What We Need to Compare

From the MiniZinc model (`aircraft.mzn`), the objective function is:
```
objective = 100000 * max(start) + sum(a in ACT, r in RESOURCE)(resource_cost[r] * dur[a] * assign[a, r])
```

This minimizes:
1. **Makespan** (weighted heavily at 100,000x)
2. **Total resource cost** (sum of resource costs × duration × assignment)

### Metrics to Compare

1. **Makespan**: Maximum end time across all activities
2. **Total Resource Cost**: Sum of (resource_cost × duration × assignment) for all activities
3. **Objective Value**: `100000 * makespan + total_cost`
4. **Activity Start Times**: Array of start times for each activity
5. **Resource Assignments**: Which resources are assigned to which activities

## Next Steps

### For MiniZinc Comparison

1. **Install CP Solver**: Install Gecode or another CP solver for MiniZinc
   ```bash
   # On Ubuntu/Debian:
   sudo apt-get install minizinc-gecode
   
   # Or use FlatZinc with a CP solver
   ```

2. **Run MiniZinc with CP Solver**:
   ```bash
   minizinc --solver Gecode --time-limit 60000 \
     aircraft.mzn B737NG-600-01-Anon.json.dzn
   ```

3. **Extract Solution**:
   - Parse `start = [...]` array
   - Parse `assign = [[...], [...], ...]` array
   - Calculate makespan, cost, and objective

### For Our Planner

1. **Fix Resource Assignment**: Update solver to assign resources before calling `c_start_activity`
   ```elixir
   # In solve_activities or similar:
   case find_resources_with_skills_ego(state, activity) do
     {:ok, assigned_resources} ->
       StartActivity.c_start_activity(state, activity, start_time, assigned_resources)
     {:error, reason} ->
       {:error, reason}
   end
   ```

2. **Track Resource Assignments**: Store which resources are assigned to which activities

3. **Calculate Metrics**: 
   - Makespan from activity end times
   - Resource cost from assignments and durations
   - Objective value

## Current Status

- ✅ Problem parsing works (DznParser)
- ✅ State initialization works
- ❌ Resource assignment not implemented in solver
- ❌ MiniZinc CP solver not available
- ❌ Comparison script incomplete

## Files

- **Comparison Script**: `scripts/compare_minizinc_simple.exs`
- **MiniZinc Model**: `thirdparty/mznc2024_probs/aircraft-disassembly/aircraft.mzn`
- **Problem Files**: `thirdparty/mznc2024_probs/aircraft-disassembly/*.dzn`
- **Our Solver**: `test/domains/thirdparty/aircraft_disassembly_solve_test.exs`

