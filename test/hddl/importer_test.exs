# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.ImporterTest do
  use ExUnit.Case

  alias AriaCore.PlanningDomain
  alias AriaPlanner.HDDL.{Importer, Parser}
  alias AriaPlanner.Planner.PlannerMetadata

  describe "import_domain/1" do
    test "imports simple domain" do
      hddl = "(define (domain test) (:requirements :strips))"

      {:ok, ast, _, _, _, _} = Parser.parse(hddl)
      assert {:ok, %PlanningDomain{} = domain} = Importer.import_domain(ast)
      assert domain.domain_type == "custom"
      assert domain.name == "test"
    end

    test "imports domain with aria-domain-metadata" do
      hddl = """
      (define (domain test)
        (:aria-domain-metadata
          :id "123"
          :name "Test Domain"
          :description "Test description"
          :domain-type navigation
          :version 2
          :state active
        )
      )
      """

      {:ok, ast, _, _, _, _} = Parser.parse(hddl)
      assert {:ok, %PlanningDomain{} = domain} = Importer.import_domain(ast)
      assert domain.domain_type == "navigation"
      assert domain.name == "Test Domain"
      assert domain.description == "Test description"
      assert domain.version == 2
      assert domain.state == :active
    end

    test "imports domain with entities" do
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

      {:ok, ast, _, _, _, _} = Parser.parse(hddl)
      assert {:ok, %PlanningDomain{} = domain} = Importer.import_domain(ast)
      assert length(domain.entities) == 1
      entity = List.first(domain.entities)
      assert entity.type == "agent"
      assert :navigation in entity.capabilities
      assert :transport in entity.capabilities
    end

    test "imports domain with actions" do
      hddl = """
      (define (domain test)
        (:action move
          :parameters (?x ?y)
          :precondition (at ?x)
          :effect (at ?y)
        )
      )
      """

      {:ok, ast, _, _, _, _} = Parser.parse(hddl)
      assert {:ok, %PlanningDomain{} = domain} = Importer.import_domain(ast)
      assert length(domain.actions) == 1
      action = List.first(domain.actions)
      assert action.name == "move"
    end

    test "imports domain with commands" do
      hddl = """
      (define (domain test)
        (:command execute
          :parameters (?x)
          :precondition (ready ?x)
          :effect (done ?x)
        )
      )
      """

      {:ok, ast, _, _, _, _} = Parser.parse(hddl)
      assert {:ok, %PlanningDomain{} = domain} = Importer.import_domain(ast)
      assert length(domain.commands) == 1
      command = List.first(domain.commands)
      assert command.name == "execute"
    end

    test "imports temporal metadata" do
      hddl = """
      (define (domain test)
        (:action move
          :aria-temporal-metadata (
            :duration "PT5M"
            :start-time "2025-01-01T10:00:00Z"
            :requires-entities (
              (:entity agent :capabilities (:navigation))
            )
          )
        )
      )
      """

      {:ok, ast, _, _, _, _} = Parser.parse(hddl)
      assert {:ok, %PlanningDomain{} = domain} = Importer.import_domain(ast)
      action = List.first(domain.actions)
      assert action.temporal_metadata != nil
    end
  end

  describe "import_problem/1" do
    test "imports problem definition" do
      hddl = """
      (define (problem test_problem)
        (:domain test)
        (:aria-plan
          :name "Test Plan"
        )
      )
      """

      {:ok, ast, _, _, _, _} = Parser.parse(hddl)
      assert {:ok, %AriaCore.Plan{} = plan} = Importer.import_problem(ast)
      assert plan.name == "Test Plan"
    end
  end

  describe "import_temporal_metadata/1" do
    test "imports temporal metadata with duration and entities" do
      hddl = """
      (define (domain test)
        (:action move
          :aria-temporal-metadata (
            :duration "PT5M"
            :requires-entities (
              (:entity agent :capabilities (:navigation))
            )
          )
        )
      )
      """

      {:ok, ast, _, _, _, _} = Parser.parse(hddl)
      {:domain, _, elements} = ast

      {:action, _, action_elements} =
        Enum.find(elements, fn
          {:action, _, _} -> true
          _ -> false
        end)

      {:aria_temporal_metadata, metadata_elements} =
        Enum.find(action_elements, fn
          {:aria_temporal_metadata, _} -> true
          _ -> false
        end)

      assert {:ok, %PlannerMetadata{} = metadata} =
               Importer.import_temporal_metadata({:aria_temporal_metadata, metadata_elements})

      assert metadata.duration == "PT5M"
      assert length(metadata.requires_entities) == 1
    end
  end
end
