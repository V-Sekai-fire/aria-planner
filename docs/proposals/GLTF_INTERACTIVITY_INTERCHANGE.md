# glTF Interactivity as interchange; native execution

**Status:** Active  
**Goal:** One interchange format (glTF Interactivity), multiple native runtimes. No HDDL on the wire; no Janet in the pipeline.

## Interchange format

- **glTF Interactivity** (KHR_interactivity) per glTF scene: graphs, types, variables, events, declarations, nodes, flows.
- Schema and semantics: `thirdparty/specification/` (glTF 2.0 Interactivity Extension).
- Elixir is the single source of truth; it emits glTF/GLB (or the interactivity payload) with this extension. Domain and plans live in Elixir and are emitted directly as glTF Interactivity JSON per scene.

## Execution

- **Interchange only:** The same KHR_interactivity graph structure is the contract.
- **Execution is native** on each platform:
  - **Godot:** Parse glTF/GLB, run the graph in **GDScript** (or C#); implement each node op in GDScript.
  - **UdonSharp (VRChat):** Same graph format; ops implemented in UdonSharp.
  - **C executor (this repo):** Small C program in this repo; takes a **path to a full glTF/GLB file**, parses the asset, runs `extensions.KHR_interactivity` graphs. Used for godot-sandbox or standalone tooling.

## Out of scope

- **HDDL** as interchange: removed from this pipeline. No export to HDDL; no HDDL parser in consumers.
- **Janet:** No Janet-based executor; no Janet migration phases.
- **External HDDL ingestion:** No automated conversion of external HDDL (e.g. IPC 2020). Use LLM-based coding to port domains if needed.

## Validation

- **QuickCheck-style property-based testing** for emitted interactivity and graph behavior (e.g. StreamData in Elixir).

## Doc cleanup

- Janet/HDDL migration and interchange proposals have been removed (Janet migration, export-to-HDDL, HDDL stdlib conversion, LFE vs Janet, phase docs). Historical HDDL spec reference: `HDDL_ARIA_EXTENSION.md` (if kept) is for reference only.

## References

- `thirdparty/specification/` — glTF 2.0 Interactivity Extension (KHR_interactivity)
- `lib/domains/interactivity/` — Elixir interactivity domain (source of truth)
