# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.MCPPlanCreationTest do
  @moduledoc """
  MCP plan creation tests for aria_planner.
  Tests plan creation workflows via MCP tools.
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
      {:ok, result, _new_state} = ToolHandlers.handle_tool_call(
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

      [content] = result.content
      response_data = Jason.decode!(content.text)
      resource_uri = response_data["resource_uri"]

      assert String.starts_with?(resource_uri, "aria://plans/")
      assert Map.has_key?(new_state.created_resources, resource_uri)
    end
  end

  describe "Plan creation with lazy execution" do
    test "lazy plan has pending status", %{state: state} do
      {:ok, result, _state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "lazy_test",
          "name" => "Lazy Test Plan",
          "domain_type" => "blocks_world",
          "run_lazy" => true
        },
        state
      )

      [content] = result.content
      response = Jason.decode!(content.text)
      assert response["execution_status"] == "pending"
      assert response["run_lazy"] == true
    end

    test "eager plan has planned status", %{state: state} do
      {:ok, result, _state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "eager_test",
          "name" => "Eager Test Plan",
          "domain_type" => "navigation",
          "run_lazy" => false
        },
        state
      )

      [content] = result.content
      response = Jason.decode!(content.text)
      assert response["execution_status"] == "planned"
      assert response["run_lazy"] == false
    end
  end

  describe "Multi-persona planning" do
    test "creates plans for multiple personas", %{state: state} do
      personas = ["persona_a", "persona_b", "persona_c"]

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

      assert final_state.prompt_uses == 3
      assert map_size(final_state.created_resources) >= 3
    end
  end
end
