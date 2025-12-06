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
9. [MCP Integration](#mcp-integration)
10. [Examples](#examples)

## Introduction

### What are Personas?

Personas are the fundamental entities in the aria-planner system. A persona represents an entity's personality and capabilities expressed through their Avatar in a 3D environment. Personas can be:

- **Human Personas**: Entities controlled by human players with capabilities like inventory, crafting, mining, building, and interaction
- **AI Personas**: Autonomous entities (sometimes called "agents") with capabilities like compute, optimize, predict, learn, and navigate
- **Hybrid Personas**: Entities with both human and AI capabilities

The system uses a **unified persona model** where the distinction between human and AI is based on capabilities, not separate types.

### Architecture Overview

The aria-planner uses a **belief-immersed projection architecture** with two key principles:

1. **Ego-centric Planning**: Each persona plans from their own perspective, with beliefs about others that may be incomplete or incorrect
2. **Allocentric Execution**: Plans execute in a shared reality where all personas can observe outcomes

This creates **information asymmetry** - personas cannot directly access each other's internal states, but can form beliefs through observation and communication.

### Key Concepts

- **Personas**: Unified entities (human or AI) with capabilities
- **Beliefs**: Ego-centric models each persona maintains about others
- **Planning Domains**: HTN-style planning with predicates, actions, commands, methods, and multigoals
- **Allocentric Facts**: Shared ground truth observable by all personas

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
    :metadata,  # Stores character, position, capabilities data
    :created_at,
    :updated_at,
    :capabilities  # Determines persona type
  ]
end
```

### Capability-Based Differentiation

Personas are differentiated by their capabilities, not by separate types:

**Human Persona Capabilities:**

- `:movable` - Can move in 3D space
- `:inventory` - Can carry items
- `:craft` - Can craft items
- `:mine` - Can mine resources
- `:build` - Can build structures
- `:interact` - Can interact with objects

**AI Persona Capabilities:**

- `:movable` - Can move in 3D space
- `:compute` - Can perform computations
- `:optimize` - Can optimize plans
- `:predict` - Can predict outcomes
- `:learn` - Can learn from experience
- `:navigate` - Can navigate autonomously

### Creating Personas

```elixir
alias AriaCore.Entity.Types.Persona

# Create a basic persona
persona = Persona.new("persona_001", "Alex")

# Enable human capabilities
human_persona = Persona.enable_human_capabilities(persona)
# Or use convenience function
human_persona = Persona.new_human_player("persona_001", "Alex")

# Enable AI capabilities (creates an AI persona)
ai_persona = Persona.enable_ai_capabilities(persona)
# Or use convenience function
ai_persona = Persona.new_ai_agent("persona_002", "GuardianBot")

# Hybrid persona with both capabilities
hybrid_persona = persona
  |> Persona.enable_human_capabilities()
  |> Persona.enable_ai_capabilities()
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

### Persona Identity Types

The system automatically determines persona identity based on capabilities:

```elixir
Persona.identity_type(persona)
# Returns: :basic, :human, :ai, or :human_and_ai
```

## Belief-Immersed Architecture

### Ego-centric vs Allocentric

The system maintains two perspectives:

**Ego-centric (Persona Perspective):**

- Each persona has their own beliefs about others
- Plans are created from the persona's perspective
- Internal states are hidden from other personas
- Beliefs may be incomplete, incorrect, or outdated

**Allocentric (Shared Reality):**

- Single source of truth for observable facts
- Terrain, shared objects, public events
- Observable entity capabilities and positions
- Execution happens in allocentric space

### Information Asymmetry

Personas cannot directly access each other's internal states:

```elixir
# This will return {:error, :hidden}
AriaCore.Persona.get_planner_state(target_persona_id, requesting_persona_id)
```

Instead, personas form beliefs through:

- **Observation**: Watching actions and outcomes
- **Communication**: Receiving messages from other personas
- **Allocentric Facts**: Observing shared reality

### Belief Formation

Beliefs are stored in the persona's `beliefs_about_others` field:

```elixir
# Get what persona_a believes about persona_b
beliefs = AriaCore.Persona.get_beliefs_about(persona_a, persona_b_id)

# Beliefs include:
# - Observed actions and patterns
# - Communication history
# - Success/failure patterns
# - Confidence levels
```

### Observation and Communication

Personas update beliefs through observation:

```elixir
# Process an observation
observation = %{
  entity: "persona_b",
  action: "movement",
  confidence: 0.8
}
{:ok, updated_persona} = AriaCore.Persona.process_observation(persona_a, observation)

# Process communication
communication = %{
  sender: persona_b,
  content: "I'll coordinate the attack",
  type: :cooperative
}
{:ok, updated_persona} = AriaCore.Persona.process_communication(persona_a, communication)
```

### Belief Confidence

Each belief has an associated confidence level (0.0 to 1.0):

```elixir
# Access belief confidence
confidence = persona.belief_confidence["persona_b"]["movement"]
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

**Predicates**: State facts stored in database tables

```elixir
# Example: blocks_world_pos table
schema "blocks_world_pos" do
  field(:entity_id, :string)
  field(:value, :string)
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

### Predicate Schemas

Each predicate has its own database table:

```elixir
# Example: Position predicate
defmodule AriaPlanner.Domains.BlocksWorld.Predicates.Pos do
  use Ecto.Schema

  schema "blocks_world_pos" do
    field(:entity_id, :string)
    field(:value, :string)
  end
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

```elixir
alias AriaCore.Entity.Types.Persona

# Human persona
human = Persona.new_human_player("human_001", "Alice")
# Capabilities: [:movable, :inventory, :craft, :mine, :build, :interact]

# AI persona (agent)
ai = Persona.new_ai_agent("ai_001", "HelperBot")
# Capabilities: [:movable, :compute, :optimize, :predict, :learn, :navigate]

# Hybrid persona
hybrid = Persona.new("hybrid_001", "Cyborg")
  |> Persona.enable_human_capabilities()
  |> Persona.enable_ai_capabilities()
```

### Planning with Personas

```elixir
# Create a plan for a persona
plan_attrs = %{
  name: "Move Blocks Plan",
  persona_id: persona.id,
  domain_type: "blocks_world",
  objectives: [Jason.encode!(["move_blocks", %{"a" => "b", "b" => "table"}])]
}

{:ok, plan} = AriaCore.Plan.create(plan_attrs)

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
# Persona A observes Persona B
observation = %{
  entity: persona_b.id,
  action: "movement",
  confidence: 0.9
}

{:ok, updated_persona_a} = AriaCore.Persona.process_observation(persona_a, observation)

# Check beliefs
beliefs = AriaCore.Persona.get_beliefs_about(updated_persona_a, persona_b.id)
# %{
#   "observed_movement" => %{
#     "observed_at" => ~U[2025-01-01 10:00:00Z],
#     "confidence" => 0.9,
#     "pattern" => "mobile"
#   }
# }
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

- **Goal Solver** (`AriaPlanner.Solvers.AriaGoalSolver`): Solves goal-based planning problems
- **STN Solver** (`AriaPlanner.Solvers.AriaStnSolver`): Solves temporal constraint networks
- **Chuffed Solver** (`AriaPlanner.Solvers.AriaChuffedSolver`): Direct Chuffed solver (no MiniZinc)

**Deprecated**: MiniZinc dependencies have been removed. `MiniZincSolver`, `ChuffedMiniZinc`, and `MiniZincConverter` are deprecated.

## MCP Integration

The system includes MCP (Model Context Protocol) tool handlers for external integration:

- `AriaPlanner.MCP.AriaForge.ToolHandlers`: Handles MCP tool calls for plan creation, domain management, etc.

## Summary

The aria-planner system is **persona-centric**, not agent-centric. Personas are the core abstraction, with AI personas (agents) being just one type. The system uses:

- **Unified Persona Model**: Human and AI personas share the same structure
- **Belief-Immersed Architecture**: Ego-centric planning with allocentric execution
- **HTN Planning**: Hierarchical task network with lazy refinement
- **Information Asymmetry**: Personas form beliefs through observation, not direct state access
- **Domain-Driven Design**: Extensible domain system with predicates, commands, tasks, and goals
- **ISO 8601 Temporal System**: All planning times use ISO 8601 strings (not integers)
- **Temporal Constraint Networks**: STN-based temporal constraint solving
- **Metadata System**: Structured planner metadata with entity requirements and temporal constraints

This architecture enables rich multi-persona interactions where each persona plans from their own perspective while executing in a shared reality.
