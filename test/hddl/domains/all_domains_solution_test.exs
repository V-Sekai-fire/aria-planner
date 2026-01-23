# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.AllDomainsSolutionTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.Neighbours
  alias AriaPlanner.HDDL

  @expected_solutions_file "test/fixtures/minizinc_expected_solutions.json"

  defp load_expected_solutions do
    case File.read(@expected_solutions_file) do
      {:ok, content} ->
        Jason.decode!(content) || %{}

      {:error, _} ->
        %{}
    end
  end

  describe "neighbours domain verification" do
    test "verifies neighbours problems have correct parameters" do
      expected_solutions = load_expected_solutions()
      neighbours_solutions = expected_solutions["neighbours"] || %{}

      problem_files = Path.wildcard("test/fixtures/hddl/neighbours_problem*.hddl")

      Enum.each(problem_files, fn problem_file ->
        problem_name = Path.basename(problem_file, ".hddl")
        expected = neighbours_solutions[problem_name]

        if expected do
          {:ok, content} = File.read(problem_file)
          {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

          initial_facts = extract_initial_facts(ast)

          # Verify grid dimensions
          n = get_fact_value(initial_facts, :n, nil)
          m = get_fact_value(initial_facts, :m, nil)

          if n && m do
            assert n == expected["n"], "Problem #{problem_name}: n mismatch"
            assert m == expected["m"], "Problem #{problem_name}: m mismatch"

            # Verify max possible objective
            max_possible = expected["max_possible"]

            if max_possible do
              assert max_possible == 5 * n * m,
                     "Problem #{problem_name}: max_possible should be 5 * #{n} * #{m} = #{5 * n * m}, got #{max_possible}"
            end
          end
        end
      end)
    end

    test "verifies neighbours objective calculation works" do
      # Test with a simple 2x2 grid
      state = %{
        grid: %{
          {1, 1} => 3,
          {1, 2} => 2,
          {2, 1} => 1,
          {2, 2} => 4
        }
      }

      objective = Neighbours.calculate_objective(state)
      expected = 3 + 2 + 1 + 4

      assert objective == expected,
             "Neighbours objective calculation: got #{objective}, expected #{expected}"
    end
  end

  describe "tiny_cvrp domain verification" do
    test "verifies tiny_cvrp problems have correct parameters" do
      expected_solutions = load_expected_solutions()
      cvrp_solutions = expected_solutions["tiny_cvrp"] || %{}

      problem_files = Path.wildcard("test/fixtures/hddl/tiny_cvrp_problem*.hddl")

      Enum.each(problem_files, fn problem_file ->
        problem_name = Path.basename(problem_file, ".hddl")
        expected = cvrp_solutions[problem_name]

        if expected do
          {:ok, content} = File.read(problem_file)
          {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

          initial_facts = extract_initial_facts(ast)

          # Verify parameters
          num_vehicles = get_fact_value(initial_facts, :num_vehicles, nil)
          num_customers = get_fact_value(initial_facts, :num_customers, nil)

          if num_vehicles && num_customers do
            assert num_vehicles == expected["num_vehicles"],
                   "Problem #{problem_name}: num_vehicles mismatch"

            assert num_customers == expected["num_customers"],
                   "Problem #{problem_name}: num_customers mismatch"
          end
        end
      end)
    end
  end

  describe "all domains problem parsing" do
    test "all domain problem files parse correctly" do
      domains = [
        "aircraft_disassembly",
        "cable_tree_wiring",
        "fox_geese_corn",
        "graph_clear",
        "hoist_benchmark",
        "neighbours",
        "portal",
        "tiny_cvrp",
        "train_scheduling",
        "yumi_dynamic"
      ]

      Enum.each(domains, fn domain_name ->
        problem_files = Path.wildcard("test/fixtures/hddl/#{domain_name}_problem*.hddl")

        if length(problem_files) > 0 do
          Enum.each(problem_files, fn problem_file ->
            {:ok, content} = File.read(problem_file)
            {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

            assert {:problem, _name, _elements} = ast,
                   "Problem file #{problem_file} should parse as a problem"
          end)
        end
      end)
    end
  end

  defp extract_initial_facts({:problem, _name, elements}) do
    case Enum.find(elements, fn {key, _} -> key == :aria_initial_state end) do
      {_, state_elements} ->
        facts = Keyword.get(state_elements, :facts, [])
        reduce_facts(facts)

      _ ->
        %{}
    end
  end

  defp reduce_facts(facts) do
    Enum.reduce(facts, %{}, fn fact, acc ->
      case fact do
        %{predicate: pred, value: val} ->
          normalized_val = normalize_fact_value(val)
          Map.put(acc, pred, normalized_val)

        _ ->
          acc
      end
    end)
  end

  defp normalize_fact_value(val) when is_binary(val) do
    case Integer.parse(val) do
      {int_val, ""} -> int_val
      _ -> val
    end
  end

  defp normalize_fact_value(val), do: val

  defp get_fact_value(facts, key, default) do
    Map.get(facts, key, default)
  end
end
