# aria-planner (LFE) — Phase 1 (alternative)

LFE (Lisp Flavored Erlang) implementation of the planner core and a subset of the glTF Interactivity domain. **Janet is the primary migration target** (Godot embed, Elixir NIF); this LFE tree is an alternative BEAM-only path. See [LFE_VS_JANET_GODOT_EVALUATION.md](../docs/proposals/LFE_VS_JANET_GODOT_EVALUATION.md).

## Requirements

- Elixir and Erlang/OTP (the same as the main Mix project)
- rebar3 (installed via Mix; see below)
- [LFE](https://lfe.io/) (pulled in automatically by the rebar3_lfe plugin)

## Install rebar3 and build LFE (from project root)

Using the project’s Elixir/Mix setup:

```bash
# Install rebar3 (downloads from Hex, stored in MIX_HOME)
mix lfe.install

# Compile the LFE project in lfe/
mix lfe.compile
```

## Test LFE

From the project root, compile then run EUnit in the LFE tree:

```bash
mix lfe.compile
cd lfe && rebar3 eunit
```

Or, if rebar3 is on your PATH:

```bash
cd lfe
rebar3 compile
rebar3 eunit
```

## Layout

- `src/aria_planner.lfe` — State (map), command registry (ETS), dispatch, `c_noop`
- `src/aria_domains_interactivity.lfe` — Operation mapping, predicates (GraphActive, SocketValue, NodeExecuted), `apply_binary_op`, commands: `c_activate_graph`, `c_math_add`, `c_flow_sequence`
- `src/aria_hddl.lfe` — HDDL state parse/emit (`:aria-initial-state`, `:facts`)
- `src/aria_gltf_state.lfe` — glTF state type
- `src/aria_gltf_json.lfe` — glTF JSON load/save (jiffy)
- `test/aria_eunit.erl` — EUnit tests

## Phase 1 scope

- Planner core: state map, command dispatch, one trivial command
- Interactivity subset: three commands, operation mapping, predicates
- HDDL state round-trip
- glTF state and JSON load/save

See `lfe/docs/proposal/` for phase proposals and `docs/proposals/LFE_MIGRATION_PROPOSAL.md` for the full migration plan.
