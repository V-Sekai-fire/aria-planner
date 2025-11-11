# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassemblySolveTest do
  @moduledoc """
  Test that demonstrates solving an aircraft disassembly problem.
  """

  use ExUnit.Case, async: false

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Commands.{CompleteActivity, StartActivity}
  alias AriaPlanner.Planner.Blacklisting

  @problem_file "B737NG-600-09-Anon.json.dzn"
  @base_path Path.join([
    __DIR__,
    "../../../thirdparty/mznc2024_probs/aircraft-disassembly"
  ])

  @tag timeout: 30_000
  test "solves aircraft disassembly problem and shows solution" do
    problem_path = Path.join(@base_path, @problem_file)

    # Parse the problem file
    {:ok, params} = AircraftDisassembly.parse_dzn_file(problem_path)

    # Initialize state
    {:ok, state} = AircraftDisassembly.initialize_state(params)

    IO.puts("\n=== Aircraft Disassembly Problem Solution ===")
    IO.puts("Problem: #{@problem_file}")
    IO.puts("Activities: #{state.num_activities}")
    IO.puts("Resources: #{state.num_resources}")
    IO.puts("Precedences: #{length(state.precedences)}")
    IO.puts("\n=== Solution Sequence ===\n")

    # Solve by scheduling all activities with blacklisting
    blacklist_state = Blacklisting.new()
    solution = solve_activities(state, [], blacklist_state)

    IO.puts("\n=== Solution Summary ===")
    IO.puts("Total activities completed: #{length(solution)}")
    IO.puts("Solution sequence:")
    Enum.each(solution, fn {activity, start_time_iso, end_time_iso, duration_iso} ->
      start_time = iso8601_to_hours(start_time_iso)
      end_time = iso8601_to_hours(end_time_iso)
      duration = iso8601_duration_to_hours(duration_iso)
      IO.puts("  Activity #{activity}: start=#{start_time}, duration=#{duration}, end=#{end_time}")
    end)

    # Generate Gantt chart
    IO.puts("\n=== Gantt Chart ===")
    print_gantt_chart(solution)

    # Verify all activities are completed (convert ISO 8601 to hours for c_start_activity)
    final_state = Enum.reduce(solution, state, fn {activity, start_time_iso, _end_time_iso, _duration_iso}, acc ->
      start_time_hours = iso8601_to_hours(start_time_iso)
      {:ok, state1, _metadata1} = StartActivity.c_start_activity(acc, activity, start_time_hours, [])
      {:ok, state2, _metadata2} = CompleteActivity.c_complete_activity(state1, activity)
      state2
    end)

    assert AircraftDisassembly.all_activities_completed?(final_state)
    IO.puts("\n✓ All activities completed successfully!")
  end

  defp solve_activities(state, solution, blacklist_state) do
    if AircraftDisassembly.all_activities_completed?(state) do
      Enum.reverse(solution)
    else
      # Find next activity that can be started (skip blacklisted ones)
      next_activity = Enum.find(1..state.num_activities, fn activity ->
        activity_id = "activity_#{activity}"
        status = get_activity_status(state, activity_id)
        
        if status == "not_started" and AircraftDisassembly.all_predecessors_completed?(state, activity) do
          # Calculate start time to check if this command is blacklisted
          start_time_iso = calculate_start_time(state, activity, solution)
          start_time_hours = iso8601_to_hours(start_time_iso)
          
          # Find resources with required skills for this activity
          assigned_resources = case find_resources_with_skills(state, activity) do
            {:ok, resources} -> resources
            {:error, _reason} -> []
          end
          
          # Check if this command is blacklisted
          command = {"c_start_activity", [activity, start_time_hours, assigned_resources]}
          not Blacklisting.command_blacklisted?(blacklist_state, command)
        else
          false
        end
      end)

      if next_activity do
        # Calculate start time (after all predecessors complete) - returns ISO 8601 datetime string
        start_time_iso = calculate_start_time(state, next_activity, solution)
        # Convert ISO 8601 to hours for c_start_activity
        start_time_hours = iso8601_to_hours(start_time_iso)

        # Find resources with required skills for this activity
        assigned_resources = case find_resources_with_skills(state, next_activity) do
          {:ok, resources} -> resources
          {:error, _reason} -> []
        end

        # Check if command is blacklisted before trying
        command = {"c_start_activity", [next_activity, start_time_hours, assigned_resources]}
        
        if Blacklisting.command_blacklisted?(blacklist_state, command) do
          # Skip blacklisted command, try next activity
          solve_activities(state, solution, blacklist_state)
        else
          # Start and complete the activity
          case StartActivity.c_start_activity(state, next_activity, start_time_hours, assigned_resources) do
            {:ok, state_after_start, metadata1} ->
              {:ok, state_after_complete, _metadata2} = CompleteActivity.c_complete_activity(state_after_start, next_activity)

              # Extract start_time, end_time, and duration from metadata (all in ISO 8601 format)
              start_time_iso = metadata1.start_time
              end_time_iso = metadata1.end_time
              duration_iso = metadata1.duration

              # Convert to hours for display
              start_time_hours = iso8601_to_hours(start_time_iso)
              end_time_hours = iso8601_to_hours(end_time_iso)
              duration_hours = iso8601_duration_to_hours(duration_iso)
              IO.puts("Activity #{next_activity}: start=#{start_time_hours}, duration=#{duration_hours}, end=#{end_time_hours}")

              # Store ISO 8601 datetime strings and duration string in solution
              solve_activities(state_after_complete, [{next_activity, start_time_iso, end_time_iso, duration_iso} | solution], blacklist_state)
            {:error, reason} ->
              IO.puts("Error starting activity #{next_activity}: #{reason}")
              # Blacklist this command to prevent infinite retry
              new_blacklist = Blacklisting.blacklist_command(blacklist_state, command)
              IO.puts("Blacklisted command: c_start_activity(#{next_activity}, #{start_time_hours}, #{inspect(assigned_resources)})")
              
              # Check if all possible commands are blacklisted
              if Blacklisting.blacklisted_command_count(new_blacklist) >= state.num_activities * 10 do
                # Too many blacklisted commands, exit to prevent infinite loop
                IO.puts("Error: Too many commands blacklisted. Stopping.")
                Enum.reverse(solution)
              else
                solve_activities(state, solution, new_blacklist)
              end
          end
        end
      else
        # No more activities can be started (shouldn't happen if problem is solvable)
        IO.puts("Warning: No more activities can be started, but not all are completed")
        Enum.reverse(solution)
      end
    end
  end

  defp calculate_start_time(state, activity, solution) do
    predecessors = AircraftDisassembly.get_predecessors(state, activity)

    if Enum.empty?(predecessors) do
      # No predecessors - start at current time (convert hours to ISO 8601)
      hours_to_iso8601(state.current_time || 0)
    else
      # Start time is max(end_time of all predecessors) - all in ISO 8601 format
      max_end_time_iso = Enum.reduce(predecessors, nil, fn pred, acc ->
        # Find when this predecessor actually completed (ISO 8601 datetime string)
        case Enum.find(solution, fn {a, _, _, _} -> a == pred end) do
          {_pred_activity, _pred_start_iso, pred_end_iso, _pred_duration_iso} ->
            if acc do
              # Compare ISO 8601 datetime strings
              {:ok, pred_dt, _} = DateTime.from_iso8601(pred_end_iso)
              {:ok, acc_dt, _} = DateTime.from_iso8601(acc)
              if DateTime.compare(pred_dt, acc_dt) == :gt do
                pred_end_iso
              else
                acc
              end
            else
              pred_end_iso
            end
          nil ->
            # Predecessor not in solution yet (shouldn't happen if we check all_predecessors_completed?)
            # Fall back to duration-based estimate
            duration = get_activity_duration(state, pred)
            end_time_hours = (state.current_time || 0) + duration
            end_time_iso = hours_to_iso8601(end_time_hours)
            if acc do
              {:ok, end_dt, _} = DateTime.from_iso8601(end_time_iso)
              {:ok, acc_dt, _} = DateTime.from_iso8601(acc)
              if DateTime.compare(end_dt, acc_dt) == :gt do
                end_time_iso
              else
                acc
              end
            else
              end_time_iso
            end
        end
      end)
      
      # Ensure we don't start before current time
      current_time_iso = hours_to_iso8601(state.current_time || 0)
      if max_end_time_iso do
        {:ok, max_dt, _} = DateTime.from_iso8601(max_end_time_iso)
        {:ok, current_dt, _} = DateTime.from_iso8601(current_time_iso)
        if DateTime.compare(max_dt, current_dt) == :gt do
          max_end_time_iso
        else
          current_time_iso
        end
      else
        current_time_iso
      end
    end
  end

  defp get_activity_status(state, activity_id) do
    case Map.get(state, :facts, %{}) do
      facts when is_map(facts) ->
        case Map.get(facts, "activity_status", %{}) do
          status_map when is_map(status_map) ->
            Map.get(status_map, activity_id, "not_started")
          _ ->
            "not_started"
        end
      _ ->
        "not_started"
    end
  end

  defp get_activity_duration(state, activity) do
    # Get duration from state.durations map (indexed from 0)
    idx = activity - 1
    Enum.at(state.durations || [], idx, 0)
  end

  defp find_resources_with_skills(state, activity) do
    num_skills = Map.get(state, :nSkills, 3)
    sreq = Map.get(state, :sreq, [])
    useful_res = get_useful_resources(state, activity)
    
    # Get skill requirements for this activity
    skill_reqs = get_activity_skill_requirements(state, activity)
    
    # Find resources that have the required skills
    assigned_resources = Enum.reduce(1..num_skills, [], fn skill_idx, acc ->
      required = get_skill_requirement(skill_reqs, activity, skill_idx, state)
      
      if required > 0 do
        # Find resources with this skill from useful_res set
        resources_with_skill = Enum.filter(useful_res, fn resource_id ->
          has_skill_capability?(state, resource_id, skill_idx)
        end)
        
        # Take required number of resources (avoid duplicates)
        needed = required - Enum.count(acc, fn r -> has_skill_capability?(state, r, skill_idx) end)
        if needed > 0 do
          available = Enum.reject(resources_with_skill, fn r -> r in acc end)
          acc ++ Enum.take(available, needed)
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
      {:error, "Cannot find resources with required skills for activity #{activity}"}
    end
  end

  defp get_activity_skill_requirements(state, activity) do
    num_skills = Map.get(state, :nSkills, 3)
    sreq = Map.get(state, :sreq, [])
    start_idx = (activity - 1) * num_skills
    Enum.slice(sreq, start_idx, num_skills)
  end

  defp get_skill_requirement(_skill_reqs, activity, skill_idx, state) do
    num_skills = Map.get(state, :nSkills, 3)
    sreq = Map.get(state, :sreq, [])
    idx = (activity - 1) * num_skills + (skill_idx - 1)
    Enum.at(sreq, idx, 0)
  end

  defp has_skill_capability?(state, resource_id, skill_idx) do
    num_skills = Map.get(state, :nSkills, 3)
    mastery = Map.get(state, :mastery, [])
    idx = (resource_id - 1) * num_skills + (skill_idx - 1)
    Enum.at(mastery, idx, false)
  end

  defp get_useful_resources(state, activity) do
    useful_res = Map.get(state, :useful_res, [])
    num_resources = Map.get(state, :num_resources, 0)
    idx = activity - 1
    case Enum.at(useful_res, idx) do
      %MapSet{} = resource_set -> MapSet.to_list(resource_set)
      list when is_list(list) -> list
      _ -> 1..num_resources |> Enum.to_list()
    end
  end

  defp print_gantt_chart(solution) do
    # Sort solution by start time, then by activity ID (convert ISO 8601 to hours for comparison)
    sorted = Enum.sort(solution, fn {a1, s1_iso, _, _}, {a2, s2_iso, _, _} ->
      s1 = iso8601_to_hours(s1_iso)
      s2 = iso8601_to_hours(s2_iso)
      if s1 == s2, do: a1 < a2, else: s1 < s2
    end)

    # Find max end time (convert ISO 8601 to hours)
    max_time = Enum.reduce(sorted, 0, fn {_activity, _start_time_iso, end_time_iso, _duration_iso}, acc ->
      end_time = iso8601_to_hours(end_time_iso)
      max(acc, end_time)
    end)

    # Scale: each character represents 1 time unit, but we'll compress for large timelines
    scale = if max_time > 100, do: 2, else: 1
    chart_width = div(max_time, scale) + 10

    IO.puts("\nTimeline (each '=' represents #{scale} time unit(s), max time: #{max_time}):")
    IO.puts(String.duplicate("=", min(chart_width, 120)))
    IO.puts("")

    # Group activities by start time for better visualization (convert ISO 8601 to hours)
    grouped = Enum.group_by(sorted, fn {_activity, start_time_iso, _, _} -> iso8601_to_hours(start_time_iso) end)

    # Print activities
    Enum.each(Enum.sort(Map.keys(grouped)), fn start_time_hours ->
      activities = Map.get(grouped, start_time_hours)
      Enum.each(activities, fn {activity, s_iso, e_iso, d_iso} ->
        s = iso8601_to_hours(s_iso)
        e = iso8601_to_hours(e_iso)
        d = iso8601_duration_to_hours(d_iso)
        bar_length = max(1, div(d, scale))
        bar = String.duplicate("█", min(bar_length, 100))
        spaces = String.duplicate(" ", min(div(s, scale), 100))
        IO.puts("Activity #{String.pad_leading(Integer.to_string(activity), 3, " ")}: #{spaces}#{bar} (#{s}→#{e})")
      end)
    end)

    # Print timeline markers
    IO.puts("")
    timeline_markers = Enum.map(0..min(div(max_time, scale), 20), fn i ->
      if rem(i * scale, 10) == 0, do: "|", else: " "
    end) |> Enum.join("")
    IO.puts("Time:  " <> timeline_markers)
    timeline_numbers = Enum.map(0..min(div(max_time, scale), 20), fn i ->
      if rem(i * scale, 10) == 0, do: Integer.to_string(i * scale), else: "   "
    end) |> Enum.join("")
    IO.puts("       " <> timeline_numbers)
  end

  defp hours_to_iso8601(hours) do
    base_datetime = ~U[2025-01-01 00:00:00Z]
    datetime = Timex.shift(base_datetime, hours: hours)
    DateTime.to_iso8601(datetime)
  end

  defp iso8601_to_hours(iso8601_string) do
    base_datetime = ~U[2025-01-01 00:00:00Z]
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601_string)
    diff = Timex.diff(datetime, base_datetime, :hours)
    diff
  end

  defp iso8601_duration_to_hours(iso8601_duration_string) do
    # Parse ISO 8601 duration string (e.g., "PT3H") to hours
    case Timex.Duration.parse(iso8601_duration_string) do
      {:ok, %Timex.Duration{} = duration} ->
        # Convert duration to hours
        microseconds = Timex.Duration.to_microseconds(duration)
        div(microseconds, 3_600_000_000)  # Convert microseconds to hours
      _ ->
        0
    end
  end
end
