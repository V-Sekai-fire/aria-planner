# Phase 2: Interactivity Domain Parity (LFE)

**Status:** Proposed  
**Parent:** [LFE_MIGRATION_PROPOSAL.md](../../../docs/proposals/LFE_MIGRATION_PROPOSAL.md)  
**Depends on:** Phase 1

## Objective

Port or reimplement the full glTF KHR_interactivity domain in LFE so that all current interactivity operations and behavior-graph execution paths are reproducible with equivalent behavior to the Elixir implementation.

## Context

Phase 1 delivers a minimal subset: three commands (`c_activate_graph`, `c_math_add`, `c_flow_sequence`), operation mapping, and core predicates (GraphActive, SocketValue, NodeExecuted). The Elixir codebase has 160+ modules under `lib/domains/interactivity/` covering math, flow, pointer, animation, events, types, and support (operation_mapping, pointer_resolver, gltf_loader).

## Scope

### In scope

- **Enumeration:** Catalog all interactivity commands, predicates, and tasks from `lib/domains/interactivity` and the glTF Interactivity Extension spec
- **Operation mapping:** Full port; preserve spec operation ID ↔ command name so existing graphs resolve
- **Pointer resolution:** Port or reimplement pointer resolution so graph edges and socket references resolve correctly
- **glTF loader:** Port or call existing Elixir/Erlang glTF/JSON code; wire graph extraction (graphs, nodes, sockets) into planner state
- **Commands and predicates:** Port remaining operations in batches: math, flow, pointer, animation, events, types
- **Tests:** Test suite comparing LFE behavior to Elixir or spec; golden graph set

### Out of scope

- Changes to the glTF Interactivity Extension specification
- ML/Axon/Nx features (remain out of scope)
- Other Elixir domains

## Implementation plan

1. **Catalog:** List all commands/predicates/tasks with Elixir module and spec reference
2. **Operation mapping:** Extend `spec-to-command` / `command-to-spec` to full op set; add tests
3. **Pointer resolver:** Port pointer resolution; add tests with sample graphs
4. **glTF loader:** Implement or call from LFE; integrate with state and node execution
5. **Batch port:** For each batch (math, flow, pointer, animation, events, types), port commands and predicates, add tests
6. **Golden graphs:** Behavior graph JSON fixtures; run in Elixir and LFE and compare (or assert against spec)

## Success criteria

- All current interactivity operations available in LFE
- All graph execution paths exercised by tests; behavior equivalent to Elixir or spec
- Golden graph suite passes in LFE

## Effort (rough)

- glTF loader: small if reusing Elixir/Erlang; medium if porting
- Remaining commands and predicates: large (batch port with tests)

## References

- Elixir source: `lib/domains/interactivity/`
- glTF Interactivity: `lib/domains/interactivity/README.md`, `thirdparty/specification/`
