# Storage and Domains

In-memory ETS storage and the planning domain struct plus domain registry.

## ETS Storage (`AriaPlanner.Storage.EtsStorage`)

All persistence is in-memory via Elixir Term Storage. No database.

**Tables**:

- `:aria_planner_planning_domains`
- `:aria_planner_items`
- `:aria_planner_personas`
- `:aria_planner_locations`
- `:aria_planner_plans`
- `:aria_planner_predicates`
- `:aria_planner_facts_allocentric`

**API**: `start_link/0`, `init/0`, `insert/3`, `get/2`, `all/1`, `delete/2`, `clear/1`.

## PlanningDomain (`AriaCore.PlanningDomain`)

Struct for a single planning domain.

- **Ids / naming**: `id`, `domain_type`, `name`, `description`.
- **Content**: `entities`, `tasks`, `actions`, `commands`, `multigoals` (lists of maps).
- **Lifecycle**: `state` — `:active` | `:archived` | `:deprecated`.
- **Versioning**: `version` (integer), `metadata` (map), `inserted_at`, `updated_at`.

**API**: `validate/1`, and ETS integration (load/save by id). Valid `domain_type` values include: blocks_world, tactical, navigation, social, economic, exploration, stealth, custom.

## DomainRegistry (`AriaPlanner.Planner.DomainRegistry`)

GenServer that registers and discovers domain **implementations** (modules), not the ETS domain struct.

- **Registration**: `register_domain(name, module, metadata)`.
- **metadata**: `%{description, optimization_supported, capabilities, version}`.
- **API**: `list_registered_domains/0`, get domain module by name, get metadata.
- Use when you have multiple domain modules (e.g. blocks_world, interactivity) and need to resolve by name at runtime.

## Domain structure (recap)

A domain implementation typically provides:

1. **Tasks** and task methods (e.g. `t_*`).
2. **Goal / unigoal methods** (e.g. `u_*`).
3. **Multigoal methods** (e.g. `m_*`).
4. **Actions and commands** (e.g. `a_*`, `c_*`) with optional PlannerMetadata.
5. **Predicates** for state (fact names and schema).

These are assembled into `Methods` and `Actions` and passed in `domain_spec` to LazyRefinement; the same domain can be stored as a `PlanningDomain` in ETS for reference.

## Summary

| Feature | Module | Purpose |
|--------|--------|---------|
| In-memory persistence | EtsStorage | All planner data (domains, plans, personas, facts, etc.) |
| Domain content + state | PlanningDomain | tasks, actions, commands, multigoals, state, version |
| Domain module discovery | DomainRegistry | Register/lookup domain modules by name + metadata |
