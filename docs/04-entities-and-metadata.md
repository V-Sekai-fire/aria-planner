# Entities and Metadata

Entity requirements and attaching temporal/entity metadata to planner elements (actions, tasks, goals, multigoals).

## EntityRequirement (`AriaPlanner.Planner.EntityRequirement`)

Specifies **who** can execute an operation: entity type and capabilities.

- **Struct**: `type` (string, non-empty), `capabilities` (list of atoms, non-empty).
- **API**: `new/2`, `new!/2`, `valid?/1`, `to_map/1`.
- **Example**: `EntityRequirement.new!("agent", [:cooking, :movable])`.

Used inside **PlannerMetadata** and **UnigoalMetadata** as `requires_entities`.

## PlannerMetadata (temporal + entities)

See [03-temporal](03-temporal.md). Summary:

- **Required**: `duration` (ISO 8601), `requires_entities` (list of `EntityRequirement`).
- **Optional**: `start_time`, `end_time` (ISO 8601).

Actions, commands, and methods return this struct so the planner can enforce temporal and entity constraints.

## MetadataAttachment (`AriaPlanner.Planner.MetadataAttachment`)

Unified way to attach temporal and entity constraints to any planner element (action, task, goal, multigoal).

- **API**: `attach_metadata(item, temporal_constraints \\ %{}, entity_constraints \\ %{})`.
- **item**: Action tuple `{:action_name, arg1, ...}`, task tuple `{:task_name, ...}`, goal `[predicate, subject, value]`, or multigoal (list of goals).
- **temporal_constraints**: Map with optional `duration`, `start_time`, `end_time` (ISO 8601).
- **entity_constraints**: Map with either:
  - `%{"type" => "agent", "capabilities" => [:cooking]}`, or
  - `%{"requires_entities" => [%EntityRequirement{...}]}`.
- Builds a `PlannerMetadata` and attaches it to the item; returns the updated item (e.g. tuple with metadata).

## Domain usage

1. **Commands/actions**: Return `{:ok, result}` or `{:error, reason}` and can attach or return `PlannerMetadata` (duration + requires_entities, optional start/end).
2. **Tasks/goals/multigoals**: Use `MetadataAttachment.attach_metadata/3` when you need to attach temporal or entity constraints to a task/goal/multigoal before passing to the planner.

## Summary

| Feature | Module | Purpose |
|--------|--------|---------|
| Who can do an operation | EntityRequirement | type + capabilities |
| Temporal + entity for steps | PlannerMetadata | duration, requires_entities, start/end |
| Attach metadata to any element | MetadataAttachment | Actions, tasks, goals, multigoals |
