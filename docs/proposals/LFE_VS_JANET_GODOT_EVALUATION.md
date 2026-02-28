# Evaluation: LFE vs Janet for Planner — Godot / godot-sandbox Target

**Status:** Decision made — go all-in on Janet  
**Date:** February 2026  
**Context:** Migration target choice given a goal to run the planner in or alongside Godot Engine, including [godot-sandbox](https://github.com/libriscv/godot-sandbox).

## Summary

If the planner must run **inside Godot** (in-editor or at game runtime) or you want a **single codebase that can be embedded in Godot and also used from Elixir**, **Janet is the better choice**. LFE is BEAM-only and cannot run inside Godot; Janet is embeddable (C library, NIF from Elixir) and easier to port toward Godot.

## Decision factor: where does the planner run?

| Scenario | LFE | Janet |
|----------|-----|--------|
| **Inside Godot** (GDExtension, sandbox, or game process) | No. LFE runs on BEAM only; embedding a full VM in Godot is not practical. | Yes. Janet has a small C API and can be embedded in a GDExtension or linked into a Godot build. Same Janet planner code can run in Godot. |
| **Alongside Godot** (separate Elixir/BEAM process, e.g. server or desktop) | Yes. LFE on BEAM; same process as Elixir; ETS/OTP available. | Yes. Janet as a separate process (stdio/socket) or as a NIF from Elixir. |
| **Elixir calls planner** (no Godot in the loop) | Yes. LFE and Elixir in the same release. | Yes. Janet as NIF (e.g. [janet_nif](https://github.com/leostera/janet_nif)) so Elixir can call Janet without a separate process. |

So the critical question is: **do you need the planner to run inside the Godot engine (e.g. in godot-sandbox)?**

## godot-sandbox and portability

[godot-sandbox](https://github.com/libriscv/godot-sandbox) provides in-editor scripting and sandboxing for Godot 4.4+ with:

- **C++, Rust, SafeGDScript** as the supported scripting surfaces.
- Sandboxed execution (RISC-V, etc.); ELF resources; no BEAM.

Implications:

- **LFE:** Cannot run inside godot-sandbox. You would run the planner in a separate BEAM node and talk to Godot over network/stdio. No “in-engine” LFE.
- **Janet:** Does not run inside godot-sandbox today either, but:
  - Janet’s runtime is a small C codebase; it can be **embedded in a GDExtension** so the same Janet planner runs inside the Godot process.
  - Alternatively, a **subprocess** (Godot spawns Janet, communicates via stdio/socket) is straightforward.
  - A future path could integrate a Janet (or similar) VM into the sandbox ecosystem if the maintainers or you pursue it; LFE/BEAM is not a realistic embed target there.

So for a path **toward** Godot and godot-sandbox, **Janet is easier to port** than LFE.

## Janet as NIF (Elixir side)

You noted “janet can also be a nif”:

- Elixir can call Janet via a NIF binding (e.g. [janet_nif](https://github.com/leostera/janet_nif) or a custom NIF).
- That gives: **one planner implementation in Janet** used both:
  - from **Elixir** (NIF, same OS process), and  
  - from **Godot** (embedded Janet or Janet subprocess).
- No need to maintain two planner codebases (LFE + something for Godot).

## Recommendation

| If your priority is… | Recommendation |
|----------------------|----------------|
| **Run planner inside Godot / easy path to Godot / godot-sandbox** | **Go all-in on Janet.** Embeddable, can be NIF from Elixir, single codebase for Elixir and Godot. |
| **Stay entirely on BEAM, never run inside Godot** | **LFE is fine.** Same VM as Elixir, ETS/OTP, gradual migration. |
| **Both: Elixir today, Godot later** | **Janet.** Use Janet for the planner; call from Elixir via NIF; later embed or subprocess the same Janet code from Godot. |

Given your stated goal (“easier to port janet to godot engine … run to godot-sandbox”) and “janet can also be a nif,” the evaluation favors **going all-in on Janet** and treating LFE as the wrong target for the Godot/sandbox path.

## Suggested next steps if you choose Janet

1. **Un-deprecate the Janet prototype** (reverse the “avoid Janet” / deprecation in `janet/README.md`) and treat Janet as the migration target again.
2. **Done:** LFE code and Mix tasks removed; Janet-only.
3. **Document the NIF option** in the Janet migration proposal: use [janet_nif](https://github.com/leostera/janet_nif) (or equivalent) so the Elixir app can call the Janet planner without a separate process.
4. **Document the Godot path** in the same proposal: embed Janet in a GDExtension, or Godot → Janet subprocess, and reference godot-sandbox where relevant.

## References

- [godot-sandbox](https://github.com/libriscv/godot-sandbox) — in-editor scripting and sandboxing for Godot 4.4+
- [Janet C API](https://janet-lang.org/capi/) — embedding
- [janet_nif](https://github.com/leostera/janet_nif) — Elixir NIF for Janet (if still maintained; otherwise similar approach)
- `docs/proposals/LFE_MIGRATION_PROPOSAL.md` — LFE migration (BEAM-only)
- `docs/proposals/JANET_MIGRATION_PROPOSAL.md` — Janet migration (if revived)
