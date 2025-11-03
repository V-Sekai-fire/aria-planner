# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Tasks.ScheduleTasks do
  @moduledoc """
  Task: t_schedule_tasks()

  Calculate the PERT schedule for all tasks.

  This task triggers the calculation of earliest and latest start/finish times
  for all tasks in the project using the forward and backward pass algorithms.

  Returns: [{"calculate_schedule"}]
  """

  @spec t_schedule_tasks() :: [tuple()]
  def t_schedule_tasks do
    [{"calculate_schedule"}]
  end
end
