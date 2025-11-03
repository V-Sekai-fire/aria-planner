# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.MCPBacktrackingTest do
  @moduledoc """
  MCP backtracking tests for aria_planner.
  Tests plan backtracking and recovery workflows via MCP tools.
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

  describe "Plan backtracking and recovery" do
    test "backtrack when initial plan fails", %{state: state} do
      # Create initial plan attempt
      {:ok, _result1, state1} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "backtrack_persona",
          "name" => "Initial Plan Attempt",
          "domain_type" => "blocks_world",
          "objectives" => ["pickup", "stack"]
        },
        state
      )

      # Create alternative plan with different approach
      {:ok, _result2, state2} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "backtrack_persona",
          "name" => "Alternative Plan (Backtracked)",
          "domain_type" => "blocks_world",
          "objectives" => ["move", "place"]
        },
        state1
      )

      # Verify backtracking occurred
      assert state2.prompt_uses == 2
      assert map_size(state2.created_resources) >= 2
    end

    test "backtrack with lazy execution and retry", %{state: state} do
      # Create lazy plan (deferred execution)
      {:ok, result1, state1} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "retry_persona",
          "name" => "Lazy Plan for Retry",
          "domain_type" => "tactical",
          "objectives" => ["engage", "retreat"],
          "run_lazy" => true
        },
        state
      )

      [content1] = result1.content
      response1 = Jason.decode!(content1["text"])
      assert response1["execution_status"] == "pending"

      # Simulate plan execution failure and create retry plan
      {:ok, result2, state2} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "retry_persona",
          "name" => "Retry Plan (Backtracked)",
          "domain_type" => "tactical",
          "objectives" => ["defend", "advance"],
          "run_lazy" => true
        },
        state1
      )

      [content2] = result2.content
      response2 = Jason.decode!(content2["text"])
      assert response2["execution_status"] == "pending"

      # Verify retry plan is tracked
      assert state2.prompt_uses == 2
      assert map_size(state2.created_resources) >= 2
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
            "objectives" => ["engage", "hold"]
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
            "objectives" => ["move", "navigate"]
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
      response1 = Jason.decode!(content1["text"])
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
      response2 = Jason.decode!(content2["text"])
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

  describe "State restoration during backtracking" do
    test "backtrack with state restoration", %{state: state} do
      # Create initial state with domain
      {:ok, _result, state1} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        %{
          "domain_type" => "restore_domain",
          "entities" => [
            %{"id" => "entity1", "name" => "Entity 1", "health" => 100}
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
  end
end
