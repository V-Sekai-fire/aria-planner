# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Commands.StartActivity do
  @moduledoc """
  Command: c_start_activity(activity, current_time)
  
  Start an activity.
  
  Preconditions:
  - Activity status is "not_started"
  - All predecessors are completed
  - Sufficient resources available (simplified for now)
  
  Effects:
  - activity_status[activity] = "in_progress"
  - activity_start[activity] = current_time
  """

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.{
    ActivityStart,
    ActivityStatus
  }

  @spec c_start_activity(state :: map(), activity :: integer(), current_time :: integer()) ::
          {:ok, map()} | {:error, String.t()}
  def c_start_activity(state, activity, current_time) do
    with :ok <- check_activity_not_started(state, activity),
         :ok <- check_predecessors_completed(state, activity) do
      new_state =
        state
        |> ActivityStatus.set(activity, "in_progress")
        |> ActivityStart.set(activity, current_time)
        |> Map.put(:current_time, current_time)

      {:ok, new_state}
    else
      error -> error
    end
  end

  # Private helper functions

  defp check_activity_not_started(state, activity) do
    status = ActivityStatus.get(state, activity)
    if status == "not_started" do
      :ok
    else
      {:error, "Activity #{activity} is already started (status: #{status})"}
    end
  end

  defp check_predecessors_completed(state, activity) do
    if AircraftDisassembly.all_predecessors_completed?(state, activity) do
      :ok
    else
      {:error, "Not all predecessors of activity #{activity} are completed"}
    end
  end
end

