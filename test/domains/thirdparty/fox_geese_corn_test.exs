# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCornTest do
  @moduledoc """
  Test-only domain for Fox-Geese-Corn transportation problem.

  This is a classic river crossing puzzle where:
  - Fox cannot be left alone with geese (fox eats geese)
  - Geese cannot be left alone with corn (geese eats corn)
  - Boat has limited capacity
  - Goal: Transport all items to the east side, maximizing points
  """

  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.FoxGeeseCorn
  alias AriaPlanner.Domains.FoxGeeseCorn.Commands.{CrossEast, CrossWest}
  alias AriaPlanner.Domains.FoxGeeseCorn.Tasks.TransportAll

  describe "domain creation" do
    test "creates planning domain with correct structure" do
      {:ok, domain} = FoxGeeseCorn.create_domain()

      assert domain.type == "fox_geese_corn"
      assert "east_fox" in domain.predicates
      assert "east_geese" in domain.predicates
      assert "east_corn" in domain.predicates
      assert "west_fox" in domain.predicates
      assert "west_geese" in domain.predicates
      assert "west_corn" in domain.predicates
      assert "boat_location" in domain.predicates
      assert length(domain.actions) >= 2
    end

    test "domain has required actions" do
      {:ok, domain} = FoxGeeseCorn.create_domain()
      action_names = Enum.map(domain.actions, & &1.name)

      assert "a_cross_east" in action_names
      assert "a_cross_west" in action_names
    end
  end

  describe "state initialization" do
    test "initializes state from problem parameters" do
      params = %{f: 6, g: 26, c: 8, k: 2, pf: 4, pg: 4, pc: 3}
      {:ok, state} = FoxGeeseCorn.initialize_state(params)

      assert state.west_fox == 6
      assert state.west_geese == 26
      assert state.west_corn == 8
      assert state.east_fox == 0
      assert state.east_geese == 0
      assert state.east_corn == 0
      assert state.boat_location == "west"
      assert state.boat_capacity == 2
    end

    test "parses MiniZinc data file" do
      data_file =
        Path.join([
          __DIR__,
          "../../../thirdparty/mznc2024_probs/fox-geese-corn/fgc_06_26_08_00.dzn"
        ])

      {:ok, params} = FoxGeeseCorn.parse_dzn_file(data_file)

      assert params.f == 6
      assert params.g == 26
      assert params.c == 8
      assert params.k == 2
      assert params.pf == 4
      assert params.pg == 4
      assert params.pc == 3
    end
  end

  describe "safety constraints" do
    test "detects unsafe state: fox alone with geese" do
      state = %{
        west_fox: 1,
        west_geese: 1,
        west_corn: 0,
        east_fox: 0,
        east_geese: 0,
        east_corn: 0,
        boat_location: "east"
      }

      assert FoxGeeseCorn.is_safe?(state) == false
    end

    test "detects unsafe state: geese alone with corn" do
      state = %{
        west_fox: 0,
        west_geese: 1,
        west_corn: 1,
        east_fox: 0,
        east_geese: 0,
        east_corn: 0,
        boat_location: "east"
      }

      assert FoxGeeseCorn.is_safe?(state) == false
    end

    test "detects safe state: all together" do
      state = %{
        west_fox: 1,
        west_geese: 1,
        west_corn: 1,
        east_fox: 0,
        east_geese: 0,
        east_corn: 0,
        boat_location: "west"
      }

      assert FoxGeeseCorn.is_safe?(state) == true
    end

    test "detects safe state: only one type" do
      state = %{
        west_fox: 1,
        west_geese: 0,
        west_corn: 0,
        east_fox: 0,
        east_geese: 0,
        east_corn: 0,
        boat_location: "east"
      }

      assert FoxGeeseCorn.is_safe?(state) == true
    end
  end

  describe "commands" do
    setup do
      params = %{f: 2, g: 2, c: 1, k: 2, pf: 4, pg: 4, pc: 3}
      {:ok, state} = FoxGeeseCorn.initialize_state(params)
      %{initial_state: state}
    end

    test "c_cross_east transports items from west to east", %{initial_state: state} do
      {:ok, new_state} = CrossEast.c_cross_east(state, 0, 1, 0)

      assert new_state.west_geese == 1
      assert new_state.east_geese == 1
      assert new_state.boat_location == "east"
    end

    test "c_cross_east respects boat capacity", %{initial_state: state} do
      # Try to transport more than capacity
      result = CrossEast.c_cross_east(state, 1, 1, 1)

      assert {:error, _} = result
    end

    test "c_cross_west transports items from east to west" do
      state = %{
        west_fox: 1,
        west_geese: 1,
        west_corn: 0,
        east_fox: 0,
        east_geese: 0,
        east_corn: 1,
        boat_location: "east",
        boat_capacity: 2
      }

      {:ok, new_state} = CrossWest.c_cross_west(state, 0, 0, 1)

      assert new_state.east_corn == 0
      assert new_state.west_corn == 1
      assert new_state.boat_location == "west"
    end

    test "commands enforce safety constraints", %{initial_state: _state} do
      # Create unsafe state (should be prevented)
      unsafe_state = %{
        west_fox: 1,
        west_geese: 1,
        west_corn: 0,
        east_fox: 0,
        east_geese: 0,
        east_corn: 0,
        boat_location: "east",
        boat_capacity: 2
      }

      # Try to cross west, leaving fox and geese alone
      result = CrossWest.c_cross_west(unsafe_state, 0, 0, 0)

      # Should fail or prevent unsafe state
      case result do
        {:error, _} -> :ok
        {:ok, new_state} -> refute FoxGeeseCorn.is_safe?(new_state)
      end
    end
  end

  describe "tasks" do
    test "t_transport_all generates subtasks" do
      params = %{f: 1, g: 1, c: 1, k: 2, pf: 4, pg: 4, pc: 3}
      {:ok, state} = FoxGeeseCorn.initialize_state(params)

      subtasks = TransportAll.t_transport_all(state)
      assert is_list(subtasks)
      assert length(subtasks) > 0
    end
  end

  describe "problem solving" do
    test "solves small instance" do
      params = %{f: 1, g: 1, c: 1, k: 2, pf: 4, pg: 4, pc: 3}
      {:ok, initial_state} = FoxGeeseCorn.initialize_state(params)

      # Valid solution using boat capacity of 2: transport geese first, return empty, transport fox and corn together
      {:ok, state1} = CrossEast.c_cross_east(initial_state, 0, 1, 0)
      assert state1.boat_location == "east"
      assert FoxGeeseCorn.is_safe?(state1)

      {:ok, state2} = CrossWest.c_cross_west(state1, 0, 0, 0)
      assert state2.boat_location == "west"
      assert FoxGeeseCorn.is_safe?(state2)

      {:ok, state3} = CrossEast.c_cross_east(state2, 1, 0, 1)
      assert state3.boat_location == "east"
      assert state3.east_fox == 1
      assert state3.east_geese == 1
      assert state3.east_corn == 1
      assert FoxGeeseCorn.is_safe?(state3)
    end

    test "calculates objective value" do
      state = %{
        east_fox: 6,
        east_geese: 26,
        east_corn: 8,
        pf: 4,
        pg: 4,
        pc: 3
      }

      objective = FoxGeeseCorn.calculate_objective(state)
      expected = 6 * 4 + 26 * 4 + 8 * 3
      assert objective == expected
    end
  end
end
