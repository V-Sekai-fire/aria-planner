# HDDL stdlib and conversion of external domains

**Status:** Proposed  
**Goal:** Use glTF Interactivity nodes as the execution stdlib for HDDL. Run existing FOSS HDDL problems by converting their primitives into ours; the engine only ever executes our primitives.

## Execution stdlib = glTF Interactivity = programming constructs

- **Our primitives** are the glTF Interactivity Extension node set: math (add, sub, mul, div, …), flow (sequence, branch, …), variable (get, set), pointer, animation, events, types, etc.
- These map to **programming-language constructs**: adding, sequencing, branching, reading/writing variables, and so on.
- The **execution engine** (e.g. Janet, or Elixir) only runs these primitives. There is no separate “rover” or “blocks” runtime; everything is expressed in terms of our stdlib.

## Consuming external HDDL (e.g. IPC 2020)

- **Existing FOSS HDDL** (e.g. [panda-planner-dev/ipc2020-domains](https://github.com/panda-planner-dev/ipc2020-domains)) defines domains with **their own** primitives: rover moves, block pick/put, transport actions, etc.
- We **do not** execute those primitives natively. We **convert** them into our stdlib.
- **Pipeline:** Parse external HDDL (domain + problem) → **convert** their actions/methods into our primitives (glTF nodes / programming constructs) → execute the result on our engine.

So: their primitives are **implemented** as recipes or compiled graphs in our primitive set. Our engine never sees “move_rover”; it sees a sequence of our ops (e.g. variable get/set, math, flow).

## Conversion approach

- **Per-action mapping table:** For each external action (e.g. `pick ?obj`), define a **recipe** in our primitive language: a small script or graph of our ops (math, flow, variable get/set) that implements the semantics. One mapping per domain or per action.
- **Compiler to our IR:** A compiler rewrites the external HDDL domain (and optionally problem) into an IR or domain that **only** uses our primitives. Tasks/methods become graphs or lists of “add”, “sequence”, “branch”, “variable_get”, “variable_set”, etc. Execution is then uniform.
- **Hybrid:** Some external actions map 1:1 to one glTF node (e.g. a “set_counter” action → variable/set); others expand to a short sequence. Maintain a mapping or small implementation module per domain.

Choice of approach can be made when implementing; the important point is that conversion is explicit and the engine only runs our stdlib.

## Success criteria

- External HDDL domains (e.g. one IPC 2020 domain) can be loaded and **converted** into a form that uses only our primitives.
- The engine executes that converted form using only glTF Interactivity nodes (our stdlib); no native implementation of external actions.
- Existing FOSS HDDL problems serve as **input** to the converter; our execution model remains single (our stdlib only).

## References

- **Our stdlib / export:** [EXPORT_INTERACTIVITY_TO_HDDL.md](EXPORT_INTERACTIVITY_TO_HDDL.md) — interactivity domain as HDDL; single source of truth in Elixir.
- **FOSS HDDL:** [panda-planner-dev/ipc2020-domains](https://github.com/panda-planner-dev/ipc2020-domains) (IPC 2020 HTN domains and problems), [pellierd/HDDL2.1](https://github.com/pellierd/HDDL2.1) (benchmarks, temporal/numerical).
- **HDDL format:** [HDDL_ARIA_EXTENSION.md](HDDL_ARIA_EXTENSION.md); standard HDDL (e.g. IPC 2020) for external domains.
