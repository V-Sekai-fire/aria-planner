# Interactivity Domain Conventions vs Game Engines

This document explains the naming conventions, architecture patterns, and design decisions used in the `lib/domains/interactivity/` implementation, comparing them to Unity, Three.js, Godot, and Unreal Engine.

## Overview

The aria-planner interactivity domain is based on the **glTF 2.0 KHR_interactivity extension specification**, which provides a standardized way to define interactive behavior graphs for 3D scenes. The implementation uses Elixir language conventions while maintaining compatibility with the glTF specification.

## Key Differences

| Aspect                 | aria-planner              | Unity                        | Three.js             | Godot               | Unreal Engine             |
| ---------------------- | ------------------------- | ---------------------------- | -------------------- | ------------------- | ------------------------- |
| **Language**           | Elixir                    | C#                           | JavaScript           | GDScript            | C++/Blueprints            |
| **Naming Convention**  | snake_case                | PascalCase                   | camelCase            | snake_case          | PascalCase                |
| **Base Specification** | glTF KHR_interactivity    | Unity Event System           | Custom/Proprietary   | Godot Signals/Nodes | Unreal Gameplay Framework |
| **Node System**        | glTF behavior graphs      | ScriptableObjects/Components | Three.js nodes       | Node tree           | Blueprint nodes           |
| **Data Storage**       | ETS (in-memory)           | GameObjects/Components       | JavaScript objects   | Resources           | UObjects                  |
| **Architecture**       | HTN planning + predicates | Component-based              | Object-oriented      | Scene tree          | Component-based           |
| **Type System**        | Dynamic (Elixir)          | Static (C#)                  | Dynamic (JavaScript) | Dynamic (GDScript)  | Static (C++)              |

## Naming Conventions

### Function Names

#### aria-planner (Elixir/Python Interop Style)

```elixir
# Command functions (c_ prefix)
def c_math_add(state, node_id, a_socket, value_socket)
def c_flow_sequence(state, node_id, flow_sockets)
def c_variable_set(state, node_id, variable_name, value_socket)

# Predicate functions
def get(state, node_id, socket_id)
def set(state, node_id, socket_id, value)
def active?(state)

# Task functions (t_ prefix)
def t_execute_graph(state, graph_id)
def t_initialize_variables(state, variables)
```

**Pattern**: `c_{category}_{operation}` for commands, snake_case throughout

#### Unity (C#)

```csharp
// Event handler pattern
public void OnMathAdd(float a, float b)
public void ExecuteNodeSequence(GameObject node)

// Component methods
public float AddValues(float a, float b)
public void SetVariable(string name, object value)
```

**Pattern**: PascalCase for methods, parameters camelCase

#### Three.js (JavaScript)

```javascript
// Method pattern
mathAdd(a, b)
executeNodeSequence(nodeId)
setVariable(name, value)

// Event handlers
.on('math:add', (a, b) => { ... })
```

**Pattern**: camelCase for methods, lowercase for events

#### Godot (GDScript)

```gdscript
# Method pattern
func math_add(a: float, b: float) -> float:
    return a + b

func execute_node_sequence(node: Node):
    pass

func set_variable(name: String, value):
    pass
```

**Pattern**: snake_case for methods (Python-like)

#### Unreal Engine (C++)

```cpp
// Function pattern
float UMathNode::AddValues(float A, float B) const
void UFlowNode::ExecuteNodeSequence(UNode* Node)
void UVariableManager::SetVariable(FName Name, const FVariant& Value)

// Event handlers
UFUNCTION(BlueprintCallable)
void OnMathAdd(float A, float B);
```

**Pattern**: PascalCase for functions, PascalCase for parameters (C++ style)

### Module/Class Names

#### aria-planner

```elixir
# Module hierarchy
AriaPlanner.Domains.Interactivity.Commands.MathAdd
AriaPlanner.Domains.Interactivity.Commands.FlowSequence
AriaPlanner.Domains.Interactivity.Predicates.SocketValue

# File structure
lib/domains/interactivity/commands/math_add.ex
lib/domains/interactivity/commands/flow_sequence.ex
lib/domains/interactivity/predicates/socket_value.ex
```

**Pattern**: PascalCase for modules, underscore-separated paths

#### Unity

```csharp
// Namespace hierarchy
namespace AriaPlanner.Interactivity.Commands
{
    public class MathAdd : MonoBehaviour { }
}

// File structure
Assets/Scripts/Interactivity/Commands/MathAdd.cs
Assets/Scripts/Interactivity/Commands/FlowSequence.cs
```

**Pattern**: PascalCase for classes, PascalCase for namespaces

#### Three.js

```javascript
// Module pattern
class MathAdd {
  constructor() {}
  add(a, b) {
    return a + b;
  }
}

// File structure
src / interactivity / commands / MathAdd.js;
src / interactivity / commands / FlowSequence.js;
```

**Pattern**: PascalCase for classes, camelCase for file names (JavaScript)

#### Godot

```gdscript
# Script pattern
extends Node
class_name MathAdd

func add(a, b):
    return a + b

# File structure
res://interactivity/commands/math_add.gd
res://interactivity/commands/flow_sequence.gd
```

**Pattern**: snake_case for file names, PascalCase for class_name

#### Unreal Engine

```cpp
// C++ class pattern
UCLASS()
class ARIAINTERACTIVITY_API UMathAdd : public UActorComponent
{
    GENERATED_BODY()
};

// File structure
Source/Interactivity/Commands/MathAdd.h
Source/Interactivity/Commands/MathAdd.cpp
```

**Pattern**: PascalCase for classes, PascalCase for file names

### Operation Names (Node Types)

#### aria-planner (glTF Spec Compliant)

```elixir
# Math operations (snake_case, category/operation)
"math/add"
"math/subtract"
"math/multiply"
"math/divide"
"math/abs"
"math/sign"

# Flow control operations
"flow/sequence"
"flow/branch"
"flow/multiGate"
"flow/switch"
"flow/while"
"flow/for"

# Type conversion operations
"type/boolToFloat"
"type/floatToInt"
"type/intToFloat"
```

**Pattern**: `category/operation`, snake_case, glTF spec compliant

#### Unity

```csharp
// Unity typically uses PascalCase for operations
"Math.Add"
"Math.Subtract"
"Math.Multiply"
"Math.Divide"
"Math.Abs"
"Math.Sign"

"Flow.Sequence"
"Flow.Branch"
"Flow.MultiGate"
"Flow.Switch"
"Flow.While"
"Flow.For"
```

**Pattern**: `Category.Operation`, PascalCase

#### Three.js

```javascript
// Three.js uses camelCase for operations
"math/add";
"math/subtract";
"math/multiply";
"math/divide";
"math/abs";
"math/sign";

"flow/sequence";
"flow/branch";
"flow/multiGate";
"flow/switch";
"flow/while";
"flow/for";
```

**Pattern**: `category/operation`, camelCase

#### Godot

```gdscript
# Godot uses snake_case for operations
"math_add"
"math_subtract"
"math_multiply"
"math_divide"
"math_abs"
"math_sign"

"flow_sequence"
"flow_branch"
"flow_multi_gate"
"flow_switch"
"flow_while"
"flow_for"
```

**Pattern**: `category_operation`, snake_case (no slash separator)

#### Unreal Engine

```cpp
// Unreal uses PascalCase with no slash separator
"Math.Add"
"Math.Subtract"
"Math.Multiply"
"Math.Divide"
"Math.Abs"
"Math.Sign"

"Flow.Sequence"
"Flow.Branch"
"Flow.MultiGate"
"Flow.Switch"
"Flow.While"
"Flow.For"
```

**Pattern**: `Category.Operation`, PascalCase, dot separator

### Data Structure Names

#### aria-planner

```elixir
# Predicates (state facts)
%NodeExecuted{node_id: "node_1", timestamp: "2025-01-01T10:00:00Z"}
%SocketValue{node_id: "node_1", socket_id: "a", value: 5.0}
%VariableValue{variable_name: "counter", value: 10}

# Commands (actions)
{:ok, state} = Commands.MathAdd.c_math_add(state, "node_1", "a", "b", "value")

# Tasks (high-level operations)
{:ok, state} = Tasks.ExecuteGraph.t_execute_graph(state, "graph_1")
```

**Pattern**: PascalCase structs, snake_case field names

#### Unity

```csharp
// Component pattern
public class NodeExecuted : MonoBehaviour
{
    public string nodeId;
    public DateTime timestamp;
}

public class SocketValue : MonoBehaviour
{
    public string nodeId;
    public string socketId;
    public object value;
}
```

**Pattern**: PascalCase classes, camelCase properties

#### Three.js

```javascript
// Object pattern
class NodeExecuted {
  constructor(nodeId, timestamp) {
    this.nodeId = nodeId;
    this.timestamp = timestamp;
  }
}

class SocketValue {
  constructor(nodeId, socketId, value) {
    this.nodeId = nodeId;
    this.socketId = socketId;
    this.value = value;
  }
}
```

**Pattern**: PascalCase classes, camelCase properties

#### Godot

```gdscript
# Resource/Node pattern
class_name NodeExecuted extends Resource

@export var node_id: String
@export var timestamp: int

class_name SocketValue extends Resource

@export var node_id: String
@export var socket_id: String
@export var value: Variant
```

**Pattern**: PascalCase class_name, snake_case properties

#### Unreal Engine

```cpp
// UObject pattern
USTRUCT(BlueprintType)
struct FNodeExecuted
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FString NodeId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FDateTime Timestamp;
};

USTRUCT(BlueprintType)
struct FSocketValue
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FString NodeId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FString SocketId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FVariant Value;
};
```

**Pattern**: `F` prefix for structs, PascalCase properties

## Architecture Patterns

### Command Pattern Implementation

#### aria-planner (Functional Style)

```elixir
# Command module structure
defmodule AriaPlanner.Domains.Interactivity.Commands.MathAdd do
  @doc """
  Executes math/add operation with component-wise support for floatN types.
  Returns {:ok, state} or {:error, reason}.
  """
  def c_math_add(state, node_id, a_socket, value_socket) do
    alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers

    with {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
         :ok <- MathHelpers.check_graph_active(state) do
      result = MathHelpers.apply_binary_op(a, b, &+/2)
      new_state = SocketValue.set(state, node_id, value_socket, result)
      {:ok, NodeExecuted.set(new_state, node_id, DateTime.utc_now())}
    end
  end
end
```

**Characteristics**:

- Pure functional (immutable state)
- Pattern matching for error handling
- Module organization by operation
- Helper functions for common operations

#### Unity (Object-Oriented)

```csharp
// Command component pattern
public class MathAdd : MonoBehaviour
{
    public string NodeId;
    public string ASocket;
    public string BSocket;
    public string ValueSocket;

    public void Execute()
    {
        if (!Graph.Active)
        {
            Debug.LogError("Graph must be active to execute operations");
            return;
        }

        float a = SocketValue.Get(NodeId, ASocket);
        float b = SocketValue.Get(NodeId, BSocket);
        float result = a + b;

        SocketValue.Set(NodeId, ValueSocket, result);
        NodeExecuted.Set(NodeId, DateTime.UtcNow);
    }
}
```

**Characteristics**:

- Object-oriented (mutable state)
- Exception-based error handling
- Component-based organization
- Direct state modification

#### Three.js (Functional/Object Hybrid)

```javascript
// Command class pattern
class MathAdd {
  constructor(nodeId, aSocket, bSocket, valueSocket) {
    this.nodeId = nodeId;
    this.aSocket = aSocket;
    this.bSocket = bSocket;
    this.valueSocket = valueSocket;
  }

  execute(state) {
    if (!state.graphActive) {
      throw new Error("Graph must be active to execute operations");
    }

    const a = SocketValue.get(state, this.nodeId, this.aSocket);
    const b = SocketValue.get(state, this.nodeId, this.bSocket);
    const result = a + b;

    const newState = SocketValue.set(
      state,
      this.nodeId,
      this.valueSocket,
      result,
    );
    return NodeExecuted.set(newState, this.nodeId, Date.now());
  }
}
```

**Characteristics**:

- Class-based (object-oriented)
- Error throwing for failures
- Prototype-based inheritance
- Immutable state pattern (functional style)

#### Godot (Object-Oriented)

```gdscript
# Node script pattern
extends Node
class_name MathAdd

@export var node_id: String
@export var a_socket: String
@export var b_socket: String
@export var value_socket: String

func execute() -> Dictionary:
    if not GraphActive.is_active():
        push_error("Graph must be active to execute operations")
        return {}

    var a = SocketValue.get(node_id, a_socket)
    var b = SocketValue.get(node_id, b_socket)
    var result = a + b

    SocketValue.set(node_id, value_socket, result)
    NodeExecuted.set(node_id, Time.get_unix_time_from_system())
    return {}
```

**Characteristics**:

- Node-based (scene tree)
- Error pushing for failures
- Signal-based communication
- Direct state modification

#### Unreal Engine (Object-Oriented)

```cpp
// Actor component pattern
UCLASS()
class ARIAINTERACTIVITY_API UMathAdd : public UActorComponent
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FString NodeId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FString ASocket;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FString BSocket;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FString ValueSocket;

    UFUNCTION(BlueprintCallable)
    void Execute()
    {
        if (!UGraphActive::IsActive())
        {
            UE_LOG(LogInteractivity, Error, TEXT("Graph must be active to execute operations"));
            return;
        }

        float A = USocketValue::Get(NodeId, ASocket);
        float B = USocketValue::Get(NodeId, BSocket);
        float Result = A + B;

        USocketValue::Set(NodeId, ValueSocket, Result);
        UNodeExecuted::Set(NodeId, FDateTime::UtcNow());
    }
};
```

**Characteristics**:

- Component-based (UObject)
- Blueprint callable functions
- Logging for error handling
- Reflection system (UPROPERTY)

### Predicate System

#### aria-planner (ETS-Based State Facts)

```elixir
# Predicate as ETS record
defmodule AriaPlanner.Domains.Interactivity.Predicates.SocketValue do
  @behaviour AriaCore.Predicate

  defstruct [:node_id, :socket_id, :value]

  def set(state, node_id, socket_id, value) do
    EtsStorage.insert(:socket_values, {node_id, socket_id}, %SocketValue{
      node_id: node_id,
      socket_id: socket_id,
      value: value
    })
    state
  end

  def get(state, node_id, socket_id) do
    case EtsStorage.get(:socket_values, {node_id, socket_id}) do
      {:ok, %SocketValue{value: value}} -> value
      :error -> nil
    end
  end
end
```

**Pattern**: ETS-based storage, functional API

#### Unity (Component-Based)

```csharp
// Singleton manager pattern
public class SocketValue : MonoBehaviour
{
    private static Dictionary<(string, string), object> values = new Dictionary<(string, string), object>();

    public static void Set(string nodeId, string socketId, object value)
    {
        values[(nodeId, socketId)] = value;
    }

    public static object Get(string nodeId, string socketId)
    {
        return values.TryGetValue((nodeId, socketId), out var value) ? value : null;
    }
}
```

**Pattern**: Static dictionary manager

#### Three.js (Map-Based)

```javascript
// Module pattern
const socketValueMap = new Map();

class SocketValue {
  static set(nodeId, socketId, value) {
    const key = `${nodeId}:${socketId}`;
    socketValueMap.set(key, value);
  }

  static get(nodeId, socketId) {
    const key = `${nodeId}:${socketId}`;
    return socketValueMap.get(key) || null;
  }
}
```

**Pattern**: Map-based storage with string keys

#### Godot (Node-Based Storage)

```gdscript
# Resource-based storage
extends Resource
class_name SocketValue

var values: Dictionary = {}

func set(node_id: String, socket_id: String, value):
    var key = "%s:%s" % [node_id, socket_id]
    values[key] = value

func get(node_id: String, socket_id: String):
    var key = "%s:%s" % [node_id, socket_id]
    return values.get(key, null)
```

**Pattern**: Dictionary in Resource

#### Unreal Engine (TMap-Based)

```cpp
// UObject-based manager
UCLASS()
class ARIAINTERACTIVITY_API USocketValue : public UObject
{
    GENERATED_BODY()

private:
    TMap<FStringPair, FVariant> Values;

public:
    UFUNCTION(BlueprintCallable)
    void Set(const FString& NodeId, const FString& SocketId, const FVariant& Value)
    {
        Values.Add(FStringPair(NodeId, SocketId), Value);
    }

    UFUNCTION(BlueprintCallable)
    FVariant Get(const FString& NodeId, const FString& SocketId) const
    {
        const FVariant* Value = Values.Find(FStringPair(NodeId, SocketId));
        return Value ? *Value : FVariant();
    }
};
```

**Pattern**: TMap-based storage with FStringPair key

## Type System

### Type Handling

#### aria-planner (Dynamic with Guards)

```elixir
# Dynamic typing with pattern matching guards
def c_math_add(state, node_id, a_socket, b_socket, value_socket) do
  with {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
       {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket) do
    # Component-wise operations support floatN, int
    result = MathHelpers.apply_binary_op(a, b, &+/2)
    {:ok, SocketValue.set(state, node_id, value_socket, result)}
  end
end

# Type conversion helpers
def apply_binary_op(a, b, op) when is_number(a) and is_number(b), do: op.(a, b)
def apply_binary_op({a1, a2}, {b1, b2}, op), do: {op.(a1, b1), op.(a2, b2)}
def apply_binary_op({a1, a2, a3}, {b1, b2, b3}, op), do: {op.(a1, b1), op.(a2, b2), op.(a3, b3)}
```

**Pattern**: Dynamic typing with pattern matching guards, runtime type checking

#### Unity (Static with Generics)

```csharp
// Static typing with generics
public class MathAdd
{
    public static T Add<T>(T a, T b)
    {
        if (typeof(T) == typeof(float) || typeof(T) == typeof(double))
        {
            return (T)(object)(Convert.ToDouble(a) + Convert.ToDouble(b));
        }
        else if (typeof(T) == typeof(int))
        {
            return (T)(object)(Convert.ToInt32(a) + Convert.ToInt32(b));
        }
        throw new NotSupportedException($"Type {typeof(T)} not supported");
    }
}
```

**Pattern**: Static typing with generics, compile-time type checking

#### Three.js (Dynamic)

```javascript
// Dynamic typing
function add(a, b) {
  if (typeof a === "number" && typeof b === "number") {
    return a + b;
  } else if (Array.isArray(a) && Array.isArray(b)) {
    return a.map((val, i) => val + b[i]);
  }
  throw new Error(`Unsupported types: ${typeof a}, ${typeof b}`);
}
```

**Pattern**: Dynamic typing with runtime type checking

#### Godot (Dynamic with Type Hints)

```gdscript
# Dynamic typing with type hints
func add(a, b) -> Variant:
    if typeof(a) == TYPE_FLOAT and typeof(b) == TYPE_FLOAT:
        return a + b
    elif typeof(a) == TYPE_INT and typeof(b) == TYPE_INT:
        return a + b
    elif a is Array and b is Array:
        var result = []
        for i in range(a.size()):
            result.append(a[i] + b[i])
        return result
    push_error("Unsupported types")
    return null
```

**Pattern**: Dynamic typing with type hints, runtime type checking

#### Unreal Engine (Static with Templates)

```cpp
// Static typing with templates
template<typename T>
T UMathNode::Add(T A, T B)
{
    static_assert(TIsFloat<T>::Value || TIsIntegral<T>::Value,
        "Type must be float or integral type");
    return A + B;
}

// Specialization for vectors
FVector UMathNode::AddVector(FVector A, FVector B)
{
    return A + B;
}
```

**Pattern**: Static typing with templates, compile-time type checking

## Special Considerations

### glTF Specification Compliance

#### aria-planner (Strict Spec Compliance)

The aria-planner interactivity domain strictly follows the glTF 2.0 KHR_interactivity extension specification:

```elixir
# Quaternion operations use glTF {x, y, z, w} order
def c_math_quat_mul(state, node_id, a_socket, b_socket, value_socket) do
  # glTF spec: quatMul formula with {x, y, z, w} component order
  result = MathHelpers.quat_mul_op(a, b)
  {:ok, SocketValue.set(state, node_id, value_socket, result)}
end

# Matrix operations use glTF column-major order
def c_math_mat_mul(state, node_id, a_socket, b_socket, value_socket) do
  # glTF spec: column-major order [c0r0, c0r1, c1r0, c1r1]
  result = MathHelpers.mat_mul_op(a, b)
  {:ok, SocketValue.set(state, node_id, value_socket, result)}
end

# Operations with isValid outputs per spec
def c_math_inverse(state, node_id, matrix_socket, value_socket, is_valid_socket) do
  # glTF spec: returns {matrix, isValid}
  {matrix, is_valid} = MathHelpers.inverse_op(matrix)
  state = SocketValue.set(state, node_id, value_socket, matrix)
  state = SocketValue.set(state, node_id, is_valid_socket, is_valid)
  {:ok, state}
end
```

**Key glTF conventions**:

- Quaternion component order: `{x, y, z, w}` (not Unity's `{x, y, z, w}` with different mathematical interpretation)
- Matrix storage: Column-major `[c0r0, c0r1, c1r0, c1r1]` (not Unity's row-major)
- Component-wise operations: Explicit support for `floatN` types
- isValid outputs: Boolean validity flags for operations that can fail

#### Unity (Different Conventions)

Unity uses different conventions:

```csharp
// Unity uses quaternion with {x, y, z, w} but different mathematical interpretation
public static Quaternion Multiply(Quaternion a, Quaternion b)
{
    // Unity's quaternion multiplication follows a different convention
    return new Quaternion(
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
        a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
    );
}

// Unity uses row-major matrices
public static Matrix4x4 Multiply(Matrix4x4 a, Matrix4x4 b)
{
    // Row-major matrix multiplication
    return a * b;
}
```

**Differences**:

- Quaternion multiplication formula differs from glTF
- Matrix storage is row-major (not column-major)
- No isValid outputs (exceptions used instead)

#### Three.js (Mixed Conventions)

Three.js attempts to follow WebGL conventions (similar to glTF):

```javascript
// Three.js quaternion uses {x, y, z, w}
function multiplyQuaternions(a, b) {
  const result = new THREE.Quaternion();
  result.copy(a).multiply(b);
  return result;
}

// Three.js matrices are column-major (WebGL convention)
function multiplyMatrices(a, b) {
  const result = new THREE.Matrix4();
  result.multiplyMatrices(a, b);
  return result;
}
```

**Similarities**:

- Quaternion order matches glTF `{x, y, z, w}`
- Matrix storage is column-major (WebGL convention)
- No explicit isValid outputs

#### Godot (Different Conventions)

Godot uses its own conventions:

```gdscript
# Godot quaternion uses Basis for rotation
func quat_multiply(a: Quaternion, b: Quaternion) -> Quaternion:
    # Godot's quaternion multiplication
    return a * b

# Godot uses column-major matrices (Basis)
func mat_multiply(a: Basis, b: Basis) -> Basis:
    return a * b
```

**Differences**:

- Uses Basis class for 3D transforms (not raw quaternions/matrices)
- Matrix storage is column-major (matches glTF)
- No isValid outputs (error pushing instead)

#### Unreal Engine (Different Conventions)

Unreal uses different conventions:

```cpp
// Unreal uses FQuat with {x, y, z, w}
static FQuat Multiply(const FQuat& A, const FQuat& B)
{
    // Unreal's quaternion multiplication
    return B * A; // Note the reverse order
}

// Unreal uses row-major matrices (FMatrix)
static FMatrix Multiply(const FMatrix& A, const FMatrix& B)
{
    // Row-major matrix multiplication
    return A * B;
}
```

**Differences**:

- Quaternion multiplication order is reversed (B _ A instead of A _ B)
- Matrix storage is row-major (not column-major)
- Uses FMatrix (not glTF's flat array representation)

## Summary Table

| Convention Type      | aria-planner          | Unity                  | Three.js            | Godot                  | Unreal                |
| -------------------- | --------------------- | ---------------------- | ------------------- | ---------------------- | --------------------- |
| **Function Names**   | `c_math_add`          | `MathAdd()`            | `mathAdd()`         | `math_add()`           | `AddValues()`         |
| **Module Names**     | `MathAdd`             | `MathAdd`              | `MathAdd`           | `MathAdd` (class)      | `UMathAdd`            |
| **Operation IDs**    | `"math/add"`          | `"Math.Add"`           | `"math/add"`        | `"math_add"`           | `"Math.Add"`          |
| **Predicates**       | `%SocketValue{}`      | `SocketValue`          | `SocketValue` class | `SocketValue` resource | `FSocketValue` struct |
| **State Storage**    | ETS                   | Static Dictionary      | Map                 | Dictionary in Resource | TMap                  |
| **Error Handling**   | Pattern matching      | Exceptions             | Error throwing      | `push_error()`         | `UE_LOG()`            |
| **Quaternion Order** | `{x, y, z, w}` (glTF) | `{x, y, z, w}` (Unity) | `{x, y, z, w}`      | `{x, y, z, w}`         | `{x, y, z, w}`        |
| **Matrix Order**     | Column-major          | Row-major              | Column-major        | Column-major           | Row-major             |
| **isValid Outputs**  | `{value, isValid}`    | Exceptions             | Errors              | `push_error()`         | `return false`        |
| **Type System**      | Dynamic               | Static (C#)            | Dynamic (JS)        | Dynamic (GDScript)     | Static (C++)          |
| **Component-wise**   | Explicit support      | Manual                 | Manual              | Manual                 | Manual                |

## Migration Guide

### Converting from Unity

**Unity → aria-planner**:

```csharp
// Unity
public class MathAdd : MonoBehaviour
{
    public void Execute()
    {
        float result = a + b;
        SocketValue.Set(NodeId, ValueSocket, result);
    }
}
```

```elixir
# aria-planner
defmodule AriaPlanner.Domains.Interactivity.Commands.MathAdd do
  def c_math_add(state, node_id, a_socket, b_socket, value_socket) do
    result = MathHelpers.apply_binary_op(a, b, &+/2)
    {:ok, SocketValue.set(state, node_id, value_socket, result)}
  end
end
```

**Key changes**:

- `Execute()` → `c_math_add/4`
- Instance fields → function parameters
- Direct state modification → functional state updates
- Exceptions → `{:ok, state}` / `{:error, reason}` tuples

### Converting from Three.js

**Three.js → aria-planner**:

```javascript
// Three.js
class MathAdd {
  execute(state) {
    const result = this.a + this.b;
    return SocketValue.set(state, this.valueSocket, result);
  }
}
```

```elixir
# aria-planner
defmodule AriaPlanner.Domains.Interactivity.Commands.MathAdd do
  def c_math_add(state, node_id, a_socket, b_socket, value_socket) do
    result = MathHelpers.apply_binary_op(a, b, &+/2)
    {:ok, SocketValue.set(state, node_id, value_socket, result)}
  end
end
```

**Key changes**:

- Class methods → module functions
- `this.a` → parameters (`a_socket`)
- `return state` → `{:ok, state}` tuple
- Error throwing → pattern matching

### Converting from Godot

**Godot → aria-planner**:

```gdscript
# Godot
func math_add(a, b) -> float:
    return a + b
```

```elixir
# aria-planner
defmodule AriaPlanner.Domains.Interactivity.Commands.MathAdd do
  def c_math_add(state, node_id, a_socket, b_socket, value_socket) do
    result = MathHelpers.apply_binary_op(a, b, &+/2)
    {:ok, SocketValue.set(state, node_id, value_socket, result)}
  end
end
```

**Key changes**:

- `func` → `def`
- Snake_case already matches
- Direct returns → tuple returns
- Error pushing → error tuples

### Converting from Unreal

**Unreal → aria-planner**:

```cpp
// Unreal
UFUNCTION(BlueprintCallable)
void UMathAdd::Execute(float A, float B, float& Result)
{
    Result = A + B;
}
```

```elixir
# aria-planner
defmodule AriaPlanner.Domains.Interactivity.Commands.MathAdd do
  def c_math_add(state, node_id, a_socket, b_socket, value_socket) do
    result = MathHelpers.apply_binary_op(a, b, &+/2)
    {:ok, SocketValue.set(state, node_id, value_socket, result)}
  end
end
```

**Key changes**:

- `UFUNCTION()` → `@spec` documentation
- Pass-by-reference → tuple returns
- `FString` → Elixir strings
- Static methods → module functions

## Conclusion

The aria-planner interactivity domain follows a **unique hybrid approach**:

1. **Elixir Language Conventions**: snake_case function names, module organization, functional programming
2. **glTF Specification Compliance**: Operation IDs, quaternion order, matrix order, isValid outputs
3. **Planning Architecture**: HTN planning with predicates, commands, and tasks
4. **In-Memory Storage**: ETS for fast, temporary state storage (no database)

This differs from game engines in several key ways:

- **Unity**: Object-oriented, component-based, C# naming, row-major matrices
- **Three.js**: Object-oriented, JavaScript naming, column-major matrices (WebGL)
- **Godot**: Node-based, Python-like naming, column-major matrices
- **Unreal**: Object-oriented, C++ naming, row-major matrices, reflection system

The aria-planner approach prioritizes **specification compliance** and **functional programming** over game engine conventions, while still providing a complete implementation of glTF interactivity behavior graphs.
