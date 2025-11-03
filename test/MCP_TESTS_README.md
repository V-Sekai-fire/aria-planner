# Aria Planner MCP Integration Tests

This directory contains comprehensive MCP (Model Context Protocol) integration tests for the aria_planner application. The tests are organized into focused modules following module size guidelines (max 500 lines per file).

## Test Modules

### 1. `mcp_plan_creation_test.exs` (~170 lines)

Tests plan creation workflows via MCP tools.

**Coverage:**

- Basic plan creation
- Plans with success probability
- Lazy execution (deferred execution with `run_lazy` flag)
- Multi-objective plans
- Resource URI creation and tracking
- Lazy vs eager plan execution status
- Multi-persona planning scenarios

**Key Tests:**

- `creates a basic plan` - Verifies basic plan creation
- `creates plan with run_lazy flag` - Tests deferred execution
- `plan resource URI is created` - Validates resource tracking
- `creates plans for multiple personas` - Multi-persona workflows

### 2. `mcp_backtracking_test.exs` (~240 lines)

Tests plan backtracking and recovery mechanisms.

**Coverage:**

- Backtracking when initial plan fails
- Lazy execution with retry mechanisms
- Execution state updates during backtracking
- Multi-persona backtracking scenarios
- Lazy execution alternatives (pending → pending → planned)
- State restoration and history preservation

**Key Tests:**

- `backtrack when initial plan fails` - Tests alternative plan creation
- `backtrack with lazy execution and retry` - Deferred execution recovery
- `backtrack with multi-persona planning` - Cross-persona backtracking
- `backtrack with state restoration` - History preservation

### 3. `mcp_domain_operations_test.exs` (~380 lines)

Tests domain creation, element management, and queries.

**Coverage:**

- Domain task operations (list, filter)
- Domain action operations
- Domain entity operations (with/without capabilities)
- Domain multigoal operations
- Domain command operations
- Planning domain creation
- Domain element addition (tasks, actions, commands)
- Domain element listing and filtering
- Complete planning workflows

**Key Tests:**

- `lists domain tasks` - Query domain tasks
- `creates a planning domain` - Domain initialization
- `adds a task to domain` - Element management
- `element resource URI is created` - Resource tracking
- `workflow: create domain, add elements, create plan` - Full workflow

## Test Structure

Each test module follows this pattern:

```elixir
defmodule AriaPlanner.MCP<Feature>Test do
  use ExUnit.Case, async: false
  alias MCP.AriaForge.ToolHandlers

  setup do
    {:ok, %{
      state: %{
        prompt_uses: 0,
        created_resources: %{},
        subscriptions: []
      }
    }}
  end

  describe "Feature group" do
    test "specific behavior", %{state: state} do
      # Test implementation
    end
  end
end
```

## Running Tests

Run all MCP tests:

```bash
mix test apps/aria_planner/test/mcp_*_test.exs
```

Run specific test module:

```bash
mix test apps/aria_planner/test/mcp_plan_creation_test.exs
```

Run specific test:

```bash
mix test apps/aria_planner/test/mcp_plan_creation_test.exs --only "creates a basic plan"
```

## Key Features Tested

### Plan Creation

- Basic plan creation with required fields
- Success probability configuration
- Multiple objectives support
- Lazy execution (deferred) vs eager execution
- Resource URI generation and tracking

### Backtracking

- Alternative plan creation on failure
- Retry mechanisms with improved success probability
- State restoration and history preservation
- Multi-persona backtracking scenarios
- Execution state updates during recovery

### Domain Operations

- Domain creation with/without entities
- Task, action, command, and multigoal queries
- Entity capability filtering
- Domain element addition and listing
- Resource URI creation for domain elements

### Execution State

- Weather updates
- Time advancement
- Player management
- State transitions

## Response Format

MCP tool responses follow this format:

```elixir
{:ok, result, new_state}
```

Where `result` contains:

```elixir
%{
  content: [
    %{
      "type" => "text",
      "text" => "{...json...}"
    }
  ]
}
```

Access response data:

```elixir
[content] = result.content
response_data = Jason.decode!(content["text"])
```

## State Management

Tests track MCP state through:

- `prompt_uses` - Counter of tool invocations
- `created_resources` - Map of created resource URIs to data
- `subscriptions` - List of active subscriptions

## Module Size Compliance

Following module size guidelines:

- `mcp_plan_creation_test.exs`: ~170 lines (soft threshold: 200-300)
- `mcp_backtracking_test.exs`: ~240 lines (soft threshold: 200-300)
- `mcp_domain_operations_test.exs`: ~380 lines (firm threshold: 400-500)

Total: ~790 lines split across 3 focused modules (vs. 1100+ line monolith)

## Future Enhancements

- Add execution state management tests
- Add resource lifecycle tests
- Add error handling tests
- Add integration workflow tests
- Performance benchmarking
