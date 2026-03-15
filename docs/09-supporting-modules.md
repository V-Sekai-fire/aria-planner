# Supporting Modules

Helper and support modules used by the planner: solution graph metadata, metadata migration, temporal conversion, and temporal constraints.

## SolutionGraphHelpers (`AriaPlanner.Planner.SolutionGraphHelpers`)

Helpers for temporal metadata on **solution graph nodes**.

- **apply_temporal_metadata(node, metadata)**: Copies duration, start_time, end_time from a `PlannerMetadata` onto a node (ISO 8601 strings).
- **extract_temporal_metadata(node, entity_reqs)**: Builds a `PlannerMetadata` from node fields plus a given list of entity requirements.

Used when building or walking the solution graph so nodes carry the same temporal format as PlannerMetadata.

## MetadataHelpers (`AriaPlanner.Planner.MetadataHelpers`)

Helpers for **creating and migrating** planner metadata (e.g. from maps or legacy formats to `PlannerMetadata` / `UnigoalMetadata`). Use when converting external or stored metadata into structs.

## TemporalConverter (`AriaPlanner.Planner.TemporalConverter`)

Converts **durative actions** with complex temporal semantics into simpler representations (e.g. for execution or STN). Used internally when temporal constraints need to be normalized or simplified.

## TemporalConstraints (`AriaCore.Metadata.TemporalConstraints`)

Simple struct for **temporal constraints** (separate from PlannerMetadata):

- **Struct**: `duration`, `start`, `end` (all ISO 8601 strings, optional).
- **API**: `new/1` (keyword list).

Use for passing pure temporal bounds; use `PlannerMetadata` when you also need entity requirements and integration with actions/commands.

## AriaStnSolver (`AriaPlanner.Solvers.AriaStnSolver`)

Solver for **temporal constraint networks** (STN). Used by STN consistency checks (e.g. `AriaPlanner.Planner.Temporal.STN.Consistency`). Internal to the temporal stack; domains use PlannerMetadata, not the solver directly.

## Built-in domains

- **BlocksWorld** (`AriaPlanner.Domains.BlocksWorld`): Tasks (e.g. move_blocks, move_one, put, get), commands, predicates (e.g. pos). Reference implementation for HTN + methods + actions.
- **Interactivity** (`AriaPlanner.Domains.Interactivity`): glTF Interactivity Extension domain: tasks (execute_graph, activate_graph, execute_node_sequence, initialize_variables), many commands (math, flow, event, variable, pointer, animation, etc.), predicates and schemas, operation mapping, pointer resolver, gltf_loader, feature flags. Shows use of complex commands and domain-specific types.

These domains register with the DomainRegistry and provide the methods/actions used by LazyRefinement.
