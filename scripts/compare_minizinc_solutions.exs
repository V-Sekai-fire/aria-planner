# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# Script to compare MiniZinc solutions with our planner's solutions
#
# Usage: mix run scripts/compare_minizinc_solutions.exs [PROBLEM_FILE]

alias AriaPlanner.Domains.AircraftDisassembly

defmodule CompareSolutions do
  @moduledoc """
  Compares MiniZinc solutions with our planner's solutions.
  """

  def run_comparison(problem_file) do
    base_path = Path.join([
      __DIR__,
      "../thirdparty/mznc2024_probs/aircraft-disassembly"
    ])
    
    problem_path = Path.join(base_path, problem_file)
    model_path = Path.join(base_path, "aircraft.mzn")
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("Comparing Solutions for: #{problem_file}")
    IO.puts(String.duplicate("=", 80))
    
    # Parse problem
    {:ok, params} = AircraftDisassembly.parse_dzn_file(problem_path)
    {:ok, state} = AircraftDisassembly.initialize_state(params)
    
    IO.puts("\nProblem Statistics:")
    IO.puts("  Activities: #{state.num_activities}")
    IO.puts("  Resources: #{state.num_resources}")
    IO.puts("  Skills: #{Map.get(state, :nSkills, 0)}")
    IO.puts("  Precedences: #{length(state.precedences)}")
    IO.puts("  Max time: #{Map.get(state, :maxt, 1920)}")
    
    # Get our solution
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("OUR PLANNER SOLUTION")
    IO.puts(String.duplicate("-", 80))
    our_solution = solve_activities(state, [])
    our_metrics = calculate_metrics(state, our_solution)
    print_solution_metrics("Our Planner", our_metrics, our_solution)
    
    # Try to get MiniZinc solution
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("MINIZINC SOLUTION")
    IO.puts(String.duplicate("-", 80))
    
    case get_minizinc_solution(model_path, problem_path) do
      {:ok, mzn_solution} ->
        mzn_metrics = parse_minizinc_solution(state, mzn_solution)
        print_solution_metrics("MiniZinc", mzn_metrics, mzn_solution)
        
        # Compare
        IO.puts("\n" <> String.duplicate("-", 80))
        IO.puts("COMPARISON")
        IO.puts(String.duplicate("-", 80))
        compare_metrics(our_metrics, mzn_metrics)
        
      {:error, reason} ->
        IO.puts("Could not get MiniZinc solution: #{reason}")
        IO.puts("To get MiniZinc solution, run:")
        IO.puts("  minizinc --solver Gecode #{model_path} #{problem_path}")
    end
  end
  
  defp solve_activities(state, solution) do
    if AircraftDisassembly.all_activities_completed?(state) do
      Enum.reverse(solution)
    else
      next_activity = Enum.find(1..state.num_activities, fn activity ->
        activity_id = "activity_#{activity}"
        status = get_activity_status(state, activity_id)
        status == "not_started" and AircraftDisassembly.all_predecessors_completed?(state, activity)
      end)
      
      if next_activity do
        start_time_iso = calculate_start_time(state, next_activity, solution)
        start_time_hours = iso8601_to_hours(start_time_iso)
        
        case AriaPlanner.Domains.AircraftDisassembly.Commands.StartActivity.c_start_activity(
          state, next_activity, start_time_hours, []
        ) do
          {:ok, state_after_start, metadata1} ->
            {:ok, state_after_complete, _metadata2} = 
              AriaPlanner.Domains.AircraftDisassembly.Commands.CompleteActivity.c_complete_activity(
                state_after_start, next_activity
              )
            
            start_time_iso = metadata1.start_time
            end_time_iso = metadata1.end_time
            duration_iso = metadata1.duration
            
            solve_activities(state_after_complete, [
              {next_activity, start_time_iso, end_time_iso, duration_iso} | solution
            ])
            
          {:error, _reason} ->
            solve_activities(state, solution)
        end
      else
        Enum.reverse(solution)
      end
    end
  end
  
  defp calculate_start_time(state, activity, solution) do
    predecessors = AircraftDisassembly.get_predecessors(state, activity)
    
    if Enum.empty?(predecessors) do
      hours_to_iso8601(state.current_time || 0)
    else
      max_end_time_iso = Enum.reduce(predecessors, nil, fn pred, acc ->
        case Enum.find(solution, fn {a, _, _, _} -> a == pred end) do
          {_pred_activity, _pred_start_iso, pred_end_iso, _pred_duration_iso} ->
            if acc do
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
    Timex.diff(datetime, base_datetime, :hours)
  end
  
  defp calculate_metrics(state, solution) do
    # Calculate makespan (max end time)
    makespan = Enum.reduce(solution, 0, fn {_activity, _start_time_iso, end_time_iso, _duration_iso}, acc ->
      end_time_hours = iso8601_to_hours(end_time_iso)
      max(acc, end_time_hours)
    end)
    
    # Calculate resource cost (simplified - we don't track assignments yet)
    # For now, estimate based on durations
    resource_cost = Map.get(state, :resource_cost, [])
    total_cost = if length(resource_cost) > 0 do
      # Estimate: assume one resource per activity at average cost
      avg_cost = Enum.sum(resource_cost) / max(length(resource_cost), 1)
      Enum.reduce(solution, 0, fn {activity, _start_time_iso, _end_time_iso, duration_iso}, acc ->
        duration_hours = iso8601_duration_to_hours(duration_iso)
        acc + (avg_cost * duration_hours)
      end)
    else
      0
    end
    
    # Calculate objective (matching MiniZinc: 100000 * makespan + cost)
    objective = 100_000 * makespan + total_cost
    
    %{
      makespan: makespan,
      total_cost: total_cost,
      objective: objective,
      num_activities: length(solution)
    }
  end
  
  defp iso8601_duration_to_hours(iso8601_duration_string) do
    case Timex.Duration.parse(iso8601_duration_string) do
      {:ok, %Timex.Duration{} = duration} ->
        microseconds = Timex.Duration.to_microseconds(duration)
        div(microseconds, 3_600_000_000)
      _ ->
        0
    end
  end
  
  defp print_solution_metrics(label, metrics, solution) do
    IO.puts("\n#{label} Metrics:")
    IO.puts("  Makespan (max end time): #{metrics.makespan}")
    IO.puts("  Total resource cost: #{:erlang.float_to_binary(metrics.total_cost, decimals: 2)}")
    IO.puts("  Objective (100000*makespan + cost): #{:erlang.float_to_binary(metrics.objective, decimals: 2)}")
    IO.puts("  Activities completed: #{metrics.num_activities}")
    
    IO.puts("\nActivity Schedule:")
    Enum.each(solution, fn {activity, start_time_iso, end_time_iso, duration_iso} ->
      start_time = iso8601_to_hours(start_time_iso)
      end_time = iso8601_to_hours(end_time_iso)
      duration = iso8601_duration_to_hours(duration_iso)
      IO.puts("  Activity #{activity}: start=#{start_time}, duration=#{duration}, end=#{end_time}")
    end)
  end
  
  defp get_minizinc_solution(model_path, data_path) do
    # Try to run MiniZinc
    cmd = "minizinc --solver Gecode --time-limit 30000 #{model_path} #{data_path}"
    
    case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}
      {output, _exit_code} ->
        {:error, "MiniZinc failed: #{output}"}
    end
  end
  
  defp parse_minizinc_solution(state, mzn_output) do
    # Parse MiniZinc output to extract start times and assignments
    # MiniZinc outputs: start = [t1, t2, ...]; assign = [[...], [...], ...];
    
    # Extract start times
    start_regex = ~r/start\s*=\s*\[([^\]]+)\];/
    start_times = case Regex.run(start_regex, mzn_output) do
      [_, values] ->
        values
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.to_integer/1)
      _ ->
        []
    end
    
    # Calculate makespan
    makespan = if length(start_times) > 0 do
      durations = state.durations || []
      Enum.zip(start_times, durations)
      |> Enum.map(fn {start, duration} -> start + duration end)
      |> Enum.max(fn -> 0 end)
    else
      0
    end
    
    # Estimate cost (simplified - would need to parse assign array)
    resource_cost = Map.get(state, :resource_cost, [])
    total_cost = if length(resource_cost) > 0 and length(start_times) > 0 do
      avg_cost = Enum.sum(resource_cost) / max(length(resource_cost), 1)
      durations = state.durations || []
      Enum.zip(start_times, durations)
      |> Enum.reduce(0, fn {_start, duration}, acc ->
        acc + (avg_cost * duration)
      end)
    else
      0
    end
    
    objective = 100_000 * makespan + total_cost
    
    %{
      makespan: makespan,
      total_cost: total_cost,
      objective: objective,
      num_activities: length(start_times),
      start_times: start_times
    }
  end
  
  defp compare_metrics(our_metrics, mzn_metrics) do
    makespan_diff = our_metrics.makespan - mzn_metrics.makespan
    makespan_pct = if mzn_metrics.makespan > 0 do
      (makespan_diff / mzn_metrics.makespan) * 100
    else
      0
    end
    
    cost_diff = our_metrics.total_cost - mzn_metrics.total_cost
    cost_pct = if mzn_metrics.total_cost > 0 do
      (cost_diff / mzn_metrics.total_cost) * 100
    else
      0
    end
    
    objective_diff = our_metrics.objective - mzn_metrics.objective
    objective_pct = if mzn_metrics.objective > 0 do
      (objective_diff / mzn_metrics.objective) * 100
    else
      0
    end
    
    IO.puts("\nMakespan:")
    IO.puts("  Our: #{our_metrics.makespan}")
    IO.puts("  MiniZinc: #{mzn_metrics.makespan}")
    IO.puts("  Difference: #{makespan_diff} (#{:erlang.float_to_binary(makespan_pct, decimals: 2)}%)")
    
    IO.puts("\nTotal Cost:")
    IO.puts("  Our: #{:erlang.float_to_binary(our_metrics.total_cost, decimals: 2)}")
    IO.puts("  MiniZinc: #{:erlang.float_to_binary(mzn_metrics.total_cost, decimals: 2)}")
    IO.puts("  Difference: #{:erlang.float_to_binary(cost_diff, decimals: 2)} (#{:erlang.float_to_binary(cost_pct, decimals: 2)}%)")
    
    IO.puts("\nObjective (100000*makespan + cost):")
    IO.puts("  Our: #{:erlang.float_to_binary(our_metrics.objective, decimals: 2)}")
    IO.puts("  MiniZinc: #{:erlang.float_to_binary(mzn_metrics.objective, decimals: 2)}")
    IO.puts("  Difference: #{:erlang.float_to_binary(objective_diff, decimals: 2)} (#{:erlang.float_to_binary(objective_pct, decimals: 2)}%)")
    
    if our_metrics.objective < mzn_metrics.objective do
      IO.puts("\n✓ Our solution is BETTER!")
    elsif our_metrics.objective > mzn_metrics.objective do
      IO.puts("\n✗ MiniZinc solution is BETTER")
    else
      IO.puts("\n= Solutions are EQUAL")
    end
  end
end

# Run comparison for a test problem
problem_file = System.get_env("PROBLEM_FILE") || "B737NG-600-09-Anon.json.dzn"
CompareSolutions.run_comparison(problem_file)

