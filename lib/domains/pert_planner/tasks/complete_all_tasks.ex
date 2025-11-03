# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Tasks.CompleteAllTasks do
  @moduledoc """
  Task: t_complete_all_tasks()

  Complete all tasks in the project using planner backtracking.

  This task decomposes into subtasks to complete each task. The planner
  will attempt these in some order, and backtrack when unigoal methods
  detect that dependencies aren't satisfied (gm_complete_task returns nil).
  This leverages HTN planning's natural backtracking rather than manual
  topological sorting.

  Returns: [{"t_complete_task", task_id1}, {"t_complete_task", task_id2}, ...]
  """

  import Ecto.Query
  alias AriaPlanner.Domains.PertPlanner.Predicates.TaskStatus
  alias AriaPlanner.Repo

  @spec t_complete_all_tasks() :: [tuple()]
  def t_complete_all_tasks do
    # Get all tasks and try to complete them
    # The planner will backtrack when dependencies aren't satisfied
    all_tasks = Repo.all(from t in TaskStatus, select: t.task_id)

    # Return subtasks to complete all tasks - planner handles ordering via backtracking
    Enum.map(all_tasks, fn task_id -> {"t_complete_task", task_id} end)
  end
end
