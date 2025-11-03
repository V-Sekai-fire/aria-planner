# Elixir Test Infrastructure Improvement Workflow

## Important Guidelines

### Umbrella Project Management

**🚫 NEVER run mix commands in individual app directories**

Running commands like:

- `cd apps/aria_planner && mix deps.get`
- `cd apps/aria_planner && mix compile`
- `cd apps/aria_planner && mix test`

**will break the umbrella structure** and cause dependency conflicts, compilation errors, and inconsistent builds.

**✅ Always run mix commands from the project root:**

Instead of the above, use:

- `mix deps.get` (from project root)
- `mix compile` (from project root)
- `mix test` (from project root) or specify with `--only aria_planner`

This maintains the umbrella project's integrity and ensures all apps work together properly.

## Quick Start

**For teams needing immediate test improvements:**

1. Run `mix test` to identify current issues
2. Create `test/fixtures/` with golden standard data
3. Replace `IO.inspect/2` with proper ExUnit assertions
4. Use fixtures instead of hardcoded test data

## Overview

This workflow provides a systematic approach to improving test infrastructure in Elixir projects by replacing debug logging with proper fixture-based tests and ensuring mathematical operations work correctly.

## Common Issues in Elixir Test Suites

### High Priority Issues

1. **Debug Logging in Tests**: Tests using `IO.inspect/2` or similar for assertions instead of proper test assertions
2. **Hardcoded Test Data**: Tests with inline data that makes maintenance difficult
3. **Missing Fixtures**: Lack of golden standard test data for complex operations

### Medium Priority Issues

4. **Compiler Warnings**: Unused aliases, parameters, or variables causing warnings
5. **Mathematical Bugs**: Incorrect implementations of mathematical operations (matrices, vectors, etc.)

## Core Workflow Steps

### Phase 1: Assessment (1-2 hours)

**Goal**: Understand current test health and identify improvement opportunities

- **Run Diagnostics**: Execute `mix test` and `mix compile --warnings-as-errors=no`
- **Analyze Patterns**: Look for debug logging, hardcoded data, and missing fixtures
- **Review Coverage**: Identify critical paths lacking test coverage

### Phase 2: Infrastructure Setup (2-4 hours)

**Goal**: Establish foundation for reliable testing

- **Create Fixtures**: Set up `test/fixtures/` directories with golden standard data
- **Update Test Helpers**: Configure automatic fixture loading in `test/test_helper.exs`
- **Fix Code Quality**: Address compiler warnings and unused code

### Phase 3: Test Refactoring (4-8 hours)

**Goal**: Transform unreliable tests into maintainable, deterministic tests

- **Replace Debug Logging**: Convert `IO.inspect/2` calls to proper ExUnit assertions
- **Implement Fixtures**: Replace hardcoded data with fixture references
- **Add Proper Equality**: Use domain-specific equality checks for complex types

### Phase 4: Verification (1-2 hours)

**Goal**: Ensure improvements work and document for future maintenance

- **Run Full Suite**: Verify all tests pass with no warnings
- **Document Patterns**: Create guidelines for future test development
- **Establish Maintenance**: Set up processes for fixture updates and test reviews

## Example Implementation

### Fixture Structure

```elixir
# test/fixtures/math_fixtures.exs
defmodule MathFixtures do
  def matrix_operations do
    %{
      identity: Matrix4.identity(),
      translation: Matrix4.translation({1.0, 2.0, 3.0}),
      rotation: Matrix4.rotation(Quaternion.from_axis_angle({0, 0, 1}, :math.pi/2)),
      scale: Matrix4.scaling({2.0, 3.0, 4.0}),
      # Expected results for operations
      inverse_translation: Matrix4.translation({-1.0, -2.0, -3.0}),
      compose_result: Matrix4.translation({3.0, 6.0, 9.0})
    }
  end
end
```

### Test Helper Setup

```elixir
# test/test_helper.exs
Code.require_file("fixtures/math_fixtures.exs", __DIR__)

ExUnit.start()
```

### Test Implementation

```elixir
# test/math_test.exs
defmodule MathTest do
  use ExUnit.Case

  test "matrix inverse of translation" do
    fixtures = MathFixtures.matrix_operations()
    result = Matrix4.inverse(fixtures.translation)
    assert Matrix4.equal?(result, fixtures.inverse_translation)
  end
end
```

## Key Improvements

1. **Deterministic Testing**: Golden standard fixtures ensure consistent, reproducible tests
2. **Mathematical Correctness**: Comprehensive verification of complex operations
3. **Maintainability**: Centralized fixture data makes updates easy
4. **Code Quality**: Clean code with no compiler warnings
5. **Documentation**: Clear patterns for future test development

## Elixir Testing Standards

### Test Output Philosophy

**Elixir testing standards emphasize quiet passing tests with informative failures:**

- **Passing Tests**: Should be silent or minimally verbose
- **Failing Tests**: Should provide detailed, actionable error information
- **Performance Tests**: Should be separated from unit tests
- **CI/CD**: Output should be scannable for actual issues

### Test Output Best Practices

#### Quiet Passing Tests

```elixir
# ❌ Verbose passing test (not recommended)
test "matrix multiplication" do
  Logger.debug("Starting matrix multiplication test")
  result = Matrix.multiply(a, b)
  Logger.info("Result: #{inspect(result)}")
  assert Matrix.equal?(result, expected)
end

# ✅ Quiet passing test (recommended)
test "matrix multiplication" do
  result = Matrix.multiply(a, b)
  assert Matrix.equal?(result, expected)
end
```

#### Informative Failing Tests

```elixir
# ✅ Good failure output
test "matrix inverse fails with singular matrix" do
  singular_matrix = Matrix4.zero()

  assert_raise ArgumentError, "Matrix is singular and cannot be inverted", fn ->
    Matrix4.inverse(singular_matrix)
  end
end
```

#### Configurable Verbosity

```elixir
# Use environment variables for optional verbose output
test "performance benchmark" do
  result = perform_operation()

  if System.get_env("BENCHMARK_VERBOSE") do
    Logger.info("Benchmark result: #{inspect(result)}")
  end

  assert result.valid?
end
```

### Separating Benchmarks from Unit Tests

```elixir
# test/performance_benchmark_test.exs (separate file)
defmodule PerformanceBenchmarkTest do
  use ExUnit.Case

  @tag :benchmark
  test "matrix multiplication performance" do
    # Performance tests in separate file with benchmark tag
    {time, result} = :timer.tc(fn -> Matrix.multiply(large_matrix_a, large_matrix_b) end)

    Logger.info("Matrix multiplication took #{time} microseconds")
    assert Matrix.equal?(result, expected)
  end
end

# Run only benchmarks when needed
# mix test --only benchmark
```

### CI/CD Considerations

```elixir
# test/test_helper.exs
# Configure test output for CI environments
if System.get_env("CI") do
  ExUnit.configure(
    formatters: [ExUnit.CLIFormatter],
    trace: false,
    colors: [enabled: false]
  )
else
  ExUnit.configure(
    formatters: [ExUnit.CLIFormatter],
    trace: true,
    colors: [enabled: true]
  )
end
```

## Best Practices

### Fixture Design

- Keep fixtures minimal but comprehensive
- Use descriptive names for test data
- Include expected results alongside input data
- Structure fixtures as maps for easy access

### Test Organization

- Group related tests in descriptive modules
- Use clear, descriptive test names
- Include comments explaining complex test scenarios
- Run tests frequently during development

### Maintenance

- Update fixtures when adding new test cases
- Review fixture data periodically for relevance
- Use version control to track fixture changes
- Document fixture structure for team members

## Common Elixir Testing Patterns

### For Phoenix Applications

- Use `Phoenix.ConnTest` fixtures for API testing
- Create database fixtures with `ExMachina` or similar
- Test context functions with proper setup

### For Mathematical Libraries

- Verify numerical precision and stability
- Test edge cases (zero, infinity, NaN)
- Include round-trip operation tests
- Use property-based testing with `StreamData`

### For Complex Data Structures

- Test serialization/deserialization
- Verify immutability properties
- Test concurrent access patterns
- Include performance benchmarks

## Testing Strategies and Mocking

### Understanding Test Categories

Following Martin Fowler's analysis of testing pyramids, it's important to distinguish between different types of tests:

- **Solitary Unit Tests**: Test a single unit in isolation using mocks/stubs for dependencies
- **Sociable Unit Tests**: Test a unit with its real dependencies (integration within the unit)
- **Integration Tests**: Test how units work together
- **System Tests**: Test the entire system end-to-end

The key insight is that "unit test" can mean different things - focus on writing tests that establish clear boundaries, run quickly, and fail for useful reasons.

### Using Mox for Mocking

Mox is Elixir's premier mocking library that provides compile-time contract verification. Here's how to use it effectively:

#### Setup

```elixir
# mix.exs
defp deps do
  [
    {:mox, "~> 1.2", only: :test}
  ]
end

# config/test.exs
config :my_app, MyApp.SomeBehaviour,
  adapter: MyApp.SomeBehaviourMock
```

#### Define Behaviors

```elixir
# lib/my_app/some_behaviour.ex
defmodule MyApp.SomeBehaviour do
  @callback process_data(data :: map()) :: {:ok, result} | {:error, reason}
end
```

#### Create Mocks

```elixir
# test/test_helper.exs
Mox.defmock(MyApp.SomeBehaviourMock, for: MyApp.SomeBehaviour)
ExUnit.start()
```

#### Write Tests with Mocks

```elixir
# test/some_service_test.exs
defmodule MyApp.SomeServiceTest do
  use ExUnit.Case
  import Mox

  setup :verify_on_exit!

  test "processes data successfully" do
    # Arrange
    expect(MyApp.SomeBehaviourMock, :process_data, fn %{id: 123} ->
      {:ok, %{processed: true}}
    end)

    # Act
    result = MyApp.SomeService.process(%{id: 123})

    # Assert
    assert {:ok, %{processed: true}} = result
  end
end
```

#### Best Practices for Mox

- **Use sparingly**: Prefer sociable tests when possible
- **Verify contracts**: Let Mox ensure your mocks match behavior interfaces
- **Global mode**: Use `setup :verify_on_exit!` to ensure all expectations are met
- **Stub vs Mock**: Use `expect/3` for mocks, `stub/3` for stubs
- **Multiple calls**: Use `expect/4` with call count for repeated calls

### When to Use Mocks vs Real Dependencies

- **Use Mocks When**:
  - External services (HTTP APIs, databases in unit tests)
  - Slow operations (file I/O, network calls)
  - Non-deterministic behavior (randomness, time)
  - Complex setup requirements

- **Use Real Dependencies When**:
  - Pure functions
  - Simple data transformations
  - Fast, deterministic operations
  - Well-tested collaborator code

## Tools and Libraries

- **ExUnit**: Built-in Elixir testing framework
- **Mox**: Compile-time verified mocking
- **StreamData**: Property-based testing
- **ExMachina**: Test data factories
- **Bypass**: HTTP client testing for integration tests

This workflow can be adapted to any Elixir project requiring improved test infrastructure and mathematical operation verification.
