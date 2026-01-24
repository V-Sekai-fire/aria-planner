# Interactivity Domain

Full planning domain implementation for glTF 2.0 Interactivity Extension behavior graphs.

## Overview

This domain provides a complete planning system for reasoning about glTF KHR_interactivity behavior graphs. It includes:

- **Full domain implementation** with predicates, commands, and tasks
- **PDDL/HDDL interoperability** for converting between behavior graphs and planning domains
- **Node operation support** for math operations, flow control, and graph execution

## Domain Components

### Predicates

State predicates for tracking behavior graph execution:

- **`NodeExecuted`** - Tracks which nodes have been executed
- **`SocketConnected`** - Tracks socket connections between nodes
- **`SocketValue`** - Stores values in value sockets (input/output)
- **`VariableValue`** - Manages custom variables with type-specific defaults
- **`EventTriggered`** - Tracks custom event triggers
- **`GraphActive`** - Indicates whether the behavior graph is active

### Commands

Executable commands for behavior graph operations:

- **`c_activate_graph`** - Activates a behavior graph
- **`c_execute_node`** - Executes a node with its operation
- **`c_math_add`** - Executes math/add operation (component-wise for floatN types)
- **`c_flow_sequence`** - Executes flow/sequence operation (activates flows in order)
- **`c_connect_socket`** - Connects sockets between nodes
- **`c_set_variable`** - Sets custom variable values

### Tasks

High-level task decomposition:

- **`t_execute_graph`** - Executes a complete behavior graph
- **`t_activate_graph`** - Activates graph and initializes variables
- **`t_execute_node_sequence`** - Executes nodes in topological order
- **`t_initialize_variables`** - Initializes custom variables

## Usage

### Creating the Domain

```elixir
alias AriaPlanner.Domains.Interactivity

{:ok, domain} = Interactivity.create_domain()
```

### Executing a Behavior Graph

```elixir
# Initialize state
state = %{
  graph_active: false
}

# Activate graph
{:ok, state} = Interactivity.Commands.ActivateGraph.c_activate_graph(state, "graph_1")

# Execute nodes
{:ok, state} = Interactivity.Commands.ExecuteNode.c_execute_node(state, "node_1", "math/add")
```

### Math Operations

```elixir
# Set input socket values
state = Interactivity.Predicates.SocketValue.set(state, "node_1", "a", 5.0)
state = Interactivity.Predicates.SocketValue.set(state, "node_1", "b", 3.0)

# Execute math/add
{:ok, state} = Interactivity.Commands.MathAdd.c_math_add(
  state,
  "node_1",
  "a",
  "b",
  "value"
)

# Get result
result = Interactivity.Predicates.SocketValue.get(state, "node_1", "value")
# => 8.0
```

## PDDL Interoperability

The `PddlInterop` module provides bidirectional conversion between glTF behavior graphs and HDDL planning domains.

### Conversion Mapping

- **Behavior Graph** → **Planning Domain** (HDDL)
- **Nodes** → **Actions/Commands** (with preconditions and effects)
- **Flow Sockets** → **Task Decomposition** (methods)
- **Value Sockets** → **Predicates** (state facts)
- **Custom Variables** → **State Variables** (predicates)
- **Custom Events** → **Event Triggers** (predicates/actions)
- **Node Operations** → **Action Names** (domain/operation pattern)

### Example Usage

```elixir
alias AriaPlanner.Domains.Interactivity.PddlInterop

# Convert glTF behavior graph to HDDL
graph = %{
  "nodes" => [
    %{
      "id" => "node_1",
      "operation" => "math/add",
      "inputs" => %{"a" => 1.0, "b" => 2.0},
      "outputs" => %{"value" => "result"}
    }
  ],
  "variables" => [],
  "events" => [],
  "declarations" => []
}

{:ok, hddl_string} = PddlInterop.graph_to_hddl(graph, domain_name: "math_example")
IO.puts(hddl_string)

# Convert HDDL back to glTF behavior graph
{:ok, graph_json} = PddlInterop.hddl_to_graph(hddl_string)
```

## Domain Structure

```
lib/domains/interactivity/
├── domain.ex                    # Main domain module
├── pddl_interop.ex             # PDDL/HDDL interoperability converter
├── predicates/
│   ├── node_executed.ex        # Node execution tracking
│   ├── socket_connected.ex     # Socket connection tracking
│   ├── socket_value.ex          # Value socket storage
│   ├── variable_value.ex       # Custom variable management
│   ├── event_triggered.ex       # Event trigger tracking
│   └── graph_active.ex          # Graph activation state
├── commands/
│   ├── activate_graph.ex        # Graph activation command
│   ├── execute_node.ex          # Node execution command
│   ├── math_add.ex              # Math/add operation
│   ├── flow_sequence.ex         # Flow/sequence operation
│   ├── connect_socket.ex        # Socket connection command
│   └── set_variable.ex          # Variable setting command
└── tasks/
    ├── execute_graph.ex         # Graph execution task
    ├── activate_graph.ex        # Graph activation task
    ├── execute_node_sequence.ex # Node sequence execution task
    └── initialize_variables.ex  # Variable initialization task
```

## Status

**Complete** - Full domain implementation with predicates, commands, tasks, and PDDL interoperability.
