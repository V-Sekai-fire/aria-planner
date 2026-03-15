# Personas and Plans

Persona entity type and plan struct plus plan creation.

## Persona (`AriaCore.Entity.Types.Persona`)

Entity (persona) with **capabilities in the ReBAC sense**: relationship-based access control. Each entity has a capabilities list; there are no special-case factories (no “human” or “AI” bundles).

- **Struct**: `id`, `name`, `type`, `active`, `metadata`, `created_at`, `updated_at`, `capabilities`.
- **Capabilities**: ReBAC-style list of atoms (what this entity can do); set at creation or via `AriaCore.Entity.update_capability/3`. No factory methods—create with `Persona.new(id, name, capabilities: [...])`.
- **API** (via `AriaCore.Entity` behaviour): `has_capability?/2`, `capabilities/1`, `update_capability/3`, `move_to/2`, `position/1`, `metadata/1`.
- **Creation**: `Persona.new(id, name, opts \\ [])` with `opts[:capabilities]` (list of atoms). Type is just capabilities; no separate identity label.

Stored in ETS table `:aria_planner_personas`.

## Plan (`AriaCore.Plan`)

Ego-centric plan for one persona.

- **Identity**: `id` (RFC 9562 UUIDv7), `name`, `persona_id`, `domain_type`.
- **Input**: `objectives`, `constraints`, `temporal_constraints`, `entity_capabilities`.
- **Result**: `solution_graph_data`, `solution_plan` (e.g. JSON string), `planning_timestamp`, `planning_duration_ms`, `planner_state_snapshot`.
- **Execution**: `execution_status` ("planned" | "executing" | "completed" | "failed"), `execution_started_at`, `execution_completed_at`.
- **Optional**: `success_probability`, `risk_assessment`, `performance_metrics`, `inserted_at`, `updated_at`.

Stored in ETS table `:aria_planner_plans`. Validated via `Plan.validate/1`, `Plan.create/1`.

## PlanManager (`AriaPlanner.PlanManager`)

- **API**: `create_plan(persona_id, name, domain_type, opts)`.
- **opts**: e.g. `:objectives` (or `:todo`), `:success_probability`.
- Validates inputs and calls `Plan.create/1` with persona_id, name, domain_type, objectives, success_probability, planning_timestamp.

## Execution lifecycle

1. **Planned**: Plan created; solution graph/plan may be empty until refinement.
2. **Executing**: LazyRefinement or executor has started (execution_started_at set).
3. **Completed / Failed**: execution_completed_at set; status updated.

Plans execute in allocentric reality; persona_id indicates which persona the plan belongs to.

## Summary

| Feature | Module | Purpose |
|--------|--------|---------|
| Persona entity | AriaCore.Entity.Types.Persona, AriaCore.Entity | ReBAC capabilities, movement |
| Plan struct | AriaCore.Plan | Objectives, solution, execution status, UUIDv7 |
| Plan creation | PlanManager | create_plan(persona_id, name, domain_type, opts) |
