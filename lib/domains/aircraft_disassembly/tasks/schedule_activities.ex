# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Tasks.ScheduleActivities do
  @moduledoc """
  Task: t_schedule_activities(state)
  
  Schedule all activities respecting precedence constraints.
  
  Returns a list of subtasks to execute.
  """

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.ActivityStatus

  @spec t_schedule_activities(state :: map()) :: [tuple()]
  def t_schedule_activities(state) do
    if AircraftDisassembly.all_activities_completed?(state) do
      []
    else
      # Find next activity that can be started (all predecessors completed)
      case find_next_activity(state) do
        nil ->
          []

        activity ->
          current_time = state.current_time || 0
          [{"c_start_activity", activity, current_time}, {"t_schedule_activities", state}]
      end
    end
  end

  defp find_next_activity(state) do
    Enum.find(1..state.num_activities, fn activity ->
      status = ActivityStatus.get(state, activity)
      status == "not_started" and AircraftDisassembly.all_predecessors_completed?(state, activity)
    end)
  end
end

