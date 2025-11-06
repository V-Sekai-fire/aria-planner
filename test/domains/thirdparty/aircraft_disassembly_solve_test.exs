# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassemblySolveTest do
  @moduledoc """
  Test that demonstrates solving an aircraft disassembly problem.
  """

  use ExUnit.Case, async: false

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Commands.{StartActivity, CompleteActivity}
  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.{ActivityStatus, ActivityStart, ActivityDuration}

  @problem_file "B737NG-600-01-Anon.json.dzn"
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
    
    # Verify all activities are completed
    final_state = Enum.reduce(solution, state, fn {activity, start_time, _duration}, acc ->
      {:ok, state1} = StartActivity.c_start_activity(acc, activity, start_time)
      {:ok, state2} = CompleteActivity.c_complete_activity(state1, activity)
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
        {:ok, state_after_start} = StartActivity.c_start_activity(state, next_activity, start_time)
        {:ok, state_after_complete} = CompleteActivity.c_complete_activity(state_after_start, next_activity)
        
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
end

