# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Unigoals.GmCompleteTask do
  @moduledoc """
  Unigoal Method: gm_complete_task(task_id)

  Complete a task by ensuring it reaches 'completed' status.

  Returns goals to achieve task_status = 'completed' for the given task.
  This may involve starting the task first if it's not already in progress.
  """

  import Ecto.Query
  alias AriaPlanner.Domains.PertPlanner.Predicates.{TaskStatus, TaskDependency}
  alias AriaPlanner.Repo

  @spec gm_complete_task(task_id :: String.t()) :: [tuple()] | nil
  def gm_complete_task(task_id) do
    # Check current task status
    case Repo.get_by(TaskStatus, task_id: task_id) do
      %TaskStatus{status: "completed"} ->
        # Already completed, no goals needed
        []
      %TaskStatus{status: "in_progress"} ->
        # Currently in progress, just need to complete it
        [{"complete_task", task_id}]
      %TaskStatus{status: "not_started"} ->
        # Need to start and complete it
        # Check if all predecessors are completed first
        if all_predecessors_completed?(task_id) do
          [{"start_task", task_id}, {"complete_task", task_id}]
        else
          nil  # Cannot complete until predecessors are done (trigger backtracking)
        end
      _ ->
        nil  # Task doesn't exist
    end
  end

  # Check if all predecessor tasks are completed
  @spec all_predecessors_completed?(task_id :: String.t()) :: boolean()
  defp all_predecessors_completed?(task_id) do
    # Get all predecessors for this task
    predecessors = Repo.all(from d in TaskDependency, where: d.successor == ^task_id, select: d.predecessor)

    # Check if all predecessors are completed
    Enum.all?(predecessors, fn pred_id ->
      case Repo.get_by(TaskStatus, task_id: pred_id) do
        %TaskStatus{status: "completed"} -> true
        _ -> false
      end
    end)
  end
end
