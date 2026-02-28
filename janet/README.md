# aria-planner (Janet) — Primary migration target

Janet is the **primary** migration target for the planner: embeddable in Godot (GDExtension or subprocess), callable from Elixir via NIF, single codebase. See [LFE_VS_JANET_GODOT_EVALUATION.md](../docs/proposals/LFE_VS_JANET_GODOT_EVALUATION.md).

Minimal Janet reimplementation of aria-planner core and a small subset of the glTF Interactivity domain, per [docs/proposals/JANET_MIGRATION_PROPOSAL.md](../docs/proposals/JANET_MIGRATION_PROPOSAL.md).

## Phase 1 scope

- **Planner core:** State table, command dispatch, one trivial command.
- **Interactivity subset:** Operation mapping (`spec-to-command`), predicates (GraphActive, SocketValue, NodeExecuted), math helper (`apply-binary-op`), and commands: `c_activate_graph`, `c_math_add`, `c_flow_sequence`.
- **Success:** One end-to-end behavior graph: activate graph → set socket values → run `math/add` → assert output and node executed.
- **glTF:** Data-schema reference ([docs/gltf_godot_data_schema.md](../docs/gltf_godot_data_schema.md)), state type, minimal JSON load/save (extensions preserved).

## Requirements

- [Janet](https://janet-lang.org/) 1.x (e.g. 1.41.2).

## Run tests

From this directory (`janet/`):

```bash
jpm test
```

Or run the E2E test explicitly:

```bash
janet test/test_e2e.janet
```

## Layout

- `aria/planner.janet` — State, command registry, dispatch.
- `aria/domains/interactivity.janet` — Predicates, operation mapping, math helper, commands (activate_graph, math_add, flow_sequence).
- `source/aria/gltf/` — glTF state and JSON load/save; `source/aria/json_minimal.janet` — minimal JSON decode/encode (no external deps).
- `test/` — Unit tests, E2E test, HDDL round-trip, glTF round-trip.

## After Phase 1

See [PHASE1_GAPS.md](PHASE1_GAPS.md) for missing pieces and effort estimate for Phase 2.
