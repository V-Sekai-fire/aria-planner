# HTN Planning

Hierarchical Task Network (HTN) planning with lazy refinement: tasks, methods, actions, and commands.

## Overview

- **Tasks**: High-level goals decomposed by methods.
- **Methods**: Decomposition rules (task / goal / multigoal) that return subtasks or subgoals.
- **Actions**: Primitive operations that change state; executed directly.
- **Commands**: Actions with side effects; same execution path as actions but domain-defined (e.g. `c_*`).

All are registered in the domain and used by `LazyRefinement` to build a solution graph.

## Modules

| Module | Purpose |
|--------|---------|
| `AriaCore.Planner.Methods` | Registry: task_method_dict, goal_method_dict, multigoal_method_dict |
| `AriaCore.Planner.Actions` | Registry: action_dict (name → function) |
| `AriaCore.Planner.LazyRefinement` | Incremental plan refinement: decompose tasks, execute actions, backtrack on failure |

## Methods (`AriaCore.Planner.Methods`)

- **Task methods**: Decompose a task into subtasks.
- **Goal methods**: Decompose a goal into subgoals.
- **Multigoal methods**: Decompose a multigoal into subgoals.

API: `new/0`, `add_task_method/3`, `add_goal_method/3`, `add_multigoal_method/3`. Dictionaries map method name (atom or string) to list of decomposition functions.

## Actions (`AriaCore.Planner.Actions`)

- **action_dict**: Map from action name (atom) to function.
- Actions are primitive: they are executed when chosen during refinement.
- API: `new/0`, `add_action/3`.

## Commands

Commands are domain-defined “actions with side effects”. They are registered as actions and executed the same way; naming (e.g. `c_pickup`) is by convention. They can return `PlannerMetadata` for temporal and entity requirements.

## Lazy Refinement (`AriaCore.Planner.LazyRefinement`)

- **Entry**: `run_lazy_refineahead(domain_spec, initial_state_params, plan, opts)`.
- **domain_spec**: `%{methods: Methods.t(), actions: Actions.t(), initial_tasks: list()}`.
- **initial_state_params**: `%{current_time, timeline, entity_capabilities, facts}`.
- Process: start from initial tasks, decompose via methods, execute actions when applicable, backtrack on failure, build solution graph, extract solution plan and attach metadata (e.g. duration).
- Uses `AriaCore.Planner.State` for current time, timeline, entity_capabilities, facts.

## Domain structure (HTN)

A domain provides:

1. **Tasks** (e.g. `t_move_blocks`): high-level; decomposed by task methods.
2. **Goal / unigoal methods** (e.g. `u_move1`): one predicate; return list of goals.
3. **Multigoal methods** (e.g. `m_move_blocks`): goal_tag + list of goals.
4. **Actions/commands**: name → function; may return `PlannerMetadata`.

See [06-storage-and-domains](06-storage-and-domains.md) for `PlanningDomain` and [05-goals](05-goals.md) for multigoals/unigoals.
