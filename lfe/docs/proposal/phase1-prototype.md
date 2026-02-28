# Phase 1: Prototype (LFE)

**Status:** Proposed  
**Parent:** [LFE_MIGRATION_PROPOSAL.md](../../../docs/proposals/LFE_MIGRATION_PROPOSAL.md)

## Objective

Validate the LFE migration approach with a minimal runnable slice: LFE project setup, planner core (state, command registry, dispatch), a small interactivity subset, one end-to-end behavior graph, HDDL state round-trip, and glTF state/JSON load-save.

## Scope

### In scope

- **LFE project:** rebar3 with LFE plugin (or Mix + LFE); source layout under `src/` with LFE modules
- **Planner core:** State (map), command registry, `command-dispatch`, trivial `c_noop`
- **Interactivity subset:** Operation mapping (`spec-to-command` / `command-to-spec`), predicates (GraphActive, SocketValue, NodeExecuted), `apply-binary-op`, commands: `c_activate_graph`, `c_math_add`, `c_flow_sequence`
- **E2E:** One behavior graph: activate graph → set socket values → run `math/add` → assert output and node executed
- **HDDL data transfer:** Parse/emit `:aria-initial-state` with `:facts`; round-trip; string fact values in emission
- **glTF:** Data-schema reference; state type and JSON load/save (reuse Jason from Erlang/Elixir or port minimal parser in LFE)

### Out of scope

- Full HDDL domain/problem parsing, `(:command ...)` emission, planning algorithms
- Full interactivity domain (remaining 160+ modules)
- GLB, mesh/accessor/buffer handling, KHR_interactivity graph loading
- Temporal (ISO 8601, STN) in LFE in this phase

## Success criteria

- [ ] LFE project builds and runs
- [ ] Planner runs; one E2E behavior graph passes
- [ ] HDDL state round-trips for Phase 1 fact set
- [ ] glTF state type and JSON load/save exist; data-schema documented
- [ ] Tests (e.g. EUnit or LFE test framework) for planner, interactivity, E2E, HDDL, glTF

## Deliverables

| Deliverable | Location (example) |
|-------------|--------------------|
| LFE project config | `rebar.config`, `src/` |
| Planner core | `src/aria_planner.lfe` (or equivalent) |
| Interactivity subset | `src/aria_domains_interactivity.lfe` |
| HDDL parse/emit | `src/aria_hddl.lfe` |
| glTF state + JSON | `src/aria_gltf_*.lfe` or call to Elixir |
| Tests | `test/` |

## Dependencies

- Erlang/OTP (current version used by Mix)
- LFE (rebar3 plugin or standalone)
- Optionally: call existing Elixir modules (e.g. Jason) from LFE during Phase 1

## Change log

- **2026-02:** Phase 1 proposal added for LFE migration.
