# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Standalone test for recursive descent parser
# This test can run even if the main parser.ex has compilation errors

Code.require_file("lib/hddl/parser/recursive_descent.ex")

defmodule AriaPlanner.HDDL.Parser.RecursiveDescentTest do
  use ExUnit.Case

  alias AriaPlanner.HDDL.Parser.RecursiveDescent

  test "parses simple domain" do
    hddl = "(define (domain test) ())"
    result = RecursiveDescent.parse(hddl)
    assert {:ok, {:domain, name, elements}} = result
    assert name in ["test", :test]
    # Empty () may result in empty list or list with empty list - both are valid
    assert elements == [] or elements == [[]]
  end

  describe "domain with requirements" do
    test "parses domain name correctly" do
      hddl = "(define (domain test) (:requirements :strips))"
      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, name, _elements}} = result
      assert name in ["test", :test]
    end

    test "parses requirements structure" do
      hddl = "(define (domain test) (:requirements :strips))"
      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert length(elements) == 1
      assert is_list(elements)
    end

    test "transforms requirements correctly" do
      hddl = "(define (domain test) (:requirements :strips))"
      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:requirements, [:strips]}] = elements
    end

    test "handles multiple requirements" do
      hddl = "(define (domain test) (:requirements :strips :typing))"
      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:requirements, reqs}] = elements
      assert :strips in reqs
      assert :typing in reqs
    end
  end

  describe "aria extensions" do
    test "parses domain metadata" do
      hddl = """
      (define (domain test)
        (:aria-domain-metadata
          :name "Test Domain"
          :domain-type navigation
          :version 1
          :state active
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:aria_domain_metadata, metadata}] = elements
      assert Keyword.get(metadata, :name) == "Test Domain"
      assert Keyword.get(metadata, :domain_type) == :navigation
      assert Keyword.get(metadata, :version) == 1
      assert Keyword.get(metadata, :state) == :active
    end

    test "parses temporal metadata with ISO 8601" do
      hddl = """
      (define (domain test)
        (:durative-action test_action
          :parameters (?x)
          :duration (= ?duration 300)
          (:aria-temporal-metadata
            :duration "PT5M"
            :start-time "2025-01-01T10:00:00Z"
            :end-time "2025-01-01T10:05:00Z"
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:durative_action, :test_action, action_elements}] = elements
      temporal_metadata = Keyword.get(action_elements, :aria_temporal_metadata)
      assert Keyword.get(temporal_metadata, :duration) == "PT5M"
      assert Keyword.get(temporal_metadata, :start_time) == "2025-01-01T10:00:00Z"
      assert Keyword.get(temporal_metadata, :end_time) == "2025-01-01T10:05:00Z"
    end

    test "parses entity requirements" do
      hddl = """
      (define (domain test)
        (:durative-action test_action
          :parameters (?x)
          :duration (= ?duration 300)
          (:aria-temporal-metadata
            :duration "PT5M"
            :requires-entities (
              (:entity agent :capabilities (:navigation :transport))
            )
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:durative_action, :test_action, action_elements}] = elements
      temporal_metadata = Keyword.get(action_elements, :aria_temporal_metadata)
      entities = Keyword.get(temporal_metadata, :requires_entities)
      assert [%{type: :entity, entity_type: :agent, capabilities: [:navigation, :transport]}] = entities
    end

    test "parses commands" do
      hddl = """
      (define (domain test)
        (:command c_test
          :parameters (?x)
          :precondition (test ?x)
          :effect (done ?x)
          (:aria-command-metadata
            :failure-handling retry
            :max-retries 3
            :side-effects true
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:command, :c_test, command_elements}] = elements
      assert Keyword.get(command_elements, :parameters) != nil
      command_metadata = Keyword.get(command_elements, :aria_command_metadata)
      assert Keyword.get(command_metadata, :failure_handling) == :retry
      assert Keyword.get(command_metadata, :max_retries) == 3
      assert Keyword.get(command_metadata, :side_effects) == true
    end

    test "parses multigoals" do
      hddl = """
      (define (domain test)
        (:multigoal transport_all_items
          :goal-tag transport_all
          :goals (
            (east_fox 1)
            (east_geese 1)
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:multigoal, :transport_all_items, multigoal_elements}] = elements
      assert Keyword.get(multigoal_elements, :goal_tag) == :transport_all
      goals = Keyword.get(multigoal_elements, :goals)
      assert length(goals) == 2
    end

    test "parses goal methods" do
      hddl = """
      (define (domain test)
        (:goal-method achieve_transport
          :goal (transport ?items)
          :subtasks (
            (transport_item ?items)
            (verify_safe ?items)
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:goal_method, :achieve_transport, method_elements}] = elements
      assert Keyword.get(method_elements, :goal) != nil
      subtasks = Keyword.get(method_elements, :subtasks)
      assert length(subtasks) == 2
    end

    test "parses entities" do
      hddl = """
      (define (domain test)
        (:entities
          (:entity agent
            :type agent
            :capabilities (:navigation :transport)
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:entities, [entity]}] = elements
      assert entity.type == :entity
      assert entity.name == :agent
      assert entity.entity_type == :agent
      assert entity.capabilities == [:navigation, :transport]
    end

    test "parses predicate schemas" do
      hddl = """
      (define (domain test)
        (:aria-predicate-schemas
          (:predicate east_fox
            :category state
            :multi-valued false
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:aria_predicate_schemas, [schema]}] = elements
      assert schema.type == :predicate
      assert schema.name == :east_fox
      assert schema.category == :state
      assert schema.multi_valued == false
    end

    test "parses planner state" do
      hddl = """
      (define (problem test_problem)
        (:domain test)
        (:aria-initial-state
          :current-time "2025-01-01T10:00:00Z"
          :entity-capabilities (
            (:entity agent_1 :capabilities (:navigation :transport))
          )
          :facts (
            (:fact west_fox state :value 1)
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:problem, _name, elements}} = result
      # Problem elements include both :domain reference and :aria_initial_state
      assert {:domain, _} =
               Enum.find(elements, fn
                 {:domain, _} -> true
                 _ -> false
               end)

      assert {:aria_initial_state, state_elements} =
               Enum.find(elements, fn
                 {:aria_initial_state, _} -> true
                 _ -> false
               end)

      assert Keyword.get(state_elements, :current_time) == "2025-01-01T10:00:00Z"
      facts = Keyword.get(state_elements, :facts)
      assert [%{type: :fact, predicate: :west_fox, subject: :state, value: 1}] = facts
    end

    test "parses plans" do
      hddl = """
      (define (problem test_problem)
        (:domain test)
        (:aria-plan
          :id "01234567-89ab-cdef-0123-456789abcdef"
          :name "Test Plan"
          :persona-id "persona_123"
          :domain-type navigation
          :execution-status planned
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:problem, _name, elements}} = result
      # Problem elements include both :domain reference and :aria_plan
      assert {:domain, _} =
               Enum.find(elements, fn
                 {:domain, _} -> true
                 _ -> false
               end)

      assert {:aria_plan, plan_elements} =
               Enum.find(elements, fn
                 {:aria_plan, _} -> true
                 _ -> false
               end)

      assert Keyword.get(plan_elements, :id) == "01234567-89ab-cdef-0123-456789abcdef"
      assert Keyword.get(plan_elements, :name) == "Test Plan"
      # Hyphens in keywords are converted to underscores
      assert Keyword.get(plan_elements, :persona_id) == "persona_123"
      assert Keyword.get(plan_elements, :domain_type) == :navigation
      assert Keyword.get(plan_elements, :execution_status) == :planned
    end

    test "parses blacklisting" do
      hddl = """
      (define (problem test_problem)
        (:domain test)
        (:aria-blacklist
          :blacklisted-commands (
            (c_cross_east 1 1 0)
          )
          :blacklisted-methods (
            (transport_all items)
          )
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:problem, _name, elements}} = result
      # Problem elements include both :domain reference and :aria_blacklist
      assert {:domain, _} =
               Enum.find(elements, fn
                 {:domain, _} -> true
                 _ -> false
               end)

      assert {:aria_blacklist, blacklist_elements} =
               Enum.find(elements, fn
                 {:aria_blacklist, _} -> true
                 _ -> false
               end)

      commands = Keyword.get(blacklist_elements, :blacklisted_commands)
      assert length(commands) == 1
      methods = Keyword.get(blacklist_elements, :blacklisted_methods)
      assert length(methods) == 1
    end

    test "parses STN temporal constraints" do
      hddl = """
      (define (domain test)
        (:aria-temporal-constraints
          (:stn
            (:time-point action1_start)
            (:time-point action1_end)
            (:constraint action1_start action1_end "PT10M" "PT15M")
          )
          :iso8601-format true
        )
      )
      """

      result = RecursiveDescent.parse(hddl)
      assert {:ok, {:domain, _name, elements}} = result
      assert [{:aria_temporal_constraints, constraint_elements}] = elements
      stn = Keyword.get(constraint_elements, :stn)
      assert length(stn) == 3
      assert Keyword.get(constraint_elements, :iso8601_format) == true
    end
  end
end
