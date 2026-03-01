# ADR: glTF Interactivity export and C executor pipeline

**Status:** Active  
**Date:** 2025-02

## Context

Interchange format is glTF Interactivity (KHR_interactivity) per scene; no HDDL on the wire. Elixir is source of truth; we emit GLB (minimal stub + extension) and run graphs in a C executor (and later Godot/UdonSharp natively). Rope-first: minimal export and minimal C runner, then expand.

## Decision

- **Export:** Domain + one problem per domain → GLB. Minimal glTF 2.0 stub (one empty scene); full payload in `extensions.KHR_interactivity` (types, variables, events, declarations, nodes). Use Sourceror where helpful to derive from `lib/domains/interactivity/`; otherwise use existing domain/operation_mapping.
- **C executor:** Lives in `c_src/`. Input: path to GLB. Extracts JSON chunk (no cgltf); parses KHR_interactivity with JSMN; runs graph (flow/sequence, math/add). Entry: activate root nodes (no incoming flow). CMake-only build (optional `mix build.native`). Fixtures: `c_src/fixtures/` (rope.glb, minecraft_buildhouse.glb; generate with `python gen_fixtures.py` or `mix gltf_interactivity.export_fixtures`).
- **Validation:** Elixir: StreamData property tests on export. C++: RapidCheck for executor (rope: minimal; highway: full).

## Implementation plan

- [x] **Phase 1 (rope) — Elixir export:** Module that builds KHR_interactivity JSON from domain actions (declarations from command_to_spec), one example graph (e.g. flow/sequence + math/add), minimal types. Emit full glTF JSON then GLB (header + JSON chunk). Implemented: `AriaPlanner.GltfInteractivity.Export`, tests in `test/aria_planner/gltf_interactivity/export_test.exs`.
- [x] **Phase 2 (rope) — c_src:** CMake build; glb_read.c extracts JSON chunk; graph.c parses KHR_interactivity with JSMN, runs flow/sequence and math/add; entry = roots. Fixtures in c_src/fixtures/ (rope.glb, minecraft_buildhouse.glb). Build: `cmake -B build -S . && cmake --build build` or `mix build.native`.
- [x] **Phase 3 — Property tests:** StreamData in Elixir (one property: export_to_glb with any problem map yields valid GLB header). RapidCheck in c_src deferred to highway.
- [x] **Elixir graph runner (rope):** `AriaPlanner.GltfInteractivity.Run` runs the same graph as Export builds: input = full extension map; entry = roots; ops = flow/sequence, math/add; return = list of `{:math_add, node_id, a, b, result}`. Tests in `test/aria_planner/gltf_interactivity/run_test.exs`. Run in Elixir first, then C.
- [ ] **Phase 4 (highway) — Expand:** Full declarations from domain; all math/flow/variable in C; RapidCheck tests; one problem per domain in export.

**Test problems:** [panda-planner-dev/ipc2020-domains](https://github.com/panda-planner-dev/ipc2020-domains) at `thirdparty/ipc2020-domains`. First port: **Minecraft-Player** (buildhouse → 6-step flow/sequence). Minimal port: problem `%{"source" => "ipc2020", "domain" => "Minecraft-Player", "task" => "buildhouse"}` exports a 7-node graph (1 flow/sequence + 6 math/add). Mapping: `docs/proposals/Minecraft-Player-port-mapping.md`. Helper: `AriaPlanner.TestFixtures.Ipc2020`.

## Consequences / risks

- GLB binary layout must match spec (chunk lengths, alignment). cgltf may not parse custom extensions; we may need to parse extension JSON ourselves after cgltf loads the file.
- Build from Mix only: Windows may need gcc/make or MSVC; document or use portable script.

## Success criteria

- `mix compile` builds C executor when present. One Mix task or function exports a GLB with one valid KHR_interactivity graph. C executable loads that GLB and runs the graph (at least flow/sequence + math/add). Elixir runner `GltfInteractivity.Run.run/1` executes the same graph from the extension map and returns results for parity with C.

## Change Log

### 2025-02
- Added Elixir graph runner: `AriaPlanner.GltfInteractivity.Run`. Runs extension graph (roots → flow/sequence, math/add); returns result list. Run in Elixir first, then C executable.
