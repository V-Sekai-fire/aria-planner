# aria-planner (Janet) — Primary migration target

Janet is the migration target for the planner: embeddable in Godot (GDExtension or subprocess), callable from Elixir via NIF, single codebase. See [LFE_VS_JANET_GODOT_EVALUATION.md](../docs/proposals/LFE_VS_JANET_GODOT_EVALUATION.md).

Minimal Janet reimplementation of aria-planner core and a small subset of the glTF Interactivity domain. Migration overview and phases: [docs/proposals/README.md](docs/proposals/README.md).

## Phase 1 scope

- **Planner core:** State table, command dispatch, one trivial command.
- **Interactivity subset:** Operation mapping (`spec-to-command`), predicates (GraphActive, SocketValue, NodeExecuted), math helper (`apply-binary-op`), and commands: `c_activate_graph`, `c_math_add`, `c_flow_sequence`.
- **Success:** One end-to-end behavior graph: activate graph → set socket values → run `math/add` → assert output and node executed.
- **glTF:** Data-schema reference ([docs/gltf_godot_data_schema.md](../docs/gltf_godot_data_schema.md)), state type, minimal JSON load/save (extensions preserved).

## Requirements

- [Janet](https://janet-lang.org/) 1.x (e.g. 1.41.2).

## Spork (required for glTF JSON)

The glTF JSON layer uses [spork](https://github.com/janet-lang/spork)’s `spork/json`; there is no fallback. Install spork before running tests or using glTF load/save:

1. Clone spork: `git clone https://github.com/janet-lang/spork.git`
2. From the spork directory: `janet --install .` (or `sudo janet --install .` on Unix so it installs to `$JANET_PATH`)

Alternatively, if you use [jpm](https://github.com/janet-lang/jpm): `jpm install spork`, or run `jpm deps` from `janet/` (spork is in `project.janet` dependencies).

**Windows:** Spork’s native modules (including `spork/json`) are built with MSVC. You need [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with the “Desktop development with C++” workload so `vcvarsall.bat` is available. Then run `jpm install spork` (with `jpm` on PATH, e.g. from Janet’s bin).

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
- `source/aria/gltf/` — glTF state and JSON load/save via `spork/json` (required).
- `test/` — Unit tests, E2E test, HDDL round-trip, glTF round-trip.

## After Phase 1

See [PHASE1_GAPS.md](PHASE1_GAPS.md) for missing pieces and effort estimate for Phase 2.
