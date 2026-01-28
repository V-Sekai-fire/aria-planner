defmodule AriaPlanner.Domains.BlocksWorldTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.BlocksWorld
  alias AriaPlanner.Domains.BlocksWorld.Tasks.MoveBlocks
  alias AriaPlanner.Domains.BlocksWorld.Tasks.MoveOne
  alias AriaPlanner.Domains.BlocksWorld.Tasks.Get
  alias AriaPlanner.Domains.BlocksWorld.Tasks.Put

  describe "domain creation" do
    test "creates blocks_world domain" do
      assert {:ok, domain} = BlocksWorld.create_domain()
      assert domain.domain_type == "blocks_world"
      assert domain.name == "Blocks World"
    end
  end

  describe "tasks decompose to interactivity commands" do
    setup do
      state = %{
        variables: %{},
        events: []
      }

      {:ok, state: state}
    end

    test "t_get decomposes to interactivity commands", %{state: state} do
      decomposition = Get.t_get(state, "block_a")

      assert is_list(decomposition)
      assert length(decomposition) == 4

      # Check for debug log
      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "Picking up block block_a")
               _ -> false
             end)

      # Check for set_variable holding
      assert Enum.any?(decomposition, fn
               {:c_set_variable, _, "holding", "block_a"} -> true
               _ -> false
             end)

      # Check for set_variable position
      assert Enum.any?(decomposition, fn
               {:c_set_variable, _, "pos_block_a", nil} -> true
               _ -> false
             end)

      # Check for trigger_event
      assert Enum.any?(decomposition, fn
               {:c_trigger_event, _, "block_picked_up", %{"block" => "block_a"}} -> true
               _ -> false
             end)
    end

    test "t_put decomposes to interactivity commands", %{state: state} do
      decomposition = Put.t_put(state, "block_a", "table")

      assert is_list(decomposition)
      assert length(decomposition) == 4

      # Check for debug log
      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "Putting block block_a on table")
               _ -> false
             end)

      # Check for set_variable position
      assert Enum.any?(decomposition, fn
               {:c_set_variable, _, "pos_block_a", "table"} -> true
               _ -> false
             end)

      # Check for set_variable holding cleared
      assert Enum.any?(decomposition, fn
               {:c_set_variable, _, "holding", nil} -> true
               _ -> false
             end)

      # Check for trigger_event
      assert Enum.any?(decomposition, fn
               {:c_trigger_event, _, "block_put_down", %{"block" => "block_a", "destination" => "table"}} -> true
               _ -> false
             end)
    end

    test "t_move_one decomposes to get and put", %{state: state} do
      decomposition = MoveOne.t_move_one(state, "block_a", "block_b")

      assert is_list(decomposition)
      # 4 commands from get + 4 commands from put
      assert length(decomposition) == 8

      # First should be get
      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "Picking up block block_a")
               _ -> false
             end)

      # Second should be put
      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "Putting block block_a on block_b")
               _ -> false
             end)
    end

    test "t_move_blocks decomposes to multiple move operations", %{state: state} do
      goal_state = %{
        "block_a" => "block_b",
        "block_b" => "table"
      }

      decomposition = MoveBlocks.t_move_blocks(state, goal_state)

      assert is_list(decomposition)
      # 2 blocks * 8 commands each (4 from get + 4 from put)
      assert length(decomposition) == 16

      # Check for both blocks being moved
      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "block_a")
               _ -> false
             end)

      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "block_b")
               _ -> false
             end)
    end

    test "t_move_blocks with empty goal returns empty list", %{state: state} do
      decomposition = MoveBlocks.t_move_blocks(state, %{})

      assert is_list(decomposition)
      assert Enum.empty?(decomposition)
    end
  end

  describe "Sussman anomaly" do
    @moduledoc """
    The Sussman anomaly is a classic blocks world problem that demonstrates
    the need for proper goal ordering in planning.

    Initial state:
    - Block A is on the table
    - Block B is on the table
    - Block C is on A
    - The hand is empty

    Goal state:
    - Block A is on B
    - Block B is on C
    - Block C is on the table

    The naive approach (achieving goals in order) creates a circular dependency:
    1. Put A on B - but C is on A, so need to unstack C first
    2. Put B on C - but A is on B (after step 1), so need to unstack A first
    3. Put C on table - but B is on C (after step 2), so need to unstack B first

    This demonstrates the need for goal ordering or backtracking in the planner.
    """

    setup do
      state = %{
        variables: %{
          "pos_a" => "table",
          "pos_b" => "table",
          "pos_c" => "a",
          "holding" => nil
        },
        events: []
      }

      {:ok, state: state}
    end

    test "Sussman anomaly initial state is correctly represented", %{state: state} do
      assert state.variables["pos_a"] == "table"
      assert state.variables["pos_b"] == "table"
      assert state.variables["pos_c"] == "a"
      assert state.variables["holding"] == nil
    end

    test "Sussman anomaly goal state is correctly defined" do
      goal_state = %{
        "a" => "b",
        "b" => "c",
        "c" => "table"
      }

      assert goal_state["a"] == "b"
      assert goal_state["b"] == "c"
      assert goal_state["c"] == "table"
    end

    test "Sussman anomaly generates decomposition for all blocks", %{state: state} do
      goal_state = %{
        "a" => "b",
        "b" => "c",
        "c" => "table"
      }

      decomposition = MoveBlocks.t_move_blocks(state, goal_state)

      assert is_list(decomposition)
      # 3 blocks * 8 commands each (4 from get + 4 from put)
      assert length(decomposition) == 24

      # Check for all blocks being moved (using block names a, b, c)
      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "block a")
               _ -> false
             end)

      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "block b")
               _ -> false
             end)

      assert Enum.any?(decomposition, fn
               {:c_debug_log, _, msg} -> String.contains?(msg, "block c")
               _ -> false
             end)
    end

    test "Sussman anomaly demonstrates circular dependency issue", %{state: state} do
      # This test documents the circular dependency problem
      # The planner needs to handle goal ordering properly

      goal_state = %{
        "a" => "b",
        "b" => "c",
        "c" => "table"
      }

      decomposition = MoveBlocks.t_move_blocks(state, goal_state)

      # The decomposition generates operations, but the planner must
      # handle the circular dependency:
      # - To put A on B, C must be moved first (C is on A)
      # - To put B on C, A must be moved first (A is on B after step 1)
      # - To put C on table, B must be moved first (B is on C after step 2)

      assert is_list(decomposition)
      assert length(decomposition) > 0

      # Verify that all three blocks are in the decomposition
      # The task decomposition doesn't handle ordering - that's the planner's job
      c_operations =
        Enum.filter(decomposition, fn
          {:c_debug_log, _, msg} -> String.contains?(msg, "block c")
          _ -> false
        end)

      b_operations =
        Enum.filter(decomposition, fn
          {:c_debug_log, _, msg} -> String.contains?(msg, "block b")
          _ -> false
        end)

      a_operations =
        Enum.filter(decomposition, fn
          {:c_debug_log, _, msg} -> String.contains?(msg, "block a")
          _ -> false
        end)

      # All three blocks should have operations in the decomposition
      # The planner is responsible for ordering them correctly
      assert length(c_operations) > 0
      assert length(b_operations) > 0
      assert length(a_operations) > 0
    end
  end
end
