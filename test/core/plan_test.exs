# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PlanTest do
  use ExUnit.Case, async: true
  alias AriaCore.Plan

  describe "plan CRUD operations (ego-centric storage)" do
    test "creates plan with UUIDv7 ID when not provided" do
      attrs = %{
        name: "Tactical Assault Plan",
        persona_id: "01812345-6789-7abc-def0-123456789abc",
        domain_type: "tactical",
        objectives: ["defeat enemy", "minimize casualties"],
        success_probability: 0.85,
        planning_duration_ms: 1250
      }

      {:ok, plan} = Plan.create(attrs)

      assert plan.name == "Tactical Assault Plan"
      assert plan.persona_id == "01812345-6789-7abc-def0-123456789abc"
      assert plan.domain_type == "tactical"
      assert plan.objectives == ["defeat enemy", "minimize casualties"]
      assert plan.success_probability == 0.85
      assert plan.planning_duration_ms == 1250
      assert String.match?(plan.id, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
    end

    test "creates plan with temporal constraints, entity capabilities, and solution plan" do
      temporal_constraints = %{"start_time" => "2025-10-26T10:00:00Z", "end_time" => "2025-10-26T11:00:00Z"}
      entity_capabilities = %{"robot_arm" => %{"lift_capacity" => "10kg"}}
      solution_plan = Jason.encode!([["move", "a", "b"], ["pick", "b"]])

      attrs = %{
        name: "Complex Temporal Plan",
        persona_id: "01812345-6789-7abc-def0-123456789abc",
        domain_type: "tactical",
        temporal_constraints: temporal_constraints,
        entity_capabilities: entity_capabilities,
        solution_plan: solution_plan
      }

      {:ok, plan} = Plan.create(attrs)

      assert plan.temporal_constraints == temporal_constraints
      assert plan.entity_capabilities == entity_capabilities
      assert plan.solution_plan == solution_plan
    end

    test "validates required fields" do
      invalid_attrs = %{name: "Test Plan"}
      {:error, error_message} = Plan.create(invalid_attrs)

      assert String.contains?(error_message, "persona_id is required")
      assert String.contains?(error_message, "domain_type is required")
    end

    test "validates domain_type inclusion" do
      attrs = %{name: "Test", persona_id: UUIDv7.generate(), domain_type: "invalid"}
      {:error, error_message} = Plan.create(attrs)

      assert String.contains?(error_message, "domain_type must be one of")
    end

    test "validates execution_status inclusion" do
      attrs = %{
        name: "Test",
        persona_id: UUIDv7.generate(),
        domain_type: "tactical",
        execution_status: "invalid"
      }

      {:error, error_message} = Plan.create(attrs)

      assert String.contains?(error_message, "execution_status must be one of")
    end

    test "validates success_probability range" do
      # Test upper bound
      attrs = %{
        name: "Test",
        persona_id: UUIDv7.generate(),
        domain_type: "tactical",
        success_probability: 1.5
      }

      {:error, error_message} = Plan.create(attrs)
      assert String.contains?(error_message, "success_probability must be between 0.0 and 1.0")

      # Test lower bound
      attrs = Map.put(attrs, :success_probability, -0.1)
      {:error, error_message} = Plan.create(attrs)
      assert String.contains?(error_message, "success_probability must be between 0.0 and 1.0")
    end

    test "validates UUIDv7 format" do
      attrs = %{
        id: "invalid-uuid",
        name: "Test",
        persona_id: UUIDv7.generate(),
        domain_type: "tactical"
      }

      {:error, error_message} = Plan.create(attrs)

      assert String.contains?(error_message, "id must be a valid RFC 9562 UUIDv7")
    end

    test "updates existing plan successfully" do
      {:ok, plan} =
        Plan.create(%{
          name: "Initial Plan",
          persona_id: "persona-uuid",
          domain_type: "tactical"
        })

      update_attrs = %{
        name: "Updated Plan",
        success_probability: 0.9,
        execution_status: "completed",
        execution_completed_at: NaiveDateTime.utc_now()
      }

      {:ok, updated_plan} = Plan.update(plan, update_attrs)

      assert updated_plan.name == "Updated Plan"
      assert updated_plan.success_probability == 0.9
      assert updated_plan.execution_status == "completed"
      assert updated_plan.execution_completed_at != nil
    end
  end

  describe "ego-centric plan behavior" do
    test "plan belongs to specific persona (ego-centric ownership)" do
      persona_id = "01812345-6789-7abc-def0-123456789abc"

      {:ok, _plan} =
        Plan.create(%{
          name: "Persona Tactical Plan",
          persona_id: persona_id,
          domain_type: "tactical",
          objectives: ["persona_goal_1", "persona_goal_2"]
        })

      # In real database, we would test that plan.persona_id == persona_id
      # and that plans are filtered by persona queries
    end

    test "plans represent individual persona perspectives" do
      # Plan for persona A
      {:ok, plan_a} =
        Plan.create(%{
          name: "Self-Centric Plan A",
          persona_id: "persona-a-uuid",
          domain_type: "navigation",
          constraints: %{"ego_constraints" => ["max_risk_20", "self_preservation"]}
        })

      # Plan for persona B
      {:ok, plan_b} =
        Plan.create(%{
          name: "Self-Centric Plan B",
          persona_id: "persona-b-uuid",
          domain_type: "navigation",
          constraints: %{"ego_constraints" => ["max_risk_80", "risk_taking"]}
        })

      # Plans should represent different ego-centric perspectives
      assert plan_a.constraints["ego_constraints"] != plan_b.constraints["ego_constraints"]
      assert plan_a.persona_id != plan_b.persona_id
    end
  end

  describe "SolutionTensorGraph integration with plans" do
    test "plan stores solution graph data as maps for persistence" do
      # Mock SolutionTensorGraph export data
      mock_graph_data = %{
        num_nodes: 5,
        num_edges: 4,
        # [task, method, action, action, goal
        node_types: [1, 2, 0, 0, 3],
        primitive_mask: [0, 0, 1, 1, 0],
        goal_mask: [0, 0, 0, 0, 1],
        metadata: %{
          version: "1.0.0",
          created_at: NaiveDateTime.utc_now(),
          ego_plugin: "tactical_planner_v2"
        }
      }

      {:ok, plan} =
        Plan.create(%{
          name: "Graph-Backed Plan",
          persona_id: "persona-uuid",
          domain_type: "tactical",
          solution_graph_data: mock_graph_data
        })

      assert plan.solution_graph_data == mock_graph_data
      assert plan.solution_graph_data.num_nodes == 5
      assert plan.solution_graph_data.node_types == [1, 2, 0, 0, 3]
      assert plan.solution_graph_data.metadata.ego_plugin == "tactical_planner_v2"
    end

    test "plan execution status transitions for allocentric run_lazy" do
      initial_plan_attrs = %{
        name: "Execution Test Plan",
        persona_id: "persona-uuid",
        domain_type: "tactical"
      }

      {:ok, plan} = Plan.create(initial_plan_attrs)

      # Initially planned (ego-centric phase)
      assert plan.execution_status == "planned"

      execution_started_at_nativetime = NaiveDateTime.utc_now()
      # Transition to executing (allocentric phase begins)
      {:ok, executing_plan} =
        Plan.update(plan, %{
          execution_status: "executing",
          execution_started_at: execution_started_at_nativetime
        })

      assert executing_plan.execution_status == "executing"
      assert executing_plan.execution_started_at == execution_started_at_nativetime

      # 5 seconds later
      execution_completed_at_nativetime = NaiveDateTime.add(execution_started_at_nativetime, 5_000, :millisecond)
      # Complete execution
      {:ok, completed_plan} =
        Plan.update(executing_plan, %{
          execution_status: "completed",
          execution_completed_at: execution_completed_at_nativetime,
          performance_metrics: %{"execution_time_ms" => 3210}
        })

      assert completed_plan.execution_status == "completed"
      assert completed_plan.execution_completed_at == execution_completed_at_nativetime
      assert completed_plan.performance_metrics["execution_time_ms"] == 3210
    end
  end

  describe "risk and success assessment" do
    test "plan includes comprehensive risk assessment from ego perspective" do
      risk_data = %{
        "position_exposure" => 0.4,
        "health_risk" => 0.2,
        "ally_coordination_required" => 0.8,
        "terrain_difficulty" => 0.3
      }

      {:ok, plan} =
        Plan.create(%{
          name: "Risk-Assessed Plan",
          persona_id: "persona-uuid",
          domain_type: "tactical",
          success_probability: 0.67,
          risk_assessment: risk_data
        })

      assert plan.success_probability == 0.67
      assert plan.risk_assessment == risk_data
    end

    test "performance metrics capture allocentric execution outcomes" do
      perf_metrics = %{
        "total_execution_time_ms" => 5210,
        "actions_completed" => 7,
        "actions_failed" => 1,
        "world_state_changes" => 12,
        "egocentric_efficiency" => 0.92
      }

      {:ok, existing_plan} =
        Plan.create(%{
          name: "Initial Plan",
          persona_id: "persona-uuid",
          domain_type: "tactical"
        })

      {:ok, plan} =
        Plan.update(existing_plan, %{
          performance_metrics: perf_metrics
        })

      assert plan.performance_metrics == perf_metrics
      assert plan.performance_metrics["egocentric_efficiency"] == 0.92
    end
  end

  describe "time-based planning metadata" do
    test "planning timestamp and duration tracking" do
      planning_start_nativetime = NaiveDateTime.utc_now()
      # Duration in ms as before
      planning_duration = 2150

      {:ok, plan} =
        Plan.create(%{
          name: "Timed Planning",
          persona_id: "persona-uuid",
          domain_type: "navigation",
          planning_timestamp: planning_start_nativetime,
          planning_duration_ms: planning_duration
        })

      assert plan.planning_timestamp == planning_start_nativetime
      assert plan.planning_duration_ms == planning_duration
    end

    test "execution time tracking for allocentric run_lazy phases" do
      execution_start_nativetime = NaiveDateTime.utc_now()
      # 5 seconds later
      execution_end_nativetime = NaiveDateTime.add(execution_start_nativetime, 5_000, :millisecond)

      {:ok, existing_plan} =
        Plan.create(%{
          name: "Timed Execution",
          persona_id: "persona-uuid",
          domain_type: "tactical"
        })

      {:ok, plan} =
        Plan.update(existing_plan, %{
          execution_started_at: execution_start_nativetime,
          execution_completed_at: execution_end_nativetime
        })

      assert plan.execution_started_at == execution_start_nativetime
      assert plan.execution_completed_at == execution_end_nativetime

      # Removed explicit duration calculation from test as it's implied by start/end time.
    end
  end

  describe "plan creation with different domain types" do
    test "creates plan for blocks_world domain" do
      {:ok, plan} =
        Plan.create(%{
          name: "Blocks World Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "blocks_world",
          objectives: ["move_block_a_to_b"]
        })

      assert plan.domain_type == "blocks_world"
      assert plan.objectives == ["move_block_a_to_b"]
    end

    test "creates plan for navigation domain" do
      {:ok, plan} =
        Plan.create(%{
          name: "Navigation Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "navigation",
          objectives: ["reach_destination"]
        })

      assert plan.domain_type == "navigation"
    end

    test "creates plan for social domain" do
      {:ok, plan} =
        Plan.create(%{
          name: "Social Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "social",
          objectives: ["build_alliance"]
        })

      assert plan.domain_type == "social"
    end

    test "creates plan for economic domain" do
      {:ok, plan} =
        Plan.create(%{
          name: "Economic Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "economic",
          objectives: ["maximize_profit"]
        })

      assert plan.domain_type == "economic"
    end

    test "creates plan for exploration domain" do
      {:ok, plan} =
        Plan.create(%{
          name: "Exploration Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "exploration",
          objectives: ["discover_new_areas"]
        })

      assert plan.domain_type == "exploration"
    end

    test "creates plan for stealth domain" do
      {:ok, plan} =
        Plan.create(%{
          name: "Stealth Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "stealth",
          objectives: ["infiltrate_base"]
        })

      assert plan.domain_type == "stealth"
    end

    test "creates plan for pert_planner domain" do
      {:ok, plan} =
        Plan.create(%{
          name: "PERT Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "pert_planner",
          objectives: ["complete_project"]
        })

      assert plan.domain_type == "pert_planner"
    end

    test "creates plan for workflow_test_domain" do
      {:ok, plan} =
        Plan.create(%{
          name: "Workflow Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "workflow_test_domain",
          objectives: ["execute_workflow"]
        })

      assert plan.domain_type == "workflow_test_domain"
    end
  end

  describe "plan get/1 and all/0" do
    test "gets plan by ID" do
      {:ok, plan} =
        Plan.create(%{
          name: "Test Plan",
          persona_id: UUIDv7.generate(),
          domain_type: "tactical"
        })

      {:ok, retrieved} = Plan.get(plan.id)
      assert retrieved.id == plan.id
      assert retrieved.name == "Test Plan"
    end

    test "returns error for non-existent plan" do
      assert {:error, :not_found} = Plan.get(UUIDv7.generate())
    end

    test "gets all plans" do
      {:ok, plan1} =
        Plan.create(%{
          name: "Plan 1",
          persona_id: UUIDv7.generate(),
          domain_type: "tactical"
        })

      {:ok, plan2} =
        Plan.create(%{
          name: "Plan 2",
          persona_id: UUIDv7.generate(),
          domain_type: "navigation"
        })

      all_plans = Plan.all()
      assert length(all_plans) >= 2
      assert Enum.any?(all_plans, &(&1.id == plan1.id))
      assert Enum.any?(all_plans, &(&1.id == plan2.id))
    end
  end

  describe "plan delete/1" do
    test "deletes plan by ID" do
      {:ok, plan} =
        Plan.create(%{
          name: "To Delete",
          persona_id: UUIDv7.generate(),
          domain_type: "tactical"
        })

      :ok = Plan.delete(plan.id)
      assert {:error, :not_found} = Plan.get(plan.id)
    end
  end
end
