# Edge Cases and Error Handling

This document describes edge cases and error handling behavior for the Interactivity domain operations, following the glTF Interactivity Extension specification.

## Overview

The glTF Interactivity Extension specification defines how operations handle special values (NaN, infinity) and error conditions. This implementation follows those rules to ensure spec compliance.

## Special Values

### NaN (Not a Number)

**Propagation Rules:**
- NaN values propagate through arithmetic operations
- Any operation involving NaN typically produces NaN
- Comparison operations with NaN return `false` (NaN != NaN)
- `math/isNaN` operation correctly identifies NaN values

**Examples:**
- `math/add(NaN, 5.0)` → NaN
- `math/mul(NaN, 2.0)` → NaN
- `math/eq(NaN, NaN)` → false
- `math/isNaN(NaN)` → true

**Implementation Notes:**
- Elixir's `:math` module operations handle NaN propagation automatically
- Custom operations use `is_nan_op/1` helper to detect NaN
- NaN detection: `a != a` (NaN is not equal to itself)

### Infinity

**Propagation Rules:**
- Infinity values propagate through arithmetic operations according to standard math rules
- `math/isInf` operation identifies infinity values
- Division by zero produces infinity (or NaN in some cases)

**Examples:**
- `math/div(1.0, 0.0)` → Infinity (or error on some platforms)
- `math/mul(Infinity, 2.0)` → Infinity
- `math/add(Infinity, -Infinity)` → NaN

**Implementation Notes:**
- Elixir's `:math` module handles infinity in arithmetic operations
- `is_inf_op/1` helper checks for infinity using division by zero test
- Platform-dependent: Some platforms may raise errors instead of producing infinity

## Division by Zero

**Behavior:**
- Division by zero typically produces infinity or NaN
- Integer division by zero may raise an error
- The glTF spec allows NaN/infinity propagation

**Examples:**
- `math/div(10.0, 0.0)` → Infinity (or error)
- `math/div(0.0, 0.0)` → NaN (or error)
- `math/div(10, 0)` → Error (integer division)

**Implementation:**
- Float division uses `/` operator (may produce infinity or error)
- Integer division uses `div/2` (raises error on division by zero)
- Operations propagate errors or special values as per Elixir behavior

## Matrix Operations

### Singular Matrices (Determinant = 0)

**Behavior:**
- `math/inverse` returns `{zero_matrix, false}` when determinant is zero
- `math/determinant` returns 0.0 for singular matrices
- `math/matDecompose` returns invalid result when matrix is singular

**Examples:**
- Singular 2x2 matrix: `{1.0, 2.0, 2.0, 4.0}` (determinant = 0)
- `math/inverse(singular_matrix)` → `{{0.0, 0.0, 0.0, 0.0}, false}`
- `math/determinant(singular_matrix)` → 0.0

**Implementation:**
- `inverse_op/1` checks determinant before computing inverse
- Returns zero matrix and `isValid = false` for singular matrices
- Per glTF spec requirement

### Matrix Format Conversion

**Column-Major vs Row-Major:**
- glTF uses column-major storage: `{c0r0, c0r1, c1r0, c1r1}` for 2x2
- `aria_math` uses row-major Nx tensors
- Conversion helpers handle format translation automatically

**Edge Cases:**
- Non-square matrices: Not supported (only 2x2, 3x3, 4x4)
- Mismatched dimensions in multiplication: Returns error
- Invalid matrix sizes: Operations validate tuple size

## Quaternion Operations

### Non-Unit Quaternions

**Behavior:**
- `math/rotate3D` assumes unit quaternions (per spec warning)
- Non-unit quaternions produce incorrect rotation results
- Operations do not normalize quaternions automatically

**Examples:**
- Unit quaternion: `{0.0, 0.0, 0.0, 1.0}` (length = 1.0)
- Non-unit quaternion: `{1.0, 1.0, 1.0, 1.0}` (length ≠ 1.0)
- `math/rotate3D` with non-unit quaternion: Incorrect rotation

**Implementation:**
- Quaternion operations use values as-is
- No automatic normalization (per spec)
- Users should normalize quaternions before rotation if needed

### Invalid Quaternion Values

**Behavior:**
- Operations handle quaternions with NaN or infinity components
- Results propagate NaN/infinity as per arithmetic rules

## Vector Operations

### Zero Vectors

**Behavior:**
- `math/length` of zero vector: 0.0
- `math/normalize` of zero vector: Returns `{{0.0, 0.0, 0.0}, false}` (invalid)
- `math/dot` with zero vector: 0.0

**Examples:**
- `math/length({0.0, 0.0, 0.0})` → 0.0
- `math/normalize({0.0, 0.0, 0.0})` → `{{0.0, 0.0, 0.0}, false}`
- `math/dot({0.0, 0.0, 0.0}, {1.0, 2.0, 3.0})` → 0.0

**Implementation:**
- `normalize_op/1` checks length before normalization
- Returns zero vector and `isValid = false` for zero-length vectors
- Per glTF spec requirement

## Type Conversion

### Float to Integer

**Behavior:**
- Truncates fractional part (not rounds)
- Large floats may overflow integer range
- NaN/infinity conversion: Undefined behavior

**Examples:**
- `type/floatToInt(3.7)` → 3
- `type/floatToInt(3.2)` → 3
- `type/floatToInt(-3.7)` → -3

### Integer to Float

**Behavior:**
- Exact conversion (no precision loss for small integers)
- Large integers may lose precision in float representation

**Examples:**
- `type/intToFloat(42)` → 42.0
- `type/intToFloat(-5)` → -5.0

### Boolean Conversion

**Behavior:**
- Non-zero → true, zero → false
- `type/boolToFloat(true)` → 1.0
- `type/boolToFloat(false)` → 0.0
- `type/boolToInt(true)` → 1
- `type/boolToInt(false)` → 0

## Overflow and Underflow

**Behavior:**
- Operations use Elixir's native number types
- Integer overflow wraps (Elixir uses arbitrary precision)
- Float overflow produces infinity
- Float underflow produces subnormal numbers or zero

**Examples:**
- Large integer multiplication: Handled by arbitrary precision
- `math/pow(2.0, 1000.0)` → May produce infinity
- `math/exp(1000.0)` → Infinity

## Error Handling

### Precondition Failures

**Graph Not Active:**
- All operations require active graph
- Returns `{:error, "Graph must be active to execute operations"}`

**Missing Socket Values:**
- Operations require input socket values
- Returns `{:error, "Socket <name> on node <id> has no value"}`

### Type Mismatches

**Behavior:**
- Operations validate input types where applicable
- Incompatible types may produce errors or unexpected results
- Component-wise operations require matching tuple sizes

**Examples:**
- `math/add({1.0, 2.0}, {3.0})` → Error (size mismatch)
- `math/add(5.0, {1.0, 2.0})` → May work or error depending on operation

## Implementation-Specific Notes

### Elixir Platform Limitations

**NaN/Infinity Creation:**
- Elixir's `:math` module may raise errors for invalid operations
- `sqrt(-1.0)` raises `ArithmeticError` instead of producing NaN
- `1.0 / 0.0` raises `ArithmeticError` instead of producing infinity
- Tests use finite values to avoid platform-specific issues

**Integer Division:**
- Elixir's `div/2` raises error on division by zero
- `rem/2` also raises error on division by zero
- Float division `/` may raise error or produce infinity depending on platform

### aria_math Integration

**Tensor Conversion:**
- Matrix operations convert between tuple and Nx tensor formats
- Conversion preserves values but changes storage format
- 4x4 matrices use `aria_math` for optimized operations

**Quaternion Operations:**
- Some operations use `aria_math` directly (conjugate, multiply, etc.)
- `rotate3D` uses custom implementation due to Axon tensor requirements
- All operations maintain glTF `{x, y, z, w}` quaternion order

## Testing Edge Cases

Edge cases are tested where possible, but some platform limitations prevent testing:
- NaN creation: Elixir doesn't easily create NaN values
- Infinity creation: Elixir doesn't easily create infinity values
- Tests use finite values and verify operations handle them correctly
- Error conditions are tested (missing sockets, inactive graph, etc.)

## References

- glTF Interactivity Extension Specification: `thirdparty/specification/02_node_types.md`
- Elixir `:math` module documentation
- `aria_math` library documentation
