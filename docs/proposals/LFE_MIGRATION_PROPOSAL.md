# Proposal: Migrate aria-planner and Interactivity Domain to LFE (Lisp Flavored Erlang)

**Status:** Proposed  
**Date:** February 2026  
**Scope:** aria-planner core planning runtime and `lib/domains/interactivity`  
**Target runtime:** LFE on BEAM (Erlang/OTP); same VM as current Elixir implementation

## Summary

Proposal to reimplement aria-planner and the glTF Interactivity Extension domain in **LFE (Lisp Flavored Erlang)** (lfe.io), replacing the current Elixir implementation while staying on the **BEAM**. LFE provides Lisp syntax, pattern matching, and macros; it compiles to BEAM bytecode and can call Erlang and Elixir code directly. The planner will use the **HDDL Aria Extension** (see `docs/proposals/HDDL_ARIA_EXTENSION.md`) as the canonical domain/problem representation where HDDL is used. This document outlines rationale, scope, migration strategy, and trade-offs.

## Context

### Current state

- **aria-planner** is an HTN planner implemented in Elixir:
  - Persona-centric planning with belief-immersed architecture
  - ETS-backed in-memory storage, no database
  - Domains: predicates, commands, tasks, methods, multigoals, lazy refinement
  - Temporal model: ISO 8601, STN, planner state

- **`lib/domains/interactivity`** implements the glTF 2.0 KHR_interactivity extension:
  - Large domain: 160+ modules (commands, predicates, tasks, support modules)
  - Behavior graph execution: node operations (math, flow, pointer, animation, events, types)
  - Operation mapping, pointer resolution, glTF loading

- **Dependencies:** Mix project with Jason, Axon, Timex, UUIDv7, Nx, and others; application supervised via `AriaPlanner.Planner.Application`.

### Motivation for considering LFE

- **Lisp semantics on BEAM:** S-expressions, macros, and pattern matching can simplify domain DSLs (task/method/command definitions) and code generation while keeping one runtime.
- **Same VM:** No runtime change; ETS, OTP, and existing Erlang/Elixir libraries (e.g. Jason, Timex) remain usable from LFE. Gradual migration (LFE modules calling Elixir and vice versa) is possible.
- **No rewrite of storage or concurrency:** ETS and OTP patterns carry over; LFE uses the same primitives.
- **Community and tooling:** LFE has rebar3 support, REPL, and documentation (lfe.io, docs.lfe.io).

Migration is a substantial effort; this proposal frames it as an option to evaluate rather than a committed plan.

## Scope

### In scope

1. **Core planner**
   - Planning state (current time, timeline, entity capabilities, facts)
   - Task/method/action/command execution model
   - Lazy refinement and solution graph construction
   - Domain registration and lookup (predicates, commands, tasks)

2. **Interactivity domain**
   - All of `lib/domains/interactivity`: commands (math, flow, pointer, animation, events, types, etc.), predicates, tasks, operation_mapping, pointer_resolver, gltf_loader, and supporting code
   - Behavior graph execution semantics aligned with the glTF Interactivity Extension spec
   - Preserve compatibility with existing glTF behavior graph JSON

3. **Storage**
   - Continue using ETS (or LFE wrappers over ETS); no database. Same in-memory design.

4. **Temporal**
   - ISO 8601 durations and datetimes in the planner API
   - STN and temporal constraints as in current design; can reuse or port Elixir/Erlang code.

5. **HDDL / domain language**
   - Use the **HDDL Aria Extension** as the canonical representation. Support `:aria-*` blocks, `(:command ...)`, `(:multigoal ...)`, `(:goal-method ...)`, `:aria-initial-state`, `:aria-plan`, entity requirements, predicate schemas, and ISO 8601. Specification: `docs/proposals/HDDL_ARIA_EXTENSION.md`.

### Out of scope

- Other Elixir domains (blocks_world, fox_geese_corn, etc.) unless explicitly added later
- aria_patrol_solver and locomotion domain (separate app)
- Changing the glTF Interactivity Extension specification
- Database or persistent storage (in-memory only)

## Target architecture in LFE

- **Project layout:** LFE modules under `src/` (e.g. rebar3 with LFE plugin or Mix with LFE). Module names mirror current structure (e.g. `aria-planner`, `aria-domains-interactivity`).
- **Domain representation:** Predicates, commands, and tasks as LFE functions and data (maps, records); HDDL Aria Extension for domain/problem files.
- **HDDL parser/emitter:** Implement or port in LFE; parse and emit `:aria-*` blocks and extension constructs. Internal planner structures map to/from this HDDL variant.
- **Operation mapping:** Port OperationMapping logic into LFE; same spec operation ID ↔ command name so existing graphs resolve.
- **glTF loading:** Port or call existing Elixir/Erlang JSON/glTF code from LFE; behavior graph extraction produces structures equivalent to current code.
- **Personas and entities:** Model as data (maps/records); LFE pattern matching and function clauses replace Elixir behaviours where needed.

## Migration strategy

### Phase 1: Prototype

- [ ] Set up LFE in the project (rebar3 + lfe plugin, or Mix + LFE).
- [ ] Implement a minimal planner core in LFE: state (map), command registry, dispatch, one trivial command; one “plan and execute” run to validate the loop.
- [ ] Port a small subset of interactivity (e.g. math/add, one flow op, SocketValue-like state) and run one behavior graph end-to-end.
- [ ] HDDL state round-trip (e.g. `:aria-initial-state` with `:facts`) and glTF state/JSON load-save.
- [ ] Document gaps and estimate effort for Phase 2+.

**Success:** One end-to-end behavior graph execution in LFE that matches current Elixir semantics for that subset.

### Phase 2: Interactivity domain parity

- [ ] Enumerate all interactivity commands/predicates/tasks; port operation mapping and pointer resolution.
- [ ] Port or reuse glTF loader; wire graph → planner state.
- [ ] Port remaining commands and predicates in batches (math, flow, pointer, animation, events, types) with tests.
- [ ] Golden graph test suite.

**Success:** All interactivity operations and graph execution paths reproducible in LFE with equivalent behavior.

### Phase 3: Core planner parity

- [ ] Port lazy refinement, solution graph, method/task decomposition.
- [ ] Port temporal model (ISO 8601, STN) and planner metadata.
- [ ] Port persona/entity and capability model; keep ETS or LFE ETS wrappers.
- [ ] Full HDDL Aria Extension: parser and emitter for domain + problem.
- [ ] Minimal CLI or API: load domain + problem from HDDL or JSON, run planner, output plan or HDDL.

**Success:** Core planning and interactivity usable from LFE; HDDL round-trip in Aria Extension format.

### Phase 4: Deprecation / coexistence

- [ ] If migration is adopted: document Elixir codebase as deprecated or archive.
- [ ] If coexistence: define boundary (e.g. shared ETS, or JSON/HTTP) and which stack owns which responsibilities.

## Risks and consequences

| Risk | Mitigation |
|------|------------|
| Large port surface (160+ interactivity modules) | Phase 1 prototype; batch porting with tests; call Elixir from LFE where useful during migration. |
| Team familiarity with LFE | LFE docs and tutorials; Phase 1 is low cost to validate. |
| Mixed Elixir/LFE codebase during migration | Clear module boundaries; document which modules are LFE vs Elixir. |

## Success criteria

- **Technical:** A BEAM program (LFE) can load a glTF asset with a KHR_interactivity behavior graph and execute that graph with the same observable results as the current Elixir implementation (for a defined test set).
- **Documentation:** Phase proposals in `lfe/docs/proposal/`; main proposal updated with Phase 1 outcomes and go/no-go rationale.

## References

- [LFE (Lisp Flavored Erlang)](https://lfe.io/)
- [LFE documentation](https://docs.lfe.io/)
- [LFE on GitHub](https://github.com/lfe/lfe)
- Current codebase: `lib/domains/interactivity/`, `lib/planner/`, AGENTS.md
- **HDDL Aria Extension:** `docs/proposals/HDDL_ARIA_EXTENSION.md`

## Change log

- **2026-02:** Initial proposal (status: Proposed); migration target changed from Janet to LFE.
