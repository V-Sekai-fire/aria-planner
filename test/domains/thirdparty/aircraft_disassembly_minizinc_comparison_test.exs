# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassemblyMinizincComparisonTest do
  @moduledoc """
  Compares our planner's solutions with MiniZinc solutions.
  """

  use ExUnit.Case, async: false

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Commands.{CompleteActivity, StartActivity}

  @problem_file "B737NG-600-01-Anon.json.dzn"
  @base_path Path.join([
    __DIR__,
    "../../../thirdparty/mznc2024_probs/aircraft-disassembly"
  ])

  @minizinc_solution_fixture """
  start = [32, 0, 8, 4, 22, 31, 20, 4, 18, 21, 6, 29, 19, 16, 16, 23];
  assign = 
  [| false, false, false, false,  true, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false,  true, false, false, false, false,  true, false, false, false, false, false, false, false, false, false
   | false, false,  true, false, false, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false, false, false,  true, false, false,  true, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false,  true, false, false, false, false,  true, false, false, false, false, false, false, false, false, false, false
   | false,  true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false, false, false
   | false, false,  true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
   | false, false, false, false,  true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false, false
   | false, false, false, false, false, false, false, false, false, false, false,  true, false, false, false, false, false, false, false, false, false
   | false, false, false,  true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
   |];
  """

  @tag timeout: 120_000
  test "compares our solution with MiniZinc solution" do
    problem_path = Path.join(@base_path, @problem_file)

    # Parse and initialize
    {:ok, params} = AircraftDisassembly.parse_dzn_file(problem_path)
    {:ok, state} = AircraftDisassembly.initialize_state(params)

    IO.puts("\n=== Problem: #{@problem_file} ===")
    IO.puts("Activities: #{state.num_activities}, Resources: #{state.num_resources}")

    # Parse MiniZinc solution from fixture
    mzn_metrics = parse_minizinc_solution(state, @minizinc_solution_fixture)
    
    IO.puts("\n=== MiniZinc Solution ===")
    IO.puts("Makespan: #{mzn_metrics.makespan}")
    IO.puts("Total Cost: #{format_float(mzn_metrics.total_cost)}")
    IO.puts("Objective: #{format_float(mzn_metrics.objective)}")
    IO.puts("Start Times: #{inspect(mzn_metrics.start_times)}")

    # Get our solution
    IO.puts("\n=== Our Planner Solution ===")
    our_solution = solve_activities(state, [])
    our_metrics = calculate_metrics(state, our_solution)
    print_metrics("Our Planner", our_metrics)

    # Compare solutions
    IO.puts("\n=== Comparison ===")
    compare_metrics(our_metrics, mzn_metrics)

    # Verify MiniZinc solution is valid
    assert mzn_metrics.makespan > 0
    assert mzn_metrics.objective > 0
    assert length(mzn_metrics.start_times) == state.num_activities
    
    # Verify our solution completed all activities
    assert length(our_solution) == state.num_activities
  end

  defp parse_minizinc_solution(state, output) do
    # Extract start times
    start_regex = ~r/start\s*=\s*\[([^\]]+)\];/
    start_times = case Regex.run(start_regex, output) do
      [_, vals] ->
        vals |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.map(&String.to_integer/1)
      _ -> []
    end

    # Extract assign matrix
    assign_regex = ~r/assign\s*=\s*\[(.*?)\];/s
    assign_matrix = case Regex.run(assign_regex, output) do
      [_, matrix_str] ->
        matrix_str
        |> String.split("|")
        |> Enum.filter(fn s -> 
          trimmed = String.trim(s)
          trimmed != "" and trimmed != "[" and trimmed != "]"
        end)
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

    # Calculate total resource cost
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
      0
    end

    %{
      makespan: makespan,
      total_cost: total_cost,
      objective: 100_000 * makespan + total_cost,
      start_times: start_times
    }
  end

  defp format_float(value) when is_integer(value), do: "#{value}.00"
  defp format_float(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 2)
  defp format_float(value), do: "#{value}"

  # Solver functions (copied from solve_test)
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
        start_time_hours = iso_to_hours(start_time_iso)

        assigned_resources = case find_resources_with_skills(state, next_activity) do
          {:ok, resources} -> resources
          {:error, _reason} -> []
        end

        case StartActivity.c_start_activity(state, next_activity, start_time_hours, assigned_resources) do
          {:ok, state1, meta1} ->
            {:ok, state2, _meta2} = CompleteActivity.c_complete_activity(state1, next_activity)
            solve_activities(state2, [{next_activity, meta1.start_time, meta1.end_time, meta1.duration} | solution])
          {:error, _reason} ->
            solve_activities(state, solution)
        end
      else
        Enum.reverse(solution)
      end
    end
  end

  defp calculate_start_time(state, activity, solution) do
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

  defp get_activity_status(state, activity_id) do
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

  defp find_resources_with_skills(state, activity) do
    num_skills = Map.get(state, :nSkills, 3)
    useful_res = get_useful_resources(state, activity)
    skill_reqs = get_activity_skill_requirements(state, activity)
    
    assigned_resources = Enum.reduce(1..num_skills, [], fn skill_idx, acc ->
      required = get_skill_requirement(skill_reqs, activity, skill_idx, state)
      
      if required > 0 do
        resources_with_skill = Enum.filter(useful_res, fn resource_id ->
          has_skill_capability?(state, resource_id, skill_idx)
        end)
        
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

  defp duration_to_hours(dur_iso) do
    case Timex.Duration.parse(dur_iso) do
      {:ok, d} -> div(Timex.Duration.to_microseconds(d), 3_600_000_000)
      _ -> 0
    end
  end

  defp print_metrics(label, metrics) do
    IO.puts("\n#{label}:")
    IO.puts("  Makespan: #{metrics.makespan}")
    IO.puts("  Total Cost: #{format_float(metrics.total_cost)}")
    IO.puts("  Objective: #{format_float(metrics.objective)}")
  end

  defp compare_metrics(our, mzn) do
    makespan_diff = our.makespan - mzn.makespan
    cost_diff = our.total_cost - mzn.total_cost
    obj_diff = our.objective - mzn.objective
    
    IO.puts("\nMakespan: Our=#{our.makespan}, MiniZinc=#{mzn.makespan}, Diff=#{makespan_diff}")
    IO.puts("Cost: Our=#{format_float(our.total_cost)}, MiniZinc=#{format_float(mzn.total_cost)}, Diff=#{format_float(cost_diff)}")
    IO.puts("Objective: Our=#{format_float(our.objective)}, MiniZinc=#{format_float(mzn.objective)}, Diff=#{format_float(obj_diff)}")
    
    cond do
      our.objective < mzn.objective -> IO.puts("\n✓ Our solution is BETTER!")
      our.objective > mzn.objective -> IO.puts("\n✗ MiniZinc solution is BETTER")
      true -> IO.puts("\n= Solutions are EQUAL")
    end
  end
end

