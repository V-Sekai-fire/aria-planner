# Goals: Multigoals and Unigoals

Multigoals (multiple goals under one tag) and unigoals (single-predicate goals), plus helpers for checking and verifying them.

## Concepts

- **Unigoal**: A single goal = `[predicate, subject, value]` (e.g. `["pos", "block_a", "table"]`). Achieved by unigoal methods (goal methods) that return a list of subgoals.
- **Multigoal**: A list of unigoals plus an optional goal_tag: used to group goals and select a multigoal method for decomposition.
- **Goal methods**: Decompose one goal (unigoal) into subgoals; registered in `Methods.goal_method_dict`.
- **Multigoal methods**: Decompose a multigoal (by goal_tag) into subgoals; registered in `Methods.multigoal_method_dict`.

## MultiGoal (`AriaCore.Planner.MultiGoal`)

- **Struct**: `goal_tag` (atom), `goals` (list).
- **API**: `new(goal_tag, goals)`.
- Used by LazyRefinement to represent a set of goals that are decomposed together.

## MultiGoalHelpers (`AriaPlanner.Planner.MultiGoalHelpers`)

- **multigoal_array?(term)**: True if term is a list of unigoals (each is a 3-element list) or a map with `"item"` containing such a list.
- **get_goal_tag(term)**: Returns goal_tag from a map-wrapped multigoal, or `""` for a plain array.
- **set_goal_tag(term, tag)**: Sets goal_tag on a map-wrapped multigoal.
- **unachieved_goals(multigoal, state)**: Returns list of goals in the multigoal not satisfied in state.
- **multigoal_achieved?(multigoal, state)**: True if all goals are satisfied in state.

Uses `AriaPlanner.Planner.State` for fact lookups (`matches?`).

## UnigoalMetadata

See [03-temporal](03-temporal.md). Unigoal methods can attach `UnigoalMetadata` (predicate, duration, requires_entities, optional start/end) to identify the predicate and temporal/entity constraints for that unigoal.

## Domain pattern

1. **Unigoal method**: e.g. `u_move1(block, destination)` → returns list of goals `[[predicate, subject, value], ...]`.
2. **Multigoal method**: e.g. `m_move_blocks(goal_state)` → takes goal_tag + goals, returns list of goals.
3. Register in `Methods`: `add_goal_method`, `add_multigoal_method`.
4. Use **MultiGoalHelpers** when you need to test achievement or filter unachieved goals against state.

## Summary

| Feature | Module / type | Purpose |
|--------|----------------|---------|
| Multigoal struct | AriaCore.Planner.MultiGoal | goal_tag + goals |
| Multigoal checks/tags | MultiGoalHelpers | is multigoal?, get/set tag, unachieved, achieved? |
| Unigoal metadata | UnigoalMetadata | predicate + duration + requires_entities (+ start/end) |
