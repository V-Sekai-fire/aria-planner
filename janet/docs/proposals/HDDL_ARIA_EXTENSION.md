# HDDL Aria Extension Specification

**Version:** 1.0
**Status:** Historical (HDDL support removed from codebase)
**Date:** January 2025
**Base Standard:** HDDL 2.1
**Implementation:** Removed in commit b100264
**License:** MIT

> **Note:** This document is preserved for reference. HDDL support was removed from aria-planner; the implementation under `lib/hddl/` and related code no longer exist. The specification describes the former aria_planner-specific extensions to HDDL 2.1.

## Abstract

This document formally specifies aria_planner-specific extensions to HDDL 2.1 (Hierarchical Domain Definition Language). HDDL 2.1 provides standard support for tasks, methods, actions, durative actions, durative methods, temporal constraints (with numeric durations), and predicates. This extension added aria_planner-specific features: ISO 8601 temporal format, commands, multigoals, goal methods, domain metadata, entities, predicate schemas, planner state, plans, blacklisting, solution graphs, and entity requirements.

All extensions were prefixed with `:aria-` to ensure backward compatibility with standard HDDL 2.1 parsers, which could safely ignore these blocks.

## Document Status

This specification is **historical**. The implementation was removed from the aria_planner codebase. This document serves as a reference for the former HDDL aria extension syntax and semantics.

## Conformance

A conforming HDDL parser that supported aria extensions had to:

1. **Parse all `:aria-*` blocks** without error
2. **Support ISO 8601 temporal formats** for durations and datetimes
3. **Handle all extension constructs** listed in this specification
4. **Maintain backward compatibility** with standard HDDL 2.1 (ignore unknown `:aria-*` blocks)

A conforming HDDL exporter that supported aria extensions had to:

1. **Export all aria_planner structures** to valid HDDL syntax
2. **Preserve ISO 8601 temporal formats** when present
3. **Include all extension metadata** in exported HDDL
4. **Generate valid HDDL 2.1** that standard parsers could process (with extensions ignored)

## Context

aria_planner is a hierarchical task network (HTN) planner with the following key features:

### Core Planning Features

- **Tasks**: High-level goals decomposed into subtasks
- **Actions**: Primitive operations that change world state
- **Commands**: Special actions with side effects and failure handling
- **Methods**: Decomposition functions for tasks, goals, and multigoals
  - Task methods: decompose tasks into subtasks
  - Goal methods: decompose goals into subtasks
  - Multigoal methods: decompose multigoals into subtasks
- **Multigoals**: Complex goals requiring multiple subgoals

### Temporal Features

- **Duration**: ISO 8601 duration strings (e.g., `"PT5M"`, `"PT1H30M"`)
- **Start/End Times**: ISO 8601 datetime strings (e.g., `"2025-01-01T10:00:00Z"`)
- **STN Support**: Simple Temporal Network for constraint solving
- **Timeline**: Temporal events and intervals tracking

### Domain Features

- **Domain Metadata**: ID, name, description, version, state, domain_type
- **Domain States**: active, archived, deprecated
- **Domain Types**: blocks_world, tactical, navigation, social, economic, exploration, stealth, custom
- **Entities**: Domain objects with capabilities
- **Predicates**: State relationships with categories (state, action, effect, goal)
- **Predicate Schemas**: Multi-valued predicates with metadata

### State and Execution Features

- **Planner State**: current_time, timeline, entity_capabilities, facts
- **Facts**: Allocentric fact structure (subject_id => predicate_table => fact_value)
- **Plans**: Objectives, constraints, solution graphs, execution status
- **Execution Status**: planned, executing, completed, failed
- **Blacklisting**: Blacklisted commands and methods for failure handling
- **Solution Graphs**: Node-based solution representation with lazy refinement

### Entity Requirements

- **Entity Requirements**: Structured entity capability requirements
- **Entity Capabilities**: Tracking entity capabilities in planner state

### Standard HDDL 2.1 Features (NOT part of this extension)

These features are **standard HDDL 2.1** and are documented in the HDDL 2.1 specification:

- **Tasks**: `(:task ...)` - Standard HDDL
- **Methods**: `(:method ...)` - Standard HDDL for task decomposition
- **Actions**: `(:action ...)` - Standard HDDL
- **Durative Actions**: `(:durative-action ...)` with numeric `:duration` - HDDL 2.1 standard
- **Durative Methods**: `(:durative-method ...)` with numeric `:duration` - HDDL 2.1 standard
- **Predicates**: `(:predicates ...)` - Standard HDDL
- **Temporal Constraints**: Numeric duration support - HDDL 2.1 standard
- **Hierarchical Decomposition**: Task/method hierarchy - Standard HDDL

### aria_planner Extensions (this document)

This document **only** covers aria_planner-specific extensions:

1. **ISO 8601 Temporal Format**: ISO 8601 duration/datetime strings (HDDL 2.1 uses numeric)
2. **Commands**: `(:command ...)` - Special actions with side effects (not in standard HDDL)
3. **Multigoals**: `(:multigoal ...)` - Complex goals requiring multiple subgoals
4. **Goal Methods**: `(:goal-method ...)` - Methods that decompose goals
5. **Multigoal Methods**: `(:multigoal-method ...)` - Methods that decompose multigoals
6. **Domain Metadata**: `:aria-domain-metadata` - ID, version, state, domain_type
7. **Entities**: `(:entities ...)` - Domain objects with capabilities
8. **Predicate Schemas**: `:aria-predicate-schemas` - Predicates with categories and metadata
9. **Planner State**: `:aria-initial-state` - Current time, timeline, entity capabilities, facts
10. **Plans**: `:aria-plan` - Plan structure with execution metadata
11. **Blacklisting**: `:aria-blacklist` - Blacklisted commands and methods
12. **Solution Graphs**: `:aria-solution-graph` - Node-based solution representation
13. **Entity Requirements**: Entity capability requirements in temporal metadata
14. **STN with ISO 8601**: `:aria-temporal-constraints` - STN with ISO 8601 format

## Extension Design Principles

1. **Backward Compatibility**: Standard HDDL 2.1 parsers can ignore all `:aria-*` extensions
2. **ISO 8601 Standard**: Extended HDDL 2.1's numeric temporal format with ISO 8601 strings
3. **Optional Annotations**: All aria extensions were optional, allowing gradual adoption
4. **Dual Format Support**: Supported both HDDL 2.1 numeric format (standard) and ISO 8601 format (extension)
5. **aria_planner-Specific Only**: Only documented features unique to aria_planner, not standard HDDL 2.1 features
6. **Structured Metadata**: Domain, plan, and execution metadata as first-class constructs (aria_planner-specific)

## Syntax Extensions

### 1. Temporal Metadata Block (ISO 8601 Format)

**Extension:** Added ISO 8601 format support to standard HDDL 2.1 durative actions and methods.

Optional `:aria-temporal-metadata` block for durative actions and durative methods:

```hddl
(:aria-temporal-metadata
  :duration "PT5M"                              ; ISO 8601 duration (required)
  :start-time "2025-01-01T10:00:00Z"            ; ISO 8601 datetime (optional)
  :end-time "2025-01-01T10:05:00Z"              ; ISO 8601 datetime (optional)
  :requires-entities (                          ; Entity requirements (optional)
    (:entity agent :capabilities (:navigation :transport))
    (:entity vehicle :capabilities (:movement))
  )
)
```

### 2. ISO 8601 Temporal Format for Durative Actions

**Extension Identifier:** `:aria-temporal-metadata` (within `:durative-action`)
**Base Construct:** `(:durative-action ...)` - Standard HDDL 2.1

Standard HDDL 2.1 durative actions use numeric durations. This extension added ISO 8601 format support:

```hddl
(:durative-action a_cross_east
  :parameters (?fox_count ?geese_count ?corn_count)
  :duration (= ?duration 300)                   ; Standard HDDL 2.1: 300 seconds
  :condition (and
    (at start (boat_location west))
    (over all (>= west_fox ?fox_count))
  )
  :effect (and
    (at start (decrease west_fox ?fox_count))
    (at end (increase east_fox ?fox_count))
    (at end (assign boat_location east))
  )
  ; aria_planner extension: ISO 8601 temporal metadata
  :aria-temporal-metadata (
    :duration "PT5M"                            ; ISO 8601: 5 minutes (extension)
    :start-time "2025-01-01T10:00:00Z"          ; Optional absolute start (extension)
    :end-time "2025-01-01T10:05:00Z"            ; Optional absolute end (extension)
    :requires-entities (
      (:entity agent :capabilities (:navigation :transport))
    )
  )
)
```

### 3. ISO 8601 Temporal Format for Durative Methods

**Extension Identifier:** `:aria-temporal-metadata` (within `:durative-method`)
**Base Construct:** `(:durative-method ...)` - Standard HDDL 2.1

```hddl
(:durative-method transport_all
  :parameters (?items)
  :task (transport ?items)
  :duration (= ?duration 1800)                   ; Standard HDDL 2.1: 1800 seconds
  :subtasks (
    (transport_item ?items)
    (verify_safe ?items)
  )
  ; aria_planner extension: ISO 8601 temporal metadata
  :aria-temporal-metadata (
    :duration "PT30M"                            ; ISO 8601: 30 minutes (extension)
    :start-time "2025-01-01T10:00:00Z"          ; Extension
    :end-time "2025-01-01T10:30:00Z"             ; Extension
    :requires-entities (
      (:entity agent :capabilities (:transport :safety_check))
    )
  )
)
```

### 4. Entity Requirements Syntax

**Extension Identifier:** `:requires-entities` (within `:aria-temporal-metadata`)

Entity requirements specified what entities (agents, objects, resources) were needed for an action, command, or method:

```hddl
(:requires-entities (
  (:entity <entity-type> :capabilities (<cap1> <cap2> ...))
  (:entity <entity-type> :capabilities (<cap1> <cap2> ...))
))
```

### 5. Commands (Special Actions with Side Effects)

**Extension Identifier:** `(:command ...)` and `:aria-command-metadata`

Commands were distinct from regular actions—they had side effects and failure handling:

```hddl
(:command c_cross_east
  :parameters (?fox_count ?geese_count ?corn_count)
  :precondition (and
    (boat_location west)
    (>= west_fox ?fox_count)
  )
  :effect (and
    (decrease west_fox ?fox_count)
    (increase east_fox ?fox_count)
    (assign boat_location east)
  )
  :aria-temporal-metadata (
    :duration "PT5M"
    :requires-entities (
      (:entity agent :capabilities (:navigation :transport))
    )
  )
  :aria-command-metadata (
    :failure-handling retry                    ; retry, skip, abort
    :max-retries 3
    :side-effects true
  )
)
```

### 6. Multigoals

**Extension Identifier:** `(:multigoal ...)`

Multigoals represented complex goals requiring multiple subgoals:

```hddl
(:multigoal transport_all_items
  :goal-tag transport_all
  :goals (
    (east_fox ?fox_count)
    (east_geese ?geese_count)
    (east_corn ?corn_count)
  )
  :aria-temporal-metadata (
    :duration "PT30M"
    :requires-entities (
      (:entity agent :capabilities (:transport))
    )
  )
)
```

### 7. Goal Methods

**Extension Identifier:** `(:goal-method ...)`

Methods that decomposed goals into subtasks:

```hddl
(:goal-method achieve_transport
  :goal (transport ?items)
  :subtasks (
    (transport_item ?items)
    (verify_safe ?items)
  )
  :aria-temporal-metadata (
    :duration "PT30M"
  )
)
```

### 8. Domain Metadata

**Extension Identifier:** `:aria-domain-metadata`

Domain-level metadata including ID, version, state, and type:

```hddl
(define (domain fox_geese_corn)
  (:requirements :strips :typing :temporal :hierarchical)

  (:aria-domain-metadata
    :id "01234567-89ab-cdef-0123-456789abcdef"   ; UUIDv7
    :name "Fox Geese Corn Domain"
    :description "Classic river crossing puzzle"
    :domain-type navigation                     ; blocks_world, tactical, navigation, etc.
    :version 1
    :state active                               ; active, archived, deprecated
    :metadata (
      :copyright "aria_planner"
      :created-at "2025-01-01T10:00:00Z"
    )
  )

  ; ... predicates, actions, methods ...
)
```

### 9. Entities

**Extension Identifier:** `(:entities ...)`

Domain entities with capabilities:

```hddl
(:entities
  (:entity agent
    :type agent
    :capabilities (:navigation :transport :safety_check)
    :metadata (
      :movable true
    )
  )
  (:entity vehicle
    :type vehicle
    :capabilities (:movement :storage)
  )
)
```

### 10. Predicate Schemas

**Extension Identifier:** `:aria-predicate-schemas`
**Base Construct:** `(:predicates ...)` - Standard HDDL

Standard HDDL supports predicates. This extension added predicate schemas with categories and metadata:

```hddl
; Standard HDDL predicates
(:predicates
  (east_fox ?count)
  (west_fox ?count)
  (boat_location ?location)
)

; aria_planner extension: Predicate schemas with categories
(:aria-predicate-schemas
  (:predicate east_fox
    :category state                              ; state, action, effect, goal
    :multi-valued false
    :metadata (
      :description "Number of foxes on east side"
    )
  )
  (:predicate boat_location
    :category state
    :multi-valued false
  )
)
```

### 11. Planner State

Initial planner state with current time, timeline, entity capabilities, and facts:

```hddl
(:aria-initial-state
  :current-time "2025-01-01T10:00:00Z"
  :timeline (
    (:event start :time "2025-01-01T10:00:00Z")
  )
  :entity-capabilities (
    (:entity agent_1 :capabilities (:navigation :transport))
    (:entity agent_2 :capabilities (:safety_check))
  )
  :facts (
    (:fact west_fox :value 1)
    (:fact west_geese :value 1)
    (:fact west_corn :value 1)
    (:fact boat_location :value west)
  )
)
```

### 12. Plans

**Extension Identifier:** `:aria-plan`

Plan structure with objectives, constraints, and execution metadata:

```hddl
(:aria-plan
  :id "01234567-89ab-cdef-0123-456789abcdef"     ; UUIDv7
  :name "Transport All Items Plan"
  :persona-id "persona_123"
  :domain-type navigation
  :objectives (
    (transport_all ?items)
  )
  :constraints (
    (:constraint safe_state :type boolean :value true)
  )
  :temporal-constraints (
    (:constraint max_duration :value "PT1H")
  )
  :entity-capabilities (
    (:entity agent_1 :capabilities (:navigation :transport))
  )
  :execution-status planned                      ; planned, executing, completed, failed
  :success-probability 0.85
  :risk-assessment (
    (:risk unsafe_state :probability 0.15)
  )
  :performance-metrics (
    (:metric expected_duration :value "PT45M")
  )
)
```

### 13. STN (Simple Temporal Network) with ISO 8601 Format

**Extension Identifier:** `:aria-temporal-constraints`

HDDL 2.1 supports temporal constraints with numeric values. This extension added ISO 8601 format support for STN constraints:

```hddl
(:aria-temporal-constraints
  (:stn
    (:time-point action1_start)
    (:time-point action1_end)
    (:time-point action2_start)
    (:time-point action2_end)
    (:constraint action1_start action1_end "PT10M" "PT15M")  ; ISO 8601 min/max duration
    (:constraint action1_end action2_start "PT0S" "PT5M")   ; ISO 8601 gap between actions
  )
  (:iso8601-format true)
)
```

### 14. Blacklisting

**Extension Identifier:** `:aria-blacklist`

Blacklisted commands and methods for failure handling:

```hddl
(:aria-blacklist
  :blacklisted-commands (
    (c_cross_east 1 1 0)
  )
  :blacklisted-methods (
    (transport_all items)
  )
)
```

### 15. Solution Graph

Node-based solution graph representation:

```hddl
(:aria-solution-graph
  (:node 0
    :type D                                      ; D (decomposition), A (action), G (goal), M (multigoal)
    :status NA                                   ; NA (not applicable), O (open), C (closed)
    :info (:root)
    :successors (1 2)
  )
  (:node 1
    :type A
    :status C
    :info (a_cross_east 1 1 0)
    :successors (3)
    :duration "PT5M"
  )
  (:node 2
    :type M
    :status O
    :info (transport_all items)
    :successors (4)
  )
)
```

## Conversion Guidelines

### ISO 8601 Duration to Numeric (for HDDL 2.1 compatibility)

When converting aria_planner's ISO 8601 durations to HDDL 2.1 numeric format:

1. **Parse ISO 8601 duration** to component parts (hours, minutes, seconds)
2. **Convert to seconds** (standard HDDL 2.1 convention)
3. **Use numeric value** in `:duration` clause

**Example:**

- ISO 8601: `"PT5M"` → Numeric: `300` (seconds)
- ISO 8601: `"PT1H30M"` → Numeric: `5400` (seconds)
- ISO 8601: `"PT2H15M30S"` → Numeric: `8130` (seconds)

### Dual Format Support

Both formats could coexist in the same domain:

```hddl
(:durative-action example_action
  :duration (= ?duration 300)                    ; HDDL 2.1: for planner compatibility
  :aria-temporal-metadata (
    :duration "PT5M"                             ; ISO 8601: for aria_planner
  )
)
```

## References

### Standards and Specifications

- [HDDL 2.1 Paper](https://arxiv.org/abs/2306.07353) - Temporal HTN Planning Formalism
- [PDDL 2.1 Specification](https://planning.wiki/ref/pddl21) - Temporal Planning Language
- [ISO 8601 Standard](https://en.wikipedia.org/wiki/ISO_8601) - Date and Time Format

## Implementation Status

**Status:** Removed

HDDL support was removed from aria-planner in commit b100264 ("Remove HDDL support and fix core validation bugs"). The former implementation lived under `lib/hddl/` (parser, importer, exporter) and is no longer present. This document is kept in `docs/` for historical reference and for anyone who may want to re-implement or interoperate with the former extension format.
