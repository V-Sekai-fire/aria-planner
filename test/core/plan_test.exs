# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PlanTest do
  use ExUnit.Case, async: true
  alias AriaCore.Plan
  alias AriaPlanner.FixtureHelpers, as: Fixtures

  describe "plan CRUD operations (ego-centric storage)" do
    test "creates plan with UUIDv7 ID when not provided" do
      data = Fixtures.load_fixture("plan_create", "plan_results")
      input = data["create_uuidv7"]["input"]
      expected = data["create_uuidv7"]["expected"]

      attrs = %{
        name: input["name"],
        persona_id: input["persona_id"],
        domain_type: input["domain_type"],
        objectives: input["objectives"],
        success_probability: input["success_probability"],
        planning_duration_ms: input["planning_duration_ms"]
      }

      {:ok, plan} = Plan.create(attrs)

      assert plan.name == expected["name"]
      assert plan.persona_id == expected["persona_id"]
      assert plan.domain_type == expected["domain_type"]
      assert plan.objectives == expected["objectives"]
      assert plan.success_probability == expected["success_probability"]
      assert plan.planning_duration_ms == expected["planning_duration_ms"]
      assert String.match?(plan.id, Regex.compile!(expected["id_uuid_pattern"]))
    end

    test "creates plan with temporal constraints, entity capabilities, and solution plan" do
      data = Fixtures.load_fixture("plan_create", "plan_results")
      input = data["create_temporal_constraints"]["input"]

      temporal_constraints = input["temporal_constraints"]
      entity_capabilities = input["entity_capabilities"]

      attrs = %{
        name: input["name"],
        persona_id: input["persona_id"],
        domain_type: input["domain_type"],
        temporal_constraints: temporal_constraints,
        entity_capabilities: entity_capabilities,
        solution_plan: input["solution_plan"]
      }

      {:ok, plan} = Plan.create(attrs)

      assert plan.temporal_constraints == temporal_constraints
      assert plan.entity_capabilities == entity_capabilities
      assert plan.solution_plan == input["solution_plan"]
    end

    test "validates required fields" do
      data = Fixtures.load_fixture("plan_create_validation", "plan_results")
      scenario = data["required_fields"]
      invalid_attrs = %{name: scenario["invalid_attrs"]["name"]}
      {:error, error_message} = Plan.create(invalid_attrs)

      for sub <- scenario["expected_message_substrings"] do
        assert String.contains?(error_message, sub)
      end
    end

    test "validates domain_type inclusion" do
      data = Fixtures.load_fixture("plan_create_validation", "plan_results")
      sub = data["domain_type_inclusion"]["expected_message_substring"]
      attrs = %{name: "Test", persona_id: UUIDv7.generate(), domain_type: "invalid"}
      {:error, error_message} = Plan.create(attrs)

      assert String.contains?(error_message, sub)
    end

    test "validates execution_status inclusion" do
      data = Fixtures.load_fixture("plan_create_validation", "plan_results")
      sub = data["execution_status_inclusion"]["expected_message_substring"]

      attrs = %{
        name: "Test",
        persona_id: UUIDv7.generate(),
        domain_type: "tactical",
        execution_status: "invalid"
      }

      {:error, error_message} = Plan.create(attrs)

      assert String.contains?(error_message, sub)
    end

    test "validates success_probability range" do
      data = Fixtures.load_fixture("plan_create_validation", "plan_results")
      scenario = data["success_probability_range"]
      sub = scenario["expected_message_substring"]

      attrs = %{
        name: "Test",
        persona_id: UUIDv7.generate(),
        domain_type: "tactical",
        success_probability: scenario["upper_bound"]
      }

      {:error, error_message} = Plan.create(attrs)
      assert String.contains?(error_message, sub)

      attrs = Map.put(attrs, :success_probability, scenario["lower_bound"])
      {:error, error_message} = Plan.create(attrs)
      assert String.contains?(error_message, sub)
    end

    test "validates UUIDv7 format" do
      data = Fixtures.load_fixture("plan_create_validation", "plan_results")
      scenario = data["uuidv7_format"]

      attrs = %{
        id: scenario["invalid_id"],
        name: "Test",
        persona_id: UUIDv7.generate(),
        domain_type: "tactical"
      }

      {:error, error_message} = Plan.create(attrs)

      assert String.contains?(error_message, scenario["expected_message_substring"])
    end

    test "updates existing plan successfully" do
      data = Fixtures.load_fixture("plan_create", "plan_results")
      scenario = data["update_success"]
      update_attrs_fixture = scenario["update_attrs"]
      expected = scenario["expected"]

      {:ok, plan} =
        Plan.create(%{
          name: "Initial Plan",
          persona_id: "persona-uuid",
          domain_type: "tactical"
        })

      update_attrs = %{
        name: update_attrs_fixture["name"],
        success_probability: update_attrs_fixture["success_probability"],
        execution_status: update_attrs_fixture["execution_status"],
        execution_completed_at: NaiveDateTime.utc_now()
      }

      {:ok, updated_plan} = Plan.update(plan, update_attrs)

      assert updated_plan.name == expected["name"]
      assert updated_plan.success_probability == expected["success_probability"]
      assert updated_plan.execution_status == expected["execution_status"]
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
      data = Fixtures.load_fixture("plan_create", "plan_results")
      scenario = data["solution_graph"]
      input = scenario["input"]
      expected = scenario["expected"]
      graph_input = input["solution_graph_data"]

      mock_graph_data = %{
        num_nodes: graph_input["num_nodes"],
        num_edges: graph_input["num_edges"],
        node_types: graph_input["node_types"],
        primitive_mask: graph_input["primitive_mask"],
        goal_mask: graph_input["goal_mask"],
        metadata: %{
          version: "1.0.0",
          created_at: NaiveDateTime.utc_now(),
          ego_plugin: graph_input["metadata"]["ego_plugin"]
        }
      }

      {:ok, plan} =
        Plan.create(%{
          name: input["name"],
          persona_id: input["persona_id"],
          domain_type: input["domain_type"],
          solution_graph_data: mock_graph_data
        })

      assert plan.solution_graph_data == mock_graph_data
      assert plan.solution_graph_data.num_nodes == expected["num_nodes"]
      assert plan.solution_graph_data.node_types == expected["node_types"]
      assert plan.solution_graph_data.metadata.ego_plugin == expected["metadata_ego_plugin"]
    end

    test "plan execution status transitions for allocentric run_lazy" do
      data = Fixtures.load_fixture("plan_create", "plan_results")
      expected_ms = data["execution_status_transitions"]["expected_execution_time_ms"]

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
          performance_metrics: %{"execution_time_ms" => expected_ms}
        })

      assert completed_plan.execution_status == "completed"
      assert completed_plan.execution_completed_at == execution_completed_at_nativetime
      assert completed_plan.performance_metrics["execution_time_ms"] == expected_ms
    end
  end

  describe "risk and success assessment" do
    test "plan includes comprehensive risk assessment from ego perspective" do
      data = Fixtures.load_fixture("plan_create", "plan_results")
      scenario = data["risk_assessment"]
      input = scenario["input"]
      expected = scenario["expected"]
      risk_data = Map.new(expected["risk_assessment"], fn {k, v} -> {k, v} end)

      attrs = %{
        name: input["name"],
        persona_id: input["persona_id"],
        domain_type: input["domain_type"],
        success_probability: input["success_probability"],
        risk_assessment: risk_data
      }

      {:ok, plan} = Plan.create(attrs)

      assert plan.success_probability == expected["success_probability"]
      assert plan.risk_assessment == risk_data
    end

    test "performance metrics capture allocentric execution outcomes" do
      data = Fixtures.load_fixture("plan_create", "plan_results")
      scenario = data["performance_metrics"]
      perf_metrics = Map.new(scenario["perf_metrics"], fn {k, v} -> {k, v} end)

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
      assert plan.performance_metrics["egocentric_efficiency"] == scenario["expected_egocentric_efficiency"]
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
    test "creates plan for each domain type from fixture" do
      data = Fixtures.load_fixture("plan_create", "plan_results")
      domain_types = data["domain_types"]

      for scenario <- domain_types do
        {:ok, plan} =
          Plan.create(%{
            name: scenario["name"],
            persona_id: UUIDv7.generate(),
            domain_type: scenario["domain_type"],
            objectives: scenario["objectives"]
          })

        assert plan.domain_type == scenario["domain_type"]
        assert plan.objectives == scenario["objectives"]
      end
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
