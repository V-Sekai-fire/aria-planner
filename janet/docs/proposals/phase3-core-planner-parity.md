# Phase 3: Core Planner Parity

**Status:** Proposed  
**Parent:** [README.md](README.md) (proposals overview)  
**Depends on:** Phase 1 (completed); Phase 2 recommended but not strictly required for core planner work

## Objective

Port the full aria-planner core to Janet: lazy refinement, solution graph, method/task decomposition, temporal model (ISO 8601, STN), persona/entity and capability model, in-memory storage equivalent to ETS, and full HDDL Aria Extension support. Provide a minimal CLI or API to load domain + problem from HDDL or JSON, run the planner, and output plan or HDDL.

## Context

Phase 1 delivered state table, command dispatch, and a trivial command. The Elixir planner has lazy refinement, solution graph construction, method/task decomposition, temporal constraints (ISO 8601, STN), planner metadata (duration, entity requirements), persona/entity model, and ETS-backed storage. The HDDL Aria Extension specifies `:aria-*` blocks (commands, multigoals, goal methods, initial state, plan, blacklist, solution graph, temporal metadata, entity requirements). Phase 1 HDDL only supports `:aria-initial-state` with `:facts`.

## Scope

### In scope

- **Lazy refinement:** Port lazy refinement loop and solution graph construction so tasks are decomposed via methods and execution follows the solution graph
- **Temporal model:** ISO 8601 durations and datetimes in planner API; STN (Simple Temporal Network) for constraint solving; planner metadata (duration, start_time, end_time, entity requirements)
- **Persona/entity:** Port persona and capability model; represent as data (e.g. tables); no Elixir behaviours—use function tables or equivalent
- **Storage:** In-memory storage equivalent to ETS (plans, personas, facts, predicates, domains, etc.) using Janet tables or native structures
- **HDDL Aria Extension:** Parser and emitter for full extension:
  - Domain: `:aria-domain-metadata`, `(:command ...)`, `(:multigoal ...)`, `(:goal-method ...)`, predicate schemas, entity requirements
  - Problem: `:aria-initial-state`, `:aria-plan`, `:aria-blacklist`, `:aria-solution-graph`
  - Temporal: `:aria-temporal-metadata`, ISO 8601 throughout
- **CLI/API:** Minimal entrypoint: load domain + problem from HDDL or JSON, run planner, output plan or HDDL

### Out of scope

- Database or persistent storage (in-memory only per main proposal)
- Axon/Nx or other ML in Janet
- Other Elixir domains unless explicitly added

## Implementation plan

1. **Lazy refinement and solution graph:** Port refinement loop and solution graph data structures; wire to command dispatch and method/task lookup
2. **Temporal:** Implement or port ISO 8601 parsing/formatting; port STN data structures and consistency/solving logic; add planner metadata to command/method results
3. **Persona/entity:** Define persona and capability structures; port registration and lookup
4. **Storage:** Design table layout (or equivalent) for plans, personas, facts, domains; implement create/get/update/delete; replace any ad-hoc state with storage abstraction
5. **HDDL full support:** Extend parser for domain (commands, multigoals, goal methods, metadata) and problem (plan, blacklist, solution graph); extend emitter to output full HDDL; round-trip tests
6. **CLI/API:** Single entrypoint (e.g. `janet main.janet --domain file.hddl --problem file.hddl`) or library API to load, run, and serialize result

## Success criteria

- Core planning (lazy refinement, solution graph, method/task decomposition) runs in Janet
- Temporal constraints (ISO 8601, STN) and planner metadata supported
- Persona/entity and capability model available; storage holds plans, personas, facts, domains
- Domain and problem can be loaded from and saved to HDDL in Aria Extension format
- Minimal CLI or API allows run-from-file and result export

## Effort (rough)

- Lazy refinement + solution graph: medium
- Temporal (ISO 8601 + STN): medium
- Persona/entity + storage: medium
- HDDL full parse/emit: medium
- CLI/API: small

## Risks

| Risk | Mitigation |
|------|------------|
| STN/solver complexity | Port existing Elixir or aria_math logic; keep same semantics |
| HDDL extension surface | Implement incrementally; round-trip tests per construct |
| Storage semantics vs ETS | Document differences; aim for same logical API (create/get/update/delete) |

## References

- Overview: [README.md](README.md)
- HDDL Aria Extension: `janet/docs/proposals/HDDL_ARIA_EXTENSION.md`
- Elixir planner: `lib/planner/`, AGENTS.md
- Phase 1 gaps: `janet/PHASE1_GAPS.md`
