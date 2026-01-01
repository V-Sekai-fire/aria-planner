# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Domains.AircraftDisassemblyTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.HDDL

  @domain_file "test/fixtures/hddl/domains/aircraft_disassembly.hddl"

  describe "domain parsing" do
    test "parses aircraft_disassembly domain file" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

      assert {:domain, :aircraft_disassembly, elements} = ast
      assert is_list(elements)
    end

    test "domain has required elements" do
      {:ok, content} = File.read(@domain_file)
      {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)
      {:ok, domain} = HDDL.Importer.import_domain(ast)

      assert domain.domain_type == "custom"
      assert domain.name == "aircraft_disassembly"
      assert length(domain.actions) > 0
    end
  end

  describe "problem parsing" do
    test "parses aircraft_disassembly problem files" do
      problem_files = Path.wildcard("test/fixtures/hddl/aircraft_disassembly_problem_*.hddl")

      Enum.each(problem_files, fn problem_file ->
        {:ok, content} = File.read(problem_file)
        {:ok, ast, _, _, _, _} = HDDL.Parser.parse(content)

        assert {:problem, _name, elements} = ast
        assert is_list(elements)
      end)
    end
  end
end
