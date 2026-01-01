# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.PlanManagerTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.PlanManager

  describe "create_plan/4" do
    test "creates plan with required parameters" do
      persona_id = UUIDv7.generate()

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          "Test Plan",
          "tactical"
        )

      assert plan.persona_id == persona_id
      assert plan.name == "Test Plan"
      assert plan.domain_type == "tactical"
      assert plan.objectives == []
      assert plan.success_probability == 0.5
    end

    test "creates plan with objectives list" do
      persona_id = UUIDv7.generate()
      objectives = ["task1", "task2", "task3"]

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          "Plan with Objectives",
          "blocks_world",
          objectives: objectives
        )

      assert plan.objectives == objectives
    end

    test "creates plan with todo list (backward compatibility)" do
      persona_id = UUIDv7.generate()
      todo = ["task1", "task2", "task3"]

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          "Plan with Todo",
          "blocks_world",
          todo: todo
        )

      assert plan.objectives == todo
    end

    test "creates plan with custom success probability" do
      persona_id = UUIDv7.generate()

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          "High Confidence Plan",
          "tactical",
          success_probability: 0.95
        )

      assert plan.success_probability == 0.95
    end

    test "creates plan with all options" do
      persona_id = UUIDv7.generate()
      objectives = ["step1", "step2"]
      success_probability = 0.85

      {:ok, plan} =
        PlanManager.create_plan(
          persona_id,
          "Complete Plan",
          "navigation",
          objectives: objectives,
          success_probability: success_probability
        )

      assert plan.objectives == objectives
      assert plan.success_probability == success_probability
      assert plan.planning_timestamp != nil
    end

    test "creates plan for different domain types" do
      persona_id = UUIDv7.generate()

      domain_types = [
        "blocks_world",
        "tactical",
        "navigation",
        "social",
        "economic",
        "exploration",
        "stealth"
      ]

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
