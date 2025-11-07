# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassemblyPertTextbookTest do
  @moduledoc """
  Tests the aircraft_disassembly domain with a classic textbook PERT problem.

  This is a simple 5-activity project scheduling problem commonly used in
  textbooks to illustrate PERT/CPM (Critical Path Method) concepts.

  Activities:
  - A: duration 3, no predecessors
  - B: duration 2, no predecessors
  - C: duration 4, requires A
  - D: duration 1, requires A and B
  - E: duration 2, requires C and D

  Expected critical path: A -> C -> E (total duration: 3 + 4 + 2 = 9)
  """

  use ExUnit.Case, async: false

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Commands.{CompleteActivity, StartActivity}

  test "solves classic textbook PERT problem" do
    # Classic textbook PERT problem
    # Activities: A=1, B=2, C=3, D=4, E=5
    params = %{
      num_activities: 5,
      num_resources: 1,
      durations: [3, 2, 4, 1, 2],  # A=3, B=2, C=4, D=1, E=2
      precedences: [
        {1, 3},  # A -> C
        {1, 4},  # A -> D
        {2, 4},  # B -> D
        {3, 5},  # C -> E
        {4, 5}   # D -> E
      ],
      locations: [1, 1, 1, 1, 1],
      location_capacities: [10]
    }

    {:ok, state} = AircraftDisassembly.initialize_state(params)

    IO.puts("\n=== Classic Textbook PERT Problem ===")
    IO.puts("Activities: A(1)=3, B(2)=2, C(3)=4, D(4)=1, E(5)=2")
    IO.puts("Precedences: A->C, A->D, B->D, C->E, D->E")
    IO.puts("Expected critical path: A->C->E (duration: 9)")
    IO.puts("\n=== Solution ===\n")

    # Solve the problem
    solution = solve_activities(state, [])

    IO.puts("\n=== Solution Summary ===")
    IO.puts("Total activities completed: #{length(solution)}")
    Enum.each(solution, fn {activity, start_time_iso, end_time_iso, duration_iso} ->
      activity_name = case activity do
        1 -> "A"
        2 -> "B"
        3 -> "C"
        4 -> "D"
        5 -> "E"
        _ -> "Activity #{activity}"
      end
      start_time = iso8601_to_hours(start_time_iso)
      end_time = iso8601_to_hours(end_time_iso)
      duration = iso8601_duration_to_hours(duration_iso)
      IO.puts("  #{activity_name}(#{activity}): start=#{start_time}, duration=#{duration}, end=#{end_time}")
    end)

    # Calculate makespan (convert ISO 8601 end times to hours)
    makespan = Enum.reduce(solution, 0, fn {_activity, _start_time_iso, end_time_iso, _duration_iso}, acc ->
      end_time_hours = iso8601_to_hours(end_time_iso)
      max(acc, end_time_hours)
    end)

    IO.puts("\nMakespan (total project duration): #{makespan}")
    IO.puts("Expected critical path duration: 9 (A->C->E)")

    # Verify critical path (convert ISO 8601 to hours)
    activity_a = Enum.find(solution, fn {a, _, _, _} -> a == 1 end)
    activity_c = Enum.find(solution, fn {a, _, _, _} -> a == 3 end)
    activity_e = Enum.find(solution, fn {a, _, _, _} -> a == 5 end)

    {_, a_start_iso, a_end_iso, a_duration_iso} = activity_a
    {_, c_start_iso, c_end_iso, c_duration_iso} = activity_c
    {_, e_start_iso, e_end_iso, e_duration_iso} = activity_e

    a_start = iso8601_to_hours(a_start_iso)
    a_end = iso8601_to_hours(a_end_iso)
    a_duration = iso8601_duration_to_hours(a_duration_iso)
    
    c_start = iso8601_to_hours(c_start_iso)
    c_end = iso8601_to_hours(c_end_iso)
    c_duration = iso8601_duration_to_hours(c_duration_iso)
    
    e_start = iso8601_to_hours(e_start_iso)
    e_end = iso8601_to_hours(e_end_iso)
    e_duration = iso8601_duration_to_hours(e_duration_iso)

    IO.puts("\n=== Critical Path Analysis ===")
    IO.puts("A: #{a_start}→#{a_end} (duration: #{a_duration})")
    IO.puts("C: #{c_start}→#{c_end} (duration: #{c_duration}) - starts when A completes")
    IO.puts("E: #{e_start}→#{e_end} (duration: #{e_duration}) - starts when C and D complete")
    IO.puts("\nCritical path: A->C->E = #{a_duration} + #{c_duration} + #{e_duration} = #{a_duration + c_duration + e_duration}")

    # Verify solution (convert ISO 8601 to hours for c_start_activity)
    final_state = Enum.reduce(solution, state, fn {activity, start_time_iso, _end_time_iso, _duration_iso}, acc ->
      start_time_hours = iso8601_to_hours(start_time_iso)
      {:ok, state1, _metadata1} = StartActivity.c_start_activity(acc, activity, start_time_hours, [])
      {:ok, state2, _metadata2} = CompleteActivity.c_complete_activity(state1, activity)
      state2
    end)

    assert AircraftDisassembly.all_activities_completed?(final_state)
    assert makespan == 9, "Expected makespan of 9 (A->C->E critical path)"
    assert c_start == a_end, "C should start when A completes"
    assert e_start >= c_end, "E should start after C completes"
    assert e_start >= 4, "E should start after D completes (D starts at 0 or 2, ends at 1 or 3)"

    IO.puts("\n✓ All activities completed successfully!")
    IO.puts("✓ Critical path verified: A->C->E (duration: 9)")
  end

  defp solve_activities(state, solution) do
    if AircraftDisassembly.all_activities_completed?(state) do
      Enum.reverse(solution)
    else
      # Find next activity that can be started
      next_activity = Enum.find(1..state.num_activities, fn activity ->
        activity_id = "activity_#{activity}"
        status = get_activity_status(state, activity_id)
        status == "not_started" and AircraftDisassembly.all_predecessors_completed?(state, activity)
      end)

      if next_activity do
        # Calculate start time (after all predecessors complete) - returns ISO 8601 datetime string
        start_time_iso = calculate_start_time(state, next_activity, solution)
        # Convert ISO 8601 to hours for c_start_activity
        start_time_hours = iso8601_to_hours(start_time_iso)
        duration = get_activity_duration(state, next_activity)

        # Start and complete the activity
        {:ok, state_after_start, metadata1} = StartActivity.c_start_activity(state, next_activity, start_time_hours, [])
        {:ok, state_after_complete, _metadata2} = CompleteActivity.c_complete_activity(state_after_start, next_activity)

        # Extract start_time, end_time, and duration from metadata (all in ISO 8601 format)
        start_time_iso = metadata1.start_time
        end_time_iso = metadata1.end_time
        duration_iso = metadata1.duration

        activity_name = case next_activity do
          1 -> "A"
          2 -> "B"
          3 -> "C"
          4 -> "D"
          5 -> "E"
          _ -> "Activity #{next_activity}"
        end

        # Convert to hours for display
        start_time_hours = iso8601_to_hours(start_time_iso)
        end_time_hours = iso8601_to_hours(end_time_iso)
        duration_hours = iso8601_duration_to_hours(duration_iso)
        IO.puts("#{activity_name}(#{next_activity}): start=#{start_time_hours}, duration=#{duration_hours}, end=#{end_time_hours}")

        # Store ISO 8601 datetime strings and duration string in solution
        solve_activities(state_after_complete, [{next_activity, start_time_iso, end_time_iso, duration_iso} | solution])
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

