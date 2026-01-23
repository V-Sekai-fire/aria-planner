# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.GraphClearTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.HDDL

  @domain_file "test/fixtures/hddl/domains/graph_clear.hddl"

  describe "domain parsing" do
    test "parses graph_clear domain file" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      assert {:domain, :graph_clear, elements} = ast
      assert is_list(elements)
    end

    test "domain has required elements" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)
      {:ok, domain} = HDDL.Importer.import_domain(ast)

      assert domain.domain_type == "navigation"
      assert domain.name == "Graph Clear Domain"
    end
  end

  describe "problem parsing" do
    test "parses graph_clear problem files if they exist" do
      problem_files = Path.wildcard("test/fixtures/hddl/graph_clear_problem_*.hddl")

      if length(problem_files) > 0 do
        Enum.each(problem_files, fn problem_file ->
          {:ok, content} = File.read(problem_file)
          {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

          assert {:problem, _name, elements} = ast
          assert is_list(elements)
        end)
      else
        # No problem files yet - just verify domain parses
        assert true
      end
    end
  end
end
