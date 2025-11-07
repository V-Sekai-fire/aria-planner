# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Tasks.ScheduleActivities do
  @moduledoc """
  Task: t_schedule_activities(state)
  
  Schedule all activities respecting precedence constraints.
  
  Returns a list of subtasks to execute.
  """

  alias AriaPlanner.Domains.AircraftDisassembly

  @spec t_schedule_activities(map()) :: [tuple()]
  def t_schedule_activities(state) do
    if AircraftDisassembly.all_activities_completed?(state) do
      []
    else
      # Find next activity that can be started (ego-centric constraint checking)
      case find_next_activity(state) do
        nil ->
          []

        {activity, assigned_resources} ->
          current_time = Map.get(state, :current_time, 0)
          [{"c_start_activity", activity, current_time, assigned_resources}, {"t_schedule_activities", state}]
      end
    end
  end

  # Ego-centric constraint checking (persona's beliefs about the world)
  @spec find_next_activity(map()) :: nil | {integer(), [integer()]}
  defp find_next_activity(state) do
    num_activities = Map.get(state, :num_activities, 0)
    Enum.reduce_while(1..num_activities, nil, fn activity, _acc ->
      activity_id = "activity_#{activity}"
      status = get_activity_status(state, activity_id)
      
      if status == "not_started" do
        # Check all constraints from ego-centric perspective (beliefs)
        case check_activity_constraints_ego(state, activity) do
          {:ok, assigned_resources} ->
            {:halt, {activity, assigned_resources}}
          
          {:error, _reason} ->
            {:cont, nil}
        end
      else
        {:cont, nil}
      end
    end)
  end

  # Ego-centric constraint checking (persona's beliefs, may be incomplete)
  @spec check_activity_constraints_ego(map(), integer()) :: {:ok, [integer()]} | {:error, String.t()}
  defp check_activity_constraints_ego(state, activity) do
    current_time = Map.get(state, :current_time, 0)
    
    with :ok <- check_precedence_ego(state, activity),
         {:ok, assigned_resources} <- find_resources_with_skills_ego(state, activity),
         :ok <- check_resource_unavailable_ego(state, assigned_resources, current_time, activity),
         :ok <- check_location_capacity_ego(state, activity, current_time),
         :ok <- check_mass_balance_ego(state, activity, current_time),
         :ok <- check_unrelated_overlap_ego(state, activity, current_time) do
      {:ok, assigned_resources}
    else
      error -> error
    end
  end

  # Ego-centric constraint checks (based on persona's beliefs)

  @spec check_precedence_ego(map(), integer()) :: :ok | {:error, String.t()}
  defp check_precedence_ego(state, activity) do
    predecessors = AircraftDisassembly.get_predecessors(state, activity)
    
    all_completed = Enum.all?(predecessors, fn pred ->
      pred_id = "activity_#{pred}"
      get_activity_status(state, pred_id) == "completed"
    end)
    
    if all_completed do
      :ok
    else
      {:error, "Not all predecessors of activity #{activity} are completed (ego-centric belief)"}
    end
  end

  @spec find_resources_with_skills_ego(map(), integer()) :: {:ok, [integer()]} | {:error, String.t()}
  defp find_resources_with_skills_ego(state, activity) do
    skill_reqs = get_activity_skill_requirements(state, activity)
    num_skills = Map.get(state, :nSkills, 3)
    useful_res = get_useful_resources(state, activity)
    
    # Find resources that have the required skills (ego-centric: based on beliefs)
    assigned_resources = Enum.reduce(1..num_skills, [], fn skill_idx, acc ->
      required = get_skill_requirement(skill_reqs, activity, skill_idx, state)
      
      if required > 0 do
        # Find resources with this skill from useful_res set
        resources_with_skill = Enum.filter(useful_res, fn resource_id ->
          has_skill_capability?(state, resource_id, skill_idx)
        end)
        
        # Take required number of resources
        needed = required - length(acc)
        if needed > 0 do
          acc ++ Enum.take(resources_with_skill, needed)
        else
          acc
        end
      else
        acc
      end
    end)
    
    # Verify we have enough resources for all skills
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
    
    if skill_ok and length(assigned_resources) > 0 do
      {:ok, assigned_resources}
    else
      {:error, "Cannot find resources with required skills for activity #{activity} (ego-centric belief)"}
    end
  end

  @spec check_resource_unavailable_ego(map(), [integer()], integer(), integer()) :: :ok | {:error, String.t()}
  defp check_resource_unavailable_ego(state, assigned_resources, start_time, activity) do
    duration = get_activity_duration(state, activity)
    end_time = start_time + duration
    unavailable_periods = get_unavailable_periods(state)
    
    # Ego-centric: check based on beliefs about resource availability
    resource_available = Enum.all?(assigned_resources, fn resource_id ->
      resource_periods = Map.get(unavailable_periods, resource_id, [])
      Enum.all?(resource_periods, fn {unavail_start, unavail_end} ->
        end_time <= unavail_start or start_time >= unavail_end
      end)
    end)
    
    if resource_available do
      :ok
    else
      {:error, "Resources may be unavailable during activity #{activity} (ego-centric belief)"}
    end
  end

  @spec check_location_capacity_ego(map(), integer(), integer()) :: :ok | {:error, String.t()}
  defp check_location_capacity_ego(state, activity, start_time) do
    location = get_activity_location(state, activity)
    duration = get_activity_duration(state, activity)
    occupancy = get_activity_occupancy(state, activity)
    capacity = get_location_capacity(state, location)
    
    # Ego-centric: check based on beliefs about other activities
    overlapping_activities = find_overlapping_activities_at_location_ego(state, location, start_time, duration)
    total_occupancy = Enum.reduce(overlapping_activities, occupancy, fn other_activity, acc ->
      acc + get_activity_occupancy(state, other_activity)
    end)
    
    if total_occupancy <= capacity do
      :ok
    else
      {:error, "Location #{location} capacity may be exceeded (ego-centric belief)"}
    end
  end

  @spec check_mass_balance_ego(map(), integer(), integer()) :: :ok
  defp check_mass_balance_ego(state, activity, _start_time) do
    # Ego-centric: simplified check based on beliefs
    mass_consumption = get_activity_mass_consumption(state, activity)
    if mass_consumption == 0 do
      :ok
    else
      # Simplified: full implementation would check mass balance based on beliefs
      :ok
    end
  end

  @spec check_unrelated_overlap_ego(map(), integer(), integer()) :: :ok
  defp check_unrelated_overlap_ego(_state, _activity, _start_time) do
    # Ego-centric: simplified check based on beliefs
    :ok
  end

  # Helper functions for ego-centric constraint checking

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

  @spec get_useful_resources(map(), integer()) :: [integer()]
  defp get_useful_resources(state, activity) do
    # Get useful resources for this activity from USEFUL_RES array
    useful_res = Map.get(state, :useful_res, [])
    num_resources = Map.get(state, :num_resources, 0)
    idx = activity - 1
    case Enum.at(useful_res, idx) do
      %MapSet{} = resource_set -> MapSet.to_list(resource_set)
      list when is_list(list) -> list
      _ -> 1..num_resources |> Enum.to_list()
    end
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

  @spec get_activity_duration(map(), integer()) :: integer()
  defp get_activity_duration(state, activity) do
    idx = activity - 1
    durations = Map.get(state, :durations, [])
    Enum.at(durations, idx, 0)
  end

  @spec find_overlapping_activities_at_location_ego(map(), integer(), integer(), integer()) :: [integer()]
  defp find_overlapping_activities_at_location_ego(state, location, _start_time, _duration) do
    # Ego-centric: find activities based on beliefs about what's in progress
    num_activities = Map.get(state, :num_activities, 0)
    Enum.filter(1..num_activities, fn other_activity ->
      other_location = get_activity_location(state, other_activity)
      if other_location == location do
        other_activity_id = "activity_#{other_activity}"
        status = get_activity_status(state, other_activity_id)
        status == "in_progress"  # Based on beliefs
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
end

