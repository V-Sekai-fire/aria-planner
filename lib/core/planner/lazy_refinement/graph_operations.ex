# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.LazyRefinement.GraphOperations do
  @moduledoc """
  Helper functions for manipulating the solution graph in lazy plan refinement.
  """

  require Logger

  # alias AriaCore.Planner.State  # Unused - removed to fix compilation warning
  alias AriaCore.Planner.MultiGoal
  alias AriaCore.Planner.LazyRefinement.NodeUtils

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
              %{
                node_attrs
                | state: nil,
                  selected_method: nil,
                  available_methods: methods.task_method_dict[elem(child_node_info, 0)]
              }

            :A ->
              %{node_attrs | action: actions.action_dict[elem(child_node_info, 0)]}

            :G ->
              %{
                node_attrs
                | state: nil,
                  selected_method: nil,
                  available_methods: methods.goal_method_dict[elem(child_node_info, 0)]
              }

            :M ->
              %{
                node_attrs
                | state: nil,
                  selected_method: nil,
                  available_methods: methods.multigoal_method_dict[child_node_info.goal_tag]
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
      is_struct(node_info, MultiGoal) -> :M
      is_tuple(node_info) and elem(node_info, 0) in methods.task_method_dict -> :T
      is_tuple(node_info) and elem(node_info, 0) in actions.action_dict -> :A
      is_tuple(node_info) and elem(node_info, 0) in methods.goal_method_dict -> :G
      # Should not happen if all types are covered
      true -> :unknown
    end
  end

  def extract_solution_plan(solution_graph) do
    # Perform a DFS traversal starting from the root (node 0)
    # and collect actions in preorder.
    do_extract_solution_plan(solution_graph, 0, [])
  end

  defp do_extract_solution_plan(solution_graph, node_id, acc) do
    node = Map.get(solution_graph, node_id)
    if node == nil, do: acc

    # Add action to accumulator if it's an action node
    new_acc = if node.type == :A, do: acc ++ [node.info], else: acc

    # Recursively visit successors
    Enum.reduce(node.successors || [], new_acc, fn successor_id, current_acc ->
      do_extract_solution_plan(solution_graph, successor_id, current_acc)
    end)
  end

  def find_open_node(solution_graph, parent_node_id) do
    Logger.info("find_open_node: parent_node_id=#{parent_node_id}")

    case Map.get(solution_graph, parent_node_id) do
      %{successors: successors} when is_list(successors) ->
        Logger.info("find_open_node: successors=#{inspect(successors)}")

        Enum.find_value(successors, fn node_id ->
          node = Map.get(solution_graph, node_id)
          Logger.info("find_open_node: checking node #{node_id}, status=#{node.status}")
          if node.status == :O, do: {:ok, node_id}
        end)

      _ ->
        Logger.info("find_open_node: no successors or parent_node_id not found")
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
