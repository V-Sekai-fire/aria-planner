# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Multigoals.ScheduleActivities do
  @moduledoc """
  Multigoal: m_schedule_activities(state)

  Schedule all activities respecting precedence constraints (goal-based).

  Returns a list of goals to achieve.
  """

  @spec m_schedule_activities(state :: map()) :: [tuple()]
  def m_schedule_activities(state) do
    # Return goals for all activities to be completed
    # Use activity_id format for planner's state facts
    num_activities = Map.get(state, :num_activities, 0)

    goals =
      for activity <- 1..num_activities do
        activity_id = "activity_#{activity}"
        {"activity_status", [activity_id, "completed"]}
      end

    goals
  end
end
