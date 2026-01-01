# HDDL Domain Tests

Separate test files for each HDDL domain to ensure proper parsing and structure validation.

## Test Files

Each domain has its own test file in `test/hddl/domains/`:

1. **aircraft_disassembly_test.exs** - Tests for aircraft disassembly domain
2. **cable_tree_wiring_test.exs** - Tests for cable tree wiring domain
3. **fox_geese_corn_test.exs** - Tests for fox-geese-corn domain
4. **graph_clear_test.exs** - Tests for graph clear domain
5. **hoist_benchmark_test.exs** - Tests for hoist benchmark domain
6. **neighbours_test.exs** - Tests for neighbours domain
7. **portal_test.exs** - Tests for portal domain
8. **tiny_cvrp_test.exs** - Tests for tiny CVRP domain
9. **train_scheduling_test.exs** - Tests for train scheduling domain
10. **yumi_dynamic_test.exs** - Tests for yumi dynamic domain

## Test Structure

Each test file includes:

### Domain Parsing Tests

- Verifies domain file parses correctly
- Validates domain structure (name, type, elements)
- Checks required elements are present

### Problem Parsing Tests

- Verifies all problem files for the domain parse correctly
- Validates problem structure
- Ensures problems reference the correct domain

## Running Tests

Run all domain tests:

```bash
mix test test/hddl/domains/
```

Run tests for a specific domain:

```bash
mix test test/hddl/domains/aircraft_disassembly_test.exs
```

## Status

✅ All 38 tests passing
✅ All 10 domains have dedicated test files
✅ Domain and problem parsing verified for all domains
