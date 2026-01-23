# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.FoxGeeseCornSolutionTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.FoxGeeseCorn
  alias AriaPlanner.HDDL

  # Load expected MiniZinc solutions
  @expected_solutions_file "test/fixtures/minizinc_expected_solutions.json"

  defp load_expected_solutions do
    case File.read(@expected_solutions_file) do
      {:ok, content} ->
        Jason.decode!(content)["fox_geese_corn"] || %{}

      {:error, _} ->
        %{}
    end
  end

  describe "solution verification against MiniZinc" do
    test "verifies expected objective values match MiniZinc calculations" do
      expected_solutions = load_expected_solutions()

      # Test all fox-geese-corn problems
      problem_files = Path.wildcard("test/fixtures/hddl/fox_geese_corn_problem*.hddl")

      Enum.each(problem_files, fn problem_file ->
        problem_name = Path.basename(problem_file, ".hddl")
        expected = expected_solutions[problem_name]

        if expected do
          {:ok, content} = File.read(problem_file)
          {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

          # Extract initial state facts
          initial_facts = extract_initial_facts(ast)

          # Get point values
          pf = get_fact_value(initial_facts, :pf, 4)
          pg = get_fact_value(initial_facts, :pg, 4)
          pc = get_fact_value(initial_facts, :pc, 3)

          # Calculate expected objective from final state
          final_state = %{
            east_fox: expected["expected_final_state"]["east_fox"],
            east_geese: expected["expected_final_state"]["east_geese"],
            east_corn: expected["expected_final_state"]["east_corn"],
            pf: pf,
            pg: pg,
            pc: pc
          }

          objective = FoxGeeseCorn.calculate_objective(final_state)
          expected_objective = expected["expected_objective"]

          assert objective == expected_objective,
                 "Problem #{problem_name}: Objective #{objective} != expected #{expected_objective}"
        end
      end)
    end

    test "verifies classic fox-geese-corn problem (f=1, g=1, c=1)" do
      expected_solutions = load_expected_solutions()
      problem_file = "test/fixtures/hddl/fox_geese_corn_problem.hddl"
      expected = expected_solutions["fox_geese_corn_problem"]

      {:ok, content} = File.read(problem_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      initial_facts = extract_initial_facts(ast)

      # Verify initial state matches problem parameters
      assert get_fact_value(initial_facts, :west_fox, 0) == expected["f"]
      assert get_fact_value(initial_facts, :west_geese, 0) == expected["g"]
      assert get_fact_value(initial_facts, :west_corn, 0) == expected["c"]

      # Verify expected final state objective
      final_state = %{
        east_fox: expected["expected_final_state"]["east_fox"],
        east_geese: expected["expected_final_state"]["east_geese"],
        east_corn: expected["expected_final_state"]["east_corn"],
        pf: get_fact_value(initial_facts, :pf, 4),
        pg: get_fact_value(initial_facts, :pg, 4),
        pc: get_fact_value(initial_facts, :pc, 3)
      }

      objective = FoxGeeseCorn.calculate_objective(final_state)

      assert objective == expected["expected_objective"],
             "Objective #{objective} != expected #{expected["expected_objective"]}"

      # Verify expected trips if specified
      if expected["expected_trips"] do
        assert expected["expected_trips"] >= 1
      end
    end
  end

  defp extract_initial_facts({:problem, _name, elements}) do
    # Find :aria-initial-state
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
    # Try to convert to integer
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
