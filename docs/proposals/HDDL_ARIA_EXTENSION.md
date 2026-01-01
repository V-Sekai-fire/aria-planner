# HDDL Aria Extension Specification

**Status:** Proposed | **Date:** January 2025

## Overview

This document specifies aria_planner-specific extensions to HDDL 2.1 (Hierarchical Domain Definition Language). HDDL 2.1 already provides standard support for tasks, methods, actions, durative actions, durative methods, temporal constraints (with numeric durations), and predicates. This extension adds only aria_planner-specific features: ISO 8601 temporal format, commands, multigoals, goal methods, domain metadata, entities, predicate schemas, planner state, plans, blacklisting, solution graphs, and entity requirements.

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
2. **ISO 8601 Standard**: Extends HDDL 2.1's numeric temporal format with ISO 8601 strings
3. **Optional Annotations**: All aria extensions are optional, allowing gradual adoption
4. **Dual Format Support**: Supports both HDDL 2.1 numeric format (standard) and ISO 8601 format (extension)
5. **aria_planner-Specific Only**: Only documents features unique to aria_planner, not standard HDDL 2.1 features
6. **Structured Metadata**: Domain, plan, and execution metadata as first-class constructs (aria_planner-specific)

## Standard HDDL 2.1 Features (Not Documented Here)

The following are **standard HDDL 2.1 features** and are NOT part of this extension:

- **Tasks**: `(:task ...)` - Standard HDDL
- **Methods**: `(:method ...)` - Standard HDDL for task decomposition
- **Actions**: `(:action ...)` - Standard HDDL
- **Durative Actions**: `(:durative-action ...)` - HDDL 2.1 standard
- **Durative Methods**: `(:durative-method ...)` - HDDL 2.1 standard
- **Predicates**: `(:predicates ...)` - Standard HDDL
- **Temporal Constraints**: Numeric duration support - HDDL 2.1 standard
- **Hierarchical Decomposition**: Task/method hierarchy - Standard HDDL

**This document only covers aria_planner-specific extensions.**

## Syntax Extensions

### 1. Temporal Metadata Block (ISO 8601 Format)

**Extension:** Adds ISO 8601 format support to standard HDDL 2.1 durative actions and methods.

Add optional `:aria-temporal-metadata` block to durative actions and durative methods:

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

**Note:** `(:durative-action ...)` is standard HDDL 2.1. Only the `:aria-temporal-metadata` block is an extension.

Standard HDDL 2.1 durative actions use numeric durations. This extension adds ISO 8601 format support:

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
    :end-time "2025-01-01T10:05:00Z"           ; Optional absolute end (extension)
    :requires-entities (
      (:entity agent :capabilities (:navigation :transport))
    )
  )
)
```

### 3. ISO 8601 Temporal Format for Durative Methods

**Note:** `(:durative-method ...)` is standard HDDL 2.1. Only the `:aria-temporal-metadata` block is an extension.

```hddl
(:durative-method transport_all
  :parameters (?items)
  :task (transport ?items)
  :duration (= ?duration 1800)                  ; Standard HDDL 2.1: 1800 seconds
  :subtasks (
    (transport_item ?items)
    (verify_safe ?items)
  )
  ; aria_planner extension: ISO 8601 temporal metadata
  :aria-temporal-metadata (
    :duration "PT30M"                           ; ISO 8601: 30 minutes (extension)
    :start-time "2025-01-01T10:00:00Z"          ; Extension
    :end-time "2025-01-01T10:30:00Z"            ; Extension
    :requires-entities (
      (:entity agent :capabilities (:transport :safety_check))
    )
  )
)
```

### 4. Entity Requirements Syntax

Entity requirements specify what entities (agents, objects, resources) are needed:

```hddl
(:requires-entities (
  (:entity <entity-type> :capabilities (<cap1> <cap2> ...))
  (:entity <entity-type> :capabilities (<cap1> <cap2> ...))
))
```

**Example:**

```hddl
:requires-entities (
  (:entity agent :capabilities (:cooking :navigation))
  (:entity vehicle :capabilities (:movement :storage))
  (:entity tool :capabilities (:cutting))
)
```

### 5. Commands (Special Actions with Side Effects)

Commands are distinct from regular actions - they have side effects and failure handling:

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

Multigoals represent complex goals requiring multiple subgoals:

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

Methods that decompose goals into subtasks:

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

Domain-level metadata including ID, version, state, and type:

```hddl
(define (domain fox_geese_corn)
  (:requirements :strips :typing :temporal :hierarchical)
  
  (:aria-domain-metadata
    :id "01234567-89ab-cdef-0123-456789abcdef"  ; UUIDv7
    :name "Fox Geese Corn Domain"
    :description "Classic river crossing puzzle"
    :domain-type navigation                      ; blocks_world, tactical, navigation, social, economic, exploration, stealth, custom
    :version 1
    :state active                                ; active, archived, deprecated
    :metadata (
      :author "aria_planner"
      :created-at "2025-01-01T10:00:00Z"
    )
  )
  
  ; ... predicates, actions, methods ...
)
```

### 9. Entities

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

**Note:** `(:predicates ...)` is standard HDDL. Only `:aria-predicate-schemas` is an extension.

Standard HDDL supports predicates. This extension adds predicate schemas with categories and metadata:

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

**Note:** HDDL 2.1 supports temporal constraints with numeric values. This extension adds ISO 8601 format support for STN constraints.

```hddl
; aria_planner extension: STN with ISO 8601 format
(:aria-temporal-constraints
  (:stn
    (:time-point action1_start)
    (:time-point action1_end)
    (:time-point action2_start)
    (:time-point action2_end)
    (:constraint action1_start action1_end "PT10M" "PT15M")  ; ISO 8601 min/max duration
    (:constraint action1_end action2_start "PT0S" "PT5M")     ; ISO 8601 gap between actions
  )
  (:iso8601-format true)                        ; Use ISO 8601 for all constraints (extension)
)
```

### 14. Blacklisting

Blacklisted commands and methods for failure handling:

```hddl
(:aria-blacklist
  :blacklisted-commands (
    (c_cross_east 1 1 0)                        ; Command with arguments that failed
  )
  :blacklisted-methods (
    (transport_all items)                       ; Method that failed
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

## Mapping to aria_planner Structures

### PlannerMetadata Mapping

aria_planner's `PlannerMetadata` struct maps to HDDL as follows:

```elixir
# aria_planner structure
%PlannerMetadata{
  duration: "PT5M",                              # ISO 8601 duration
  start_time: "2025-01-01T10:00:00Z",            # ISO 8601 datetime
  end_time: "2025-01-01T10:05:00Z",             # ISO 8601 datetime
  requires_entities: [                          # Entity requirements
    %EntityRequirement{type: "agent", capabilities: [:navigation, :transport]}
  ]
}
```

**HDDL representation:**

```hddl
:aria-temporal-metadata (
  :duration "PT5M"
  :start-time "2025-01-01T10:00:00Z"
  :end-time "2025-01-01T10:05:00Z"
  :requires-entities (
    (:entity agent :capabilities (:navigation :transport))
  )
)
```

### TemporalConstraints Mapping

aria_planner's `TemporalConstraints` struct:

```elixir
%TemporalConstraints{
  duration: "PT5M",
  start: "2025-01-01T10:00:00Z",
  end: "2025-01-01T10:05:00Z"
}
```

**HDDL representation:**

```hddl
:aria-temporal-metadata (
  :duration "PT5M"
  :start-time "2025-01-01T10:00:00Z"
  :end-time "2025-01-01T10:05:00Z"
)
```

### PlanningDomain Mapping

aria_planner's `PlanningDomain` struct:

```elixir
%PlanningDomain{
  id: "01234567-89ab-cdef-0123-456789abcdef",
  domain_type: "navigation",
  name: "Fox Geese Corn Domain",
  description: "Classic river crossing puzzle",
  entities: [...],
  tasks: [...],
  actions: [...],
  commands: [...],
  multigoals: [...],
  state: :active,
  version: 1,
  metadata: %{},
  inserted_at: ~U[2025-01-01 10:00:00Z],
  updated_at: ~U[2025-01-01 10:00:00Z]
}
```

**HDDL representation:**

```hddl
(define (domain fox_geese_corn)
  (:aria-domain-metadata
    :id "01234567-89ab-cdef-0123-456789abcdef"
    :name "Fox Geese Corn Domain"
    :description "Classic river crossing puzzle"
    :domain-type navigation
    :version 1
    :state active
  )
  ; ... domain elements ...
)
```

### Plan Mapping

aria_planner's `Plan` struct:

```elixir
%Plan{
  id: "01234567-89ab-cdef-0123-456789abcdef",
  name: "Transport All Items Plan",
  persona_id: "persona_123",
  domain_type: "navigation",
  objectives: [...],
  constraints: %{},
  temporal_constraints: %{},
  entity_capabilities: %{},
  solution_graph_data: %{},
  solution_plan: "[...]",
  execution_status: "planned",
  success_probability: 0.85,
  risk_assessment: %{},
  performance_metrics: %{}
}
```

**HDDL representation:**

```hddl
(:aria-plan
  :id "01234567-89ab-cdef-0123-456789abcdef"
  :name "Transport All Items Plan"
  :persona-id "persona_123"
  :domain-type navigation
  :objectives (...)
  :execution-status planned
  :success-probability 0.85
)
```

### Planner State Mapping

aria_planner's `Planner.State` struct:

```elixir
%State{
  current_time: ~U[2025-01-01 10:00:00Z],
  timeline: %{},
  entity_capabilities: %{},
  facts: %{
    "subject_1" => %{predicate_table: fact_value}
  }
}
```

**HDDL representation:**

```hddl
(:aria-initial-state
  :current-time "2025-01-01T10:00:00Z"
  :entity-capabilities (...)
  :facts (
    (:fact subject_1 predicate_table :value fact_value)
  )
)
```

### MultiGoal Mapping

aria_planner's `MultiGoal` struct:

```elixir
%MultiGoal{
  goal_tag: :transport_all,
  goals: [
    ["east_fox", "fox", 1],
    ["east_geese", "geese", 1]
  ]
}
```

**HDDL representation:**

```hddl
(:multigoal transport_all_items
  :goal-tag transport_all
  :goals (
    (east_fox fox 1)
    (east_geese geese 1)
  )
)
```

### PredicateSchema Mapping

aria_planner's `PredicateSchema` struct:

```elixir
%PredicateSchema{
  id: "pred_123",
  name: "east_fox",
  description: "Number of foxes on east side",
  category: "state",
  multi_valued: false,
  metadata: %{}
}
```

**HDDL representation:**

```hddl
(:aria-predicate-schemas
  (:predicate east_fox
    :category state
    :multi-valued false
    :metadata (...)
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

Both formats can coexist in the same domain:

```hddl
(:durative-action example_action
  :duration (= ?duration 300)                   ; HDDL 2.1: for planner compatibility
  :aria-temporal-metadata (
    :duration "PT5M"                            ; ISO 8601: for aria_planner
  )
)
```

**Parser behavior:**

- Standard HDDL 2.1 parsers use `:duration` numeric value
- aria_planner parsers prefer `:aria-temporal-metadata :duration` ISO 8601 value
- If both present, ISO 8601 takes precedence for aria_planner

## Complete Domain Example

This example demonstrates all aria_planner features in HDDL format:

```hddl
(define (domain fox_geese_corn)
  (:requirements :strips :typing :temporal :hierarchical)

  ; Domain metadata
  (:aria-domain-metadata
    :id "01234567-89ab-cdef-0123-456789abcdef"
    :name "Fox Geese Corn Domain"
    :description "Classic river crossing puzzle with temporal constraints"
    :domain-type navigation
    :version 1
    :state active
    :metadata (
      :author "aria_planner"
      :created-at "2025-01-01T10:00:00Z"
    )
  )

  ; Entities with capabilities
  (:entities
    (:entity agent
      :type agent
      :capabilities (:navigation :transport :safety_check)
      :metadata (
        :movable true
      )
    )
  )

  ; Predicates
  (:predicates
    (east_fox ?count)
    (west_fox ?count)
    (west_geese ?count)
    (west_corn ?count)
    (east_geese ?count)
    (east_corn ?count)
    (boat_location ?location)
  )

  ; Predicate schemas
  (:aria-predicate-schemas
    (:predicate east_fox
      :category state
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

  ; Standard HDDL 2.1 durative actions (with aria_planner ISO 8601 extension)
  (:durative-action a_cross_east
    :parameters (?fox_count ?geese_count ?corn_count)
    :duration (= ?duration 300)                 ; 5 minutes in seconds
    :condition (and
      (at start (boat_location west))
      (over all (>= west_fox ?fox_count))
      (over all (>= west_geese ?geese_count))
      (over all (>= west_corn ?corn_count))
      (over all (<= (+ ?fox_count ?geese_count ?corn_count) 2))
    )
    :effect (and
      (at start (decrease west_fox ?fox_count))
      (at start (decrease west_geese ?geese_count))
      (at start (decrease west_corn ?corn_count))
      (at end (increase east_fox ?fox_count))
      (at end (increase east_geese ?geese_count))
      (at end (increase east_corn ?corn_count))
      (at end (assign boat_location east))
    )
    :aria-temporal-metadata (
      :duration "PT5M"
      :requires-entities (
        (:entity agent :capabilities (:navigation :transport))
      )
    )
  )

  ; Commands (special actions with side effects)
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
      :failure-handling retry
      :max-retries 3
      :side-effects true
    )
  )

  ; Standard HDDL task methods (with aria_planner ISO 8601 extension)
  (:method transport_all
    :parameters (?items)
    :task (transport ?items)
    :subtasks (
      (transport_item ?items)
      (verify_safe ?items)
    )
    :aria-temporal-metadata (
      :duration "PT30M"
      :requires-entities (
        (:entity agent :capabilities (:transport :safety_check))
      )
    )
  )

  ; Standard HDDL 2.1 durative methods (with aria_planner ISO 8601 extension)
  (:durative-method transport_all_durative
    :parameters (?items)
    :task (transport ?items)
    :duration (= ?duration 1800)                ; 30 minutes
    :subtasks (
      (transport_item ?items)
      (verify_safe ?items)
    )
    :aria-temporal-metadata (
      :duration "PT30M"
      :start-time "2025-01-01T10:00:00Z"
      :end-time "2025-01-01T10:30:00Z"
      :requires-entities (
        (:entity agent :capabilities (:transport :safety_check))
      )
    )
  )

  ; Goal methods
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

  ; Multigoals
  (:multigoal transport_all_items
    :goal-tag transport_all
    :goals (
      (east_fox 1)
      (east_geese 1)
      (east_corn 1)
    )
    :aria-temporal-metadata (
      :duration "PT30M"
      :requires-entities (
        (:entity agent :capabilities (:transport))
      )
    )
  )

  ; Multigoal methods
  (:multigoal-method achieve_all_items
    :multigoal transport_all_items
    :subtasks (
      (transport_item fox)
      (transport_item geese)
      (transport_item corn)
    )
    :aria-temporal-metadata (
      :duration "PT30M"
    )
  )

  ; aria_planner extension: STN with ISO 8601 format
  (:aria-temporal-constraints
    (:stn
      (:time-point transport_start)
      (:time-point transport_end)
      (:time-point verify_start)
      (:time-point verify_end)
      (:constraint transport_start transport_end "PT25M" "PT35M")
      (:constraint transport_end verify_start "PT0S" "PT2M")
      (:constraint verify_start verify_end "PT3M" "PT5M")
    )
    (:iso8601-format true)
  )

  ; Initial planner state
  (:aria-initial-state
    :current-time "2025-01-01T10:00:00Z"
    :timeline (
      (:event start :time "2025-01-01T10:00:00Z")
    )
    :entity-capabilities (
      (:entity agent_1 :capabilities (:navigation :transport))
    )
    :facts (
      (:fact west_fox :value 1)
      (:fact west_geese :value 1)
      (:fact west_corn :value 1)
      (:fact boat_location :value west)
    )
  )
)

; Problem definition with plan
(define (problem fox_geese_corn_problem)
  (:domain fox_geese_corn)
  
  ; Plan structure
  (:aria-plan
    :id "01234567-89ab-cdef-0123-456789abcdef"
    :name "Transport All Items Plan"
    :persona-id "persona_123"
    :domain-type navigation
    :objectives (
      (transport_all items)
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
    :execution-status planned
    :success-probability 0.85
    :risk-assessment (
      (:risk unsafe_state :probability 0.15)
    )
    :performance-metrics (
      (:metric expected_duration :value "PT45M")
    )
  )

  ; Blacklist (for failure handling)
  (:aria-blacklist
    :blacklisted-commands ()
    :blacklisted-methods ()
  )
)
```

## Parser Implementation Notes

### Standard HDDL 2.1 Parser Features (Not aria_planner Extensions)

Standard HDDL 2.1 parsers already handle:
- Tasks, methods, actions (standard HDDL)
- Durative actions and durative methods (HDDL 2.1)
- Temporal constraints with numeric durations (HDDL 2.1)
- Predicates (standard HDDL)
- Hierarchical task decomposition (standard HDDL)

### Required aria_planner Extension Parser Features

1. **ISO 8601 Duration Parsing** (Extension)
   - Parse `PT[n]H[n]M[n]S` format
   - Convert to numeric seconds for HDDL 2.1 compatibility
   - Validate duration format
   - Parse `:aria-temporal-metadata :duration` blocks

2. **ISO 8601 Datetime Parsing** (Extension)
   - Parse `YYYY-MM-DDTHH:mm:ssZ` format
   - Support timezone offsets
   - Validate datetime format
   - Parse `:aria-temporal-metadata :start-time` and `:end-time`

3. **Entity Requirements Parsing** (Extension)
   - Parse `(:entity <type> :capabilities (<cap1> <cap2> ...))` syntax
   - Convert to `EntityRequirement` structs
   - Validate entity types and capabilities

4. **Commands Parsing** (Extension - aria_planner-specific)
   - Distinguish commands from regular actions
   - Parse `(:command ...)` declarations
   - Parse command metadata (failure-handling, max-retries, side-effects)
   - Build command registry separate from action registry

5. **Multigoals Parsing** (Extension - aria_planner-specific)
   - Parse `(:multigoal ...)` declarations with goal-tag and goals list
   - Support multigoal methods for decomposition
   - Map to `MultiGoal` structs

6. **Goal Methods Parsing** (Extension - aria_planner-specific)
   - Parse `(:goal-method ...)` declarations
   - Support goal decomposition into subtasks
   - Map to goal method dictionary

7. **Domain Metadata Parsing** (Extension - aria_planner-specific)
   - Parse `:aria-domain-metadata` blocks
   - Parse domain ID, name, description, version, state, domain_type
   - Validate domain types (blocks_world, tactical, navigation, etc.)
   - Validate domain states (active, archived, deprecated)
   - Map to `PlanningDomain` struct

8. **Entities Parsing** (Extension - aria_planner-specific)
   - Parse `(:entities ...)` declarations
   - Parse entity declarations with type and capabilities
   - Support entity metadata
   - Build entity capability registry

9. **Predicate Schemas Parsing** (Extension - aria_planner-specific)
   - Parse `:aria-predicate-schemas` blocks
   - Support categories (state, action, effect, goal)
   - Support multi-valued flags
   - Map to `PredicateSchema` structs

10. **Planner State Parsing** (Extension - aria_planner-specific)
    - Parse `:aria-initial-state` blocks
    - Parse current_time, timeline, entity_capabilities, facts
    - Support allocentric fact structure (subject_id => predicate_table => fact_value)
    - Map to `Planner.State` struct

11. **Plan Parsing** (Extension - aria_planner-specific)
    - Parse `:aria-plan` blocks
    - Parse plan structure with objectives, constraints, execution metadata
    - Support execution status (planned, executing, completed, failed)
    - Support success probability, risk assessment, performance metrics
    - Map to `Plan` struct

12. **Blacklisting Parsing** (Extension - aria_planner-specific)
    - Parse `:aria-blacklist` blocks
    - Parse blacklisted commands and methods
    - Support blacklist state management
    - Map to blacklist state structure

13. **Solution Graph Parsing** (Extension - aria_planner-specific)
    - Parse `:aria-solution-graph` blocks
    - Parse node-based solution graph representation
    - Support node types (D, A, G, M)
    - Support node status (NA, O, C)
    - Build solution graph structure

14. **STN with ISO 8601 Parsing** (Extension)
    - Parse `:aria-temporal-constraints` blocks
    - Parse time point declarations
    - Parse constraint min/max durations (ISO 8601 format)
    - Build STN network structure

### Backward Compatibility

- **Standard HDDL 2.1 parsers** should ignore all `:aria-*` blocks
- Standard parsers will use standard HDDL 2.1 features (tasks, methods, actions, durative actions/methods, numeric durations)
- If `:aria-temporal-metadata` is missing, aria_planner parsers should use `:duration` numeric value from standard HDDL 2.1
- All aria extensions are optional and can be omitted
- Commands can be treated as regular actions by standard parsers (if they parse `:command` as `:action`)
- Multigoals, goal methods, domain metadata, entities, predicate schemas, state, plans are all optional extensions
- Standard HDDL 2.1 domains work without any aria extensions

## Benefits

1. **Standard Format**: Uses ISO 8601, a widely supported temporal format
2. **Interoperability**: Works with both HDDL 2.1 planners and aria_planner
3. **Rich Metadata**: Supports absolute time, durations, and entity requirements
4. **STN Support**: Enables complex temporal constraint networks
5. **Backward Compatible**: Existing HDDL 2.1 domains continue to work

## Feature Coverage Summary

This extension provides complete coverage of all aria_planner features:

### ✅ Core Planning Features (Extensions Only)
- **Commands**: Special actions with side effects and failure handling (aria_planner-specific)
- **Goal Methods**: Methods that decompose goals (aria_planner-specific)
- **Multigoals**: Complex goals requiring multiple subgoals (aria_planner-specific)
- **Multigoal Methods**: Methods that decompose multigoals (aria_planner-specific)

**Note:** Tasks, standard methods, actions, and durative actions/methods are standard HDDL 2.1 (not documented here).

### ✅ Temporal Features (Extensions Only)
- **ISO 8601 Durations**: Duration strings (PT5M, PT1H30M, etc.) - Extension (HDDL 2.1 uses numeric)
- **ISO 8601 Datetimes**: Start/end time support - Extension (HDDL 2.1 has no absolute time)
- **STN with ISO 8601**: Simple Temporal Network with ISO 8601 format - Extension
- **Timeline**: Temporal events and intervals - Extension

**Note:** HDDL 2.1 supports temporal constraints with numeric durations (standard, not documented here).

### ✅ Domain Features (Extensions Only)
- **Domain Metadata**: ID, name, description, version, state, domain_type - Extension
- **Domain States**: active, archived, deprecated - Extension
- **Domain Types**: blocks_world, tactical, navigation, social, economic, exploration, stealth, custom - Extension
- **Entities**: Domain objects with capabilities - Extension
- **Predicate Schemas**: Multi-valued predicates with categories and metadata - Extension

**Note:** Predicates are standard HDDL (not documented here).

### ✅ State and Execution Features
- **Planner State**: current_time, timeline, entity_capabilities, facts
- **Facts**: Allocentric fact structure
- **Plans**: Objectives, constraints, solution graphs, execution status
- **Execution Status**: planned, executing, completed, failed
- **Blacklisting**: Blacklisted commands and methods
- **Solution Graphs**: Node-based solution representation

### ✅ Entity Requirements
- **Entity Requirements**: Structured entity capability requirements
- **Entity Capabilities**: Tracking in planner state

## Future Extensions

Potential future enhancements:

1. **Temporal Relations**: Support for Allen's interval algebra relations
2. **Recurring Constraints**: Support for periodic temporal constraints
3. **Time Windows**: Support for flexible time windows with earliest/latest bounds
4. **Temporal Optimization**: Extend goal specifications with temporal optimization criteria
5. **Lazy Refinement Metadata**: Explicit support for lazy refinement planning strategies
6. **Persona-Centric Planning**: Enhanced persona-specific plan metadata

## References

- [HDDL 2.1 Paper](https://arxiv.org/abs/2306.07353) - Temporal HTN Planning Formalism
- [PDDL 2.1 Specification](https://planning.wiki/ref/pddl21) - Temporal Planning Language
- [ISO 8601 Standard](https://en.wikipedia.org/wiki/ISO_8601) - Date and Time Format
- [aria_planner Documentation](../../README.md) - aria_planner Implementation

## Implementation Status

**Status:** Proposed

This extension is currently a specification. Implementation requires:

### Core Parser Features
- HDDL parser updates to support all `:aria-*` blocks
- ISO 8601 parsing library integration (duration and datetime)
- Entity requirement validation and parsing
- STN constraint network builder

### Domain Features
- Domain metadata parsing (ID, version, state, type)
- Entity declarations and capability tracking
- Predicate schema parsing with categories
- Command parsing (distinct from actions)
- Multigoal and goal method parsing

### State and Execution Features
- Planner state parsing (current_time, timeline, entity_capabilities, facts)
- Plan structure parsing (objectives, constraints, execution status)
- Blacklist state parsing
- Solution graph parsing and construction

### Conversion Utilities
- Conversion utilities between HDDL 2.1 numeric and ISO 8601 formats
- Mapping utilities from HDDL structures to aria_planner structs
- Validation utilities for all aria_planner features

### Testing Requirements
- Test backward compatibility with standard HDDL 2.1 parsers
- Test all aria_planner features are correctly parsed
- Test conversion between formats
- Test validation of all structures
