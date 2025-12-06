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
      # Should not happen if all types are covered
      true -> :unknown
    end
  end

  def goals_not_achieved(multigoal_info, current_state) do
    Enum.reduce(multigoal_info.goals, [], fn goal, acc ->
      # Support new goal format: {predicate_table, [subject_id, desired_val]}
      case goal do
        {predicate_table, args} when is_list(args) ->
          [subject_id, desired_val] = args

          if State.get_fact_by_predicate(current_state, predicate_table, subject_id) == desired_val do
            acc
          else
            acc ++ [{predicate_table, args}]
          end

        # Legacy format support: {subject_id, predicate_table, desired_val}
        {subject_id, predicate_table, desired_val} when is_binary(subject_id) or is_atom(subject_id) ->
          if State.get_fact(current_state, subject_id, predicate_table) == desired_val do
            acc
          else
            acc ++ [{subject_id, predicate_table, desired_val}]
          end

        _ ->
          # Unknown format, treat as not achieved
          acc ++ [goal]
      end
    end)
  end
end
