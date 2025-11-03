# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorldTest do
  use ExUnit.Case, async: true
  doctest AriaPlanner.Domains.BlocksWorld

  alias AriaPlanner.Domains.BlocksWorld
  alias AriaPlanner.Domains.BlocksWorld.Predicates.{Pos, Clear, Holding}
  alias AriaPlanner.Domains.BlocksWorld.Commands.{Pickup, Unstack, Putdown, Stack}
  alias AriaPlanner.Domains.BlocksWorld.Tasks.{MoveBlocks, MoveOne, Get, Put, IsDone, Status, AllBlocks, FindIf}
  alias AriaPlanner.Domains.BlocksWorld.Unigoals.Move1
  alias AriaPlanner.Domains.BlocksWorld.Multigoals.MoveBlocks
  alias AriaPlanner.Repo
  alias AriaPlanner.BlocksWorldProblems
  alias AriaPlanner.PlanManager
  alias AriaCore.Plan
  alias Jason
  alias MCP.AriaForge.ToolHandlers
  import AriaPlanner.BlocksWorldProblems

  setup do
    :ok
  end

  defp setup_initial_state(initial_state_map) do
    # Clean up state before setting up - Removed due to Ecto.Adapters.SQL.Sandbox
    # Repo.delete_all(Pos)
    # Repo.delete_all(Clear)
    # Repo.delete_all(Holding)

    Enum.each(initial_state_map.pos, fn {block, pos_val} ->
      Repo.insert!(%Pos{entity_id: block, value: pos_val})
    end)
    Enum.each(initial_state_map.clear, fn {block, clear_val} ->
      Repo.insert!(%Clear{entity_id: block, value: clear_val})
    end)
    Repo.insert!(%Holding{entity_id: "hand", value: initial_state_map.holding["hand"]})
  end

  describe "domain creation" do
    test "creates planning domain with correct structure" do
      {:ok, domain} = BlocksWorld.create_domain()

      assert domain.type == "blocks_world"
      assert domain.predicates == ["pos", "clear", "holding"]
      assert length(domain.actions) == 4
      assert length(domain.methods) == 4
      assert length(domain.goal_methods) == 4
    end

    test "domain has all required actions" do
      {:ok, domain} = BlocksWorld.create_domain()
      action_names = Enum.map(domain.actions, & &1.name)

      assert "a_pickup" in action_names
      assert "a_unstack" in action_names
      assert "a_putdown" in action_names
      assert "a_stack" in action_names
    end

    test "domain has all required task methods" do
      {:ok, domain} = BlocksWorld.create_domain()
      method_names = Enum.map(domain.methods, & &1.name)

      assert "move_blocks" in method_names
      assert "move_one" in method_names
      assert "get" in method_names
      assert "put" in method_names
    end

    test "domain has all required goal methods" do
      {:ok, domain} = BlocksWorld.create_domain()
      goal_method_names = Enum.map(domain.goal_methods, & &1.name)

      assert "move_blocks" in goal_method_names
      assert "gm_move1" in goal_method_names
      assert "gm_get" in goal_method_names
      assert "gm_put" in goal_method_names
    end
  end

  describe "state initialization" do
    test "initializes state with blocks" do
      blocks = ["a", "b", "c"]
      {:ok, result} = BlocksWorld.initialize_state(blocks)

      assert result.blocks == blocks
      assert result.initialized == true

      # Verify pos facts
      pos_facts = Repo.all(Pos)
      assert length(pos_facts) == 3
      Enum.each(pos_facts, fn fact -> assert fact.value == "table" end)

      # Verify clear facts
      clear_facts = Repo.all(Clear)
      assert length(clear_facts) == 3
      Enum.each(clear_facts, fn fact -> assert fact.value == true end)

      # Verify holding fact
      holding_facts = Repo.all(Holding)
      assert length(holding_facts) == 1
      assert Enum.at(holding_facts, 0).value == "false"
    end

    test "get_state returns current state" do
      blocks = ["a", "b"]
      BlocksWorld.initialize_state(blocks)

      {:ok, state} = BlocksWorld.get_state()

      assert state.pos["a"] == "table"
      assert state.pos["b"] == "table"
      assert state.clear["a"] == true
      assert state.clear["b"] == true
      assert state.holding["hand"] == "false"
    end

    test "reset_state clears all facts" do
      blocks = ["a", "b"]
      BlocksWorld.initialize_state(blocks)

      {:ok, _} = BlocksWorld.reset_state()

      assert Repo.all(Pos) == []
      assert Repo.all(Clear) == []
      assert Repo.all(Holding) == []
    end
  end

  describe "helper functions" do
    setup do
      blocks = ["a", "b", "c"]
      BlocksWorld.initialize_state(blocks)
      :ok
    end

    test "all_blocks returns all block IDs" do
      blocks = AllBlocks.t_all_blocks()
      assert length(blocks) == 3
      assert "a" in blocks
      assert "b" in blocks
      assert "c" in blocks
    end

    test "is_done checks if block is in final position" do
      goal = %{"a" => "table", "b" => "a"}

      # Block a is done (on table as required)
      assert IsDone.t_is_done("a", goal) == true

      # Block b is not done (on table but should be on a)
      assert IsDone.t_is_done("b", goal) == false
    end

    test "status returns correct block status" do
      goal = %{"a" => "table", "b" => "a"}

      # Block a is done
      assert Status.t_status("a", goal) == "done"

      # Block b needs to move to block a
      assert Status.t_status("b", goal) == "move-to-block"
    end

    test "find_if finds first matching element" do
      blocks = ["a", "b", "c"]
      result = FindIf.t_find_if(fn x -> x == "b" end, blocks)
      assert result == "b"

      result = FindIf.t_find_if(fn x -> x == "z" end, blocks)
      assert result == nil
    end
  end

  describe "actions" do
    setup do
      blocks = ["a", "b"]
      BlocksWorld.initialize_state(blocks)
      :ok
    end

    test "a_pickup succeeds with correct preconditions" do
      {:ok, result} = Pickup.c_pickup("a")

      assert result.command == "c_pickup"
      assert result.block == "a"

      # Verify state changed
      {:ok, state} = BlocksWorld.get_state()
      assert state.pos["a"] == "hand"
      assert state.clear["a"] == false
      assert state.holding["hand"] == "a"
    end

    test "a_pickup fails if block not on table" do
      # Move block a to hand first
      Pickup.c_pickup("a")

      # Try to pickup again
      result = Pickup.c_pickup("a")
      assert {:error, _} = result
    end

    test "a_putdown succeeds with correct preconditions" do
      Pickup.c_pickup("a")
      {:ok, result} = Putdown.c_putdown("a")

      assert result.command == "c_putdown"
      assert result.block == "a"

      # Verify state changed
      {:ok, state} = BlocksWorld.get_state()
      assert state.pos["a"] == "table"
      assert state.clear["a"] == true
      assert state.holding["hand"] == "false"
    end

    test "a_stack succeeds with correct preconditions" do
      Pickup.c_pickup("a")
      {:ok, result} = Stack.c_stack("a", "b")

      assert result.command == "c_stack"
      assert result.block == "a"
      assert result.on == "b"

      # Verify state changed
      {:ok, state} = BlocksWorld.get_state()
      assert state.pos["a"] == "b"
      assert state.clear["a"] == true
      assert state.clear["b"] == false
      assert state.holding["hand"] == "false"
    end
  end

  describe "task-based methods" do
    setup do
      blocks = ["a", "b", "c"]
      BlocksWorld.initialize_state(blocks)
      :ok
    end

    test "move_one generates correct subtasks" do
      subtasks = MoveOne.t_move_one("a", "table")

      assert length(subtasks) == 2
      assert Enum.at(subtasks, 0) == {"t_get", "a"}
      assert Enum.at(subtasks, 1) == {"t_put", "a", "table"}
    end

    test "get generates pickup for block on table" do
      subtasks = Get.t_get("a")

      assert length(subtasks) == 1
      assert Enum.at(subtasks, 0) == {"c_pickup", "a"}
    end

    test "put generates putdown for table destination" do
      Pickup.c_pickup("a")
      subtasks = Put.t_put("a", "table")

      assert length(subtasks) == 1
      assert Enum.at(subtasks, 0) == {"c_putdown", "a"}
    end

    test "move_blocks generates recursive task list" do
      goal = %{"a" => "b", "b" => "table"}
      subtasks = MoveBlocks.m_move_blocks(goal)

      # Should generate at least one move task
      assert is_list(subtasks)
      assert length(subtasks) > 0
    end
  end

  describe "goal-based methods" do
    setup do
      blocks = ["a", "b"]
      BlocksWorld.initialize_state(blocks)
      :ok
    end

    test "gm_move1 generates correct goals" do
      goals = Move1.u_move1("a", "table")

      assert is_list(goals)
      assert length(goals) == 2
      assert Enum.at(goals, 0) == {"pos", "a", "hand"}
      assert Enum.at(goals, 1) == {"pos", "a", "table"}
    end

    test "gm_get generates pickup goal for block on table" do
      goals = AriaPlanner.Domains.BlocksWorld.Unigoals.Get.u_get("a", "hand")

      assert is_list(goals)
      assert length(goals) == 1
      assert Enum.at(goals, 0) == {"c_pickup", "a"}
    end

    test "gm_put generates putdown goal for table" do
      Pickup.c_pickup("a")
      goals = AriaPlanner.Domains.BlocksWorld.Unigoals.Put.u_put("a", "table")

      assert is_list(goals)
      assert length(goals) == 1
      assert Enum.at(goals, 0) == {"c_putdown", "a"}
    end

    test "move_blocks multigoal generates recursive goals" do
      goal = %{"a" => "b", "b" => "table"}
      goals = AriaPlanner.Domains.BlocksWorld.Multigoals.MoveBlocks.m_move_blocks(goal)

      assert is_list(goals)
    end
  end

  defp goal_map_to_objectives(goal_map) do
    Enum.flat_map(goal_map, fn
      {"pos", pos_map} ->
        Enum.map(pos_map, fn {block, pos_val} ->
          "pos(#{block}, #{pos_val})"
        end)
      {"clear", clear_map} ->
        Enum.map(clear_map, fn {block, clear_val} ->
          "clear(#{block}, #{clear_val})"
        end)
      {"holding", holding_map} ->
        Enum.map(holding_map, fn {hand, holding_val} ->
          "holding(#{hand}, #{holding_val})"
        end)
      {key, value} ->
        [Jason.encode!(%{key => value})]
    end)
  end

  describe "thirdparty blocks world problems" do
    setup do
      # Clean up state before each test - Removed due to Ecto.Adapters.SQL.Sandbox
      # Repo.delete_all(Pos)
      # Repo.delete_all(Clear)
      # Repo.delete_all(Holding)
      :ok
    end

    test "solves init_state_1 to goal1a via task-based planning" do
      {:ok, domain} = BlocksWorld.create_domain()
      initial_state_map = BlocksWorldProblems.init_state_1()
      goal_map = BlocksWorldProblems.goal1a()

      setup_initial_state(initial_state_map)

      # Task-based planning: use "move_blocks" task as an objective
      # The objective needs to be a string, so we'll JSON encode the task tuple
      task_objective = Jason.encode!(["move_blocks", goal_map])
      objectives = [task_objective]

      {:ok, result, _state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "test_persona",
          "name" => "Test Plan Task-Based",
          "domain_type" => "blocks_world",
          "objectives" => objectives,
          "run_lazy" => false
        },
        %{prompt_uses: %{}} # Initial state for the tool handler
      )

      [content] = result[:content]
      {:ok, plan_data} = Jason.decode(content["text"])
      plan_id = plan_data["id"]

      {:ok, plan_struct} = Repo.get(Plan, plan_id)

      assert plan_struct.solution_plan != "[]" # Assert that a plan was generated

      # Verify the final state using planner_state_snapshot
      {:ok, final_state_snapshot} = Jason.decode(plan_struct.planner_state_snapshot)

      # Check pos predicates
      Enum.each(goal_map.pos || %{}, fn {block, expected_pos} ->
        assert Map.get(final_state_snapshot["pos"], block) == expected_pos,
               "Block #{block} position mismatch. Expected #{expected_pos}, got #{Map.get(final_state_snapshot["pos"], block)}"
      end)

      # Check clear predicates
      Enum.each(goal_map.clear || %{}, fn {block, expected_clear} ->
        assert Map.get(final_state_snapshot["clear"], block) == expected_clear,
               "Block #{block} clear state mismatch. Expected #{expected_clear}, got #{Map.get(final_state_snapshot["clear"], block)}"
      end)

      # Check holding predicate
      if goal_map.holding do
        Enum.each(goal_map.holding, fn {hand, expected_holding} ->
          assert Map.get(final_state_snapshot["holding"], hand) == expected_holding,
                 "Hand holding state mismatch. Expected #{expected_holding}, got #{Map.get(final_state_snapshot["holding"], hand)}"
        end)
      end
    end

    test "solves init_state_1 to goal1a via multigoal-based planning" do
      {:ok, domain} = BlocksWorld.create_domain()
      initial_state_map = BlocksWorldProblems.init_state_1()
      goal_map = BlocksWorldProblems.goal1a()

      setup_initial_state(initial_state_map)

      # Multigoal-based planning: pass goal_map directly as an objective
      # The objective needs to be a string, so we'll JSON encode the goal map
      multigoal_objective = Jason.encode!(goal_map)
      objectives = [multigoal_objective]

      {:ok, result, _state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "test_persona",
          "name" => "Test Plan Multigoal-Based",
          "domain_type" => "blocks_world",
          "objectives" => objectives,
          "run_lazy" => false
        },
        %{prompt_uses: %{}} # Initial state for the tool handler
      )

      [content] = result[:content]
      {:ok, plan_data} = Jason.decode(content["text"])
      plan_id = plan_data["id"]

      {:ok, plan_struct} = Repo.get(Plan, plan_id)

      assert plan_struct.solution_plan != "[]" # Assert that a plan was generated

      # Verify the final state using planner_state_snapshot
      {:ok, final_state_snapshot} = Jason.decode(plan_struct.planner_state_snapshot)

      # Check pos predicates
      Enum.each(goal_map.pos || %{}, fn {block, expected_pos} ->
        assert Map.get(final_state_snapshot["pos"], block) == expected_pos,
               "Block #{block} position mismatch. Expected #{expected_pos}, got #{Map.get(final_state_snapshot["pos"], block)}"
      end)

      # Check clear predicates
      Enum.each(goal_map.clear || %{}, fn {block, expected_clear} ->
        assert Map.get(final_state_snapshot["clear"], block) == expected_clear,
               "Block #{block} clear state mismatch. Expected #{expected_clear}, got #{Map.get(final_state_snapshot["clear"], block)}"
      end)

      # Check holding predicate
      if goal_map.holding do
        Enum.each(goal_map.holding, fn {hand, expected_holding} ->
          assert Map.get(final_state_snapshot["holding"], hand) == expected_holding,
                 "Hand holding state mismatch. Expected #{expected_holding}, got #{Map.get(final_state_snapshot["holding"], hand)}"
        end)
      end
    end
  end
end
