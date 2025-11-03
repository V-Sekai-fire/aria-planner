# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Tasks.PlanProject do
  @moduledoc """
  Task: t_plan_project()

  Main entry point for planning a PERT project.

  This task decomposes the overall project planning into:
  1. Calculate the PERT schedule (earliest/latest times)
  2. Complete all tasks in dependency order

  Returns: [{"t_schedule_tasks"}, {"t_complete_all_tasks"}]
  """

  @spec t_plan_project() :: [tuple()]
  def t_plan_project do
    [{"t_schedule_tasks"}, {"t_complete_all_tasks"}]
  end
end
