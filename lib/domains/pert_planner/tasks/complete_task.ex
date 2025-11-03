# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Tasks.CompleteTask do
  @moduledoc """
  Task: t_complete_task(task_id)

  Complete a specific task.

  This task decomposes into:
  1. Start the task (if not already started)
  2. Complete the task

  Returns: [{"start_task", task_id}, {"complete_task", task_id}]
  """

  @spec t_complete_task(task_id :: String.t()) :: [tuple()]
  def t_complete_task(task_id) do
    [{"start_task", task_id}, {"complete_task", task_id}]
  end
end
