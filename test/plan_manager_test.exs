# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.PlanManagerTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.PlanManager
  alias AriaPlanner.FixtureHelpers, as: Fixtures

  describe "create_plan/4" do
    test "creates plan with required parameters" do
      fixture = Fixtures.load_fixture("plan_manager_create_plan", "plan_results")
      [scenario] = Enum.filter(fixture["scenarios"], &(&1["description"] == "required parameters"))
      persona_id = UUIDv7.generate()

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          scenario["input"]["name"],
          scenario["input"]["domain_type"]
        )

      assert plan.persona_id == persona_id
      assert plan.name == scenario["expected"]["name"]
      assert plan.domain_type == scenario["expected"]["domain_type"]
      assert plan.objectives == scenario["expected"]["objectives"]
      assert plan.success_probability == scenario["expected"]["success_probability"]
    end

    test "creates plan with objectives list" do
      fixture = Fixtures.load_fixture("plan_manager_create_plan", "plan_results")
      [scenario] = Enum.filter(fixture["scenarios"], &(&1["description"] == "objectives list"))
      persona_id = UUIDv7.generate()
      input = scenario["input"]

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          input["name"],
          input["domain_type"],
          objectives: input["objectives"]
        )

      assert plan.objectives == scenario["expected"]["objectives"]
    end

    test "creates plan with todo list (backward compatibility)" do
      fixture = Fixtures.load_fixture("plan_manager_create_plan", "plan_results")
      [scenario] = Enum.filter(fixture["scenarios"], &(&1["description"] == "todo list (backward compatibility)"))
      persona_id = UUIDv7.generate()
      input = scenario["input"]

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          input["name"],
          input["domain_type"],
          todo: input["todo"]
        )

      assert plan.objectives == scenario["expected"]["objectives"]
    end

    test "creates plan with custom success probability" do
      fixture = Fixtures.load_fixture("plan_manager_create_plan", "plan_results")
      [scenario] = Enum.filter(fixture["scenarios"], &(&1["description"] == "custom success probability"))
      persona_id = UUIDv7.generate()
      input = scenario["input"]

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          input["name"],
          input["domain_type"],
          success_probability: input["success_probability"]
        )

      assert plan.success_probability == scenario["expected"]["success_probability"]
    end

    test "creates plan with all options" do
      fixture = Fixtures.load_fixture("plan_manager_create_plan", "plan_results")
      [scenario] = Enum.filter(fixture["scenarios"], &(&1["description"] == "all options"))
      persona_id = UUIDv7.generate()
      input = scenario["input"]
      expected = scenario["expected"]

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          input["name"],
          input["domain_type"],
          objectives: input["objectives"],
          success_probability: input["success_probability"]
        )

      assert plan.objectives == expected["objectives"]
      assert plan.success_probability == expected["success_probability"]
      assert plan.planning_timestamp != nil
    end

    test "creates plan for different domain types" do
      fixture = Fixtures.load_fixture("plan_manager_create_plan", "plan_results")
      domain_types = fixture["domain_types"]
      persona_id = UUIDv7.generate()

      for domain_type <- domain_types do
        {:ok, plan} =
          PlanManager.create_plan(
            persona_id,
            "Plan for #{domain_type}",
            domain_type
          )

        assert plan.domain_type == domain_type
      end
    end
  end
end
