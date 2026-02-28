# Phase 4: Deprecation / Coexistence

**Status:** Proposed  
**Parent:** [JANET_MIGRATION_PROPOSAL.md](../proposals/JANET_MIGRATION_PROPOSAL.md)  
**Depends on:** Phase 1 (completed); Phases 2 and 3 determine scope of migration adoption

## Objective

Define how the Elixir and Janet codebases coexist or how the Elixir codebase is deprecated after the Janet migration reaches sufficient parity. Optional phase: only applies if the migration is adopted and a clear policy is needed.

## Context

The main proposal leaves open whether the Elixir codebase will be deprecated or maintained in parallel. Phase 4 is the decision and execution phase: document deprecation, archive, or define a boundary (e.g. JSON over stdio or HTTP) so Elixir can call the Janet planner or vice versa, with clear ownership of responsibilities.

## Scope

### Option A: Deprecation

- Document the Elixir codebase as deprecated (or archived) with a timeline
- Update README, AGENTS.md, and contribution guidelines to point to Janet as the primary implementation
- Preserve Elixir code in read-only or archive branch for reference; no new features
- Migrate CI/docs to Janet as primary; Elixir build optional or removed

### Option B: Coexistence

- Define a small boundary between Elixir and Janet:
  - **Option B1:** Elixir calls Janet planner (e.g. subprocess or HTTP): domain/problem in JSON or HDDL, plan/solution back
  - **Option B2:** Janet calls Elixir services (e.g. for ML/Nx or legacy domains)
- Document which stack owns which responsibilities (e.g. “Janet: planner + interactivity; Elixir: ML pipeline”)
- Maintain both codebases; shared contract (e.g. JSON schema for domain/problem/plan) and tests

### Out of scope

- Forcing a single choice; the proposal can be updated after Phases 2–3 with a go/no-go and then Option A or B

## Implementation plan

1. **Decision:** After Phase 2 and/or 3, record go/no-go and chosen option (A or B) in an ADR or the main proposal changelog
2. **If A (deprecation):**
   - Add deprecation notice to Elixir README and key modules
   - Update project docs to list Janet as primary; add link to `janet/`
   - Optionally: move Elixir to `legacy/` or archive repo
3. **If B (coexistence):**
   - Define boundary protocol (e.g. stdio JSON, or HTTP API)
   - Implement adapter in Janet (client or server) and/or Elixir (client or server)
   - Document contract (inputs/outputs, versioning) and ownership

## Success criteria

- Decision (A or B) documented with rationale
- If A: Elixir clearly marked deprecated/archived; Janet is primary
- If B: Boundary and ownership documented; adapter(s) implemented and tested

## Effort (rough)

- Option A: small (docs + optional move/archive)
- Option B: small–medium (adapter + contract + tests)

## References

- Main proposal: `janet/docs/proposals/JANET_MIGRATION_PROPOSAL.md`
- Phase 2 / Phase 3 proposals in `janet/docs/proposal/`
