# Personas and Planning Architecture

This document explains the persona system, belief-immersed planning architecture, and execution model for the aria-planner codebase. The system is **persona-centric**, where personas are the core abstraction. AI personas (sometimes called "agents") are just one type of persona in the unified system.

## Table of Contents

1. [Introduction](#introduction)
2. [Persona System](#persona-system)
3. [Belief-Immersed Architecture](#belief-immersed-architecture)
4. [Planning Architecture](#planning-architecture)
5. [Execution Model](#execution-model)
6. [Domain System](#domain-system)
7. [Temporal System](#temporal-system)
8. [Solver Architecture](#solver-architecture)
9. [Storage Architecture](#storage-architecture)
10. [Examples](#examples)
11. [Summary](#summary)

## Introduction

### What are Personas?

Personas are the fundamental entities in the aria-planner system. A persona is an entity with **capabilities in the ReBAC sense** (relationship-based access control): a list of capability atoms that define what it can do. There is no separate "type" or identity label—only the capability set. Examples of capability sets:

- **Movement + interaction**: `:movable`, `:inventory`, `:craft`, `:mine`, `:build`, `:interact` (e.g. player-like)
- **Movement + reasoning**: `:movable`, `:compute`, `:optimize`, `:predict`, `:learn`, `:navigate` (e.g. agent-like)
- **Hybrid**: any combination of the above

Create with `Persona.new(id, name, capabilities: [...])`; grant or revoke via `AriaCore.Entity.update_capability/3`. No factory methods (no "human" or "AI" bundles).

### Architecture Overview

The aria-planner uses a **belief-immersed projection architecture** with two key principles:

1. **Ego-centric Planning**: Each persona plans from their own perspective, with beliefs about others that may be incomplete or incorrect
2. **Allocentric Execution**: Plans execute in a shared reality where all personas can observe outcomes

This creates **information asymmetry** - personas cannot directly access each other's internal states, but can form beliefs through observation and communication.

### Key Concepts

- **Personas**: Entities with ReBAC capabilities (no separate type/identity label)
- **Beliefs**: Ego-centric models each persona maintains about others
- **Planning Domains**: HTN-style planning with predicates, actions, commands, methods, and multigoals
- **Allocentric Facts**: Shared ground truth observable by all personas
- **ETS Storage**: All data stored in-memory using Elixir Term Storage (ETS), no database dependencies

## Persona System

### Unified Persona Entity

All personas implement the `AriaCore.Entity` behaviour and use the `AriaCore.Entity.Types.Persona` struct:

```elixir
defmodule AriaCore.Entity.Types.Persona do
  @behaviour AriaCore.Entity

  defstruct [
    :id,
    :name,
    :type,
    :active,
    :metadata,  # Stores character, position, etc.
    :created_at,
    :updated_at,
    :capabilities  # ReBAC: list of capability atoms (what this entity can do)
  ]
end
```

### Capabilities (ReBAC)

Each entity has a capabilities list; there is no separate type or identity. Example capability sets:

**Example set (player-like):**

- `:movable` - Can move in 3D space
- `:inventory` - Can carry items
- `:craft` - Can craft items
- `:mine` - Can mine resources
- `:build` - Can build structures
- `:interact` - Can interact with objects

**Example set (agent-like):**

- `:movable` - Can move in 3D space
- `:compute` - Can perform computations
- `:optimize` - Can optimize plans
- `:predict` - Can predict outcomes
- `:learn` - Can learn from experience
- `:navigate` - Can navigate autonomously

### Creating Personas

Capabilities are ReBAC-style (relationship-based access control). Each entity has a capabilities list; set them explicitly at creation or via `AriaCore.Entity.update_capability/3`. No special-case factories.

```elixir
alias AriaCore.Entity.Types.Persona

# Create with explicit capabilities
persona = Persona.new("persona_001", "Alex", capabilities: [:movable])

# Human-like capabilities (inventory, craft, etc.)
human_persona = Persona.new("persona_001", "Alex", capabilities: [:movable, :inventory, :craft, :mine, :build, :interact])

# AI-like capabilities (compute, optimize, etc.)
ai_persona = Persona.new("persona_002", "GuardianBot", capabilities: [:movable, :compute, :optimize, :predict, :learn, :navigate])

# Hybrid: pass both capability sets
hybrid_persona = Persona.new("persona_003", "Cyborg", capabilities: [:movable, :inventory, :craft, :mine, :build, :interact, :compute, :optimize, :predict, :learn, :navigate])

# Grant or revoke capabilities later
persona = AriaCore.Entity.update_capability(persona, :inventory, [])
persona = AriaCore.Entity.update_capability(persona, :craft, nil)  # revoke
```

### Entity Behaviour Interface

All personas implement the `AriaCore.Entity` behaviour, providing a unified interface:

```elixir
# Check capabilities
AriaCore.Entity.has_capability?(persona, :craft)
AriaCore.Entity.capabilities(persona)

# Movement
persona = AriaCore.Entity.move_to(persona, {10.0, 5.0, 2.0})
position = AriaCore.Entity.position(persona)

# Metadata access
metadata = AriaCore.Entity.metadata(persona)
```

## Belief-Immersed Architecture

### Ego-centric vs Allocentric

The system maintains two perspectives:

**Ego-centric (Persona Perspective):**

- Each persona plans from their own perspective, with beliefs about others
- Plans are created from the persona's perspective
- Internal states are hidden from other personas
- Beliefs may be incomplete, incorrect, or outdated

**Allocentric (Shared Reality):**

- Single source of truth for observable facts
- Terrain, shared objects, public events
- Observable entity capabilities and positions
- Execution happens in allocentric space

### Information Asymmetry

Personas cannot directly access each other's internal states. Instead, personas form beliefs through observation and communication, which are stored as facts in the allocentric facts system.

### Belief Storage as Facts

**Beliefs are stored as facts** where the persona is the subject of the fact. This eliminates the need for a separate belief management system:

```elixir
# Persona A's belief about Persona B being trustworthy
FactsAllocentric.create(%{
  fact_id: UUIDv7.generate(),
  fact_type: "agent_observable",
  subject_id: persona_a.id,       # The believer
  subject_type: "persona",
  predicate: "believes_trustworthy",
  object_value: persona_b.id,     # The target of belief
  object_type: "entity_ref",
  confidence: 0.8                 # Belief confidence
})

# Persona A's belief about weather conditions
FactsAllocentric.create(%{
  fact_id: UUIDv7.generate(),
  fact_type: "environmental",
  subject_id: persona_a.id,
  subject_type: "persona",
  predicate: "believes_weather",
  object_value: "stormy",
  object_type: "string",
  confidence: 0.9
})
```

### Retrieving Beliefs

Beliefs are retrieved using the standard facts querying interface:

```elixir
# Get all beliefs held by persona A
{:ok, persona_a_beliefs} = FactsAllocentric.get_facts_about(persona_a.id)

# Filter for specific belief types
trust_beliefs = Enum.filter(persona_a_beliefs, &(&1.predicate == "believes_trustworthy"))
weather_beliefs = Enum.filter(persona_a_beliefs, &(&1.predicate == "believes_weather"))
```

### Belief Formation

Beliefs are formed through observation and communication, stored as facts with confidence levels. The belief system emerges naturally from the facts storage rather than requiring hardcoded belief management functions.

### Belief Confidence

Each belief fact has an associated confidence level (0.0 to 1.0) stored in the `confidence` field. Confidence can be updated by modifying the fact:

```elixir
# Update belief confidence based on new evidence
FactsAllocentric.update(belief_fact, %{confidence: 0.95})
```

Confidence increases with:
- Consistent observations
- Successful predictions
- Reliable communication patterns

## Planning Architecture

### HTN Planning

The system uses **Hierarchical Task Network (HTN)** planning with lazy refinement:

1. **Tasks**: High-level goals to be decomposed
2. **Methods**: Decomposition rules for tasks
3. **Actions**: Primitive operations that change state
4. **Commands**: Actions with side effects
5. **Multigoals**: Complex goals requiring multiple subgoals

### Lazy Refinement

Plans are refined incrementally using lazy evaluation:

```elixir
# Lazy refinement process
{:ok, plan} = AriaCore.Planner.LazyRefinement.run_lazy_refineahead(
  domain_spec,
  initial_state_params,
  plan,
  opts
)
```

The refinement process:

1. Starts with initial tasks
2. Decomposes tasks using methods
3. Executes actions when preconditions are met
4. Backtracks on failures
5. Builds a solution graph incrementally

### Task-Based Planning

Tasks are decomposed using methods:

```elixir
# Task method example (from blocks_world)
defmodule AriaPlanner.Domains.BlocksWorld.Tasks.MoveBlocks do
  def t_move_blocks(goal_state) do
    # Decompose into subtasks
    [{"t_move_one", block, destination}, {"t_move_blocks", goal_state}]
  end
end
```

### Goal-Based Planning

Goals are achieved using goal methods:

```elixir
# Goal method example
defmodule AriaPlanner.Domains.BlocksWorld.Unigoals.Move1 do
  def u_move1(block_id, destination) do
    # Return subgoals to achieve
    [{"pos", block_id, "hand"}, {"pos", block_id, destination}]
  end
end
```

### Multigoal Planning

Complex goals requiring multiple subgoals:

```elixir
# Multigoal method example
defmodule AriaPlanner.Domains.BlocksWorld.Multigoals.MoveBlocks do
  def m_move_blocks(goal_state) do
    # Return list of goals to achieve
    [{"pos", "a", "b"}, {"pos", "b", "table"}]
  end
end
```

### Domain Structure

Planning domains consist of:

**Predicates**: State facts stored as plain structs in ETS (Elixir Term Storage)

```elixir
# Example: Position predicate (plain struct, no database)
defmodule AriaPlanner.Domains.BlocksWorld.Predicates.Pos do
  defstruct [:entity_id, :value]

  # Stored in ETS (Elixir Term Storage) for in-memory persistence
  # All data is stored in-memory and lost on application restart
end
```

**Commands**: Actions with side effects (c\_\* functions)

```elixir
defmodule AriaPlanner.Domains.BlocksWorld.Commands.Pickup do
  def c_pickup(block_id) do
    # Update state predicates
    # Return {:ok, result} or {:error, reason}
  end
end
```

**Tasks**: High-level operations (t\_\* functions)

```elixir
defmodule AriaPlanner.Domains.BlocksWorld.Tasks.MoveOne do
  def t_move_one(block, destination) do
    # Return list of subtasks
    [{"t_get", block}, {"t_put", block, destination}]
  end
end
```

**Unigoals**: Single goal methods (u\_\* functions)

```elixir
defmodule AriaPlanner.Domains.BlocksWorld.Unigoals.Move1 do
  def u_move1(block, destination) do
    # Return list of goals
    [{"pos", block, destination}]
  end
end
```

**Multigoals**: Complex goal methods (m\_\* functions)

```elixir
defmodule AriaPlanner.Domains.BlocksWorld.Multigoals.MoveBlocks do
  def m_move_blocks(goal_state) do
    # Return list of goals
    goals
  end
end
```

## Execution Model

### Allocentric Execution

Plans execute in allocentric (shared) reality, not in ego-centric space:

```elixir
# Plan execution lifecycle
plan.execution_status
# "planned" -> "executing" -> "completed" or "failed"
```

### Plan Lifecycle

1. **Planning Phase (Ego-centric)**:

   - Persona creates plan from their perspective
   - Plan stored with `execution_status: "planned"`
   - Contains solution graph and metadata

2. **Execution Phase (Allocentric)**:

   - Plan transitions to `execution_status: "executing"`
   - Actions execute in shared reality
   - All personas can observe outcomes

3. **Completion**:
   - Plan transitions to `execution_status: "completed"` or `"failed"`
   - Performance metrics recorded
   - Beliefs updated based on outcomes

### State Management

Execution state is managed allocentrically:

```elixir
# Execution state with ISO 8601 datetime string
state = AriaPlanner.Planner.State.new(
  current_time: "2025-01-01T10:00:00Z",  # ISO 8601 datetime string
  timeline: %{},
  entity_capabilities: %{},
  facts: %{}
)

# State updates during execution
new_state = AriaPlanner.Planner.State.update_fact(state, entity_id, predicate, value)
```

### Planner Metadata

Actions, commands, and methods return `PlannerMetadata` with temporal and entity requirements:

```elixir
metadata = %AriaPlanner.Planner.PlannerMetadata{
  duration: "PT2H",  # ISO 8601 duration string
  requires_entities: [
    %AriaPlanner.Planner.EntityRequirement{
      type: "agent",
      capabilities: [:cooking, :movable]
    }
  ],
  start_time: "2025-01-01T10:00:00Z",  # Optional ISO 8601 datetime
  end_time: "2025-01-01T12:00:00Z"    # Optional ISO 8601 datetime
}
```

### Temporal Constraint Networks (STN)

The system uses Simple Temporal Networks (STN) for temporal constraint solving:

```elixir
# Create STN with time unit and level of detail
stn = AriaPlanner.Planner.Temporal.STN.new(
  time_unit: :second,
  lod_level: :medium  # 100ms resolution
)

# Add temporal intervals with ISO 8601 strings
interval = %AriaPlanner.Planner.Temporal.Interval{
  id: "action1",
  start_time: "2025-01-01T10:00:00Z",  # ISO 8601 datetime
  end_time: "2025-01-01T10:05:00Z",    # ISO 8601 datetime
  duration: "PT5M"                      # ISO 8601 duration
}

stn = AriaPlanner.Planner.Temporal.STN.add_interval(stn, interval)

# Check consistency
case AriaPlanner.Planner.Temporal.STN.check_consistency(stn) do
  {:consistent, solution} -> # Plan is temporally consistent
  {:inconsistent, reason} -> # Temporal conflict detected
end
```

### Temporal Constraints

Plans can include temporal constraints using **ISO 8601 strings** (not integers):

```elixir
plan = %AriaCore.Plan{
  temporal_constraints: %{
    "action_1" => %{
      start: "2025-01-01T10:00:00Z",
      duration: "PT5M"  # ISO 8601 duration string
    },
    "action_2" => %{
      after: "action_1",
      duration: "PT3M20S"  # ISO 8601 duration string
    }
  }
}
```

**Important**: All planning-related time values use ISO 8601 format:

- **Datetime strings**: `"2025-01-01T10:00:00Z"` (absolute times)
- **Duration strings**: `"PT5M"`, `"PT2H30M"`, `"PT30S"` (relative durations)

The system uses `AriaPlanner.Planner.TimeRange` and `AriaPlanner.Planner.PlannerMetadata` for temporal management. Internal conversion to microseconds happens only for calculations, but the API uses ISO strings exclusively.

**Note**: `ExecutionState.world_time` remains an integer for game simulation (Minecraft-like world state), but all planning operations use ISO 8601 strings.

## Domain System

### Domain Registration

Domains are registered with the planning system:

```elixir
# Create and register a domain
{:ok, domain} = AriaPlanner.Domains.BlocksWorld.create_domain()

# Domain structure
%{
  type: "blocks_world",
  predicates: ["pos", "clear", "holding"],
  actions: [...],
  methods: [...],
  goal_methods: [...]
}
```

### Storage System

All data is stored in-memory using **ETS (Elixir Term Storage)**. The system uses `AriaPlanner.Storage.EtsStorage` to manage all data:

**Supported Tables:**

- `plans` - Persona-specific plans
- `personas` - Persona entities
- `facts_allocentric` - Shared ground truth facts
- `predicates` - Planning domain predicates
- `planning_domains` - Domain definitions
- `locations` - Location entities
- `items` - Item entities

**Storage API:**

```elixir
# Create/Update
{:ok, plan} = AriaCore.Plan.create(attrs)
{:ok, updated_plan} = AriaCore.Plan.update(plan, new_attrs)

# Read
{:ok, plan} = AriaCore.Plan.get(plan_id)
all_plans = AriaCore.Plan.all()

# Delete
:ok = AriaCore.Plan.delete(plan_id)
```

**Important**: All data is stored in-memory and will be lost on application restart. This is similar to `ipyhop` which also doesn't use a database.

### Predicate Schemas

Each predicate is a plain struct stored in ETS:

```elixir
# Example: Position predicate (plain struct, no database)
defmodule AriaPlanner.Domains.BlocksWorld.Predicates.Pos do
  defstruct [:entity_id, :value]

  # Stored in ETS (Elixir Term Storage) for in-memory persistence
  # All data is stored in-memory and lost on application restart
end
```

### Command Execution

Commands execute actions and update state:

```elixir
# Execute a command
{:ok, result} = AriaPlanner.Domains.BlocksWorld.Commands.Pickup.c_pickup("block_a")

# Commands update predicates
# - Check preconditions
# - Update state
# - Return result
```

### Task Decomposition

Tasks decompose into subtasks or actions:

```elixir
# Task decomposition
subtasks = AriaPlanner.Domains.BlocksWorld.Tasks.MoveOne.t_move_one("a", "table")
# Returns: [{"t_get", "a"}, {"t_put", "a", "table"}]
```

### Multigoal Handling

Multigoals decompose into multiple goals:

```elixir
# Multigoal decomposition
goals = AriaPlanner.Domains.BlocksWorld.Multigoals.MoveBlocks.m_move_blocks(goal_map)
# Returns: [{"pos", "a", "b"}, {"pos", "b", "table"}]
```

## Examples

### Creating Personas

Entities have capabilities in the ReBAC sense (relationship-based access control). No factory methods—create with explicit capabilities.

```elixir
alias AriaCore.Entity.Types.Persona

# Human-like persona (explicit capabilities)
human = Persona.new("human_001", "Alice", capabilities: [:movable, :inventory, :craft, :mine, :build, :interact])

# AI persona (agent)
ai = Persona.new("ai_001", "HelperBot", capabilities: [:movable, :compute, :optimize, :predict, :learn, :navigate])

# Hybrid: both capability sets
hybrid = Persona.new("hybrid_001", "Cyborg", capabilities: [:movable, :inventory, :craft, :mine, :build, :interact, :compute, :optimize, :predict, :learn, :navigate])
```

### Planning with Personas

```elixir
# ETS storage is automatically initialized on application start
# via AriaPlanner.Storage.EtsStorage.start_link()

# Create a plan for a persona (stored in ETS)
plan_attrs = %{
  name: "Move Blocks Plan",
  persona_id: persona.id,
  domain_type: "blocks_world",
  objectives: [Jason.encode!(["move_blocks", %{"a" => "b", "b" => "table"}])]
}

{:ok, plan} = AriaCore.Plan.create(plan_attrs)
# Plan is now stored in ETS table :aria_planner_plans

# Execute plan (lazy refinement)
domain_spec = %{
  methods: methods,
  actions: actions,
  initial_tasks: initial_tasks
}

# Initial state with ISO 8601 datetime string
initial_state = %{
  current_time: DateTime.utc_now() |> DateTime.to_iso8601(),  # ISO 8601 string
  timeline: %{},
  entity_capabilities: %{},
  facts: %{}
}

{:ok, executed_plan} = AriaCore.Planner.LazyRefinement.run_lazy_refineahead(
  domain_spec,
  initial_state,
  plan
)
```

### Command Execution with Temporal Constraints

Commands accept ISO 8601 datetime strings for temporal parameters:

```elixir
# Start activity with ISO 8601 datetime string
current_time = DateTime.utc_now() |> DateTime.to_iso8601()  # "2025-01-01T10:00:00Z"

{:ok, new_state, metadata} = AriaPlanner.Domains.AircraftDisassembly.Commands.StartActivity.c_start_activity(
  state,
  activity_id: 1,
  current_time: current_time,  # ISO 8601 string, not integer
  assigned_resources: [resource_1, resource_2]
)

# Metadata includes ISO 8601 temporal constraints
metadata.duration      # "PT2H" - ISO 8601 duration
metadata.start_time    # "2025-01-01T10:00:00Z" - ISO 8601 datetime
metadata.end_time      # "2025-01-01T12:00:00Z" - ISO 8601 datetime
```

### Belief Updates

```elixir
# Persona A observes Persona B and forms/updates a belief
belief_fact = %{
  fact_id: UUIDv7.generate(),
  fact_type: "agent_observable",
  subject_id: persona_a.id,       # The believer
  subject_type: "persona",
  predicate: "believes_mobile",   # Belief about mobility
  object_value: persona_b.id,     # The target of belief
  object_type: "entity_ref",
  confidence: 0.9
}

{:ok, _} = FactsAllocentric.create(belief_fact)

# Check beliefs - retrieve all facts about persona A
{:ok, beliefs} = FactsAllocentric.get_facts_about(persona_a.id)

# Filter for beliefs about persona B
beliefs_about_b = Enum.filter(beliefs, &(&1.object_value == persona_b.id))
```

### Domain Examples

The codebase includes several example domains:

**Blocks World** (`lib/domains/blocks_world/`):

- Classic block stacking problem
- Predicates: `pos`, `clear`, `holding`
- Commands: `c_pickup`, `c_putdown`, `c_stack`, `c_unstack`
- Tasks: `t_move_blocks`, `t_move_one`, `t_get`, `t_put`

**PERT Planner** (`lib/domains/pert_planner/`):

- Project management with tasks and dependencies
- Predicates: `task_duration`, `task_dependency`, `task_status`
- Commands: `c_add_task`, `c_add_dependency`, `c_start_task`, `c_complete_task`

**Aircraft Disassembly** (`lib/domains/aircraft_disassembly/`):

- Complex scheduling with precedence, resources, and location capacity
- Commands: `c_start_activity`, `c_complete_activity`, `c_assign_resource`
- Tasks: `t_schedule_activities`
- Multigoals: `m_schedule_activities`
- Uses ISO 8601 datetime strings for temporal constraints

**Fox-Geese-Corn** (`lib/domains/fox_geese_corn/`):

- Classic river crossing puzzle
- Commands: `c_cross_east`, `c_cross_west`
- Tasks: `t_transport_all`
- Multigoals: `m_transport_all`

**Neighbours** (`lib/domains/neighbours/`):

- Grid value assignment with neighbor constraints
- Commands: `c_assign_value`
- Tasks: `t_maximize_grid`
- Multigoals: `m_maximize_grid`

**Tiny-CVRP** (`lib/domains/tiny_cvrp/`):

- Capacitated Vehicle Routing Problem
- Commands: `c_visit_customer`, `c_return_to_depot`
- Tasks: `t_route_vehicles`
- Multigoals: `m_route_vehicles`

**Locomotion** (migrated to `apps/aria_patrol_solver/lib/aria_patrol_solver/domains/locomotion/`):

- 3D movement and navigation planning with Fibonacci sphere quantization
- Positions and rotations quantized to sphere points for discrete state space
- Predicates: `quantized_position`, `quantized_rotation`, `entity_speed`, `movement_type`, `waypoint_reached`
- Commands: `c_move_to`, `c_rotate_to`, `c_move_and_rotate`, `c_mark_waypoint_reached`
- Tasks: `t_navigate_to`, `t_navigate_path`, `t_patrol`, `t_return_to_start`
- Multigoals: `m_navigate_to`, `m_navigate_path`, `m_patrol`
- **Visualization**: Blender MCP integration for 3D trajectory visualization with keyframe animation
  - Patrol problems create time-based animations with keyframes at each trajectory step
  - Entity movement animated along patrol paths through scattered waypoints
  - Path curves use POLY splines to pass exactly through waypoint positions
  - Meter-scale visualization with proper camera positioning
  - See `apps/aria_patrol_solver` for usage via `mix patrol_solve` or `AriaPatrolSolver.Solver.solve/1`

**Note**: MiniZinc dependencies have been removed from the solver. The `MiniZincSolver`, `ChuffedMiniZinc`, and `MiniZincConverter` modules are deprecated and should not be used in new code.

## Temporal System

### ISO 8601 Time Format

All planning-related time values use **ISO 8601 strings**:

- **Datetime strings**: `"2025-01-01T10:00:00Z"` for absolute times
- **Duration strings**: `"PT5M"`, `"PT2H30M"`, `"PT30S"` for relative durations

**Key Modules**:

- `AriaPlanner.Client`: Converts between ISO 8601 strings and microseconds (internal calculations)
- `AriaPlanner.Planner.TimeRange`: Manages time ranges with ISO 8601 strings
- `AriaPlanner.Planner.PlannerMetadata`: Stores temporal constraints as ISO 8601 strings
- `AriaPlanner.Planner.Temporal.STN`: Simple Temporal Network for constraint solving

**Conversion Functions**:

```elixir
# Convert ISO 8601 datetime to microseconds (internal use)
{:ok, microseconds} = AriaPlanner.Client.iso8601_to_absolute_microseconds("2025-01-01T10:00:00Z")

# Convert microseconds back to ISO 8601 datetime
{:ok, datetime_string} = AriaPlanner.Client.absolute_microseconds_to_iso8601(microseconds)

# Convert ISO 8601 duration to microseconds
{:ok, microseconds} = AriaPlanner.Client.iso8601_duration_to_microseconds("PT5M")

# Convert microseconds to ISO 8601 duration
{:ok, duration_string} = AriaPlanner.Client.microseconds_to_iso8601_duration(microseconds)
```

**Note**: Godot uses integer microseconds internally, but the Elixir planner API exclusively uses ISO 8601 strings. Conversion happens at the boundary layer.

## Solver Architecture

The planner uses multiple solver types:

- **STN Solver** (`AriaPlanner.Solvers.AriaStnSolver`): Solves temporal constraint networks

**Note**: Goal solving is handled by `LazyRefinement` planning loop, not a separate solver module.

**Deprecated**: MiniZinc dependencies have been removed. `MiniZincSolver`, `ChuffedMiniZinc`, `MiniZincConverter`, and `AriaChuffedSolver` are deprecated and have been removed.

## Storage Architecture

### ETS (Elixir Term Storage)

The aria-planner uses **ETS (Elixir Term Storage)** for all data persistence. This is an in-memory storage system that provides fast access to structured data without database dependencies.

**Key Features:**

- **In-Memory Storage**: All data stored in ETS tables (no disk persistence)
- **Fast Access**: O(1) lookup performance for keyed data
- **No Database Dependencies**: No SQLite, PostgreSQL, or other database required
- **Simple API**: Direct struct manipulation with `create/1`, `update/2`, `get/1`, `all/0`, `delete/1`

**Storage Module:**

```elixir
# Initialize ETS storage (called automatically on application start)
AriaPlanner.Storage.EtsStorage.start_link()

# Direct storage operations
AriaPlanner.Storage.EtsStorage.insert(:plans, plan_id, plan)
{:ok, plan} = AriaPlanner.Storage.EtsStorage.get(:plans, plan_id)
all_plans = AriaPlanner.Storage.EtsStorage.all(:plans)
:ok = AriaPlanner.Storage.EtsStorage.delete(:plans, plan_id)
```

**Data Models:**
All core data models are plain structs (not Ecto schemas):

- `AriaCore.Plan` - Persona-specific plans
- `AriaCore.Persona` - Persona entities
- `AriaCore.FactsAllocentric` - Shared ground truth facts
- `AriaCore.PredicateSchema` - Planning domain predicates
- `AriaCore.PlanningDomain` - Domain definitions
- `AriaCore.Location` - Location entities
- `AriaCore.Item` - Item entities

**Important**: All data is stored in-memory and will be lost on application restart. This design is intentional and similar to `ipyhop`, which also doesn't use a database.

## Summary

The aria-planner system is **persona-centric**, not agent-centric. Personas are the core abstraction, with AI personas (agents) being just one type. The system uses:

- **Unified Persona Model**: Human and AI personas share the same structure
- **Belief-Immersed Architecture**: Ego-centric planning with allocentric execution where beliefs are stored as facts
- **HTN Planning**: Hierarchical task network with lazy refinement
- **Information Asymmetry**: Personas form beliefs through observation, stored as facts in the allocentric system
- **Domain-Driven Design**: Extensible domain system with predicates, commands, tasks, and goals
- **ISO 8601 Temporal System**: All planning times use ISO 8601 strings (not integers)
- **Temporal Constraint Networks**: STN-based temporal constraint solving
- **Metadata System**: Structured planner metadata with entity requirements and temporal constraints
- **ETS Storage**: In-memory storage using Elixir Term Storage (no database dependencies)
- **3D Visualization**: Blender MCP integration for visualizing planning solutions as time-based animations with keyframes

This architecture enables rich multi-persona interactions where each persona plans from their own perspective while executing in a shared reality. All data is stored in-memory using ETS, providing fast access without database overhead. The Locomotion domain includes Blender visualization support for patrol problems, creating keyframe animations that show entity movement through waypoints over time.
