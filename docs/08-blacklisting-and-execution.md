# Blacklisting and Execution

Blacklisting failed commands/methods and the execution lifecycle of the solution graph.

## Blacklisting (`AriaPlanner.Planner.Blacklisting`)

When a command or method fails during refinement, it can be blacklisted so the planner tries alternatives instead of repeating the same failure.

- **State**: `%{blacklisted_commands: MapSet.t(), blacklisted_methods: MapSet.t()}`.
- **Commands**: Key = `{action_name, args}` tuple.
- **API**: `new/0`, `blacklist_command/2`, `command_blacklisted?/2`, `blacklist_method/2`, `method_blacklisted?/2` (and any other helpers in the module).

LazyRefinement maintains this state and consults it when choosing next actions/methods.

## Solution graph

LazyRefinement builds a **solution graph**:

- **Nodes**: Each node has type (e.g. `:D` for decomposition, `:A` for action), status, info (e.g. task/goal/action), optional duration/metadata, successors.
- **Root**: Node 0 = root; initial tasks are added as successors.
- **Process**: GraphOperations add nodes/edges from tasks/goals via methods; when an action is chosen, an action node is added. Backtracking can remove or mark failed branches.
- **Output**: `GraphOperations.extract_solution_plan(solution_graph)` produces the sequence of actions (solution plan) for the plan.

## Execution lifecycle

1. **Plan created** (PlanManager / Plan.create): `execution_status: "planned"`.
2. **LazyRefinement.run_lazy_refineahead**: Sets status to "executing", runs planning loop (decompose, execute actions, backtrack), then sets "completed" and fills solution_plan, planning_duration_ms, etc.
3. **Failure**: If refinement cannot complete, status may be set to "failed" and execution_completed_at set.

Execution is allocentric: the plan runs in shared reality; the solution plan is the sequence of commands/actions to run.

## Integration points

- **Domain spec**: methods, actions, initial_tasks passed to run_lazy_refineahead.
- **Initial state**: current_time, timeline, entity_capabilities, facts.
- **Plan**: Updated with solution_graph_data, solution_plan, execution_status, timestamps.

## Summary

| Feature | Module / concept | Purpose |
|--------|-------------------|---------|
| Command blacklist | Blacklisting | Avoid retrying failed {action, args} |
| Method blacklist | Blacklisting | Avoid retrying failed methods |
| Solution graph | LazyRefinement, GraphOperations | Nodes and edges for tasks/actions; extract solution plan |
| Execution status | Plan | planned → executing → completed/failed |
