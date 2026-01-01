# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.ExporterTest do
  use ExUnit.Case

  alias AriaCore.Plan
  alias AriaCore.PlanningDomain
  alias AriaPlanner.HDDL.Exporter

  describe "export_domain/1" do
    test "exports simple domain" do
      {:ok, domain} =
        PlanningDomain.create(%{
          id: UUIDv7.generate(),
          domain_type: "custom",
          name: "test_domain",
          description: "Test domain"
        })

      hddl = Exporter.export_domain(domain)
      assert String.contains?(hddl, "define (domain test_domain)")
      assert String.contains?(hddl, ":requirements")
    end

    test "exports domain with entities" do
      {:ok, domain} =
        PlanningDomain.create(%{
          id: UUIDv7.generate(),
          domain_type: "custom",
          name: "test_domain",
          entities: [
            %{
              id: UUIDv7.generate(),
              type: "agent",
              capabilities: [:navigation, :transport],
              metadata: %{}
            }
          ]
        })

      hddl = Exporter.export_domain(domain)
      assert String.contains?(hddl, ":entities")
      assert String.contains?(hddl, "agent")
    end

    test "exports domain with actions" do
      {:ok, domain} =
        PlanningDomain.create(%{
          id: UUIDv7.generate(),
          domain_type: "custom",
          name: "test_domain",
          actions: [
            %{
              id: UUIDv7.generate(),
              name: "move",
              parameters: ["?x", "?y"],
              precondition: ["at", "?x"],
              effect: ["at", "?y"]
            }
          ]
        })

      hddl = Exporter.export_domain(domain)
      assert String.contains?(hddl, ":action move")
    end

    test "exports domain with commands" do
      {:ok, domain} =
        PlanningDomain.create(%{
          id: UUIDv7.generate(),
          domain_type: "custom",
          name: "test_domain",
          commands: [
            %{
              id: UUIDv7.generate(),
              name: "execute",
              parameters: ["?x"],
              precondition: ["ready", "?x"],
              effect: ["done", "?x"]
            }
          ]
        })

      hddl = Exporter.export_domain(domain)
      assert String.contains?(hddl, ":command execute")
    end

    test "exports domain with multigoals" do
      {:ok, domain} =
        PlanningDomain.create(%{
          id: UUIDv7.generate(),
          domain_type: "custom",
          name: "test_domain",
          multigoals: [
            %{
              goal_tag: :transport_all,
              goals: [
                ["at", "item1", "location1"],
                ["at", "item2", "location2"]
              ]
            }
          ]
        })

      hddl = Exporter.export_domain(domain)
      assert String.contains?(hddl, ":multigoal")
    end
  end

  describe "export_problem/1" do
    test "exports plan" do
      {:ok, plan} =
        Plan.create(%{
          id: UUIDv7.generate(),
          name: "test_plan",
          persona_id: UUIDv7.generate(),
          domain_type: "blocks_world"
        })

      hddl = Exporter.export_problem(plan)
      assert String.contains?(hddl, "define (problem test_plan)")
      assert String.contains?(hddl, ":domain")
    end
  end

  describe "export_temporal_metadata/1" do
    test "exports temporal metadata" do
      alias AriaPlanner.Planner.{EntityRequirement, PlannerMetadata}

      {:ok, metadata} =
        PlannerMetadata.new("PT5M", [
          EntityRequirement.new!("agent", [:navigation])
        ])

      hddl = Exporter.export_temporal_metadata(metadata)
      assert String.contains?(hddl, ":aria-temporal-metadata")
      assert String.contains?(hddl, "PT5M")
      assert String.contains?(hddl, ":requires-entities")
    end

    test "returns empty string for nil" do
      assert Exporter.export_temporal_metadata(nil) == ""
    end
  end
end
