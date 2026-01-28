# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.GltfLoaderTest do
  @moduledoc """
  Tests for glTF loader functionality.
  """

  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.Interactivity.GltfLoader

  setup do
    # Enable feature flags needed for glTF loader functionality
    FunWithFlags.enable(:gltf_loader_support)

    on_exit(fn ->
      FunWithFlags.disable(:gltf_loader_support)
    end)

    :ok
  end

  describe "load_gltf_json" do
    test "loads valid glTF JSON with behavior graph" do
      gltf_json = """
      {
        "asset": {"version": "2.0"},
        "nodes": [{"name": "Node0"}],
        "extensions": {
          "KHR_interactivity": {
            "nodes": [
              {
                "id": "node1",
                "operation": "math/add"
              }
            ]
          }
        }
      }
      """

      assert {:ok, {asset, behavior_graph}} = GltfLoader.load_gltf_json(gltf_json)
      assert is_map(asset)
      assert is_map(behavior_graph)
      assert Map.has_key?(behavior_graph, "nodes")
    end

    test "returns error for glTF without behavior graph" do
      gltf_json = """
      {
        "asset": {"version": "2.0"},
        "nodes": [{"name": "Node0"}]
      }
      """

      assert {:error, "No KHR_interactivity extension found in glTF asset"} =
               GltfLoader.load_gltf_json(gltf_json)
    end

    test "returns error for invalid JSON" do
      invalid_json = "{ invalid json }"

      assert {:error, _reason} = GltfLoader.load_gltf_json(invalid_json)
    end

    test "validates behavior graph structure" do
      gltf_json = """
      {
        "asset": {"version": "2.0"},
        "extensions": {
          "KHR_interactivity": {
            "invalid": "missing nodes"
          }
        }
      }
      """

      assert {:error, "Invalid behavior graph: Behavior graph must contain 'nodes' array"} =
               GltfLoader.load_gltf_json(gltf_json)
    end
  end

  describe "extract_behavior_graph" do
    test "extracts behavior graph from parsed asset" do
      asset = %{
        "extensions" => %{
          "KHR_interactivity" => %{
            "nodes" => [%{"id" => "node1", "operation" => "math/add"}]
          }
        }
      }

      assert {:ok, {_asset, graph}} = GltfLoader.extract_behavior_graph(asset)
      assert Map.has_key?(graph, "nodes")
    end

    test "returns error if no extension" do
      asset = %{"nodes" => []}

      assert {:error, "No KHR_interactivity extension found in glTF asset"} =
               GltfLoader.extract_behavior_graph(asset)
    end
  end

  describe "get_behavior_graph" do
    test "gets behavior graph from asset" do
      asset = %{
        "extensions" => %{
          "KHR_interactivity" => %{"nodes" => []}
        }
      }

      graph = GltfLoader.get_behavior_graph(asset)
      assert is_map(graph)
      assert Map.has_key?(graph, "nodes")
    end

    test "returns nil if no extension" do
      asset = %{"nodes" => []}
      assert GltfLoader.get_behavior_graph(asset) == nil
    end
  end

  describe "validate_graph" do
    test "validates graph with nodes" do
      graph = %{"nodes" => [%{"id" => "node1"}]}
      assert GltfLoader.validate_graph(graph) == :ok
    end

    test "returns error if missing nodes" do
      graph = %{"variables" => []}
      assert {:error, "Behavior graph must contain 'nodes' array"} = GltfLoader.validate_graph(graph)
    end

    test "returns error if not a map" do
      assert {:error, "Behavior graph must be a map"} = GltfLoader.validate_graph([])
    end
  end
end
