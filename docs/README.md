# Aria Planner — Feature Documentation

This directory documents every feature of the aria-planner library. Use it as a reference when implementing domains or integrating with v-sekai.

## Feature index

| Doc | Feature area | Key modules / concepts |
|-----|----------------|-------------------------|
| [01-htn-planning](01-htn-planning.md) | HTN planning | Tasks, methods, actions, commands, LazyRefinement |
| [02-state-and-facts](02-state-and-facts.md) | State and facts | State (core + planner), predicates, facts storage |
| [03-temporal](03-temporal.md) | Temporal system | PlannerMetadata, UnigoalMetadata, TimeRange, Client, STN |
| [04-entities-and-metadata](04-entities-and-metadata.md) | Entities and metadata | EntityRequirement, PlannerMetadata, MetadataAttachment |
| [05-goals](05-goals.md) | Goals | Multigoals, unigoals, MultiGoalHelpers |
| [06-storage-and-domains](06-storage-and-domains.md) | Storage and domains | ETS, PlanningDomain, DomainRegistry |
| [07-personas-and-plans](07-personas-and-plans.md) | Personas and plans | Persona, Plan, PlanManager |
| [08-blacklisting-and-execution](08-blacklisting-and-execution.md) | Blacklisting and execution | Blacklisting, solution graph, execution lifecycle |
| [09-supporting-modules](09-supporting-modules.md) | Supporting modules | SolutionGraphHelpers, MetadataHelpers, TemporalConverter, TemporalConstraints, AriaStnSolver, built-in domains |

## Quick reference

- **HTN**: Tasks → methods → subtasks/actions; lazy refinement via `LazyRefinement`.
- **Temporal**: All times/durations use **ISO 8601** (strings). `PlannerMetadata` carries duration + optional start/end; STN is the low-level API that backs it.
- **Entities**: `EntityRequirement` (type + capabilities) is required in metadata for actions/commands.
- **State**: Facts are `predicate → subject → value`; state holds `facts` and `entity_capabilities`.
- **Storage**: In-memory only via ETS; no database. Tables: planning_domains, items, personas, locations, plans, predicates, facts_allocentric.
- **Personas**: ReBAC capabilities only; create with `Persona.new(id, name, capabilities: [...])`. No factory methods or identity/type label.

## See also

- [AGENTS.md](../AGENTS.md) — Persona-centric architecture, belief-immersed planning, and solver overview.
