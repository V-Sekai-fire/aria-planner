# Janet for Godot / godot-sandbox

**Status:** Decision — Janet for embedding; Elixir for BEAM  
**Context:** Run planner in or alongside [Godot](https://godotengine.org/) / [godot-sandbox](https://github.com/libriscv/godot-sandbox).

## Summary

- **Janet** (`janet/`): Godot embedding, NIF from Elixir, or standalone. One Janet codebase for embeddable execution.
- **Elixir:** All BEAM-side work (planner, interactivity, glTF, HDDL parse/emit, storage). No LFE; do it all in Elixir.

## Recommendation

| Priority | Stack |
|----------|--------|
| Planner inside Godot / godot-sandbox | Janet |
| BEAM-only (server, tooling, HDDL export) | Elixir |
| HDDL interchange | Export from Elixir; Janet (or others) parse and execute. See EXPORT_INTERACTIVITY_TO_HDDL.md, HDDL_STDLIB_AND_CONVERSION.md. |

## References

- [Janet C API](https://janet-lang.org/capi/), [janet_nif](https://github.com/leostera/janet_nif)
- `JANET_MIGRATION_PROPOSAL.md`, `EXPORT_INTERACTIVITY_TO_HDDL.md`
