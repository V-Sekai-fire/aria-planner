# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Standalone test for Sourceror-style parser
# This test can run even if the main parser.ex has compilation errors

Code.require_file("lib/hddl/parser/sourceror_style.ex")

defmodule AriaPlanner.HDDL.Parser.SourcerorStyleTest do
  use ExUnit.Case

  alias AriaPlanner.HDDL.Parser.SourcerorStyle

  test "parses simple domain" do
    hddl = "(define (domain test) ())"
    result = SourcerorStyle.parse(hddl)
    assert {:ok, {:domain, name, elements}} = result
    assert name in ["test", :test]
    # Empty () may result in empty list or list with empty list - both are valid
    assert elements == [] or elements == [[]]
  end

  describe "domain with requirements" do
    test "parses domain name correctly" do
      hddl = "(define (domain test) (:requirements :strips))"
      result = SourcerorStyle.parse(hddl)
      assert {:ok, {:domain, name, _elements}} = result
      assert name in ["test", :test]
    end

    test "parses requirements structure" do
      hddl = "(define (domain test) (:requirements :strips))"
      result = SourcerorStyle.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert length(elements) == 1
      assert is_list(elements)
    end

    test "transforms requirements correctly" do
      hddl = "(define (domain test) (:requirements :strips))"
      result = SourcerorStyle.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:requirements, [:strips]}] = elements
    end

    test "handles multiple requirements" do
      hddl = "(define (domain test) (:requirements :strips :typing))"
      result = SourcerorStyle.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:requirements, reqs}] = elements
      assert :strips in reqs
      assert :typing in reqs
    end
  end
end

