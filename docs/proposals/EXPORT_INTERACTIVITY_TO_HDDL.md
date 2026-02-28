# Export entire interactivity domain to HDDL (for Janet / independent execution)

**Status:** Proposed  
**Goal:** Janet (or any consumer) executes the interactivity domain from HDDL without re-implementing it. Single source of truth: Elixir.

## Principle: don’t repeat yourself

- **Domain is defined once:** `lib/domains/interactivity` (Elixir) — commands, predicates, operation mapping, glTF usage.
- **Export, don’t reimplement:** A tool **generates** HDDL (Aria Extension) from the existing Elixir domain. No hand-written duplicate of the domain in Janet or elsewhere.
- **Consumers:** Parse the exported HDDL and execute it (e.g. Janet: HDDL parser + generic command executor that follows the HDDL `(:command ...)` and `:aria-*` descriptions).

## Flow

1. **Elixir** (single source of truth): full interactivity domain in `lib/domains/interactivity`.
2. **Export pipeline** (Elixir): Mix task or module that walks Commands.*, OperationMapping, predicates and **emits** HDDL:
   - `:aria-domain-metadata` (domain type, version)
   - `(:command ...)` for each command (name, parameters, preconditions/effects as needed for execution)
   - `:aria-initial-state` / `:facts` for state shape
   - Operation mapping (spec ID ↔ command name) so behavior graphs can resolve ops from the same HDDL.
3. **Artifact:** One or more HDDL files (e.g. `interactivity_domain.hddl`, optional `interactivity_problem.hddl`).
4. **Janet (or others):** Load HDDL → parse `(:command ...)` and `:aria-*` → execute commands by name and parameters. Janet implements an **HDDL executor** (interpreter), not a second copy of the domain logic.

## Scope

- **In scope:** Exporter in Elixir (codegen or runtime discovery, e.g. Sourceror or `Module.__info__`); HDDL format per `HDDL_ARIA_EXTENSION.md`; Janet (or other) parser/executor that consume exported HDDL.
- **Out of scope:** Defining the domain twice; hand-porting interactivity commands to Janet.

## Success criteria

- Running the exporter produces HDDL that describes the full interactivity domain (all commands, operation mapping, state shape).
- Janet can parse that HDDL and execute behavior-graph flows (e.g. activate → math/add → variable/get) using only the exported spec, with no duplicate Elixir command logic in Janet.

## Related: external HDDL and stdlib

External HDDL domains (e.g. IPC 2020 rover, blocks) use their own primitives; we **convert** those into our stdlib (glTF nodes) so the engine only runs our primitives. See [HDDL_STDLIB_AND_CONVERSION.md](HDDL_STDLIB_AND_CONVERSION.md).

## References

- `docs/proposals/HDDL_ARIA_EXTENSION.md`, `docs/proposals/HDDL_STDLIB_AND_CONVERSION.md`
- `lib/domains/interactivity/`, `lib/domains/interactivity/operation_mapping.ex`
- Janet: `janet/docs/proposals/README.md`, Phase 2 (consume exported HDDL)
