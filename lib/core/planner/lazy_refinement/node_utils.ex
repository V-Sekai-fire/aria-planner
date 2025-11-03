# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.LazyRefinement.NodeUtils do
  @moduledoc """
  Helper functions for node-related utilities in lazy plan refinement.
  """

  alias AriaCore.Planner.State
  alias AriaCore.Planner.MultiGoal

  def get_node_type(node_info, methods, actions) do
    cond do
      is_struct(node_info, MultiGoal) -> :M
      is_tuple(node_info) and elem(node_info, 0) in methods.task_method_dict -> :T
      is_tuple(node_info) and elem(node_info, 0) in actions.action_dict -> :A
      is_tuple(node_info) and elem(node_info, 0) in methods.goal_method_dict -> :G
      true -> :unknown # Should not happen if all types are covered
    end
  end

  def goals_not_achieved(multigoal_info, current_state) do
    Enum.reduce(multigoal_info.goals, [], fn {subject_id, predicate_table, desired_val}, acc ->
      if State.get_fact(current_state, subject_id, predicate_table) == desired_val do
        acc
      else
        acc ++ [{subject_id, predicate_table, desired_val}]
      end
    end)
  end
end
