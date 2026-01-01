# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.TrainSchedulingTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.HDDL

  @domain_file "test/fixtures/hddl/domains/train_scheduling.hddl"

  describe "domain parsing" do
    test "parses train_scheduling domain file" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      assert {:domain, :train_scheduling, elements} = ast
      assert is_list(elements)
    end

    test "domain has required elements" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)
      {:ok, domain} = HDDL.Importer.import_domain(ast)

      assert domain.domain_type == "navigation"
      assert domain.name == "Train Scheduling Domain"
    end

    test "domain has predicates" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      assert {:domain, _name, elements} = ast
      # Check for predicates in elements
      assert Enum.any?(elements, fn
               {:predicates, _} -> true
               _ -> false
             end)
    end
  end

  describe "problem parsing" do
    test "parses train_scheduling problem files" do
      problem_files = Path.wildcard("test/fixtures/hddl/train_scheduling_problem_*.hddl")

      Enum.each(problem_files, fn problem_file ->
        {:ok, content} = File.read(problem_file)
        {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

        assert {:problem, _name, elements} = ast
        assert is_list(elements)
      end)
    end
  end
end
