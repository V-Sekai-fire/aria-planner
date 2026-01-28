# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.PointerOperationsTest do
  @moduledoc """
  Tests for pointer operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  setup do
    # Enable feature flags needed for pointer operations
    FunWithFlags.enable(:gltf_asset_support)
    FunWithFlags.enable(:pointer_template_support)

    on_exit(fn ->
      FunWithFlags.disable(:gltf_asset_support)
      FunWithFlags.disable(:pointer_template_support)
    end)

    :ok
  end

  alias AriaPlanner.Domains.Interactivity.Commands.{
    PointerGet,
    PointerInterpolate,
    PointerSet
  }

  alias AriaPlanner.Domains.Interactivity.Predicates.GltfAsset

  describe "pointer/get operations" do
    test "gets property from glTF asset with simple pointer", %{state: state} do
      # Create a simple glTF asset
      asset = %{
        "nodes" => [
          %{"translation" => [1.0, 2.0, 3.0]}
        ]
      }

      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      # Set pointer template in socket
      state = SocketValue.set(state, "node1", "pointer", "/nodes/0/translation")

      {:ok, result_state} =
        PointerGet.c_pointer_get(state, "node1", "pointer", "value", type: 4)

      assert NodeExecuted.get(result_state, "node1") == true
      {value, is_valid} = SocketValue.get(result_state, "node1", "value")
      assert is_valid == true
      assert value == [1.0, 2.0, 3.0]
    end

    @tag :skip
    # FIXME: Re-enable when template parameter resolution is fully implemented
    test "gets property with template parameter", %{state: state} do
      # Create glTF asset with multiple nodes
      asset = %{
        "nodes" => [
          %{"scale" => [1.0, 1.0, 1.0]},
          %{"scale" => [2.0, 2.0, 2.0]}
        ]
      }

      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      # Set pointer template and parameter
      state = SocketValue.set(state, "node1", "pointer", "/nodes/{nodeId}/scale")
      state = SocketValue.set(state, "node1", "nodeId", 1)

      {:ok, result_state} =
        PointerGet.c_pointer_get(state, "node1", "pointer", "value", type: 4)

      assert NodeExecuted.get(result_state, "node1") == true
      {value, is_valid} = SocketValue.get(result_state, "node1", "value")
      assert is_valid == true
      assert value == [2.0, 2.0, 2.0]
    end

    test "returns invalid for non-existent property", %{state: state} do
      asset = %{"nodes" => []}
      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      state = SocketValue.set(state, "node1", "pointer", "/nodes/0/translation")

      {:ok, result_state} =
        PointerGet.c_pointer_get(state, "node1", "pointer", "value", type: 4)

      assert NodeExecuted.get(result_state, "node1") == true
      {_value, is_valid} = SocketValue.get(result_state, "node1", "value")
      assert is_valid == false
    end

    test "returns invalid for negative parameter", %{state: state} do
      asset = %{"nodes" => [%{"scale" => [1.0, 1.0, 1.0]}]}
      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      state = SocketValue.set(state, "node1", "pointer", "/nodes/{nodeId}/scale")
      state = SocketValue.set(state, "node1", "nodeId", -1)

      {:ok, result_state} =
        PointerGet.c_pointer_get(state, "node1", "pointer", "value", type: 4)

      assert NodeExecuted.get(result_state, "node1") == true
      {_value, is_valid} = SocketValue.get(result_state, "node1", "value")
      assert is_valid == false
    end

    test "falls back to VariableValue when no glTF asset", %{state: state} do
      # No glTF asset set - should fall back to VariableValue
      alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue

      state = VariableValue.set(state, "/test/path", 42.0)
      state = SocketValue.set(state, "node1", "pointer", "/test/path")

      {:ok, result_state} = PointerGet.c_pointer_get(state, "node1", "pointer", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      {value, is_valid} = SocketValue.get(result_state, "node1", "value")
      assert is_valid == true
      assert value == 42.0
    end
  end

  describe "pointer/set operations" do
    @tag :skip
    # FIXME: Re-enable when glTF asset property setting is fully implemented
    test "sets property in glTF asset", %{state: state} do
      asset = %{
        "nodes" => [
          %{"translation" => [0.0, 0.0, 0.0]}
        ]
      }

      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      state = SocketValue.set(state, "node1", "pointer", "/nodes/0/translation")
      state = SocketValue.set(state, "node1", "value", [1.0, 2.0, 3.0])

      {:ok, result_state} =
        PointerSet.c_pointer_set(state, "node1", "pointer", "value", type: 4)

      assert NodeExecuted.get(result_state, "node1") == true

      # Verify asset was updated
      updated_asset = GltfAsset.get(result_state, graph_id)
      assert get_in(updated_asset, ["nodes", Access.at(0), "translation"]) == [1.0, 2.0, 3.0]
    end

    @tag :skip
    # FIXME: Re-enable when template parameter resolution in set operations is implemented
    test "sets property with template parameter", %{state: state} do
      asset = %{
        "nodes" => [
          %{"scale" => [1.0, 1.0, 1.0]},
          %{"scale" => [1.0, 1.0, 1.0]}
        ]
      }

      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      state = SocketValue.set(state, "node1", "pointer", "/nodes/{nodeId}/scale")
      state = SocketValue.set(state, "node1", "nodeId", 1)
      state = SocketValue.set(state, "node1", "value", [2.0, 2.0, 2.0])

      {:ok, result_state} =
        PointerSet.c_pointer_set(state, "node1", "pointer", "value", type: 4)

      assert NodeExecuted.get(result_state, "node1") == true

      # Verify second node's scale was updated
      updated_asset = GltfAsset.get(result_state, graph_id)
      assert get_in(updated_asset, ["nodes", Access.at(1), "scale"]) == [2.0, 2.0, 2.0]
    end

    test "handles negative parameter gracefully", %{state: state} do
      asset = %{"nodes" => [%{"scale" => [1.0, 1.0, 1.0]}]}
      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      state = SocketValue.set(state, "node1", "pointer", "/nodes/{nodeId}/scale")
      state = SocketValue.set(state, "node1", "nodeId", -1)
      state = SocketValue.set(state, "node1", "value", [2.0, 2.0, 2.0])

      {:ok, result_state} =
        PointerSet.c_pointer_set(state, "node1", "pointer", "value", type: 4)

      assert NodeExecuted.get(result_state, "node1") == true
      # Asset should not be modified
      updated_asset = GltfAsset.get(result_state, graph_id)
      assert get_in(updated_asset, ["nodes", Access.at(0), "scale"]) == [1.0, 1.0, 1.0]
    end
  end

  describe "pointer/interpolate operations" do
    @tag :skip
    # FIXME: Re-enable when interpolation type validation is fixed
    test "interpolates property value", %{state: state} do
      asset = %{
        "nodes" => [
          %{"translation" => [0.0, 0.0, 0.0]}
        ]
      }

      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      state = SocketValue.set(state, "node1", "pointer", "/nodes/0/translation")
      state = SocketValue.set(state, "node1", "a", [0.0, 0.0, 0.0])
      state = SocketValue.set(state, "node1", "b", [10.0, 20.0, 30.0])
      state = SocketValue.set(state, "node1", "t", 0.5)

      {:ok, result_state} =
        PointerInterpolate.c_pointer_interpolate(
          state,
          "node1",
          "pointer",
          "a",
          "b",
          "t",
          type: 4
        )

      assert NodeExecuted.get(result_state, "node1") == true

      # Verify interpolated value was set (0.5 * [10, 20, 30] = [5, 10, 15])
      updated_asset = GltfAsset.get(result_state, graph_id)
      translation = get_in(updated_asset, ["nodes", Access.at(0), "translation"])

      assert_in_delta List.first(translation), 5.0, 0.001
      assert_in_delta Enum.at(translation, 1), 10.0, 0.001
      assert_in_delta Enum.at(translation, 2), 15.0, 0.001
    end

    @tag :skip
    # FIXME: Re-enable when scalar interpolation operations are working
    test "interpolates scalar values", %{state: state} do
      asset = %{
        "materials" => [
          %{"emissiveFactor" => [0.0, 0.0, 0.0]}
        ]
      }

      graph_id = "test_graph"
      state = GltfAsset.set(state, graph_id, asset)
      state = Map.put(state, :active_graph_id, graph_id)

      state = SocketValue.set(state, "node1", "pointer", "/materials/0/emissiveFactor")
      state = SocketValue.set(state, "node1", "a", [0.0, 0.0, 0.0])
      state = SocketValue.set(state, "node1", "b", [1.0, 1.0, 1.0])
      state = SocketValue.set(state, "node1", "t", 0.5)

      {:ok, result_state} =
        PointerInterpolate.c_pointer_interpolate(
          state,
          "node1",
          "pointer",
          "a",
          "b",
          "t",
          type: 4
        )

      assert NodeExecuted.get(result_state, "node1") == true

      updated_asset = GltfAsset.get(result_state, graph_id)
      emissive = get_in(updated_asset, ["materials", Access.at(0), "emissiveFactor"])

      assert_in_delta List.first(emissive), 0.5, 0.001
    end
  end
end
