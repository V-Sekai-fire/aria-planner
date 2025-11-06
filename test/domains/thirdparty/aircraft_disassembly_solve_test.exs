# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassemblySolveTest do
  @moduledoc """
  Test that demonstrates solving an aircraft disassembly problem.
  """

  use ExUnit.Case, async: false

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Commands.{CompleteActivity, StartActivity}
  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.{ActivityDuration, ActivityStart, ActivityStatus}

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

    # Solve by scheduling all activities
    solution = solve_activities(state, [])

    IO.puts("\n=== Solution Summary ===")
    IO.puts("Total activities completed: #{length(solution)}")
    IO.puts("Solution sequence:")
    Enum.each(solution, fn {activity, start_time, duration} ->
      IO.puts("  Activity #{activity}: start=#{start_time}, duration=#{duration}, end=#{start_time + duration}")
    end)

    # Generate Gantt chart
    IO.puts("\n=== Gantt Chart ===")
    print_gantt_chart(solution)

    # Verify all activities are completed
    final_state = Enum.reduce(solution, state, fn {activity, start_time, _duration}, acc ->
      {:ok, state1, _metadata1} = StartActivity.c_start_activity(acc, activity, start_time)
      {:ok, state2, _metadata2} = CompleteActivity.c_complete_activity(state1, activity)
      state2
    end)

    assert AircraftDisassembly.all_activities_completed?(final_state)
    IO.puts("\n✓ All activities completed successfully!")
  end

  defp solve_activities(state, solution) do
    if AircraftDisassembly.all_activities_completed?(state) do
      Enum.reverse(solution)
    else
      # Find next activity that can be started
      next_activity = Enum.find(1..state.num_activities, fn activity ->
        status = ActivityStatus.get(state, activity)
        status == "not_started" and AircraftDisassembly.all_predecessors_completed?(state, activity)
      end)

      if next_activity do
        # Calculate start time (after all predecessors complete)
        start_time = calculate_start_time(state, next_activity)
        duration = ActivityDuration.get(state, next_activity)

        # Start and complete the activity
        {:ok, state_after_start, _metadata1} = StartActivity.c_start_activity(state, next_activity, start_time)
        {:ok, state_after_complete, _metadata2} = CompleteActivity.c_complete_activity(state_after_start, next_activity)

        IO.puts("Activity #{next_activity}: start=#{start_time}, duration=#{duration}, end=#{start_time + duration}")

        # Continue solving
        solve_activities(state_after_complete, [{next_activity, start_time, duration} | solution])
      else
        # No more activities can be started (shouldn't happen if problem is solvable)
        IO.puts("Warning: No more activities can be started, but not all are completed")
        Enum.reverse(solution)
      end
    end
  end

  defp calculate_start_time(state, activity) do
    predecessors = AircraftDisassembly.get_predecessors(state, activity)

    if Enum.empty?(predecessors) do
      state.current_time || 0
    else
      # Start time is max(end_time of all predecessors)
      max_end_time = Enum.reduce(predecessors, 0, fn pred, acc ->
        start = ActivityStart.get(state, pred)
        duration = ActivityDuration.get(state, pred)
        end_time = start + duration
        max(acc, end_time)
      end)
      max(max_end_time, state.current_time || 0)
    end
  end

  defp print_gantt_chart(solution) do
    # Sort solution by start time, then by activity ID
    sorted = Enum.sort(solution, fn {a1, s1, _d1}, {a2, s2, _d2} ->
      if s1 == s2, do: a1 < a2, else: s1 < s2
    end)

    # Find max end time
    max_time = Enum.reduce(sorted, 0, fn {_activity, start_time, duration}, acc ->
      max(acc, start_time + duration)
    end)

    # Scale: each character represents 1 time unit, but we'll compress for large timelines
    scale = if max_time > 100, do: 2, else: 1
    chart_width = div(max_time, scale) + 10

    IO.puts("\nTimeline (each '=' represents #{scale} time unit(s), max time: #{max_time}):")
    IO.puts(String.duplicate("=", min(chart_width, 120)))
    IO.puts("")

    # Group activities by start time for better visualization
    grouped = Enum.group_by(sorted, fn {_activity, start_time, _duration} -> start_time end)

    # Print activities
    Enum.each(Enum.sort(Map.keys(grouped)), fn start_time ->
      activities = Map.get(grouped, start_time)
      Enum.each(activities, fn {activity, s, duration} ->
        bar_length = max(1, div(duration, scale))
        bar = String.duplicate("█", min(bar_length, 100))
        spaces = String.duplicate(" ", min(div(s, scale), 100))
        IO.puts("Activity #{String.pad_leading(Integer.to_string(activity), 3, " ")}: #{spaces}#{bar} (#{s}→#{s + duration})")
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
end
