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
    # Mark current node as failed
    solution_graph = Map.put(solution_graph, curr_node_id, %{curr_node | status: :F})

    # Remove descendants of the failed node
    solution_graph = GraphOperations.remove_descendants(solution_graph, curr_node_id)

    # Find the nearest ancestor that can be refined (has available methods or actions)
    # This is a simplified version of IPyHOP's _backtrack
    new_parent_node_id = parent_node_id
    # Fix unused new_curr_node_id
    new_curr_node_id = curr_node_id

    # Traverse up the tree to find a node that can be retried
    # Fix unused _c_id
    Enum.reduce_while(
      0..parent_node_id,
      {new_parent_node_id, new_curr_node_id, solution_graph, current_state, blacklisted_commands},
      fn _i, {p_id, _c_id, sg, cs, bc} ->
        node = Map.get(sg, p_id)

        case node.type do
          # Task
          :T ->
            if Enum.empty?(node.available_methods) do
              # No more methods, this task also fails, continue backtracking
              {:cont,
               {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
            else
              # Found a task with available methods, retry it
              {:halt,
               {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :O}), cs, bc}}
            end

          # Goal
          :G ->
            if Enum.empty?(node.available_methods) do
              # No more methods, this goal also fails, continue backtracking
              {:cont,
               {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
            else
              # Found a goal with available methods, retry it
              {:halt,
               {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :O}), cs, bc}}
            end

          # MultiGoal
          :M ->
            if Enum.empty?(node.available_methods) do
              # No more methods, this multigoal also fails, continue backtracking
              {:cont,
               {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
            else
              # Found a multigoal with available methods, retry it
              {:halt,
               {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :O}), cs, bc}}
            end

          # Action
          :A ->
            # Actions don't have alternative methods, so they always fail and cause backtracking
            {:cont, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}

          # Other node types (D, VG, VM)
          _ ->
            {:cont, {GraphOperations.find_predecessor(sg, p_id), p_id, Map.put(sg, p_id, %{node | status: :F}), cs, bc}}
        end
      end
    )
  end
end
