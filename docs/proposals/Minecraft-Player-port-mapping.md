# Minecraft-Player (IPC 2020) port mapping to glTF Interactivity

**Status:** Active (minimal port)  
**Reference:** `thirdparty/ipc2020-domains/total-order/Minecraft-Player/` (domain.hddl, p-003-003-003-003.hddl)

## HDDL summary

- **Domain:** minecraft. Top-level task: `(buildhouse ?loc1..?loc6 ?len ?len2 ?hgt ?t)`.
- **Decomposition (build-house-1):** ordered subtasks  
  `(buildwall ?loc1 ?len ?hgt e ?t)`,  
  `(buildwall ?loc2 ?len2 ?hgt n ?t)`,  
  `(buildwall ?loc3 ?len ?hgt w ?t)`,  
  `(buildwall ?loc4 ?len2 ?hgt s ?t)`,  
  `(builddoor ?loc5)`,  
  `(buildroof ?loc6 ?len ?len2 e n ?t)`.
- **Primitive actions:** `walk`, `placeblock`, `removeblock`.

## Minimal port (current)

We do not ingest HDDL. We represent one problem as a **fixed graph** that mirrors the buildhouse decomposition:

- **Problem shape:** `%{"source" => "ipc2020", "domain" => "Minecraft-Player", "task" => "buildhouse"}` (or `"minecraft_player_buildhouse_steps" => 6`).
- **Exported graph:** One `flow/sequence` node with six output flows, each connected to a `math/add` node (0+1, 0+2, …, 0+6). So 7 nodes total. This validates the pipeline: six ordered steps, runnable by the C executor with flow/sequence + math/add.
- **Future:** Replace each step with real ops (e.g. variable get/set for state, or custom minecraft/buildwall-style nodes when the executor supports them). Optionally parse HDDL to derive parameters and initial state for a fuller port.

## Reference

- IPC 2020 Minecraft-Player: [panda-planner-dev/ipc2020-domains](https://github.com/panda-planner-dev/ipc2020-domains) (total-order/Minecraft-Player).
- glTF Interactivity: `thirdparty/specification/`.
