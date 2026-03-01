# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.GltfInteractivity.ExportFixtures do
  @shortdoc "Export rope and Minecraft-Player buildhouse GLB to c_src/fixtures/"
  @moduledoc """
  Writes rope.glb and minecraft_buildhouse.glb into c_src/fixtures/ for the C executor tests.
  Run from repo root: mix gltf_interactivity.export_fixtures
  """

  use Mix.Task

  @impl true
  def run(_args) do
    {:ok, domain} = AriaPlanner.Domains.Interactivity.create_domain()
    fixtures_dir = Path.join(File.cwd!(), "c_src/fixtures")
    File.mkdir_p!(fixtures_dir)

    rope_glb = AriaPlanner.GltfInteractivity.Export.export_to_glb(domain, %{})
    rope_path = Path.join(fixtures_dir, "rope.glb")
    File.write!(rope_path, rope_glb)
    Mix.shell().info("Wrote #{rope_path} (#{byte_size(rope_glb)} bytes)")

    mc_problem = %{
      "source" => "ipc2020",
      "domain" => "Minecraft-Player",
      "task" => "buildhouse"
    }
    mc_glb = AriaPlanner.GltfInteractivity.Export.export_to_glb(domain, mc_problem)
    mc_path = Path.join(fixtures_dir, "minecraft_buildhouse.glb")
    File.write!(mc_path, mc_glb)
    Mix.shell().info("Wrote #{mc_path} (#{byte_size(mc_glb)} bytes)")
  end
end
