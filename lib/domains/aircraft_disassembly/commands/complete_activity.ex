# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Commands.CompleteActivity do
  @moduledoc """
  Command: c_complete_activity(activity)
  
  Complete an activity.
  
  Preconditions:
  - Activity status is "in_progress"
  - Activity duration has elapsed (simplified - just check status)
  
  Effects:
  - activity_status[activity] = "completed"
  """

  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.ActivityStatus

  @spec c_complete_activity(state :: map(), activity :: integer()) ::
          {:ok, map()} | {:error, String.t()}
  def c_complete_activity(state, activity) do
    with :ok <- check_activity_in_progress(state, activity) do
      new_state = ActivityStatus.set(state, activity, "completed")
      {:ok, new_state}
    else
      error -> error
    end
  end

  # Private helper functions

  defp check_activity_in_progress(state, activity) do
    status = ActivityStatus.get(state, activity)
    if status == "in_progress" do
      :ok
    else
      {:error, "Activity #{activity} is not in progress (status: #{status})"}
    end
  end
end

