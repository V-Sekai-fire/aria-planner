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
  alias AriaPlanner.Planner.PlannerMetadata
  alias AriaPlanner.Planner.MetadataHelpers
  use Timex

  @spec c_start_activity(state :: map(), activity :: integer(), current_time :: integer(), list()) ::
          {:ok, map(), PlannerMetadata.t()} | {:error, String.t()}
  def c_start_activity(state, activity, current_time, assigned_resources \\ []) do
    with :ok <- check_activity_not_started(state, activity),
         :ok <- check_precedence_constraints(state, activity),
         :ok <- check_resource_skill_requirements(state, activity, assigned_resources),
         :ok <- check_resource_unavailable(state, assigned_resources, current_time, activity),
         :ok <- check_location_capacity(state, activity, current_time),
         :ok <- check_mass_balance(state, activity, current_time),
         :ok <- check_unrelated_overlap(state, activity, current_time) do
      # Get duration from state (in hours)
      duration_hours = get_activity_duration(state, activity)
      
      # Calculate start and end times
      start_datetime = hours_to_datetime(current_time)
      end_datetime = hours_to_datetime(current_time + duration_hours)
      
      # Update state: set activity status to "in_progress" using facts
      activity_id = "activity_#{activity}"
      new_state = update_activity_status(state, activity_id, "in_progress")
      new_state = Map.put(new_state, :current_time, current_time)

      # Map MiniZinc skills to entity capabilities
      # Skills are typically: skill1 (mechanical), skill2 (electrical), skill3 (specialized)
      required_capabilities = get_required_capabilities(state, activity)
      
      # Return planner metadata with temporal constraints (hours)
      duration_iso = "PT#{duration_hours}H"
      
      metadata = MetadataHelpers.command_metadata(
        duration_iso,
        "worker",
        required_capabilities,
        start_time: DateTime.to_iso8601(start_datetime),
        end_time: DateTime.to_iso8601(end_datetime)
      )

      {:ok, new_state, metadata}
    else
      error -> error
    end
  end

  # Private helper functions

  @spec check_activity_not_started(map(), integer()) :: :ok | {:error, String.t()}
  defp check_activity_not_started(state, activity) do
    activity_id = "activity_#{activity}"
    status = get_activity_status(state, activity_id)
    if status == "not_started" do
      :ok
    else
      {:error, "Activity #{activity} is already started (status: #{status})"}
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

  @spec get_activity_duration(map(), integer()) :: integer()
  defp get_activity_duration(state, activity) do
    # Get duration from state.durations map (indexed from 0)
    idx = activity - 1
    durations = Map.get(state, :durations, [])
    Enum.at(durations, idx, 0)
  end

  @spec hours_to_datetime(integer()) :: DateTime.t()
  defp hours_to_datetime(hours) do
    # Convert hours (integer) to DateTime
    # Use a reference datetime (e.g., epoch) and add hours
    base_datetime = ~U[2025-01-01 00:00:00Z]
    Timex.shift(base_datetime, hours: hours)
  end

  @spec get_required_capabilities(map(), integer()) :: [atom()]
  defp get_required_capabilities(state, activity) do
    # Map MiniZinc skills to entity capabilities
    # skill1 -> :mechanical, skill2 -> :electrical, skill3 -> :specialized
    skill_reqs = get_activity_skill_requirements(state, activity)
    num_skills = Map.get(state, :nSkills, 3)
    
    capabilities = []
    capabilities = if Enum.at(skill_reqs, 0, 0) > 0, do: [:mechanical | capabilities], else: capabilities
    capabilities = if num_skills >= 2 and Enum.at(skill_reqs, 1, 0) > 0, do: [:electrical | capabilities], else: capabilities
    capabilities = if num_skills >= 3 and Enum.at(skill_reqs, 2, 0) > 0, do: [:specialized | capabilities], else: capabilities
    
    # Default to disassembly if no specific skills
    if Enum.empty?(capabilities), do: [:disassembly, :mechanical], else: capabilities
  end

  # Constraint checking functions (planner todo type - preconditions)

  @spec check_precedence_constraints(map(), integer()) :: :ok | {:error, String.t()}
  defp check_precedence_constraints(state, activity) do
    predecessors = AircraftDisassembly.get_predecessors(state, activity)
    
    all_completed = Enum.all?(predecessors, fn pred ->
      pred_id = "activity_#{pred}"
      get_activity_status(state, pred_id) == "completed"
    end)
    
    if all_completed do
      :ok
    else
      {:error, "Not all predecessors of activity #{activity} are completed"}
    end
  end

  @spec check_resource_skill_requirements(map(), integer(), [integer()]) :: :ok | {:error, String.t()}
  defp check_resource_skill_requirements(state, activity, assigned_resources) do
    skill_reqs = get_activity_skill_requirements(state, activity)
    num_skills = Map.get(state, :nSkills, 3)
    
    skill_ok = Enum.all?(1..num_skills, fn skill_idx ->
      required = get_skill_requirement(skill_reqs, activity, skill_idx, state)
      
      if required > 0 do
        skill_count = Enum.count(assigned_resources, fn resource_id ->
          has_skill_capability?(state, resource_id, skill_idx)
        end)
        skill_count >= required
      else
        true
      end
    end)
    
    if skill_ok do
      :ok
    else
      {:error, "Insufficient resources with required skills for activity #{activity}"}
    end
  end

  @spec check_resource_unavailable(map(), [integer()], integer(), integer()) :: :ok | {:error, String.t()}
  defp check_resource_unavailable(state, assigned_resources, start_time, activity) do
    duration = get_activity_duration(state, activity)
    end_time = start_time + duration
    unavailable_periods = get_unavailable_periods(state)
    
    resource_available = Enum.all?(assigned_resources, fn resource_id ->
      resource_periods = Map.get(unavailable_periods, resource_id, [])
      Enum.all?(resource_periods, fn {unavail_start, unavail_end} ->
        end_time <= unavail_start or start_time >= unavail_end
      end)
    end)
    
    if resource_available do
      :ok
    else
      {:error, "Assigned resources are unavailable during activity #{activity} time window"}
    end
  end

  @spec check_location_capacity(map(), integer(), integer()) :: :ok | {:error, String.t()}
  defp check_location_capacity(state, activity, start_time) do
    location = get_activity_location(state, activity)
    duration = get_activity_duration(state, activity)
    occupancy = get_activity_occupancy(state, activity)
    capacity = get_location_capacity(state, location)
    
    overlapping_activities = find_overlapping_activities_at_location(state, location, start_time, duration)
    total_occupancy = Enum.reduce(overlapping_activities, occupancy, fn other_activity, acc ->
      acc + get_activity_occupancy(state, other_activity)
    end)
    
    if total_occupancy <= capacity do
      :ok
    else
      {:error, "Location #{location} capacity exceeded for activity #{activity}"}
    end
  end

  @spec check_mass_balance(map(), integer(), integer()) :: :ok
  defp check_mass_balance(state, activity, _start_time) do
    mass_consumption = get_activity_mass_consumption(state, activity)
    if mass_consumption == 0 do
      :ok
    else
      # Simplified: full implementation would track mass levels over time
      :ok
    end
  end

  @spec check_unrelated_overlap(map(), integer(), integer()) :: :ok
  defp check_unrelated_overlap(_state, _activity, _start_time) do
    # Simplified: full implementation would check unrelated activity pairs
    :ok
  end

  # Helper functions for constraint checking

  @spec get_activity_skill_requirements(map(), integer()) :: [integer()]
  defp get_activity_skill_requirements(state, activity) do
    num_skills = Map.get(state, :nSkills, 3)
    sreq = Map.get(state, :sreq, [])
    start_idx = (activity - 1) * num_skills
    Enum.slice(sreq, start_idx, num_skills)
  end

  @spec get_skill_requirement([integer()], integer(), integer(), map()) :: integer()
  defp get_skill_requirement(_skill_reqs, activity, skill_idx, state) do
    num_skills = Map.get(state, :nSkills, 3)
    sreq = Map.get(state, :sreq, [])
    idx = (activity - 1) * num_skills + (skill_idx - 1)
    Enum.at(sreq, idx, 0)
  end

  @spec has_skill_capability?(map(), integer(), integer()) :: boolean()
  defp has_skill_capability?(state, resource_id, skill_idx) do
    num_skills = Map.get(state, :nSkills, 3)
    mastery = Map.get(state, :mastery, [])
    idx = (resource_id - 1) * num_skills + (skill_idx - 1)
    Enum.at(mastery, idx, false)
  end

  @spec get_unavailable_periods(map()) :: %{integer() => [{integer(), integer()}]}
  defp get_unavailable_periods(state) do
    unavailable_resources = Map.get(state, :unavailable_resource, [])
    unavailable_starts = Map.get(state, :unavailable_start, [])
    unavailable_ends = Map.get(state, :unavailable_end, [])
    
    unavailable_resources
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {resource_id, idx}, acc ->
      start_time = Enum.at(unavailable_starts, idx, 0)
      end_time = Enum.at(unavailable_ends, idx, 0)
      periods = Map.get(acc, resource_id, [])
      Map.put(acc, resource_id, [{start_time, end_time} | periods])
    end)
  end

  @spec get_activity_location(map(), integer()) :: integer()
  defp get_activity_location(state, activity) do
    idx = activity - 1
    locations = Map.get(state, :locations, [])
    Enum.at(locations, idx, 1)
  end

  @spec get_activity_occupancy(map(), integer()) :: integer()
  defp get_activity_occupancy(state, activity) do
    idx = activity - 1
    occupancy = Map.get(state, :occupancy, [])
    Enum.at(occupancy, idx, 1)
  end

  @spec get_location_capacity(map(), integer()) :: integer()
  defp get_location_capacity(state, location) do
    idx = location - 1
    location_capacities = Map.get(state, :location_capacities, [])
    Enum.at(location_capacities, idx, 1)
  end

  @spec find_overlapping_activities_at_location(map(), integer(), integer(), integer()) :: [integer()]
  defp find_overlapping_activities_at_location(state, location, _start_time, _duration) do
    num_activities = Map.get(state, :num_activities, 0)
    Enum.filter(1..num_activities, fn other_activity ->
      other_location = get_activity_location(state, other_activity)
      if other_location == location do
        other_activity_id = "activity_#{other_activity}"
        status = get_activity_status(state, other_activity_id)
        status == "in_progress"
      else
        false
      end
    end)
  end

  @spec get_activity_mass_consumption(map(), integer()) :: integer()
  defp get_activity_mass_consumption(state, activity) do
    idx = activity - 1
    mass = Map.get(state, :mass, [])
    Enum.at(mass, idx, 0)
  end
end

