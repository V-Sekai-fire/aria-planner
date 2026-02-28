# Phase 1: Prototype

**Status:** Completed  
**Parent:** [JANET_MIGRATION_PROPOSAL.md](../proposals/JANET_MIGRATION_PROPOSAL.md)  
**Outcomes:** [PHASE1_GAPS.md](../../PHASE1_GAPS.md)

## Objective

Validate the Janet migration approach with a minimal runnable slice: planner core, a small interactivity subset, one end-to-end behavior graph, HDDL state round-trip, and glTF state/JSON load-save.

## Scope

### In scope

- Janet project layout: `project.janet`, `main.janet`, `source/aria/`
- **Planner core:** `state-new`, command registry, `command-dispatch`, trivial `c_noop`
- **Interactivity subset:** Operation mapping (`spec-to-command` / `command-to-spec`), predicates (GraphActive, SocketValue, NodeExecuted), `apply-binary-op`, commands: `c_activate_graph`, `c_math_add`, `c_flow_sequence`
- **E2E:** One behavior graph: activate graph → set socket values → run `math/add` → assert output and node executed
- **HDDL data transfer:** Parse/emit `:aria-initial-state` with `:facts`; round-trip; string fact values in emission
- **glTF:** Data-schema reference, `aria/gltf/state`, `aria/gltf/json` load/save, minimal JSON decoder (`aria/json_minimal.janet`) with no external deps; round-trip test

### Out of scope

- Full HDDL domain/problem parsing, `(:command ...)` emission, planning algorithms
- Full interactivity domain (remaining 160+ modules)
- GLB, mesh/accessor/buffer handling, KHR_interactivity graph loading
- Temporal (ISO 8601, STN), storage (ETS equivalent)

## Success criteria (met)

- [x] Planner runs; one E2E behavior graph passes
- [x] HDDL state round-trips for Phase 1 fact set
- [x] glTF state type and JSON load/save exist; data-schema documented
- [x] QuickCheck-style property tests for planner, interactivity, E2E, HDDL, glTF

## Deliverables

| Deliverable | Location |
|-------------|----------|
| Planner core | `source/aria/planner.janet` |
| Interactivity subset | `source/aria/domains/interactivity.janet` |
| HDDL parse/emit | `source/aria/hddl.janet` |
| glTF state + JSON | `source/aria/gltf/state.janet`, `source/aria/gltf/json.janet` |
| Minimal JSON | `source/aria/json_minimal.janet` |
| Tests | `test/test_planner.janet`, `test_interactivity.janet`, `test_e2e.janet`, `test_hddl.janet`, `test_gltf.janet` |
| Gaps and Phase 2 estimate | `janet/PHASE1_GAPS.md` |

## Dependencies

- Janet 1.x (e.g. 1.41.2)
- No external packages for Phase 1 (JSON implemented in-tree)

## Change log

- **2025-02:** Phase 1 completed; proposal added to `janet/docs/proposal/`.
