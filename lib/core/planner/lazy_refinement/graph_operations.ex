# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.LazyRefinement.GraphOperations do
  @moduledoc """
  Helper functions for manipulating the solution graph in lazy plan refinement.
  """

  require Logger

  alias AriaCore.Planner.LazyRefinement.NodeUtils
  alias AriaCore.Planner.MultiGoal

  # Helper function to add nodes and edges to the solution graph
  def add_nodes_and_edges(id, parent_node_id, children_node_info_list, solution_graph, methods, actions) do
    {new_id, current_graph} =
      Enum.reduce(children_node_info_list, {id, solution_graph}, fn child_node_info, {current_id, current_graph} ->
        new_id = current_id + 1
        node_type = get_node_type(child_node_info, methods, actions)

        node_attrs = %{
          info: child_node_info,
          type: node_type,
          # Open
          status: :O,
          tag: :new,
          successors: [],
          # Initialize state
          state: nil,
          # Initialize selected_method
          selected_method: nil,
          # Initialize available_methods
          available_methods: nil,
          # Initialize action
          action: nil,
          # Initialize start_time
          start_time: nil,
          # Initialize end_time
          end_time: nil,
          # Initialize duration
          duration: nil
        }

        node_attrs =
          case node_type do
            :T ->
              # Wrap method in list if it's a single function (not already a list)
              method = methods.task_method_dict[elem(child_node_info, 0)]
              available_methods = if is_function(method), do: [method], else: method || []

              %{
                node_attrs
                | state: nil,
                  selected_method: nil,
                  available_methods: available_methods
              }

            :A ->
              %{node_attrs | action: actions.action_dict[elem(child_node_info, 0)]}

            :G ->
              # Wrap method in list if it's a single function (not already a list)
              method = methods.goal_method_dict[elem(child_node_info, 0)]
              available_methods = if is_function(method), do: [method], else: method || []

              %{
                node_attrs
                | state: nil,
                  selected_method: nil,
                  available_methods: available_methods
              }

            :M ->
              # Wrap method in list if it's a single function (not already a list)
              method = methods.multigoal_method_dict[child_node_info.goal_tag]
              available_methods = if is_function(method), do: [method], else: method || []

              %{
                node_attrs
                | state: nil,
                  selected_method: nil,
                  available_methods: available_methods
              }

            _ ->
              node_attrs
          end

        updated_graph = Map.put(current_graph, new_id, node_attrs)

        # Add edge from parent to new node
        parent_node = Map.get(updated_graph, parent_node_id)

        updated_graph =
          Map.put(updated_graph, parent_node_id, %{parent_node | successors: parent_node.successors ++ [new_id]})

        {new_id, updated_graph}
      end)

    # Add verification nodes for Goals and MultiGoals
    parent_node = Map.get(current_graph, parent_node_id)

    {final_id, final_graph} =
      case parent_node.type do
        :G ->
          new_id = new_id + 1

          updated_graph =
            Map.put(current_graph, new_id, %{info: :VerifyGoal, type: :VG, status: :O, tag: :new, successors: []})

          updated_graph =
            Map.put(updated_graph, parent_node_id, %{parent_node | successors: parent_node.successors ++ [new_id]})

          {new_id, updated_graph}

        :M ->
          new_id = new_id + 1

          updated_graph =
            Map.put(current_graph, new_id, %{info: :VerifyMultiGoal, type: :VM, status: :O, tag: :new, successors: []})

          updated_graph =
            Map.put(updated_graph, parent_node_id, %{parent_node | successors: parent_node.successors ++ [new_id]})

          {new_id, updated_graph}

        _ ->
          {new_id, current_graph}
      end

    {final_id, final_graph}
  end

  defp get_node_type(node_info, methods, actions) do
    cond do
      is_struct(node_info, MultiGoal) ->
        :M

      is_tuple(node_info) and elem(node_info, 0) in Map.keys(methods.task_method_dict) ->
        :T

      is_tuple(node_info) and elem(node_info, 0) in Map.keys(actions.action_dict) ->
        :A

      is_tuple(node_info) and elem(node_info, 0) in Map.keys(methods.goal_method_dict) ->
        :G

      # Should not happen if all types are covered
      true ->
        Logger.warning(
          "get_node_type: unknown node type for #{inspect(node_info)}. Task methods: #{inspect(Map.keys(methods.task_method_dict))}, Action methods: #{inspect(Map.keys(actions.action_dict))}"
        )

        :unknown
    end
  end

  def extract_solution_plan(solution_graph) do
    # Perform a DFS traversal starting from the root (node 0)
    # and collect actions in preorder.
    do_extract_solution_plan(solution_graph, 0, [])
  end

  defp do_extract_solution_plan(solution_graph, node_id, acc) do
    node = Map.get(solution_graph, node_id)

    if node == nil do
      acc
    else
      # Add action to accumulator if it's an action node
      new_acc = if node.type == :A, do: acc ++ [node.info], else: acc

      # Recursively visit successors
      Enum.reduce(node.successors || [], new_acc, fn successor_id, current_acc ->
        do_extract_solution_plan(solution_graph, successor_id, current_acc)
      end)
    end
  end

  # IPyHOP BFS search: Find first open node in entire solution graph starting from root
  def find_open_node(solution_graph) do
    # BFS search starting from root (node 0)
    queue = :queue.in(0, :queue.new())
    visited = MapSet.new([0])

    do_bfs_search(solution_graph, queue, visited)
  end

  defp do_bfs_search(solution_graph, queue, visited) do
    case :queue.out(queue) do
      {{:value, node_id}, remaining_queue} ->
        node = Map.get(solution_graph, node_id)

        if node == nil do
          # Node doesn't exist, continue BFS
          do_bfs_search(solution_graph, remaining_queue, visited)
        else
          # Check if this node is open
          if node.status == :O do
            Logger.info("find_open_node: found open node #{node_id} with info #{inspect(node.info)}")
            {:ok, node_id}
          else
            # Add children to queue for BFS
            new_queue =
              Enum.reduce(node.successors || [], remaining_queue, fn child_id, q ->
                if MapSet.member?(visited, child_id) do
                  q
                else
                  :queue.in(child_id, q)
                end
              end)

            new_visited = Enum.reduce(node.successors || [], visited, &MapSet.put(&2, &1))
            do_bfs_search(solution_graph, new_queue, new_visited)
          end
        end

      {:empty, _} ->
        Logger.info("find_open_node: no open nodes found in entire graph")
        :no_open_node
    end
  end

  def find_predecessor(solution_graph, node_id) do
    Enum.find_value(solution_graph, fn {id, node} ->
      if Enum.member?(node.successors || [], node_id), do: id
    end)
  end

  def remove_descendants(solution_graph, node_id) do
    descendants_to_remove = get_descendants(solution_graph, node_id)
    Enum.reduce(descendants_to_remove, solution_graph, fn id, sg -> Map.delete(sg, id) end)
  end

  defp get_descendants(solution_graph, node_id) do
    do_get_descendants(solution_graph, [node_id], MapSet.new())
    # Don't remove the node itself, only its descendants
    |> MapSet.delete(node_id)
    |> MapSet.to_list()
  end

  defp do_get_descendants(solution_graph, current_nodes, visited) do
    Enum.reduce(current_nodes, visited, fn node_id, acc ->
      if MapSet.member?(acc, node_id) do
        acc
      else
        node = Map.get(solution_graph, node_id)
        new_visited = MapSet.put(acc, node_id)

        if node != nil and Map.has_key?(node, :successors) do
          do_get_descendants(solution_graph, node.successors, new_visited)
        else
          new_visited
        end
      end
    end)
  end

  def goals_not_achieved(multigoal_info, current_state) do
    # Delegate to NodeUtils to avoid duplication
    NodeUtils.goals_not_achieved(multigoal_info, current_state)
  end
end
