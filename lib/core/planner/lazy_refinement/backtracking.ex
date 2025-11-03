# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.LazyRefinement.Backtracking do
  @moduledoc """
  Helper functions for backtracking in lazy plan refinement.
  """

  require Logger

  alias AriaCore.Planner.LazyRefinement.GraphOperations

  # Helper function for backtracking
  def backtrack(solution_graph, parent_node_id, curr_node_id, current_state, blacklisted_commands) do
    Logger.info("Backtracking from node #{curr_node_id}")
    curr_node = Map.get(solution_graph, curr_node_id)
    solution_graph = Map.put(solution_graph, curr_node_id, %{curr_node | status: :F}) # Mark current node as failed

    # Remove descendants of the failed node
    solution_graph = GraphOperations.remove_descendants(solution_graph, curr_node_id)

    # Find the nearest ancestor that can be refined (has available methods or actions)
    # This is a simplified version of IPyHOP's _backtrack
    new_parent_node_id = parent_node_id
    new_curr_node_id = curr_node_id # Fix unused new_curr_node_id

    # Traverse up the tree to find a node that can be retried
    Enum.reduce_while(0..parent_node_id, {new_parent_node_id, new_curr_node_id, solution_graph, current_state, blacklisted_commands}, fn _i, {p_id, _c_id, sg, cs, bc} -> # Fix unused _c_id
      node = Map.get(sg, p_id)
      case node.type do
        :T -> # Task
          if Enum.empty?(node.available_methods) do
            # No more methods, this task also fails, continue backtracking
            {:cont, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
          else
            # Found a task with available methods, retry it
            {:halt, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :O}), cs, bc}}
          end
        :G -> # Goal
          if Enum.empty?(node.available_methods) do
            # No more methods, this goal also fails, continue backtracking
            {:cont, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
          else
            # Found a goal with available methods, retry it
            {:halt, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :O}), cs, bc}}
          end
        :M -> # MultiGoal
          if Enum.empty?(node.available_methods) do
            # No more methods, this multigoal also fails, continue backtracking
            {:cont, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
          else
            # Found a multigoal with available methods, retry it
            {:halt, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :O}), cs, bc}}
          end
        :A -> # Action
          # Actions don't have alternative methods, so they always fail and cause backtracking
          {:cont, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
        _ -> # Other node types (D, VG, VM)
          {:cont, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
      end
    end)
  end
end
