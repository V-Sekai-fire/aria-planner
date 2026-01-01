# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.CableTreeWiringTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.HDDL

  @domain_file "test/fixtures/hddl/domains/cable_tree_wiring.hddl"

  describe "domain parsing" do
    test "parses cable_tree_wiring domain file" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      assert {:domain, :cable_tree_wiring, elements} = ast
      assert is_list(elements)
    end

    test "domain has required elements" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)
      {:ok, domain} = HDDL.Importer.import_domain(ast)

      assert domain.domain_type == "navigation"
      assert domain.name == "Cable Tree Wiring Domain"
    end
  end

  describe "problem parsing" do
    test "parses cable_tree_wiring problem files" do
      problem_files = Path.wildcard("test/fixtures/hddl/cable_tree_wiring_problem_*.hddl")

      Enum.each(problem_files, fn problem_file ->
        {:ok, content} = File.read(problem_file)
        {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

        assert {:problem, _name, elements} = ast
        assert is_list(elements)
      end)
    end
  end
end
