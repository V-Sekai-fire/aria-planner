# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.TinyCvrpTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.HDDL

  @domain_file "test/fixtures/hddl/domains/tiny_cvrp.hddl"

  describe "domain parsing" do
    test "parses tiny_cvrp domain file" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      assert {:domain, :tiny_cvrp, elements} = ast
      assert is_list(elements)
    end

    test "domain has required elements" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)
      {:ok, domain} = HDDL.Importer.import_domain(ast)

      assert domain.domain_type == "custom"
      assert domain.name == "tiny_cvrp"
    end
  end

  describe "problem parsing" do
    test "parses tiny_cvrp problem files" do
      problem_files = Path.wildcard("test/fixtures/hddl/tiny_cvrp_problem_*.hddl")

      Enum.each(problem_files, fn problem_file ->
        {:ok, content} = File.read(problem_file)
        {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

        assert {:problem, _name, elements} = ast
        assert is_list(elements)
      end)
    end
  end
end
