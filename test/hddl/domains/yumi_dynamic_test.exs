# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.YumiDynamicTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.HDDL

  @domain_file "test/fixtures/hddl/domains/yumi_dynamic.hddl"

  describe "domain parsing" do
    test "parses yumi_dynamic domain file" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      assert {:domain, :yumi_dynamic, elements} = ast
      assert is_list(elements)
    end

    test "domain has required elements" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)
      {:ok, domain} = HDDL.Importer.import_domain(ast)

      assert domain.domain_type == "navigation"
      assert domain.name == "Yumi Dynamic Domain"
    end
  end

  describe "problem parsing" do
    test "parses yumi_dynamic problem files" do
      problem_files = Path.wildcard("test/fixtures/hddl/yumi_dynamic_problem_*.hddl")

      Enum.each(problem_files, fn problem_file ->
        {:ok, content} = File.read(problem_file)
        {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

        assert {:problem, _name, elements} = ast
        assert is_list(elements)
      end)
    end

    test "verifies yumi_dynamic problems have required facts" do
      problem_files = Path.wildcard("test/fixtures/hddl/yumi_dynamic_problem_*.hddl")

      Enum.each(problem_files, fn problem_file ->
        {:ok, content} = File.read(problem_file)
        {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

        {:problem, _name, elements} = ast
        {:aria_initial_state, state_elements} = Enum.find(elements, fn {k, _} -> k == :aria_initial_state end)
        facts = Keyword.get(state_elements, :facts, [])

        # Verify key facts exist (yumi_dynamic has complex data structures)
        fact_predicates = Enum.map(facts, fn %{predicate: p} -> p end)

        # Check for common yumi_dynamic facts
        assert :task_durations_array in fact_predicates or
                 Enum.any?(fact_predicates, fn p -> String.contains?(to_string(p), "task_duration") end),
               "Problem #{Path.basename(problem_file)} should have task_durations fact"
      end)
    end
  end
end
