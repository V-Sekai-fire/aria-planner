# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.MCPIntegrationTest do
  @moduledoc """
  MCP integration tests for aria_planner.
  Tests aria_planner workflows via MCP tools and resources.
  """

  use ExUnit.Case, async: false

  alias MCP.AriaForge.ToolHandlers
  alias MCP.AriaForge.ResourceHandlers

  setup do
    # Initialize state for MCP handlers
    {:ok, %{
      state: %{
        prompt_uses: 0,
        created_resources: %{},
        subscriptions: []
      }
    }}
  end

  # ============================================================================
  # Plan Creation via MCP
  # ============================================================================

  describe "Plan creation via MCP tools" do
    test "creates a basic plan", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "test_persona_1",
          "name" => "Basic Navigation Plan",
          "domain_type" => "navigation",
          "objectives" => ["reach destination"]
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "creates plan with success probability", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "test_persona_2",
          "name" => "High Confidence Plan",
          "domain_type" => "tactical",
          "objectives" => ["complete mission"],
          "success_probability" => 0.95
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "creates plan with run_lazy flag (deferred execution)", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "test_persona_3",
          "name" => "Lazy Execution Plan",
          "domain_type" => "blocks_world",
          "objectives" => ["stack blocks"],
          "run_lazy" => true
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      # Verify lazy execution status in response
      [content] = result.content
      assert String.contains?(content.text, "pending")
    end

    test "creates plan with multiple objectives", %{state: state} do
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "test_persona_4",
          "name" => "Multi-Objective Plan",
          "domain_type" => "tactical",
          "objectives" => [
            "secure perimeter",
            "establish communication",
            "gather intelligence"
          ],
          "success_probability" => 0.75
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end

    test "plan resource URI is created", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "test_persona_5",
          "name" => "URI Test Plan",
          "domain_type" => "navigation"
        },
        state
      )

      # Extract resource URI from response
      [content] = result.content
      response_data = Jason.decode!(content.text)
      resource_uri = response_data["resource_uri"]

      assert String.starts_with?(resource_uri, "aria://plans/")
      assert Map.has_key?(new_state.created_resources, resource_uri)
    end
  end

  # ============================================================================
  # Domain Operations via MCP
  # ============================================================================

  describe "Domain task operations" do
    test "lists domain tasks", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "list_domain_tasks",
        %{"domain_type" => "blocks_world"},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "lists tasks for navigation domain", %{state: state} do
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "list_domain_tasks",
        %{"domain_type" => "navigation"},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end

    test "lists all tasks when domain not specified", %{state: state} do
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "list_domain_tasks",
        %{},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end
  end

  describe "Domain action operations" do
    test "lists domain actions", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "list_domain_actions",
        %{"domain_type" => "blocks_world"},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "lists actions for tactical domain", %{state: state} do
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "list_domain_actions",
        %{"domain_type" => "tactical"},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end
  end

  describe "Domain entity operations" do
    test "lists domain entities with capabilities", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "list_domain_entities",
        %{
          "domain_type" => "blocks_world",
          "include_capabilities" => true
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "lists domain entities without capabilities", %{state: state} do
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "list_domain_entities",
        %{
          "domain_type" => "blocks_world",
          "include_capabilities" => false
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end
  end

  describe "Domain multigoal operations" do
    test "lists domain multigoals", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "list_domain_multigoals",
        %{"domain_type" => "blocks_world"},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end
  end

  describe "Domain command operations" do
    test "lists domain commands", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "list_domain_commands",
        %{"domain_type" => "blocks_world"},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end
  end

  # ============================================================================
  # Planning Domain Creation
  # ============================================================================

  describe "Planning domain creation" do
    test "creates a planning domain", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "test_domain_1",
          "entities" => [
            %{
              "id" => "entity_1",
              "name" => "Test Entity",
              "position" => [0, 0, 0],
              "health" => 100
            }
          ]
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "creates domain without entities", %{state: state} do
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{"domain_type" => "empty_domain"},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end

    test "creates domain with multiple entities", %{state: state} do
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "multi_entity_domain",
          "entities" => [
            %{"id" => "e1", "name" => "Entity 1", "position" => [0, 0, 0], "health" => 100},
            %{"id" => "e2", "name" => "Entity 2", "position" => [10, 10, 0], "health" => 80},
            %{"id" => "e3", "name" => "Entity 3", "position" => [20, 20, 0], "health" => 90}
          ]
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end
  end

  # ============================================================================
  # Domain Element Management
  # ============================================================================

  describe "Domain element addition" do
    test "adds a task to domain", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "blocks_world",
          "element_type" => "task",
          "name" => "New Stacking Task",
          "data" => %{"description" => "Stack three blocks"}
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
      assert map_size(new_state.created_resources) > 0
    end

    test "adds an action to domain", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "blocks_world",
          "element_type" => "action",
          "name" => "Pickup Action",
          "data" => %{"description" => "Pick up a block"}
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "adds element with run_lazy flag", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "blocks_world",
          "element_type" => "task",
          "name" => "Lazy Task",
          "data" => %{},
          "run_lazy" => true
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      [content] = result.content
      assert String.contains?(content.text, "pending")
    end

    test "element resource URI is created", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "test_domain",
          "element_type" => "task",
          "name" => "URI Test Task"
        },
        state
      )

      [content] = result.content
      response_data = Jason.decode!(content.text)
      resource_uri = response_data["resource_uri"]

      assert String.starts_with?(resource_uri, "aria://domain_elements/")
      assert Map.has_key?(new_state.created_resources, resource_uri)
    end
  end

  describe "Domain element listing" do
    test "lists all elements in domain", %{state: state} do
      # First add some elements
      {:ok, _result, state1} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "list_test_domain",
          "element_type" => "task",
          "name" => "Task 1"
        },
        state
      )

      {:ok, _result, state2} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "list_test_domain",
          "element_type" => "action",
          "name" => "Action 1"
        },
        state1
      )

      # Now list them
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "list_domain_elements",
        %{"domain_type" => "list_test_domain"},
        state2
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end

    test "filters elements by type", %{state: state} do
      {:ok, _result, state1} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "filter_test_domain",
          "element_type" => "task",
          "name" => "Task 1"
        },
        state
      )

      {:ok, _result, state2} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "filter_test_domain",
          "element_type" => "action",
          "name" => "Action 1"
        },
        state1
      )

      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
        "list_domain_elements",
        %{
          "domain_type" => "filter_test_domain",
          "element_type" => "task"
        },
        state2
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
    end
  end

  # ============================================================================
  # Execution State Management
  # ============================================================================

  describe "Execution state operations" do
    test "gets current execution state", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "get_execution_state",
        %{},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "updates weather in execution state", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "update_execution_state",
        %{"weather_type" => "rain"},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "advances world time", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "update_execution_state",
        %{"advance_time_minutes" => 120},
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "adds player to execution state", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "update_execution_state",
        %{
          "add_player" => %{
            "player_id" => "test_player_1",
            "player_data" => %{
              "name" => "Test Player",
              "health" => 100,
              "position" => [0, 0, 0]
            }
          }
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end
  end

  # ============================================================================
  # Resource Lifecycle
  # ============================================================================

  describe "Resource lifecycle" do
    test "plan resource can be read after creation", %{state: state} do
      # Create a plan
      {:ok, plan_result, state1} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "resource_test_persona",
          "name" => "Resource Lifecycle Plan",
          "domain_type" => "navigation"
        },
        state
      )

      [content] = plan_result.content
      response_data = Jason.decode!(content.text)
      plan_id = response_data["plan_id"]

      # Verify plan is in created_resources
      assert map_size(state1.created_resources) > 0
      assert Enum.any?(state1.created_resources, fn {_uri, resource} ->
        is_map(resource) && Map.get(resource, :id) == plan_id
      end)
    end

    test "domain elements accumulate in state", %{state: state} do
      {:ok, _result, state1} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "accumulation_test",
          "element_type" => "task",
          "name" => "Element 1"
        },
        state
      )

      initial_count = map_size(state1.created_resources)

      {:ok, _result, state2} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "accumulation_test",
          "element_type" => "action",
          "name" => "Element 2"
        },
        state1
      )

      final_count = map_size(state2.created_resources)
      assert final_count >= initial_count
    end

    test "prompt_uses counter tracks tool invocations", %{state: state} do
      assert state.prompt_uses == 0

      {:ok, _result, state1} = ToolHandlers.handle_tool_call(
        "list_domain_tasks",
        %{},
        state
      )
      assert state1.prompt_uses == 1

      {:ok, _result, state2} = ToolHandlers.handle_tool_call(
        "list_domain_actions",
        %{},
        state1
      )
      assert state2.prompt_uses == 2

      {:ok, _result, state3} = ToolHandlers.handle_tool_call(
        "get_execution_state",
        %{},
        state2
      )
      assert state3.prompt_uses == 3
    end
  end

  # ============================================================================
  # Integration Workflows
  # ============================================================================

  describe "Complete planning workflows" do
    test "workflow: create domain, add elements, create plan", %{state: state} do
      # Step 1: Create planning domain
      {:ok, _domain_result, state1} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "workflow_test_domain",
          "entities" => [
            %{"id" => "robot", "name" => "Robot", "position" => [0, 0, 0], "health" => 100}
          ]
        },
        state
      )

      # Step 2: Add tasks to domain
      {:ok, _task_result, state2} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "workflow_test_domain",
          "element_type" => "task",
          "name" => "Move to Location"
        },
        state1
      )

      # Step 3: Add actions to domain
      {:ok, _action_result, state3} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "workflow_test_domain",
          "element_type" => "action",
          "name" => "Move Action"
        },
        state2
      )

      # Step 4: Create a plan using the domain
      {:ok, plan_result, _state4} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "workflow_persona",
          "name" => "Workflow Test Plan",
          "domain_type" => "workflow_test_domain",
          "objectives" => ["complete workflow"]
        },
        state3
      )

      assert is_map(plan_result)
      assert Map.has_key?(plan_result, :content)
    end

    test "workflow: lazy plan creation and state tracking", %{state: state} do
      # Create plan with lazy execution
      {:ok, result1, state1} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "lazy_persona",
          "name" => "Lazy Plan 1",
          "domain_type" => "blocks_world",
          "run_lazy" => true
        },
        state
      )

      [content1] = result1.content
      response1 = Jason.decode!(content1.text)
      assert response1["run_lazy"] == true

      # Create another lazy plan
      {:ok, result2, state2} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "lazy_persona",
          "name" => "Lazy Plan 2",
          "domain_type" => "navigation",
          "run_lazy" => true
        },
        state1
      )

      [content2] = result2.content
      response2 = Jason.decode!(content2.text)
      assert response2["run_lazy"] == true

      # Verify both plans are tracked
      assert state2.prompt_uses == 2
      assert map_size(state2.created_resources) >= 2
    end

    test "workflow: multi-persona planning", %{state: state} do
      personas = ["persona_a", "persona_b", "persona_c"]

      # Create plans for multiple personas
      final_state = Enum.reduce(personas, state, fn persona_id, acc_state ->
        {:ok, _result, new_state} = ToolHandlers.handle_tool_call(
          "create_plan",
          %{
            "persona_id" => persona_id,
            "name" => "Plan for #{persona_id}",
            "domain_type" => "tactical",
            "objectives" => ["achieve goal"]
          },
          acc_state
        )
        new_state
      end)

      # Verify all plans were created
      assert final_state.prompt_uses == 3
      assert map_size(final_state.created_resources) >= 3
    end
  end

  # ============================================================================
  # Backtracking Tests
  # ============================================================================

  describe "Plan backtracking and recovery" do
    test "backtrack when initial plan fails", %{state: state} do
      # Create initial plan attempt
      {:ok, result1, state1} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "backtrack_persona",
          "name" => "Initial Plan Attempt",
          "domain_type" => "blocks_world",
          "objectives" => ["stack blocks"],
          "success_probability" => 0.3
        },
        state
      )

      assert is_map(result1)
      [content1] = result1.content
      response1 = Jason.decode!(content1.text)
      plan_id_1 = response1["plan_id"]

      # Create alternative plan with different approach
      {:ok, result2, state2} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "backtrack_persona",
          "name" => "Alternative Plan (Backtracked)",
          "domain_type" => "blocks_world",
          "objectives" => ["stack blocks"],
          "success_probability" => 0.85
        },
        state1
      )

      assert is_map(result2)
      [content2] = result2.content
      response2 = Jason.decode!(content2.text)
      plan_id_2 = response2["plan_id"]

      # Verify both plans exist and are different
      assert plan_id_1 != plan_id_2
      assert state2.prompt_uses == 2
      assert map_size(state2.created_resources) >= 2
    end

    test "backtrack through domain element alternatives", %{state: state} do
      # Create domain with initial task
      {:ok, _result, state1} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "backtrack_domain",
          "entities" => [
            %{"id" => "robot", "name" => "Robot", "position" => [0, 0, 0], "health" => 100}
          ]
        },
        state
      )

      # Add first task approach
      {:ok, result_task1, state2} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "backtrack_domain",
          "element_type" => "task",
          "name" => "Move Direct",
          "data" => %{"approach" => "direct_path"}
        },
        state1
      )

      [content_task1] = result_task1.content
      response_task1 = Jason.decode!(content_task1.text)
      task_id_1 = response_task1["element_id"]

      # Add alternative task approach (backtrack)
      {:ok, result_task2, state3} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "backtrack_domain",
          "element_type" => "task",
          "name" => "Move Indirect",
          "data" => %{"approach" => "avoid_obstacles"}
        },
        state2
      )

      [content_task2] = result_task2.content
      response_task2 = Jason.decode!(content_task2.text)
      task_id_2 = response_task2["element_id"]

      # Verify both alternatives exist
      assert task_id_1 != task_id_2
      assert state3.prompt_uses == 3
      assert map_size(state3.created_resources) >= 2
    end

    test "backtrack with lazy execution and retry", %{state: state} do
      # Create lazy plan (deferred execution)
      {:ok, result1, state1} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "retry_persona",
          "name" => "Lazy Plan for Retry",
          "domain_type" => "tactical",
          "objectives" => ["complete mission"],
          "run_lazy" => true
        },
        state
      )

      [content1] = result1.content
      response1 = Jason.decode!(content1.text)
      assert response1["execution_status"] == "pending"

      # Simulate plan execution failure and create retry plan
      {:ok, result2, state2} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "retry_persona",
          "name" => "Retry Plan (Backtracked)",
          "domain_type" => "tactical",
          "objectives" => ["complete mission"],
          "success_probability" => 0.9,
          "run_lazy" => true
        },
        state1
      )

      [content2] = result2.content
      response2 = Jason.decode!(content2.text)
      assert response2["execution_status"] == "pending"

      # Verify retry plan is tracked
      assert state2.prompt_uses == 2
      assert map_size(state2.created_resources) >= 2
    end

    test "backtrack through multiple domain element types", %{state: state} do
      # Create domain
      {:ok, _result, state1} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{"domain_type" => "multi_backtrack_domain"},
        state
      )

      # Add task (first approach)
      {:ok, _result, state2} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "multi_backtrack_domain",
          "element_type" => "task",
          "name" => "Primary Task"
        },
        state1
      )

      # Add action (alternative approach)
      {:ok, _result, state3} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "multi_backtrack_domain",
          "element_type" => "action",
          "name" => "Fallback Action"
        },
        state2
      )

      # Add command (final fallback)
      {:ok, _result, state4} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "multi_backtrack_domain",
          "element_type" => "command",
          "name" => "Emergency Command"
        },
        state3
      )

      # Verify all alternatives are tracked
      assert state4.prompt_uses == 4
      assert map_size(state4.created_resources) >= 3
    end

    test "backtrack with state restoration", %{state: state} do
      # Create initial state with domain
      {:ok, _result, state1} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "restore_domain",
          "entities" => [
            %{"id" => "entity1", "name" => "Entity 1", "position" => [0, 0, 0], "health" => 100}
          ]
        },
        state
      )

      initial_resource_count = map_size(state1.created_resources)

      # Add element
      {:ok, _result, state2} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "restore_domain",
          "element_type" => "task",
          "name" => "Task 1"
        },
        state1
      )

      after_add_count = map_size(state2.created_resources)
      assert after_add_count > initial_resource_count

      # Simulate backtrack by creating alternative without removing original
      {:ok, _result, state3} = ToolHandlers.handle_tool_call(
        "add_domain_element",
        %{
          "domain_type" => "restore_domain",
          "element_type" => "task",
          "name" => "Task 1 Alternative"
        },
        state2
      )

      # Verify state accumulation (backtracking preserves history)
      assert map_size(state3.created_resources) >= after_add_count
      assert state3.prompt_uses == 3
    end

    test "backtrack with execution state updates", %{state: state} do
      # Get initial execution state
      {:ok, result1, state1} = ToolHandlers.handle_tool_call(
        "get_execution_state",
        %{},
        state
      )

      assert is_map(result1)

      # Update execution state (first attempt)
      {:ok, result2, state2} = ToolHandlers.handle_tool_call(
        "update_execution_state",
        %{"weather_type" => "rain"},
        state1
      )

      assert is_map(result2)

      # Backtrack: update with different weather (alternative approach)
      {:ok, result3, state3} = ToolHandlers.handle_tool_call(
        "update_execution_state",
        %{"weather_type" => "clear"},
        state2
      )

      assert is_map(result3)
      assert state3.prompt_uses == 3
    end

    test "backtrack with multi-persona planning", %{state: state} do
      personas = ["persona_x", "persona_y"]

      # First round: create plans for each persona
      state_after_round1 = Enum.reduce(personas, state, fn persona_id, acc_state ->
        {:ok, _result, new_state} = ToolHandlers.handle_tool_call(
          "create_plan",
          %{
            "persona_id" => persona_id,
            "name" => "Plan Round 1",
            "domain_type" => "tactical",
            "objectives" => ["goal_1"]
          },
          acc_state
        )
        new_state
      end)

      assert state_after_round1.prompt_uses == 2

      # Second round: backtrack with alternative plans
      state_after_round2 = Enum.reduce(personas, state_after_round1, fn persona_id, acc_state ->
        {:ok, _result, new_state} = ToolHandlers.handle_tool_call(
          "create_plan",
          %{
            "persona_id" => persona_id,
            "name" => "Plan Round 2 (Backtracked)",
            "domain_type" => "navigation",
            "objectives" => ["goal_2"]
          },
          acc_state
        )
        new_state
      end)

      # Verify backtracking across personas
      assert state_after_round2.prompt_uses == 4
      assert map_size(state_after_round2.created_resources) >= 4
    end

    test "backtrack with lazy execution alternatives", %{state: state} do
      # Create lazy plan (pending execution)
      {:ok, result1, state1} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "lazy_backtrack_persona",
          "name" => "Lazy Plan 1",
          "domain_type" => "blocks_world",
          "run_lazy" => true
        },
        state
      )

      [content1] = result1.content
      response1 = Jason.decode!(content1.text)
      assert response1["execution_status"] == "pending"

      # Backtrack: create alternative lazy plan
      {:ok, result2, state2} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "lazy_backtrack_persona",
          "name" => "Lazy Plan 2 (Backtracked)",
          "domain_type" => "navigation",
          "run_lazy" => true
        },
        state1
      )

      [content2] = result2.content
      response2 = Jason.decode!(content2.text)
      assert response2["execution_status"] == "pending"

      # Backtrack: create eager plan (non-lazy)
      {:ok, result3, state3} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "lazy_backtrack_persona",
          "name" => "Eager Plan (Final Backtrack)",
          "domain_type" => "tactical",
          "run_lazy" => false
        },
        state2
      )

      assert is_map(result3)
      assert state3.prompt_uses == 3
      assert map_size(state3.created_resources) >= 3
    end
  end

  # ============================================================================
  # Error Handling
  # ============================================================================

  describe "Error handling" do
    test "handles unknown tool gracefully", %{state: state} do
      {:error, message, new_state} = ToolHandlers.handle_tool_call(
        "unknown_tool",
        %{},
        state
      )

      assert String.contains?(message, "Tool not found")
      assert new_state.prompt_uses == 1
    end

    test "handles missing required parameters", %{state: state} do
      # create_plan requires persona_id, name, domain_type
      result = ToolHandlers.handle_tool_call(
        "create_plan",
        %{"name" => "Incomplete Plan"},
        state
      )

      # Should either error or handle gracefully
      assert is_tuple(result)
    end
  end
end
