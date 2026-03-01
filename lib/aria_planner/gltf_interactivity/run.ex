# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.GltfInteractivity.Run do
  @moduledoc """
  Runs a KHR_interactivity graph from the extension map (same shape as Export builds).

  Input: full extension map from `Export.build_extension(domain, problem)`.
  Entry: root nodes (no incoming flow). Supported ops: flow/sequence, math/add.
  Returns a list of results for tests; unsupported op returns `{:error, _}`.
  """

  @doc """
  Runs the default graph in the extension map.

  Returns `{:ok, results}` where results is a list of `{:math_add, node_id, a, b, result}`.
  Flow/sequence nodes do not append to results; they only enqueue targets.
  Returns `{:error, reason}` on unsupported op or invalid structure.
  """
  @spec run(map()) :: {:ok, [tuple()]} | {:error, term()}
  def run(ext) when is_map(ext) do
    graph = get_default_graph(ext)
    if is_nil(graph), do: {:error, :no_graph}, else: run_graph(graph)
  end

  defp get_default_graph(ext) do
    graphs = ext["graphs"]
    idx = Map.get(ext, "graph", 0)
    if is_list(graphs) and idx >= 0 and idx < length(graphs), do: Enum.at(graphs, idx), else: nil
  end

  defp run_graph(graph) do
    nodes = graph["nodes"] || []
    declarations = graph["declarations"] || []
    if nodes == [] or declarations == [], do: {:error, :empty_graph}, else: execute(nodes, declarations, [])
  end

  defp execute(nodes, declarations, acc) do
    roots = find_roots(nodes)
    queue = :queue.from_list(roots)
    do_run(nodes, declarations, queue, acc)
  end

  defp find_roots(nodes) do
    targets =
      nodes
      |> Enum.with_index()
      |> Enum.flat_map(fn {node, _i} ->
        (node["flows"] || %{}) |> Map.values() |> Enum.map(& &1["node"])
      end)
      |> MapSet.new()

    nodes
    |> Enum.with_index()
    |> Enum.filter(fn {_node, i} -> not MapSet.member?(targets, i) end)
    |> Enum.map(fn {_node, i} -> i end)
  end

  defp do_run(nodes, declarations, queue, acc) do
    case :queue.out(queue) do
      {{:value, node_id}, rest} ->
        node = Enum.at(nodes, node_id)
        decl_idx = node["declaration"]
        op = (Enum.at(declarations, decl_idx) || %{})["op"]

        case run_node(op, node, node_id, nodes, rest) do
          {:ok, new_queue, new_acc} -> do_run(nodes, declarations, new_queue, new_acc ++ acc)
          {:error, _} = err -> err
        end

      {:empty, _} ->
        {:ok, Enum.reverse(acc)}
    end
  end

  defp run_node("flow/sequence", node, _node_id, _nodes, queue) do
    flows = node["flows"] || %{}
    targets =
      flows
      |> Map.keys()
      |> Enum.sort_by(&String.to_integer/1)
      |> Enum.map(&Map.fetch!(flows, &1))
      |> Enum.map(& &1["node"])

    new_queue = Enum.reduce(targets, queue, &:queue.in/2)
    {:ok, new_queue, []}
  end

  defp run_node("math/add", node, node_id, _nodes, queue) do
    a = get_value(node, "a")
    b = get_value(node, "b")
    if a == nil or b == nil, do: {:error, :missing_values}
    result = a + b
    acc = [{:math_add, node_id, a, b, result}]
    {:ok, queue, acc}
  end

  defp run_node(op, _node, _node_id, _nodes, _queue) do
    {:error, {:unsupported_op, op}}
  end

  defp get_value(node, key) do
    (node["values"] || %{})
    |> Map.get(key, %{})
    |> Map.get("value", [])
    |> List.first()
  end
end
