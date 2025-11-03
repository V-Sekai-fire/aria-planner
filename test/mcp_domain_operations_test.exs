# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.MCPDomainOperationsTest do
  @moduledoc """
  MCP domain operations tests for aria_planner.
  Tests domain creation, element management, and queries via MCP tools.
  """

  use ExUnit.Case, async: false

  alias MCP.AriaForge.ToolHandlers

  setup do
    {:ok, %{
      state: %{
        prompt_uses: 0,
        created_resources: %{},
        subscriptions: []
      }
    }}
  end

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

  describe "Planning domain creation" do
    test "creates a planning domain", %{state: state} do
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "test_domain_1",
          "entities" => []
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
      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "multi_entity_domain",
          "entities" => [
            %{"id" => "e1", "name" => "Entity 1"},
            %{"id" => "e2", "name" => "Entity 2"},
            %{"id" => "e3", "name" => "Entity 3"}
          ]
        },
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end
  end

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
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
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
      assert String.contains?(content["text"], "pending")
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
      response_data = Jason.decode!(content["text"])
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

  describe "Complete planning workflows" do
    test "workflow: create domain, add elements, create plan", %{state: state} do
      # Step 1: Create planning domain
      {:ok, _domain_result, state1} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "workflow_test_domain",
          "entities" => []
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
      {:ok, plan_result, state4} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "workflow_persona",
          "name" => "Workflow Test Plan",
          "domain_type" => "workflow_test_domain",
          "objectives" => ["move", "navigate"]
        },
        state3
      )

      # Verify workflow completed successfully
      assert is_map(plan_result)
      assert Map.has_key?(plan_result, :content)
      assert state4.prompt_uses == 4
      assert map_size(state4.created_resources) >= 3
    end
  end
end
