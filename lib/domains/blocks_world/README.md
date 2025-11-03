# Blocks World Planning Domain

A complete translation of the IPyHOP blocks world domain to Elixir/Beamserver MCP architecture, supporting both task-based and goal-based hierarchical planning.

## Overview

The blocks world is a classic planning problem where the goal is to stack blocks in a specific configuration. This implementation provides:

- **Predicate-based state management** - Each predicate (pos, clear, holding) has its own database table
- **Dual planning paradigms** - Both task-based and goal-based variants that can be mixed and matched
- **Helper functions as planner tasks** - Queryable functions for state analysis
- **Full Ecto integration** - Database persistence with migrations
- **MCP integration** - Remote planning capabilities through Model Context Protocol
- **Temporal reasoning** - Support for durative actions and temporal constraints

## Architecture

### Predicates

State is represented using three independent predicates:

- **pos[block]** - Position of a block: "table", "hand", or another block ID
- **clear[block]** - Boolean indicating if a block is clear (nothing on top)
- **holding[hand]** - What the hand is holding: block ID or "false"

### Modules

#### Core Schemas

- `Pos` - Position predicate schema
- `Clear` - Clear predicate schema
- `Holding` - Holding predicate schema

#### Planning Components

- `Helpers` - Helper tasks for state analysis
  - `is_done/2` - Check if block is in final position
  - `status/2` - Get block status (done, inaccessible, move-to-table, move-to-block, waiting)
  - `all_blocks/0` - Get all blocks in state
  - `find_if/2` - Find first matching element

- `Actions` - Primitive actions
  - `a_pickup/1` - Pick up block from table
  - `a_unstack/2` - Unstack block from another block
  - `a_putdown/1` - Put down block on table
  - `a_stack/2` - Stack block on another block

- `Methods` - Task-based decomposition
  - `move_blocks/1` - Recursive block stacking algorithm
  - `move_one/2` - Move single block to destination
  - `get/1` - Get block (pickup or unstack)
  - `put/2` - Put block (putdown or stack)

- `GoalMethods` - Goal-based decomposition
  - `move_blocks/1` - Multigoal method for goal-based planning
  - `gm_move1/2` - Goal method for moving block
  - `gm_get/2` - Goal method for getting block
  - `gm_put/2` - Goal method for putting block

#### Domain Management

- `BlocksWorld` (domain.ex) - Domain registration and state management
  - `create_domain/0` - Create and register domain
  - `initialize_state/1` - Initialize blocks world state
  - `get_state/0` - Get current state
  - `reset_state/0` - Clear all state facts

## Usage

### Initialize State

```elixir
# Create initial state with blocks a, b, c
{:ok, result} = AriaPlanner.Domains.BlocksWorld.initialize_state(["a", "b", "c"])
```

### Get Current State

```elixir
{:ok, state} = AriaPlanner.Domains.BlocksWorld.get_state()
# Returns: %{
#   pos: %{"a" => "table", "b" => "table", "c" => "table"},
#   clear: %{"a" => true, "b" => true, "c" => true},
#   holding: %{"hand" => "false"}
# }
```

### Execute Actions

```elixir
# Pick up block a
{:ok, result} = AriaPlanner.Domains.BlocksWorld.Actions.a_pickup("a")

# Stack a on b
{:ok, result} = AriaPlanner.Domains.BlocksWorld.Actions.a_stack("a", "b")
```

### Task-Based Planning

```elixir
# Get decomposition for move_blocks task
goal = %{"a" => "b", "b" => "table"}
subtasks = AriaPlanner.Domains.BlocksWorld.Methods.move_blocks(goal)
```

### Goal-Based Planning

```elixir
# Get decomposition for pos goal
goals = AriaPlanner.Domains.BlocksWorld.GoalMethods.gm_move1("a", "table")
```

## Database Schema

### blocks_world_pos

```sql
CREATE TABLE blocks_world_pos (
  id VARCHAR PRIMARY KEY,
  entity_id VARCHAR NOT NULL,
  value VARCHAR NOT NULL,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
CREATE INDEX ON blocks_world_pos(entity_id);
```

### blocks_world_clear

```sql
CREATE TABLE blocks_world_clear (
  id VARCHAR PRIMARY KEY,
  entity_id VARCHAR NOT NULL,
  value BOOLEAN NOT NULL,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
CREATE INDEX ON blocks_world_clear(entity_id);
```

### blocks_world_holding

```sql
CREATE TABLE blocks_world_holding (
  id VARCHAR PRIMARY KEY,
  entity_id VARCHAR NOT NULL,
  value VARCHAR,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
CREATE INDEX ON blocks_world_holding(entity_id);
```

## Testing

Run the test suite:

```bash
mix test apps/aria_planner/test/domains/blocks_world_test.exs
```

Tests cover:

- Domain creation and structure
- State initialization and management
- Helper function behavior
- Action precondition checking and effects
- Task-based method decomposition
- Goal-based method decomposition

## Implementation Notes

### Predicate-Based State

Unlike traditional EAV (Entity-Attribute-Value) patterns, each predicate has its own independent table. This provides:

- Better query performance
- Clearer schema semantics
- Type-safe value storage

### Helper Functions as Tasks

Helper functions (is_done, status, all_blocks, find_if) are implemented as queryable planner tasks rather than simple utilities. This allows them to be:

- Integrated into planning processes
- Tracked and logged
- Composed with other planner elements

### Dual Planning Paradigms

The domain supports both:

- **Task-based planning** - Decompose tasks into subtasks
- **Goal-based planning** - Decompose goals into subgoals

These can be mixed and matched in the same planning problem.

## Translation from IPyHOP

This implementation translates the IPyHOP blocks world domain:

- `blocks_world_actions.py` → `actions.ex`
- `blocks_world_methods_1.py` → `methods.ex` + `helpers.ex`
- `blocks_world_methods.py` → `goal_methods.ex`

Key differences:

- Elixir pattern matching replaces Python conditionals
- Database persistence replaces in-memory state
- Type specs provide compile-time safety
- Functional approach replaces imperative state mutation

## Future Enhancements

- Integration with MCP infrastructure for remote planning
- Probabilistic planning with success tracking
- Multi-agent blocks world variants
- Constraint-based planning extensions
