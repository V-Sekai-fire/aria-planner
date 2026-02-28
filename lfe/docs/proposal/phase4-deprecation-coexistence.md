# Phase 4: Deprecation / Coexistence (LFE)

**Status:** Proposed  
**Parent:** [LFE_MIGRATION_PROPOSAL.md](../../../docs/proposals/LFE_MIGRATION_PROPOSAL.md)  
**Depends on:** Phase 1; Phases 2 and 3 determine scope of migration adoption

## Objective

Define how the Elixir and LFE codebases coexist or how the Elixir codebase is deprecated after the LFE migration reaches sufficient parity. Optional phase: only applies if the migration is adopted and a clear policy is needed.

## Context

LFE runs on the same BEAM as Elixir; coexistence (mixed Elixir and LFE modules in one release) is natural. Phase 4 is the decision phase: document deprecation of Elixir planner/interactivity modules, or define a boundary and ownership (e.g. LFE owns planner, Elixir owns ML pipeline).

## Scope

### Option A: Deprecation

- Document Elixir planner and interactivity modules as deprecated; LFE is the primary implementation
- Update README and contribution guidelines to point to LFE modules
- Preserve Elixir code in read-only or archive for reference; no new features there

### Option B: Coexistence

- LFE and Elixir modules coexist in the same release; LFE calls Elixir (e.g. Jason, Axon) and vice versa as needed
- Document which stack owns which responsibilities (e.g. “LFE: planner + interactivity; Elixir: Mix build, Nx/Axon”)
- Shared ETS and OTP; no process boundary required unless a clear API is desired

### Out of scope

- Forcing a single choice; the proposal can be updated after Phases 2–3 with go/no-go and chosen option

## Implementation plan

1. **Decision:** After Phase 2 and/or 3, record go/no-go and chosen option (A or B) in an ADR or the main proposal changelog
2. **If A (deprecation):** Add deprecation notices to Elixir README and key modules; document LFE as primary
3. **If B (coexistence):** Document module ownership and call conventions; ensure build and test run both LFE and Elixir code

## Success criteria

- Decision (A or B) documented with rationale
- If A: Elixir planner/interactivity marked deprecated; LFE is primary
- If B: Ownership and coexistence approach documented

## Effort (rough)

- Option A: small (docs + optional archive)
- Option B: small (docs + clear boundaries)

## References

- Main proposal: `docs/proposals/LFE_MIGRATION_PROPOSAL.md`
- Phase 2 / Phase 3 proposals in `lfe/docs/proposal/`
