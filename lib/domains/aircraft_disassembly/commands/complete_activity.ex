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

  alias AriaPlanner.Planner.PlannerMetadata
  alias AriaPlanner.Planner.MetadataHelpers

  @spec c_complete_activity(state :: map(), activity :: integer()) ::
          {:ok, map(), PlannerMetadata.t()} | {:error, String.t()}
  def c_complete_activity(state, activity) do
    with :ok <- check_activity_in_progress(state, activity) do
      # Update state: set activity status to "completed" using facts
      activity_id = "activity_#{activity}"
      new_state = update_activity_status(state, activity_id, "completed")
      
      # Return planner metadata - completion is instant
      metadata = MetadataHelpers.instant_metadata("worker", [:disassembly])
      
      {:ok, new_state, metadata}
    else
      error -> error
    end
  end

  # Private helper functions

  @spec check_activity_in_progress(map(), integer()) :: :ok | {:error, String.t()}
  defp check_activity_in_progress(state, activity) do
    activity_id = "activity_#{activity}"
    status = get_activity_status(state, activity_id)
    if status == "in_progress" do
      :ok
    else
      {:error, "Activity #{activity} is not in progress (status: #{status})"}
    end
  end

  @spec get_activity_status(map(), String.t()) :: String.t()
  defp get_activity_status(state, activity_id) do
    # Use planner's state facts system
    case Map.get(state, :facts, %{}) do
      facts when is_map(facts) ->
        case Map.get(facts, "activity_status", %{}) do
          status_map when is_map(status_map) ->
            Map.get(status_map, activity_id, "not_started")
          _ ->
            "not_started"
        end
      _ ->
        # Fallback to old state structure
        Map.get(state.activity_status || %{}, String.to_integer(String.replace(activity_id, "activity_", "")), "not_started")
    end
  end

  @spec update_activity_status(map(), String.t(), String.t()) :: map()
  defp update_activity_status(state, activity_id, status) do
    # Update using planner's state facts system
    facts = Map.get(state, :facts, %{})
    activity_status_facts = Map.get(facts, "activity_status", %{})
    updated_activity_status = Map.put(activity_status_facts, activity_id, status)
    updated_facts = Map.put(facts, "activity_status", updated_activity_status)
    Map.put(state, :facts, updated_facts)
  end
end

