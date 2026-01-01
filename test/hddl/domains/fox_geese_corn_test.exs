# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.FoxGeeseCornTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.HDDL

  @domain_file "test/fixtures/hddl/domains/fox_geese_corn.hddl"

  describe "domain parsing" do
    test "parses fox_geese_corn domain file" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      assert {:domain, :fox_geese_corn, elements} = ast
      assert is_list(elements)
    end

    test "domain has required elements" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)
      {:ok, domain} = HDDL.Importer.import_domain(ast)

      assert domain.domain_type == "custom"
      assert domain.name == "fox_geese_corn"
    end
  end

  describe "problem parsing" do
    test "parses fox_geese_corn problem files" do
      problem_files = Path.wildcard("test/fixtures/hddl/fox_geese_corn_problem_*.hddl")

      Enum.each(problem_files, fn problem_file ->
        {:ok, content} = File.read(problem_file)
        {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

        assert {:problem, _name, elements} = ast
        assert is_list(elements)
      end)
    end
  end
end
