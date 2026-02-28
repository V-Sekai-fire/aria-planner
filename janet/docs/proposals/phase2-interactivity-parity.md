# Phase 2: Interactivity Domain Parity

**Status:** Proposed  
**Parent:** [README.md](README.md) (proposals overview)  
**Depends on:** Phase 1 (completed)

## Objective

Port or reimplement the full glTF KHR_interactivity domain in Janet so that all current interactivity operations and behavior-graph execution paths are reproducible with equivalent behavior to the Elixir implementation.

## Context

Phase 1 delivered a minimal subset: three commands (`c_activate_graph`, `c_math_add`, `c_flow_sequence`), operation mapping, and core predicates (GraphActive, SocketValue, NodeExecuted). The Elixir codebase has 160+ modules under `lib/domains/interactivity/` covering math, flow, pointer, animation, events, types, and support (operation_mapping, pointer_resolver, gltf_loader).

## Scope

### In scope

- **Enumeration:** Catalog all interactivity commands, predicates, and tasks from `lib/domains/interactivity` and the glTF Interactivity Extension spec
- **Operation mapping:** Full port or regeneration; preserve spec operation ID ↔ command name so existing graphs resolve
- **Pointer resolution:** Port or reimplement pointer resolution so graph edges and socket references resolve correctly
- **glTF loader:** Port or reimplement glTF loader (or FFI to existing parser); wire graph extraction (graphs, nodes, sockets) into planner state
- **Commands and predicates:** Port remaining operations in batches:
  - Math (beyond add: subtract, multiply, etc.)
  - Flow (beyond sequence: branch, switch, etc.)
  - Pointer (get, set, resolve)
  - Animation (play, blend, etc.)
  - Events (emit, listen, etc.)
  - Types (cast, validate, etc.)
- **Tests:** Test suite (e.g. Janet tests + QuickCheck-style properties) comparing against Elixir behavior or spec; golden graph set

### Out of scope

- Changes to the glTF Interactivity Extension specification
- ML/Axon/Nx features (remain out of scope per main proposal)
- Other Elixir domains (blocks_world, etc.)

## Implementation plan

1. **Catalog:** Produce a list of all commands/predicates/tasks with Elixir module and spec reference
2. **Operation mapping:** Extend `spec-to-command` / `command-to-spec` to cover full op set; add tests
3. **Pointer resolver:** Port pointer resolution logic; add tests with sample graphs
4. **glTF loader:** Implement or FFI graph extraction; integrate with state and node execution
5. **Batch port:** For each batch (math, flow, pointer, animation, events, types), port commands and predicates, add property/golden tests
6. **Golden graphs:** Maintain a set of behavior graph JSON fixtures; run in both Elixir and Janet and compare outputs (or assert against spec)

## Success criteria

- All current interactivity operations available in Janet
- All graph execution paths exercised by tests; behavior equivalent to Elixir or spec
- Golden graph suite passes in Janet
- Operation mapping and pointer resolution documented and tested

## Effort (rough)

- HDDL full parse/emit and command definitions: small–medium (if done in Phase 2)
- glTF GLB + mesh/graph loading: medium (depends on Godot contract)
- Remaining interactivity commands and predicates: large (batch port with tests)

## Risks

| Risk | Mitigation |
|------|------------|
| Large surface (160+ modules) | Batch by category; automated tests and golden graphs |
| Semantics drift (floats, NaNs, edge cases) | Reuse spec and EDGE_CASES docs; Janet tests mirror Elixir/spec |
| glTF loader complexity | Start with JSON-only; GLB optional or FFI to C library |

## References

- Elixir source: `lib/domains/interactivity/`
- glTF Interactivity: `lib/domains/interactivity/README.md`, `thirdparty/specification/`
- Phase 1 gaps: `janet/PHASE1_GAPS.md`
