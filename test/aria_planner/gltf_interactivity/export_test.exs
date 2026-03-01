# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.GltfInteractivity.ExportTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.Interactivity
  alias AriaPlanner.GltfInteractivity.Export

  use StreamData.ExUnitProperties

  describe "build_extension/2" do
    test "returns KHR_interactivity with one graph" do
      {:ok, domain} = Interactivity.create_domain()
      problem = %{}
      ext = Export.build_extension(domain, problem)
      assert %{"graphs" => [graph], "graph" => 0} = ext
      assert is_list(graph["types"])
      assert is_list(graph["declarations"])
      assert is_list(graph["nodes"])
    end

    test "declarations include flow/sequence and math/add" do
      {:ok, domain} = Interactivity.create_domain()
      problem = %{}
      ext = Export.build_extension(domain, problem)
      [graph] = ext["graphs"]
      ops = Enum.map(graph["declarations"], & &1["op"])
      assert "flow/sequence" in ops
      assert "math/add" in ops
    end
  end

  describe "build_gltf_json/2" do
    test "returns valid glTF 2.0 root with extension" do
      {:ok, domain} = Interactivity.create_domain()
      problem = %{}
      gltf = Export.build_gltf_json(domain, problem)
      assert gltf["asset"]["version"] == "2.0"
      assert "KHR_interactivity" in gltf["extensionsUsed"]
      assert is_map(gltf["extensions"]["KHR_interactivity"])
    end
  end

  describe "to_glb/1" do
    test "produces binary with GLB magic and version" do
      {:ok, domain} = Interactivity.create_domain()
      problem = %{}
      glb = Export.export_to_glb(domain, problem)
      assert byte_size(glb) >= 12
      <<magic::32-little, version::32-little, _total::32-little>> = glb
      assert magic == 0x46546C67
      assert version == 2
    end

    test "Minecraft-Player buildhouse problem produces 7-node graph (6-step sequence)" do
      {:ok, domain} = Interactivity.create_domain()
      problem = %{
        "source" => "ipc2020",
        "domain" => "Minecraft-Player",
        "task" => "buildhouse"
      }
      ext = Export.build_extension(domain, problem)
      [graph] = ext["graphs"]
      assert length(graph["nodes"]) == 7
      # Node 0 is flow/sequence with 6 outputs
      [seq | _rest] = graph["nodes"]
      assert map_size(seq["flows"]) == 6
    end

    test "JSON chunk is parseable and contains KHR_interactivity" do
      {:ok, domain} = Interactivity.create_domain()
      problem = %{}
      glb = Export.export_to_glb(domain, problem)
      # Skip 12-byte header, then 4 byte chunk length, 4 byte chunk type
      <<_::12-binary, chunk_len::32-little, _type::32-little, rest::binary>> = glb
      json_bin = binary_part(rest, 0, chunk_len)
      gltf = Jason.decode!(json_bin)
      assert is_map(gltf["extensions"]["KHR_interactivity"])
    end
  end

  property "export_to_glb with domain and any problem map always produces valid GLB header" do
    check all problem <- StreamData.map_of(StreamData.term(), StreamData.term(), max_length: 3) do
      {:ok, domain} = Interactivity.create_domain()
      glb = Export.export_to_glb(domain, problem)
      assert byte_size(glb) >= 12
      <<magic::32-little, version::32-little, _::32-little>> = glb
      assert magic == 0x46546C67
      assert version == 2
    end
  end
end
