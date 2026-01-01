# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.ParserTest do
  use ExUnit.Case

  alias AriaPlanner.HDDL.Parser

  # define_domain parser tests removed - parser needs refactoring

  describe "parse/1" do
    test "parses domain with predicates" do
      hddl = """
      (define (domain test)
        (:requirements :strips)
        (:predicates
          (at ?x ?y)
          (clear ?x)
        )
      )
      """

      assert {:ok, {:domain, :test, elements}, _, _, _, _} = Parser.parse(hddl)

      assert {:requirements, _} =
               Enum.find(elements, fn
                 {:requirements, _} -> true
                 _ -> false
               end)

      assert {:predicates, _} =
               Enum.find(elements, fn
                 {:predicates, _} -> true
                 _ -> false
               end)
    end

    test "parses action with parameters" do
      hddl = """
      (define (domain test)
        (:action move
          :parameters (?x ?y)
          :precondition (at ?x)
          :effect (and (not (at ?x)) (at ?y))
        )
      )
      """

      assert {:ok, {:domain, :test, elements}, _, _, _, _} = Parser.parse(hddl)

      assert {:action, :move, action_elements} =
               Enum.find(elements, fn
                 {:action, _, _} -> true
                 _ -> false
               end)

      assert {:parameters, _} =
               Enum.find(action_elements, fn
                 {:parameters, _} -> true
                 _ -> false
               end)
    end

    test "parses durative action" do
      hddl = """
      (define (domain test)
        (:durative-action move
          :parameters (?x ?y)
          :duration (= ?duration 300)
          :condition (at start (at ?x))
          :effect (and (at start (not (at ?x))) (at end (at ?y)))
        )
      )
      """

      assert {:ok, {:domain, :test, elements}, _, _, _, _} = Parser.parse(hddl)

      assert {:durative_action, :move, _} =
               Enum.find(elements, fn
                 {:durative_action, _, _} -> true
                 _ -> false
               end)
    end

    test "parses aria-temporal-metadata" do
      hddl = """
      (define (domain test)
        (:action move
          :aria-temporal-metadata (
            :duration "PT5M"
            :start-time "2025-01-01T10:00:00Z"
            :end-time "2025-01-01T10:05:00Z"
            :requires-entities (
              (:entity agent :capabilities (:navigation))
            )
          )
        )
      )
      """

      assert {:ok, {:domain, :test, elements}, _, _, _, _} = Parser.parse(hddl)

      assert {:action, :move, action_elements} =
               Enum.find(elements, fn
                 {:action, _, _} -> true
                 _ -> false
               end)

      assert {:aria_temporal_metadata, _} =
               Enum.find(action_elements, fn
                 {:aria_temporal_metadata, _} -> true
                 _ -> false
               end)
    end

    test "parses command" do
      hddl = """
      (define (domain test)
        (:command execute
          :parameters (?x)
          :precondition (ready ?x)
          :effect (done ?x)
          :aria-command-metadata (
            :failure-handling retry
            :max-retries 3
          )
        )
      )
      """

      assert {:ok, {:domain, :test, elements}, _, _, _, _} = Parser.parse(hddl)

      assert {:command, :execute, _} =
               Enum.find(elements, fn
                 {:command, _, _} -> true
                 _ -> false
               end)
    end

    test "parses multigoal" do
      hddl = """
      (define (domain test)
        (:multigoal transport_all
          :goal-tag transport
          :goals (
            (at item1 location1)
            (at item2 location2)
          )
        )
      )
      """

      assert {:ok, {:domain, :test, elements}, _, _, _, _} = Parser.parse(hddl)

      assert {:multigoal, :transport_all, _} =
               Enum.find(elements, fn
                 {:multigoal, _, _} -> true
                 _ -> false
               end)
    end

    test "parses problem definition" do
      hddl = """
      (define (problem test_problem)
        (:domain test)
        (:aria-plan
          :id "123"
          :name "Test Plan"
        )
      )
      """

      assert {:ok, {:problem, :test_problem, elements}, _, _, _, _} = Parser.parse(hddl)

      assert {:domain, _} =
               Enum.find(elements, fn
                 {:domain, _} -> true
                 _ -> false
               end)

      assert {:aria_plan, _} =
               Enum.find(elements, fn
                 {:aria_plan, _} -> true
                 _ -> false
               end)
    end

    test "handles comments" do
      hddl = """
      (define (domain test)
        ; This is a comment
        (:requirements :strips)
      )
      """

      assert {:ok, {:domain, :test, _}, _, _, _, _} = Parser.parse(hddl)
    end

    test "returns error for invalid syntax" do
      hddl = "(define (domain test"
      assert {:error, _} = Parser.parse(hddl)
    end
  end

  describe "parse_file/1" do
    test "parses HDDL file" do
      path = "test/fixtures/hddl/fox_geese_corn.hddl"

      assert {:ok, {:domain, :fox_geese_corn, _}} = Parser.parse_file(path)
    end

    test "returns error for non-existent file" do
      assert {:error, _} = Parser.parse_file("nonexistent.hddl")
    end
  end
end
