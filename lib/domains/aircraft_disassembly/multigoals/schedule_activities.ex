# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Multigoals.ScheduleActivities do
  @moduledoc """
  Multigoal: m_schedule_activities(state)
  
  Schedule all activities respecting precedence constraints (goal-based).
  
  Returns a list of goals to achieve.
  """

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.ActivityStatus

  @spec m_schedule_activities(state :: map()) :: [tuple()]
  def m_schedule_activities(state) do
    # Return goals for all activities to be completed
    goals =
      for activity <- 1..state.num_activities do
        {"activity_status", [activity, "completed"]}
      end

    goals
  end
end

