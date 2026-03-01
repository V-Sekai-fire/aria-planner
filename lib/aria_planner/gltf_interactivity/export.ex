# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.GltfInteractivity.Export do
  @moduledoc """
  Exports domain + one problem to glTF Interactivity (KHR_interactivity) and GLB.

  Rope-first: builds one graph with minimal types and declarations (e.g. flow/sequence, math/add).
  Schema: thirdparty/specification/ (glTF 2.0 Interactivity Extension).
  """

  alias AriaPlanner.Domains.Interactivity.OperationMapping

  @glb_magic 0x46546C67
  @glb_version 2
  @chunk_type_json 0x4E4F534A
  @chunk_type_bin 0x004E4942

  @doc """
  Builds KHR_interactivity extension payload (one graph) from domain actions and one problem.

  Returns a map suitable for `extensions.KHR_interactivity` with `graphs` and `graph` (default index).
  """
  @spec build_extension(map(), map()) :: map()
  def build_extension(domain, problem) do
    declarations = build_declarations(domain)
    graph = build_graph(domain, problem, declarations)
    %{
      "graphs" => [graph],
      "graph" => 0
    }
  end

  @doc """
  Builds minimal glTF 2.0 JSON (stub + KHR_interactivity) and returns the JSON map.
  """
  @spec build_gltf_json(map(), map()) :: map()
  def build_gltf_json(domain, problem) do
    ext = build_extension(domain, problem)
    %{
      "asset" => %{"version" => "2.0"},
      "extensionsUsed" => ["KHR_interactivity"],
      "extensions" => %{"KHR_interactivity" => ext},
      "scene" => 0,
      "scenes" => [%{"nodes" => []}]
    }
  end

  @doc """
  Encodes glTF JSON to GLB binary (header + JSON chunk only; no BIN chunk).
  """
  @spec to_glb(map()) :: binary()
  def to_glb(gltf_json) do
    json_bin = Jason.encode!(gltf_json)
    json_len = byte_size(json_bin)
    # Pad to multiple of 4
    pad = rem(4 - rem(json_len, 4), 4)
    json_padded = json_bin <> String.duplicate(" ", pad)
    chunk_len = byte_size(json_padded)
    total_len = 12 + 8 + chunk_len

    header = <<@glb_magic::32-little, @glb_version::32-little, total_len::32-little>>
    chunk = <<chunk_len::32-little, @chunk_type_json::32-little>> <> json_padded
    header <> chunk
  end

  @doc """
  Exports domain + problem to GLB binary. Convenience: build_gltf_json then to_glb.
  """
  @spec export_to_glb(map(), map()) :: binary()
  def export_to_glb(domain, problem) do
    domain
    |> build_gltf_json(problem)
    |> to_glb()
  end

  defp build_declarations(domain) do
    actions = Map.get(domain, :actions, [])
    # Rope: only ops we need for the example graph (flow/sequence, math/add); order fixed for node indices
    rope_ops = ["c_flow_sequence", "c_math_add"]
    actions
    |> Enum.filter(fn a -> a.name in rope_ops end)
    |> Enum.sort_by(fn a -> a.name end)
    |> Enum.map(fn a -> %{"op" => OperationMapping.command_to_spec(a.name)} end)
  end

  defp build_graph(domain, problem, decl_list) do
    if minecraft_player_buildhouse?(problem) do
      build_minecraft_player_buildhouse_graph(decl_list)
    else
      build_rope_graph(decl_list)
    end
  end

  defp minecraft_player_buildhouse?(problem) when is_map(problem) do
    problem["source"] == "ipc2020" and problem["domain"] == "Minecraft-Player" and
      (problem["task"] == "buildhouse" or problem["minecraft_player_buildhouse_steps"] == 6)
  end

  defp minecraft_player_buildhouse?(_), do: false

  # buildhouse decomposes to: buildwall, buildwall, buildwall, buildwall, builddoor, buildroof (6 steps).
  # Each step exported as flow/sequence output -> math/add (pipeline validation; future: real ops).
  defp build_minecraft_player_buildhouse_graph(decl_list) do
    flow_seq_idx = index_of_op(decl_list, "flow/sequence")
    math_add_idx = index_of_op(decl_list, "math/add")
    types = [%{"signature" => "float"}]

    # Node 0: flow/sequence with 6 outputs -> nodes 1..6
    flows =
      Enum.map(0..5, fn i ->
        {"#{i}", %{"node" => i + 1, "socket" => "in"}}
      end)
      |> Map.new()

    seq_node = %{"declaration" => flow_seq_idx, "flows" => flows}

    # Nodes 1..6: math/add (step i: 0 + (i+1) so execution order is observable)
    add_nodes =
      Enum.map(1..6, fn i ->
        %{
          "declaration" => math_add_idx,
          "values" => %{
            "a" => %{"type" => 0, "value" => [0.0]},
            "b" => %{"type" => 0, "value" => [float(i)]}
          }
        }
      end)

    nodes = [seq_node | add_nodes]
    graph = %{"types" => types, "declarations" => decl_list, "nodes" => nodes}
    Enum.reject(graph, fn {_k, v} -> is_list(v) and v == [] end) |> Map.new()
  end

  defp build_rope_graph(decl_list) do
    flow_seq_idx = index_of_op(decl_list, "flow/sequence")
    math_add_idx = index_of_op(decl_list, "math/add")
    types = [%{"signature" => "float"}]
    nodes = [
      %{
        "declaration" => flow_seq_idx,
        "flows" => %{"0" => %{"node" => 1, "socket" => "in"}}
      },
      %{
        "declaration" => math_add_idx,
        "values" => %{
          "a" => %{"type" => 0, "value" => [1.0]},
          "b" => %{"type" => 0, "value" => [2.0]}
        }
      }
    ]
    graph = %{"types" => types, "declarations" => decl_list, "nodes" => nodes}
    Enum.reject(graph, fn {_k, v} -> is_list(v) and v == [] end) |> Map.new()
  end

  defp index_of_op(decl_list, op) do
    Enum.find_index(decl_list, fn d -> d["op"] == op end) || 0
  end
end
