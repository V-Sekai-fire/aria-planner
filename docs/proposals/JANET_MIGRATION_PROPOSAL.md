# Proposal: Migrate aria-planner and Interactivity Domain to Janet

**Status:** Proposed  
**Date:** February 2025  
**Scope:** aria-planner core planning runtime and `lib/domains/interactivity`  
**Target runtime:** Janet 1.x (verified: 1.41.2-local on proposal author machine)

## Summary

Proposal to reimplement aria-planner and the glTF Interactivity Extension domain in **Janet** (janet-lang.org), replacing the current Elixir/OTP implementation. The planner will use a **modified HDDL congruent with aria-planner**: the HDDL Aria Extension (see `docs/proposals/HDDL_ARIA_EXTENSION.md`), which extends HDDL 2.1 with `:aria-*` constructs (commands, multigoals, goal methods, ISO 8601 temporals, domain metadata, entity requirements, etc.). Janet is already installed on the development machine. This document outlines rationale, scope, migration strategy, and trade-offs.

## Context

### Current state

- **aria-planner** is an HTN (Hierarchical Task Network) planner implemented in Elixir:
  - Persona-centric planning with belief-immersed architecture
  - ETS-backed in-memory storage, no database
  - Domains: predicates, commands, tasks, methods, multigoals, lazy refinement
  - Temporal model: ISO 8601, STN, planner state

- **`lib/domains/interactivity`** implements the glTF 2.0 KHR_interactivity extension:
  - Large domain: 160+ modules (commands, predicates, tasks, support modules)
  - Behavior graph execution: node operations (math, flow, pointer, animation, events, types)
  - Operation mapping, pointer resolution, glTF loading
  - PDDL/HDDL interop (historical; HDDL removed, PddlInterop still referenced for graph ↔ planning)

- **Dependencies:** Mix project with Jason, Axon, Timex, UUIDv7, Nx, and others; application supervised via `AriaPlanner.Planner.Application`.

### Motivation for considering Janet

- **Single binary / small runtime:** Janet compiles to a small native binary and has a minimal runtime, which can simplify deployment and embedding (e.g. in game engines or tools).
- **Lisp semantics:** Macros and a single, consistent syntax can make domain DSLs (e.g. task/method/command definitions) and code generation straightforward.
- **C interop:** Easy FFI to C libraries (e.g. for glTF parsing or engine integration) without maintaining a separate NIF/Rust layer.
- **Already available:** Janet is installed on this computer, reducing setup friction for prototyping.

Migration is a major undertaking; this proposal frames it as an option to evaluate rather than a committed plan.

## Scope

### In scope

1. **Core planner**
   - Planning state (current time, timeline, entity capabilities, facts)
   - Task/method/action/command execution model
   - Lazy refinement and solution graph construction
   - Domain registration and lookup (predicates, commands, tasks)

2. **Interactivity domain**
   - All of `lib/domains/interactivity`: commands (math, flow, pointer, animation, events, types, etc.), predicates, tasks, `operation_mapping`, `pointer_resolver`, `gltf_loader`, and supporting code
   - Behavior graph execution semantics aligned with the glTF Interactivity Extension spec
   - Preserve compatibility with existing glTF behavior graph JSON (same graph structure and operation semantics where applicable)

3. **Storage**
   - In-memory storage equivalent to current ETS usage (tables → Janet data structures or native tables)
   - No requirement to add a database; keep the “no DB” design unless explicitly scoped later

4. **Temporal**
   - ISO 8601 durations and datetimes in the planner API
   - STN and temporal constraints as in current design (semantics preserved; implementation in Janet)

5. **HDDL / domain language**
   - Use the **HDDL Aria Extension** (modified HDDL congruent with aria-planner) as the canonical domain/problem representation where HDDL is used.
   - Support the extension’s constructs: `:aria-temporal-metadata`, `:aria-domain-metadata`, `(:command ...)`, `(:multigoal ...)`, `(:goal-method ...)`, `:aria-initial-state`, `:aria-plan`, `:aria-blacklist`, `:aria-solution-graph`, entity requirements, predicate schemas, and ISO 8601 throughout.
   - Standard HDDL 2.1 parsers may ignore `:aria-*` blocks; the Janet implementation must parse and emit them for full aria-planner compatibility.
   - Specification reference: `docs/proposals/HDDL_ARIA_EXTENSION.md`.

### Out of scope (for this proposal)

- Other Elixir domains (e.g. blocks_world, fox_geese_corn, aircraft_disassembly, neighbours, tiny_cvrp) unless explicitly added later
- aria_patrol_solver and locomotion domain (separate app)
- Re-implementing Axon/Nx-based ML features in Janet (would require a separate decision; could remain in Elixir or be replaced by another stack)
- Changing the glTF Interactivity Extension specification itself
- Database or persistent storage (proposal keeps in-memory only)

## Target architecture in Janet

- **Namespacing:** Use Janet modules (e.g. `aria/planner`, `aria/domains/interactivity`) to mirror current structure where it helps.
- **Domain representation:** Represent predicates, commands, and tasks as Janet functions and data (e.g. maps/structs for state, function tables for command lookup). Domain/problem files use the **HDDL Aria Extension** syntax so that exported or hand-written HDDL remains congruent with aria-planner semantics.
- **HDDL parser/emitter:** Implement (or port) an HDDL parser and emitter that understand the aria extension: `:aria-*` blocks, `(:command ...)`, `(:multigoal ...)`, `(:goal-method ...)`, ISO 8601 in temporal metadata, and the rest of the extension as specified in `HDDL_ARIA_EXTENSION.md`. Internal planner structures map to/from this HDDL variant.
- **Operation mapping:** Port `OperationMapping` logic (spec operation ID ↔ command name) into Janet; keep the same mapping rules so existing graphs still resolve.
- **glTF loading:** Either reimplement a minimal glTF/JSON reader in Janet or call out to a C/library via Janet’s FFI; behavior graph extraction (graphs, nodes, sockets) must produce structures equivalent to what the current code expects.
- **Personas and entities:** Model personas and capabilities as data (e.g. maps); no need for Elixir behaviours—protocols can be replaced by function tables or multimethods if needed.

## Migration strategy

### Phase 1: Prototype (recommended first step)

- [ ] Set up a Janet project (e.g. `jpm init` or project layout with `project.janet`).
- [ ] Implement a minimal planner core in Janet: state struct, one trivial domain (e.g. one predicate, one command, one task), and a single run of “plan and execute” to validate the loop.
- [ ] Port a small subset of the interactivity domain (e.g. `math/add`, one flow op, `SocketValue`-like state) and run one behavior graph end-to-end.
- [ ] Document gaps (e.g. missing ops, differences in semantics) and estimate effort to reach parity.

**Success:** One end-to-end behavior graph execution in Janet that matches current Elixir semantics for that subset.

### Phase 2: Interactivity domain parity

- [ ] Enumerate all interactivity commands/predicates/tasks from `lib/domains/interactivity` and the spec.
- [ ] Port or regenerate operation mapping and pointer resolution.
- [ ] Port or reimplement glTF loader (or FFI to existing parser) and wire graph → planner state.
- [ ] Port remaining commands and predicates in batches (math, flow, pointer, animation, events, types), with tests comparing against Elixir behavior or spec.
- [ ] Add a small test suite (e.g. Janet’s test framework) that runs a set of golden graphs.

**Success:** All current interactivity operations and graph execution paths reproducible in Janet with equivalent behavior.

### Phase 3: Core planner parity

- [ ] Port lazy refinement, solution graph, and method/task decomposition.
- [ ] Port temporal model (ISO 8601, STN) and planner metadata.
- [ ] Port persona/entity and capability model.
- [ ] Replace ETS with Janet tables or equivalent in-memory structures.
- [ ] Implement HDDL Aria Extension support: parser and emitter for the modified HDDL (domain + problem with `:aria-*` blocks), so that domains and plans can be loaded from/saved to aria-congruent HDDL.
- [ ] Provide a minimal CLI or API entrypoint (e.g. load domain + problem from HDDL or JSON, run planner, output plan or HDDL).

**Success:** Core planning and interactivity domain usable from Janet without Elixir; HDDL round-trip uses the aria extension format.

### Phase 4: Deprecation / coexistence (optional)

- [ ] If migration is adopted: document Elixir codebase as deprecated, archive or maintain in parallel.
- [ ] If coexistence is preferred: define a small boundary (e.g. JSON over stdio or HTTP) so Elixir can call Janet planner or vice versa, and document which stack owns which responsibilities.

## Risks and consequences

| Risk | Mitigation |
|------|------------|
| Large port surface (160+ interactivity modules) | Phase 1 prototype to validate approach; batch porting with automated tests. |
| Subtle semantics differences (floats, NaNs, spec edge cases) | Reuse same spec and EDGE_CASES docs; add Janet tests that mirror Elixir or spec. |
| Loss of Elixir ecosystem (Mix, Hex, tooling) | Use Janet’s jpm, testing, and docs; accept different tooling. |
| No direct replacement for Nx/Axon in Janet | Leave ML/neural work out of scope or in a separate service. |
| Team familiarity with Janet | Invest in small tutorials and internal docs; Phase 1 is low cost. |
| Long-lived branch / fork | Prefer a separate repo or clear “janet” directory to avoid constant merge conflicts. |

## Success criteria

- **Technical:** A Janet program can load a glTF asset with a KHR_interactivity behavior graph and execute that graph with the same observable results as the current Elixir interactivity domain (for a defined test set).
- **Documentation:** Proposal updated with Phase 1 outcomes (what worked, what didn’t, revised effort estimate).
- **Decision:** After Phase 1, a go/no-go decision on continuing to Phase 2+ with rationale recorded (e.g. in an ADR or this doc’s changelog).

## References

- [Janet language](https://janet-lang.org/)
- [Janet C API](https://janet-lang.org/capi/) (for FFI and embedding)
- Current codebase: `lib/domains/interactivity/`, `lib/planner/`, `AGENTS.md`
- glTF Interactivity: `lib/domains/interactivity/README.md`, `thirdparty/specification/`
- **HDDL Aria Extension** (modified HDDL congruent with aria-planner): `docs/proposals/HDDL_ARIA_EXTENSION.md` — canonical specification for the HDDL variant used by this migration.

## Change log

- **2025-02:** Initial proposal (status: Proposed).
- **2025-02:** Phase 1 prototype completed: Janet project, planner core, interactivity subset (three commands, predicates, E2E behavior graph), HDDL state parse/emit (`:aria-initial-state` / `:facts`), glTF data-schema reference and minimal JSON load/save. See `janet/README.md`, `janet/PHASE1_GAPS.md`.
