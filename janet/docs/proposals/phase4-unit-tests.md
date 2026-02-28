# Phase 4: Restore unit tests

**Status:** Proposed  
**Parent:** [README.md](README.md) (proposals overview)  
**Depends on:** Phase 1 (completed); Phases 2 and 3 as needed for coverage

## Objective

Restore and maintain unit tests for the Janet planner and interactivity code so that behavior is well covered and regressions are caught. Align test style (e.g. property/QuickCheck-style where used) and ensure the test suite runs reliably.

## Context

Phase 1 introduced QuickCheck-style property tests and focused tests for planner, interactivity, E2E, HDDL, and glTF. As Phases 2 and 3 add more code, unit tests must be restored or added so that new and existing behavior is covered. This phase makes test restoration and coverage an explicit checkpoint before deprecation/coexistence (Phase 5).

## Scope

### In scope

- **Restore unit tests:** Identify any missing or broken unit tests from the Elixir test suite or Phase 1 Janet tests; port or re-add them in Janet.
- **Coverage:** Ensure planner core, interactivity commands/predicates, HDDL round-trip, and glTF load/save have direct unit tests (and property tests where appropriate).
- **Test harness:** Keep or extend the existing Janet test runner and property helpers (`test/property.janet`, `jpm test`); ensure tests run in CI or locally without flake.
- **Documentation:** Document how to run tests and what each test file covers.

### Out of scope

- Full golden-graph suite (covered in Phase 2); temporal/STN tests (Phase 3)
- Changing Phase 1 test style unless necessary for consistency

## Implementation plan

1. Audit current Janet tests: list `test/*.janet` and what each covers; note gaps vs. Elixir or spec.
2. Restore or add unit tests for any missing paths (e.g. edge cases in commands, HDDL parse/emit, glTF fields).
3. Fix any failing or skipped tests; ensure `jpm test` (or equivalent) passes.
4. Add a short “Testing” section to `janet/README.md` if not already present.

## Success criteria

- All existing Janet unit and property tests pass.
- Gaps from audit addressed with new or restored unit tests.
- Test run is documented and repeatable.

## Effort (rough)

- Small–medium (audit + restore/add tests + docs).

## References

- Overview: [README.md](README.md)
- Phase 1 tests: `janet/test/`, [phase1-prototype.md](phase1-prototype.md)
- Phase 3: [phase3-core-planner-parity.md](phase3-core-planner-parity.md)
