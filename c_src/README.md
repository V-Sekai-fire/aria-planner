# C executor for glTF Interactivity (KHR_interactivity)

Reads a GLB file path, parses the asset, and runs the default behavior graph from `extensions.KHR_interactivity`. Entry: activate root nodes (nodes with no incoming flow); supports `flow/sequence` and `math/add` nodes.

**Build (CMake, independent of Elixir):**

```bash
cd c_src
cmake -B build -S .
cmake --build build
# Binary: build/interactivity_runner (Unix) or build/Debug/interactivity_runner.exe (MSVC)
./build/interactivity_runner path/to/file.glb
```

**Build from Mix:** `mix build.native` runs the same CMake steps from the repo root.

**Fixtures:** Generate GLB fixtures (rope and Minecraft-Player buildhouse) with `mix gltf_interactivity.export_fixtures` from the repo root, then run the runner on `c_src/fixtures/rope.glb` or `c_src/fixtures/minecraft_buildhouse.glb`.

**Dependencies:** JSMN (minimal JSON parser) is fetched by CMake via FetchContent from https://github.com/zserge/jsmn. No system packages required.
