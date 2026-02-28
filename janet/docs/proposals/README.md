# Janet migration — overview

**Status:** Active (Phase 1 completed; Phases 2–5 proposed)  
**Scope:** aria-planner core planning runtime and `lib/domains/interactivity`  
**Target runtime:** Janet 1.x (embed in Godot, Elixir NIF, or standalone)

## Summary

Reimplement aria-planner and the glTF Interactivity Extension domain in **Janet** (janet-lang.org), replacing the current Elixir/OTP implementation. The planner uses the **HDDL Aria Extension** (see [HDDL_ARIA_EXTENSION.md](HDDL_ARIA_EXTENSION.md)): HDDL 2.1 plus `:aria-*` constructs (commands, multigoals, goal methods, ISO 8601 temporals, domain metadata, entity requirements). Janet is embeddable in Godot (GDExtension or subprocess) and callable from Elixir via NIF; one codebase for both.

## Phases

| Phase | Document | Status |
|-------|----------|--------|
| Phase 1 | [phase1-prototype.md](phase1-prototype.md) | Completed |
| Phase 2 | [phase2-interactivity-parity.md](phase2-interactivity-parity.md) | Proposed |
| Phase 3 | [phase3-core-planner-parity.md](phase3-core-planner-parity.md) | Proposed |
| Phase 4 | [phase4-unit-tests.md](phase4-unit-tests.md) | Proposed |
| Phase 5 | [phase5-deprecation-coexistence.md](phase5-deprecation-coexistence.md) | Proposed |

## Context

- **aria-planner (Elixir):** HTN planner, persona-centric, ETS-backed, domains (predicates, commands, tasks, methods, multigoals), lazy refinement, temporal (ISO 8601, STN).
- **lib/domains/interactivity:** glTF KHR_interactivity; 160+ modules; behavior graph execution (math, flow, pointer, animation, events, types); operation mapping, pointer resolution, glTF loading.

**Why Janet:** Small runtime, embeddable (Godot, tools); Lisp semantics for domain DSLs; C interop; single codebase for Elixir (NIF) and Godot. See repo root [LFE_VS_JANET_GODOT_EVALUATION.md](../../../docs/proposals/LFE_VS_JANET_GODOT_EVALUATION.md).

## Scope

**In scope:** Core planner (state, command dispatch, lazy refinement, solution graph); full interactivity domain; in-memory storage (Janet tables); temporal (ISO 8601, STN); HDDL Aria Extension parse/emit.

**Out of scope:** Other Elixir domains unless added later; aria_patrol_solver / locomotion; Axon/Nx in Janet; changing the glTF Interactivity spec; database persistence.

## Target architecture

- **Modules:** `aria/planner`, `aria/domains/interactivity`; state and command lookup as tables/functions.
- **HDDL:** Parser/emitter for `:aria-*` blocks; internal structures map to/from [HDDL_ARIA_EXTENSION.md](HDDL_ARIA_EXTENSION.md).
- **Operation mapping:** Spec operation ID ↔ command name; same rules as Elixir.
- **glTF:** Minimal JSON or FFI; behavior graph extraction equivalent to current code.
- **Personas/entities:** Data (maps); function tables instead of Elixir behaviours.

## Risks and mitigation

| Risk | Mitigation |
|------|------------|
| Large port (160+ modules) | Phase 1 done; batch port with tests. |
| Semantics drift | Reuse spec and tests; Janet tests mirror Elixir/spec. |
| No Nx/Axon in Janet | ML out of scope or separate service. |
| Godot integration | Embed Janet or subprocess; see evaluation doc. |

## Success criteria

- Janet can load a glTF asset with a KHR_interactivity behavior graph and execute it with the same observable results as Elixir (for a defined test set).
- Phases documented and updated with outcomes; go/no-go and rationale recorded.

## References

- [Janet](https://janet-lang.org/), [Janet C API](https://janet-lang.org/capi/)
- Codebase: `lib/domains/interactivity/`, `lib/planner/`, AGENTS.md
- glTF Interactivity: `lib/domains/interactivity/README.md`, `thirdparty/specification/`
- [HDDL_ARIA_EXTENSION.md](HDDL_ARIA_EXTENSION.md) — HDDL variant for this migration
