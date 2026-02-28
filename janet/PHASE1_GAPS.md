# Phase 1 Gaps — After Phase 1 Prototype

Summary of what Phase 1 delivered and what remains for Phase 2+.

## Phase 1 Delivered

- **Janet project:** `project.janet`, `main.janet`, source layout under `source/aria/`.
- **Planner core:** `state-new`, command registry, `command-dispatch`, trivial `c_noop`.
- **Interactivity subset:** Operation mapping (`spec-to-command` / `command-to-spec`), predicates (GraphActive, SocketValue, NodeExecuted), `apply-binary-op`, commands `c_activate_graph`, `c_math_add`, `c_flow_sequence`.
- **E2E:** One behavior graph: activate → set sockets → `math/add` → assert output and node executed.
- **HDDL data transfer:** Parse/emit `:aria-initial-state` with `:facts`; round-trip test; string fact values in emission (Phase 1).
- **glTF:** Data-schema reference (`docs/gltf_godot_data_schema.md`), `aria/gltf/state`, `aria/gltf/json` load/save, minimal JSON decoder (`aria/json_minimal.janet`) with no external deps; round-trip test (state with `:json` and optional `:nodes`).

## Gaps / Not in Phase 1

- **Full HDDL:** Only `:aria-initial-state` `:facts`; no full problem/domain parsing, no `(:command ...)` emission, no planning algorithms.
- **Full interactivity domain:** Only three commands and a small predicate set; no pointer resolution, animation, events, types, or remaining 160+ modules.
- **glTF:** No GLB, no mesh/accessor/buffer handling, no KHR_interactivity graph loading; minimal JSON only.
- **Temporal:** No ISO 8601, STN, or planner temporal metadata in Janet.
- **Storage:** No ETS equivalent; in-memory tables only.

## Phase 2 Effort (Rough)

- HDDL full parse/emit and command definitions: small–medium.
- glTF GLB + mesh/graph loading: medium (depends on Godot contract).
- Remaining interactivity commands and predicates: large (batch port with tests).
- Temporal and storage: medium each.

## Success Criteria Met

- Planner runs; one E2E behavior graph passes.
- HDDL state round-trips for Phase 1 fact set.
- glTF state type and JSON load/save exist; data-schema documented.
