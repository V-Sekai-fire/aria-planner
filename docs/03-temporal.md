# Temporal System

All temporal data uses **ISO 8601** strings (datetimes and durations). The user-facing API is **PlannerMetadata** (and UnigoalMetadata); STN is the low-level implementation for constraint solving.

## Overview

- **PlannerMetadata**: Required duration (ISO 8601 duration string), required requires_entities, optional start_time/end_time (ISO 8601 datetime strings). Returned by actions/commands/methods.
- **UnigoalMetadata**: Like PlannerMetadata plus required **predicate** (which unigoal it applies to).
- **TimeRange**: Helper for start_time, end_time, duration in ISO 8601; calculate duration from start/end or end from start+duration.
- **Client**: Converts between civil/ISO 8601 and absolute microseconds (for internal use).
- **STN**: Simple Temporal Network; low-level API for constraint consistency and scheduling. Used internally to back temporal validation/scheduling implied by PlannerMetadata.

## PlannerMetadata (`AriaPlanner.Planner.PlannerMetadata`)

- **Required**: `duration` (ISO 8601 duration, e.g. `"PT2H"`), `requires_entities` (list of `EntityRequirement`).
- **Optional**: `start_time`, `end_time` (ISO 8601 datetime strings).
- **API**: `new/3`, `new!/3`, `from_map/1`, `valid?/1`, `merge/2`, `to_map/1`, `validate/1`.
- **Merge**: Implements Allen interval algebra (before, after, meets, overlaps, contains, during, equals, etc.) to merge two metadata structs for temporal bridging.

## UnigoalMetadata (`AriaPlanner.Planner.UnigoalMetadata`)

- **Required**: `predicate`, `duration`, `requires_entities`.
- **Optional**: `start_time`, `end_time`.
- **API**: `new/4`, `new!/4`, `from_map/1`, `valid?/1`.

## TimeRange (`AriaPlanner.Planner.TimeRange`)

- **Struct**: `start_time`, `end_time`, `duration` (all ISO 8601 strings, optional).
- **API**: `new/1`, `set_start_now/1`, `set_end_now/1`, `set_start_time/2`, `get_start_time/1`, `set_end_time/2`, `get_end_time/1`, `set_duration/2`, `get_duration/1`, `calculate_duration/1`, `calculate_end_from_duration/1`, `now_iso8601/0`, `to_map/1`, `from_map/1`.

## Client (`AriaPlanner.Client`)

- **Purpose**: Convert between civil time and absolute microseconds (for STN and internal use).
- **API**: `civil_datetime_to_absolute_microseconds/1`, `iso8601_to_absolute_microseconds/1`, `iso8601_duration_to_microseconds/1`, `microseconds_to_iso8601_duration/1`, `absolute_microseconds_to_iso8601/1`.

## STN — Simple Temporal Network (`AriaPlanner.Planner.Temporal.STN`)

- **Role**: Low-level temporal constraint network. Used internally to validate and schedule temporal constraints; domain code works with **PlannerMetadata** (and UnigoalMetadata), not STN directly.
- **Concepts**: Time points, constraints (min/max distance between points), consistency via Floyd-Warshall.
- **LOD**: Resolution levels (e.g. ultra_high → very_low) for different time granularities.
- **API** (for planner internals): `new/1`, `add_constraint/4`, `consistent?/1`, `find_free_slots/4`, etc.
- Submodules: Consistency, Operations, Scheduling, Units.

## Temporal converter and metadata helpers

- **`AriaPlanner.Planner.TemporalConverter`**: Converts between planner temporal representations (e.g. ISO 8601) and internal formats.
- **`AriaPlanner.Planner.MetadataHelpers`**: Helpers for building or validating metadata used in plans.

## Summary

| Feature | Module | Use in domains |
|--------|--------|-----------------|
| Action/command/method temporal + entities | PlannerMetadata | Return from c_* / a_* / methods |
| Unigoal temporal + predicate | UnigoalMetadata | Unigoal method metadata |
| Start/end/duration helpers | TimeRange | Build or adjust time ranges |
| ISO 8601 ↔ microseconds | Client | When integrating with STN or storage |
| Constraint solving | STN | Internal; domains use PlannerMetadata |
