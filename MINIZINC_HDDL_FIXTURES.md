# MiniZinc to HDDL Fixtures

This document summarizes the HDDL domain and problem fixtures generated from MiniZinc problems.

## Generated Files

### Domain Files

All domain files are located in `test/fixtures/hddl/domains/`:

- `aircraft_disassembly.hddl` - Aircraft disassembly scheduling domain
- `cable_tree_wiring.hddl` - Cable tree wiring domain
- `fox_geese_corn.hddl` - Fox-geese-corn river crossing domain (stub - full domain exists in `lib/domains/fox_geese_corn/`)
- `hoist_benchmark.hddl` - Cyclic hoist scheduling domain
- `neighbours.hddl` - Neighbours grid assignment domain (stub - full domain exists in `lib/domains/neighbours/`)
- `portal.hddl` - Portal puzzle domain
- `tiny_cvrp.hddl` - Capacitated Vehicle Routing Problem domain (stub - full domain exists in `lib/domains/tiny_cvrp/`)
- `train_scheduling.hddl` - Train scheduling domain
- `yumi_dynamic.hddl` - Yumi dynamic planning domain

### Problem Files

Problem files are located in `test/fixtures/hddl/` with the naming pattern:
`{domain_name}_problem_{minizinc_file_name}.hddl`

Each problem file contains:

- Problem definition referencing the domain
- `:aria-plan` section with plan metadata
- `:aria-initial-state` section with facts extracted from MiniZinc `.dzn` files
- `:aria-blacklist` section (empty, for failure handling)

## Generation Script

The fixtures are generated using `scripts/create_minizinc_hddl_fixtures.exs`.

To regenerate all fixtures:

```bash
mix run scripts/create_minizinc_hddl_fixtures.exs
```

## Status

✅ **All generated files parse successfully** - Verified with `AriaPlanner.HDDL.Parser`

⚠️ **Note**: Most domain files are stubs with basic structure. Full implementation requires:

- Proper predicates based on MiniZinc model
- Actions and commands for state transitions
- Methods for task decomposition
- Integration with existing domain implementations where available

## Next Steps

1. Implement full domain logic for each problem type
2. Create solver integration for each domain
3. Verify solutions match MiniZinc results
4. Add comprehensive tests for each domain/problem combination
