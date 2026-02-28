# Phase 3: Core Planner Parity (LFE)

**Status:** Proposed  
**Parent:** [LFE_MIGRATION_PROPOSAL.md](../../../docs/proposals/LFE_MIGRATION_PROPOSAL.md)  
**Depends on:** Phase 1; Phase 2 recommended but not strictly required for core planner work

## Objective

Port the full aria-planner core to LFE: lazy refinement, solution graph, method/task decomposition, temporal model (ISO 8601, STN), persona/entity and capability model, ETS (or LFE wrappers), and full HDDL Aria Extension support. Provide a minimal CLI or API to load domain + problem from HDDL or JSON, run the planner, and output plan or HDDL.

## Context

Phase 1 delivers state map, command dispatch, and a trivial command. The Elixir planner has lazy refinement, solution graph construction, method/task decomposition, temporal constraints (ISO 8601, STN), planner metadata, persona/entity model, and ETS-backed storage. The HDDL Aria Extension specifies `:aria-*` blocks (commands, multigoals, goal methods, initial state, plan, blacklist, solution graph, temporal metadata, entity requirements). Phase 1 HDDL only supports `:aria-initial-state` with `:facts`.

## Scope

### In scope

- **Lazy refinement:** Port lazy refinement loop and solution graph construction; tasks decomposed via methods; execution follows solution graph
- **Temporal model:** ISO 8601 durations and datetimes in planner API; STN for constraint solving; planner metadata (duration, start_time, end_time, entity requirements); can reuse or port Elixir/Erlang code
- **Persona/entity:** Port persona and capability model as data (maps/records); LFE pattern matching for lookup
- **Storage:** Continue using ETS (LFE can call `:ets` directly) or thin LFE wrappers; same table layout as current design
- **HDDL Aria Extension:** Parser and emitter for full extension (domain + problem, all `:aria-*` constructs)
- **CLI/API:** Minimal entrypoint: load domain + problem from HDDL or JSON, run planner, output plan or HDDL

### Out of scope

- Database or persistent storage (in-memory only)
- Other Elixir domains unless explicitly added

## Implementation plan

1. **Lazy refinement and solution graph:** Port refinement loop and solution graph structures; wire to command dispatch and method/task lookup
2. **Temporal:** Port or call ISO 8601 and STN logic from Elixir/Erlang; add planner metadata to command/method results
3. **Persona/entity:** Define structures and registration/lookup in LFE
4. **Storage:** Use ETS from LFE; same create/get/update/delete semantics
5. **HDDL full support:** Extend parser and emitter for domain and problem; round-trip tests
6. **CLI/API:** Single entrypoint (e.g. `rebar3 lfe run -- domain.hddl problem.hddl`) or library API

## Success criteria

- Core planning (lazy refinement, solution graph, method/task decomposition) runs in LFE
- Temporal constraints (ISO 8601, STN) and planner metadata supported
- Persona/entity and ETS storage available; domain and problem load/save to HDDL Aria Extension format
- Minimal CLI or API for run-from-file and result export

## Effort (rough)

- Lazy refinement + solution graph: medium
- Temporal (ISO 8601 + STN): small–medium (reuse from Elixir)
- Persona/entity + ETS: small (same VM)
- HDDL full parse/emit: medium
- CLI/API: small

## References

- Main proposal: `docs/proposals/LFE_MIGRATION_PROPOSAL.md`
- HDDL Aria Extension: `docs/proposals/HDDL_ARIA_EXTENSION.md`
- Elixir planner: `lib/planner/`, AGENTS.md
