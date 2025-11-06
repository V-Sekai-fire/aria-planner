# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.NeighboursTest do
  @moduledoc """
  Test-only domain for Neighbours grid assignment problem.
  
  Each cell in an n×m grid gets a number 1-5.
  If a cell has value N>1, it must have neighbors with values 1, 2, ..., N-1.
  Goal: Maximize the sum of all values.
  """

  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.Neighbours
  alias AriaPlanner.Domains.Neighbours.Commands.AssignValue
  alias AriaPlanner.Domains.Neighbours.Predicates.GridValue
  alias AriaPlanner.Domains.Neighbours.Tasks.MaximizeGrid

  describe "domain creation" do
    test "creates planning domain with correct structure" do
      {:ok, domain} = Neighbours.create_domain()

      assert domain.type == "neighbours"
      assert "grid_value" in domain.predicates
      assert length(domain.actions) >= 1
    end

    test "domain has required actions" do
      {:ok, domain} = Neighbours.create_domain()
      action_names = Enum.map(domain.actions, & &1.name)

      assert "a_assign_value" in action_names
    end
  end

  describe "state initialization" do
    test "initializes state from grid dimensions" do
      {:ok, state} = Neighbours.initialize_state(4, 2)

      assert state.n == 4
      assert state.m == 2
      assert map_size(state.grid) == 8
      assert GridValue.get(state, 1, 1) == 0
      assert GridValue.get(state, 4, 2) == 0
    end

    test "parses MiniZinc data file" do
      data_file =
        Path.join([
          __DIR__,
          "../../../thirdparty/mznc2024_probs/neighbours/neightbours-new-2.dzn"
        ])

      {:ok, params} = Neighbours.parse_dzn_file(data_file)

      assert params.n == 4
      assert params.m == 2
    end
  end

  describe "neighbor detection" do
    test "gets neighbors for corner cell" do
      {:ok, state} = Neighbours.initialize_state(3, 3)
      neighbors = Neighbours.get_neighbors(state, 1, 1)

      assert length(neighbors) == 2
      assert {2, 1} in neighbors
      assert {1, 2} in neighbors
    end

    test "gets neighbors for edge cell" do
      {:ok, state} = Neighbours.initialize_state(3, 3)
      neighbors = Neighbours.get_neighbors(state, 1, 2)

      assert length(neighbors) == 3
      assert {2, 2} in neighbors
      assert {1, 1} in neighbors
      assert {1, 3} in neighbors
    end

    test "gets neighbors for center cell" do
      {:ok, state} = Neighbours.initialize_state(3, 3)
      neighbors = Neighbours.get_neighbors(state, 2, 2)

      assert length(neighbors) == 4
      assert {1, 2} in neighbors
      assert {3, 2} in neighbors
      assert {2, 1} in neighbors
      assert {2, 3} in neighbors
    end
  end

  describe "neighbor constraint checking" do
    test "value 1 can be assigned anywhere" do
      {:ok, state} = Neighbours.initialize_state(2, 2)

      assert Neighbours.has_neighbors_with_values(state, 1, 1, 1..0//-1) == true
    end

    test "value 2 requires neighbor with value 1" do
      {:ok, state} = Neighbours.initialize_state(2, 2)
      state = GridValue.set(state, 1, 2, 1)

      assert Neighbours.has_neighbors_with_values(state, 1, 1, 1..1) == true
    end

    test "value 3 requires neighbors with values 1 and 2" do
      {:ok, state} = Neighbours.initialize_state(3, 3)
      state = GridValue.set(state, 1, 2, 1)
      state = GridValue.set(state, 2, 1, 2)

      assert Neighbours.has_neighbors_with_values(state, 2, 2, 1..2) == true
    end
  end

  describe "commands" do
    test "c_assign_value assigns value to cell" do
      {:ok, state} = Neighbours.initialize_state(2, 2)
      {:ok, new_state} = AssignValue.c_assign_value(state, 1, 1, 1)

      assert GridValue.get(new_state, 1, 1) == 1
    end

    test "c_assign_value enforces neighbor constraint" do
      {:ok, state} = Neighbours.initialize_state(2, 2)

      # Try to assign value 2 without neighbor having value 1
      result = AssignValue.c_assign_value(state, 1, 1, 2)

      assert {:error, _} = result
    end

    test "c_assign_value allows value 2 with neighbor having value 1" do
      {:ok, state} = Neighbours.initialize_state(2, 2)
      state = GridValue.set(state, 1, 2, 1)

      {:ok, new_state} = AssignValue.c_assign_value(state, 1, 1, 2)

      assert GridValue.get(new_state, 1, 1) == 2
    end

    test "c_assign_value prevents reassignment" do
      {:ok, state} = Neighbours.initialize_state(2, 2)
      {:ok, state} = AssignValue.c_assign_value(state, 1, 1, 1)

      result = AssignValue.c_assign_value(state, 1, 1, 2)

      assert {:error, _} = result
    end
  end

  describe "tasks" do
    test "t_maximize_grid generates subtasks" do
      {:ok, state} = Neighbours.initialize_state(2, 2)

      subtasks = MaximizeGrid.t_maximize_grid(state)
      assert is_list(subtasks)
      assert length(subtasks) > 0
    end
  end

  describe "problem solving" do
    test "solves small 2x2 instance" do
      {:ok, state} = Neighbours.initialize_state(2, 2)

      # Assign value 1 to first cell
      {:ok, state} = AssignValue.c_assign_value(state, 1, 1, 1)

      # Now can assign value 2 to neighbor
      {:ok, state} = AssignValue.c_assign_value(state, 1, 2, 2)

      # Continue with other cells
      {:ok, state} = AssignValue.c_assign_value(state, 2, 1, 1)
      {:ok, state} = AssignValue.c_assign_value(state, 2, 2, 2)

      assert Neighbours.is_complete?(state)
      objective = Neighbours.calculate_objective(state)
      assert objective == 6
    end
  end
end
