# State and Facts

Planning state and fact representation: two state modules and predicate/fact storage.

## Overview

- **Facts**: Triples of (predicate, subject, value). State stores them as nested maps: `predicate → subject → value`.
- **State**: Holds current time, timeline, entity capabilities, and facts. Used during refinement and execution.

## State modules (two)

### 1. `AriaCore.Planner.State` (used by LazyRefinement)

- **Struct**: `current_time` (DateTime), `timeline` (map), `entity_capabilities` (map), `facts` (map).
- **Purpose**: Runtime planning state during lazy refinement.
- **API**: `new/4`, `copy/1`, `update/2`.

### 2. `AriaPlanner.Planner.State` (in-memory state for hybrid planner)

- **Struct**: `facts` (required), `entity_capabilities`.
- **Facts**: `%{predicate => %{subject => value}}`.
- **API**: `new/0`, `new/1`, `new/2`, `matches?/4`, fact list conversion, get/update fact helpers.

## Predicates

- **`AriaCore.Predicate`**: Simple predicate map: id, name, description, category, multi_valued, metadata. Validation via `new/1`, `validate/1`.
- **`AriaCore.PredicateSchema`**: Struct for stored predicates (e.g. in ETS): same logical fields plus inserted_at, updated_at. Validation and ETS integration.

Predicates define *what* can be stated (e.g. "pos", "at"); facts are concrete (predicate, subject, value) instances in state.

## Facts storage (allocentric)

- **`AriaCore.FactsAllocentric`**: Shared “ground truth” facts (terrain, public state, beliefs). Stored in ETS table `:aria_planner_facts_allocentric`.
- Beliefs are represented as facts with the believer as subject (see AGENTS.md).

## Summary

| Concept | Module / location | Role |
|--------|--------------------|------|
| Planning state (time, timeline, caps, facts) | `AriaCore.Planner.State` | Used by LazyRefinement |
| State (facts + entity_capabilities) | `AriaPlanner.Planner.State` | Hybrid planner state |
| Predicate definition | `AriaCore.Predicate`, `AriaCore.PredicateSchema` | Schema for facts |
| Stored facts | ETS + `AriaCore.FactsAllocentric` | Allocentric / belief storage |
