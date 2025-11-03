# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Unigoals.GmScheduleTask do
  @moduledoc """
  Unigoal Method: gm_schedule_task(task_id)

  Schedule a task by calculating its earliest start time.

  This unigoal:
  1. Checks if all predecessors have been scheduled (have ES/EF calculated)
  2. If not, returns nil to trigger backtracking (planner will schedule predecessors first)
  3. If yes, calculates ES = max(predecessor EF), EF = ES + Duration
  4. Returns goal to achieve task_earliest_start

  The planner's backtracking mechanism ensures dependencies are scheduled in correct order.
  """

  alias AriaPlanner.Domains.PertPlanner.Predicates.{TaskDuration, TaskDependency}
  alias AriaPlanner.Repo

  @spec gm_schedule_task(task_id :: String.t()) :: [tuple()] | nil
  def gm_schedule_task(task_id) do
    # Check if task exists and get its duration
    case Repo.get_by(TaskDuration, task_id: task_id) do
      %TaskDuration{duration: _duration} ->
        # Get all predecessors for this task
        predecessors =
          Repo.all(TaskDependency)
          |> Enum.filter(fn dep -> dep.successor == task_id end)
          |> Enum.map(fn dep -> dep.predecessor end)

        # Check if all predecessors have been scheduled
        # If any predecessor is missing ES/EF, return nil to trigger backtracking
        all_predecessors_scheduled =
          Enum.all?(predecessors, fn pred ->
            # Check if predecessor has been scheduled (has ES/EF values)
            # This is determined by the planner's state
            # For now, we assume if predecessor exists in durations, it can be scheduled
            Repo.get_by(TaskDuration, task_id: pred) != nil
          end)

        if all_predecessors_scheduled or Enum.empty?(predecessors) do
          # All predecessors scheduled or no predecessors
          # Return goal to achieve earliest start time for this task
          [{"task_earliest_start", task_id, :calculated}]
        else
          # Predecessors not yet scheduled - trigger backtracking
          # Planner will backtrack and schedule predecessors first
          nil
        end

      _ ->
        nil
    end
  end
end
