# LFE Migration — Phase Proposals

Proposals for each phase of the LFE (Lisp Flavored Erlang) migration. The parent document is [LFE_MIGRATION_PROPOSAL](../../../docs/proposals/LFE_MIGRATION_PROPOSAL.md).

| Phase | Document | Status |
|-------|----------|--------|
| **Phase 1** | [phase1-prototype.md](phase1-prototype.md) | Proposed |
| **Phase 2** | [phase2-interactivity-parity.md](phase2-interactivity-parity.md) | Proposed |
| **Phase 3** | [phase3-core-planner-parity.md](phase3-core-planner-parity.md) | Proposed |
| **Phase 4** | [phase4-deprecation-coexistence.md](phase4-deprecation-coexistence.md) | Proposed |

## Summary

- **Phase 1 (Prototype):** Set up LFE in the project; minimal planner core; small interactivity subset; one E2E behavior graph; HDDL state round-trip; glTF state/JSON. Validate approach and document gaps.
- **Phase 2 (Interactivity parity):** Full port of interactivity domain (160+ modules), operation mapping, pointer resolution, glTF loader, golden graph tests.
- **Phase 3 (Core planner parity):** Lazy refinement, solution graph, temporal (ISO 8601, STN), persona/entity, ETS (or LFE wrappers), full HDDL Aria Extension, CLI/API.
- **Phase 4 (Deprecation / coexistence):** Policy for Elixir vs LFE: deprecate Elixir or define boundary and ownership.

## References

- Main proposal: [../../../docs/proposals/LFE_MIGRATION_PROPOSAL.md](../../../docs/proposals/LFE_MIGRATION_PROPOSAL.md)
- HDDL Aria Extension: [../../../docs/proposals/HDDL_ARIA_EXTENSION.md](../../../docs/proposals/HDDL_ARIA_EXTENSION.md)
