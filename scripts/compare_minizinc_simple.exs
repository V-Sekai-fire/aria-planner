# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# Simple script to compare MiniZinc solutions with our planner's solutions
# Usage: mix run scripts/compare_minizinc_simple.exs [PROBLEM_FILE]

alias AriaPlanner.Domains.AircraftDisassembly
alias AriaPlanner.Domains.AircraftDisassembly.Commands.{CompleteActivity, StartActivity}

defmodule CompareSolutionsSimple do
  def run(problem_file \\ "B737NG-600-01-Anon.json.dzn") do
    base_path = Path.join([__DIR__, "../thirdparty/mznc2024_probs/aircraft-disassembly"])
    problem_path = Path.join(base_path, problem_file)
    model_path = Path.join(base_path, "aircraft.mzn")
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("Comparing Solutions: #{problem_file}")
    IO.puts(String.duplicate("=", 80))
    
    # Parse and initialize
    {:ok, params} = AircraftDisassembly.parse_dzn_file(problem_path)
    {:ok, state} = AircraftDisassembly.initialize_state(params)
    
    IO.puts("\nProblem Statistics:")
    IO.puts("  Activities: #{state.num_activities}")
    IO.puts("  Resources: #{state.num_resources}")
    IO.puts("  Precedences: #{length(state.precedences)}")
    
    # Get our solution
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("OUR PLANNER SOLUTION")
    IO.puts(String.duplicate("-", 80))
    our_solution = solve_activities(state, [])
    our_metrics = calculate_metrics(state, our_solution)
    print_metrics("Our Planner", our_metrics)
    
    # Try MiniZinc
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("MINIZINC SOLUTION")
    IO.puts(String.duplicate("-", 80))
    
    case run_minizinc(model_path, problem_path) do
      {:ok, mzn_output} ->
        mzn_metrics = parse_minizinc_output(state, mzn_output)
        print_metrics("MiniZinc", mzn_metrics)
        
        IO.puts("\n" <> String.duplicate("-", 80))
        IO.puts("COMPARISON")
        IO.puts(String.duplicate("-", 80))
        compare(our_metrics, mzn_metrics)
        
      {:error, reason} ->
        IO.puts("Could not run MiniZinc: #{reason}")
        IO.puts("\nTo run MiniZinc manually:")
        IO.puts("  minizinc --solver Gecode --time-limit 30000 #{model_path} #{problem_path}")
    end
  end
  
  defp solve_activities(state, solution) do
    if AircraftDisassembly.all_activities_completed?(state) do
      Enum.reverse(solution)
    else
      next_activity = Enum.find(1..state.num_activities, fn activity ->
        activity_id = "activity_#{activity}"
        status = get_status(state, activity_id)
        status == "not_started" and AircraftDisassembly.all_predecessors_completed?(state, activity)
      end)
      
      if next_activity do
        start_time_iso = calculate_start(state, next_activity, solution)
        start_hours = iso_to_hours(start_time_iso)
        
        case StartActivity.c_start_activity(state, next_activity, start_hours, []) do
          {:ok, state1, meta1} ->
            {:ok, state2, _meta2} = CompleteActivity.c_complete_activity(state1, next_activity)
            solve_activities(state2, [{next_activity, meta1.start_time, meta1.end_time, meta1.duration} | solution])
          {:error, _} ->
            solve_activities(state, solution)
        end
      else
        Enum.reverse(solution)
      end
    end
  end
  
  defp calculate_start(state, activity, solution) do
    preds = AircraftDisassembly.get_predecessors(state, activity)
    
    if Enum.empty?(preds) do
      hours_to_iso(state.current_time || 0)
    else
      max_end = Enum.reduce(preds, nil, fn pred, acc ->
        case Enum.find(solution, fn {a, _, _, _} -> a == pred end) do
          {_, _, pred_end, _} ->
            if acc do
              {:ok, pred_dt, _} = DateTime.from_iso8601(pred_end)
              {:ok, acc_dt, _} = DateTime.from_iso8601(acc)
              if DateTime.compare(pred_dt, acc_dt) == :gt, do: pred_end, else: acc
            else
              pred_end
            end
          nil ->
            dur = get_duration(state, pred)
            end_hours = (state.current_time || 0) + dur
            end_iso = hours_to_iso(end_hours)
            if acc do
              {:ok, end_dt, _} = DateTime.from_iso8601(end_iso)
              {:ok, acc_dt, _} = DateTime.from_iso8601(acc)
              if DateTime.compare(end_dt, acc_dt) == :gt, do: end_iso, else: acc
            else
              end_iso
            end
        end
      end)
      
      current_iso = hours_to_iso(state.current_time || 0)
      if max_end do
        {:ok, max_dt, _} = DateTime.from_iso8601(max_end)
        {:ok, curr_dt, _} = DateTime.from_iso8601(current_iso)
        if DateTime.compare(max_dt, curr_dt) == :gt, do: max_end, else: current_iso
      else
        current_iso
      end
    end
  end
  
  defp get_status(state, activity_id) do
    Map.get(state, :facts, %{})
    |> Map.get("activity_status", %{})
    |> Map.get(activity_id, "not_started")
  end
  
  defp get_duration(state, activity) do
    Enum.at(state.durations || [], activity - 1, 0)
  end
  
  defp hours_to_iso(hours) do
    ~U[2025-01-01 00:00:00Z]
    |> Timex.shift(hours: hours)
    |> DateTime.to_iso8601()
  end
  
  defp iso_to_hours(iso) do
    {:ok, dt, _} = DateTime.from_iso8601(iso)
    Timex.diff(dt, ~U[2025-01-01 00:00:00Z], :hours)
  end
  
  defp duration_to_hours(dur_iso) do
    case Timex.Duration.parse(dur_iso) do
      {:ok, d} -> div(Timex.Duration.to_microseconds(d), 3_600_000_000)
      _ -> 0
    end
  end
  
  defp calculate_metrics(state, solution) do
    makespan = Enum.reduce(solution, 0, fn {_, _, end_iso, _}, acc ->
      max(acc, iso_to_hours(end_iso))
    end)
    
    costs = Map.get(state, :resource_cost, [])
    total_cost = if length(costs) > 0 do
      avg = Enum.sum(costs) / length(costs)
      Enum.reduce(solution, 0, fn {_, _, _, dur_iso}, acc ->
        acc + avg * duration_to_hours(dur_iso)
      end)
    else
      0
    end
    
    %{makespan: makespan, total_cost: total_cost, objective: 100_000 * makespan + total_cost}
  end
  
  defp print_metrics(label, metrics) do
    IO.puts("\n#{label}:")
    IO.puts("  Makespan: #{metrics.makespan}")
    IO.puts("  Total Cost: #{:erlang.float_to_binary(metrics.total_cost, decimals: 2)}")
    IO.puts("  Objective: #{:erlang.float_to_binary(metrics.objective, decimals: 2)}")
    if Map.has_key?(metrics, :start_times) and length(metrics.start_times) > 0 do
      IO.puts("  Start Times: #{inspect(metrics.start_times)}")
    end
  end
  
  defp run_minizinc(model_path, data_path) do
    # Use COIN-BC MIP solver (works for this CP problem)
    cmd = "minizinc --solver COIN-BC --time-limit 120000 #{model_path} #{data_path} 2>&1"
    timeout_ms = 180_000  # 3 minute timeout for the entire command
    
    IO.puts("Running MiniZinc with COIN-BC (this may take 1-2 minutes)...")
    
    case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true, timeout: timeout_ms) do
      {output, 0} -> 
        IO.puts("MiniZinc completed successfully")
        {:ok, output}
      {output, exit_code} -> 
        IO.puts("MiniZinc exited with code #{exit_code}")
        # Still try to parse output even if exit code is non-zero
        if String.contains?(output, "start =") do
          {:ok, output}
        else
          {:error, "MiniZinc failed: #{String.slice(output, 0, 500)}"}
        end
    end
  rescue
    e ->
      {:error, "MiniZinc execution timed out or failed: #{inspect(e)}"}
  end
  
  defp parse_minizinc_output(state, output) do
    # Extract start times from MiniZinc output
    start_regex = ~r/start\s*=\s*\[([^\]]+)\];/
    start_times = case Regex.run(start_regex, output) do
      [_, vals] ->
        vals |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.map(&String.to_integer/1)
      _ -> []
    end
    
    # Extract assign array (2D: activities x resources)
    assign_regex = ~r/assign\s*=\s*\[(.*?)\];/s
    assign_matrix = case Regex.run(assign_regex, output) do
      [_, matrix_str] ->
        # Parse the matrix format: [| row1 | row2 | ... |]
        matrix_str
        |> String.split("|")
        |> Enum.filter(fn s -> String.trim(s) != "" and String.trim(s) != "[" and String.trim(s) != "]" end)
        |> Enum.map(fn row_str ->
          row_str
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(fn val -> val == "true" end)
        end)
      _ -> []
    end
    
    # Calculate makespan
    makespan = if length(start_times) > 0 do
      durations = state.durations || []
      Enum.zip(start_times, durations)
      |> Enum.map(fn {s, d} -> s + d end)
      |> Enum.max(fn -> 0 end)
    else
      0
    end
    
    # Calculate total resource cost from assign matrix
    costs = Map.get(state, :resource_cost, [])
    total_cost = if length(costs) > 0 and length(start_times) > 0 and length(assign_matrix) > 0 do
      durations = state.durations || []
      Enum.reduce(0..(length(start_times) - 1), 0, fn act_idx, acc ->
        activity_cost = Enum.reduce(0..(length(costs) - 1), 0, fn res_idx, res_acc ->
          if act_idx < length(assign_matrix) and res_idx < length(Enum.at(assign_matrix, act_idx, [])) do
            assigned = Enum.at(Enum.at(assign_matrix, act_idx, []), res_idx, false)
            duration = Enum.at(durations, act_idx, 0)
            resource_cost = Enum.at(costs, res_idx, 0)
            if assigned do
              res_acc + resource_cost * duration
            else
              res_acc
            end
          else
            res_acc
          end
        end)
        acc + activity_cost
      end)
    else
      # Fallback: estimate if we can't parse assign matrix
      if length(costs) > 0 and length(start_times) > 0 do
        avg = Enum.sum(costs) / length(costs)
        durations = state.durations || []
        Enum.zip(start_times, durations)
        |> Enum.reduce(0, fn {_, d}, acc -> acc + avg * d end)
      else
        0
      end
    end
    
    %{makespan: makespan, total_cost: total_cost, objective: 100_000 * makespan + total_cost, start_times: start_times}
  end
  
  defp compare(our, mzn) do
    makespan_diff = our.makespan - mzn.makespan
    cost_diff = our.total_cost - mzn.total_cost
    obj_diff = our.objective - mzn.objective
    
    IO.puts("\nMakespan: Our=#{our.makespan}, MiniZinc=#{mzn.makespan}, Diff=#{makespan_diff}")
    IO.puts("Cost: Our=#{:erlang.float_to_binary(our.total_cost, decimals: 2)}, MiniZinc=#{:erlang.float_to_binary(mzn.total_cost, decimals: 2)}, Diff=#{:erlang.float_to_binary(cost_diff, decimals: 2)}")
    IO.puts("Objective: Our=#{:erlang.float_to_binary(our.objective, decimals: 2)}, MiniZinc=#{:erlang.float_to_binary(mzn.objective, decimals: 2)}, Diff=#{:erlang.float_to_binary(obj_diff, decimals: 2)}")
    
    cond do
      our.objective < mzn.objective -> IO.puts("\n✓ Our solution is BETTER!")
      our.objective > mzn.objective -> IO.puts("\n✗ MiniZinc solution is BETTER")
      true -> IO.puts("\n= Solutions are EQUAL")
    end
  end
end

# Run with smallest problem by default (16 activities)
problem_file = case System.argv() do
  [file] -> file
  _ -> "B737NG-600-01-Anon.json.dzn"  # Smallest: 16 activities, 21 resources
end

IO.puts("Using problem file: #{problem_file}")
CompareSolutionsSimple.run(problem_file)

