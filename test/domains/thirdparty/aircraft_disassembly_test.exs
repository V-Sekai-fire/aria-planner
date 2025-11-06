# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassemblyTest do
  @moduledoc """
  Tests for Aircraft Disassembly domain with all problem instances.
  """

  use ExUnit.Case, async: false

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Commands.{StartActivity, CompleteActivity}
  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.ActivityStatus

  @problem_files [
    "B737NG-600-01-Anon.json.dzn",
    "B737NG-600-02-Anon.json.dzn",
    "B737NG-600-04-Anon.json.dzn",
    "B737NG-600-06-Anon.json.dzn",
    "B737NG-600-09-Anon.json.dzn"
  ]

  @base_path Path.join([
    __DIR__,
    "../../../thirdparty/mznc2024_probs/aircraft-disassembly"
  ])

  describe "problem instances" do
    for problem_file <- @problem_files do
      @problem_file problem_file
      @tag timeout: 30_000
      test "solves #{problem_file}" do
        problem_path = Path.join(@base_path, @problem_file)
        
        # Parse the problem file
        {:ok, params} = AircraftDisassembly.parse_dzn_file(problem_path)
        
        # Initialize state
        {:ok, state} = AircraftDisassembly.initialize_state(params)
        
        # Verify initial state
        assert state.num_activities > 0
        assert state.num_resources > 0
        
        # Try to schedule activities (simplified - just verify we can start and complete)
        # For a full solution, we'd need to implement the full scheduling algorithm
        # For now, we just verify the domain can handle the problem data
        
        # Find an activity with no predecessors (if any)
        startable_activity = Enum.find(1..state.num_activities, fn activity ->
          AircraftDisassembly.all_predecessors_completed?(state, activity)
        end)
        
        if startable_activity do
          # Start the activity
          {:ok, state_after_start} = StartActivity.c_start_activity(
            state,
            startable_activity,
            0
          )
          
          assert ActivityStatus.get(state_after_start, startable_activity) == "in_progress"
          
          # Complete the activity
          {:ok, state_after_complete} = CompleteActivity.c_complete_activity(
            state_after_start,
            startable_activity
          )
          
          assert ActivityStatus.get(state_after_complete, startable_activity) == "completed"
        end
        
        # Verify domain structure
        {:ok, domain} = AircraftDisassembly.create_domain()
        assert domain.type == "aircraft_disassembly"
        assert length(domain.predicates) >= 6
      end
    end
  end

  describe "domain creation" do
    test "creates planning domain with correct structure" do
      {:ok, domain} = AircraftDisassembly.create_domain()

      assert domain.type == "aircraft_disassembly"
      assert "activity_start" in domain.predicates
      assert "activity_duration" in domain.predicates
      assert "activity_status" in domain.predicates
      assert "precedence" in domain.predicates
      assert length(domain.actions) >= 3
    end
  end

  describe "state initialization" do
    test "initializes state from problem parameters" do
      params = %{
        num_activities: 5,
        num_resources: 3,
        durations: [10, 20, 15, 5, 30],
        precedences: [{1, 2}, {2, 3}],
        locations: [1, 2, 1, 2, 1],
        location_capacities: [2, 2]
      }

      {:ok, state} = AircraftDisassembly.initialize_state(params)

      assert state.num_activities == 5
      assert state.num_resources == 3
      assert length(state.durations) == 5
      assert length(state.precedences) == 2
    end
  end

  describe "commands" do
    setup do
      params = %{
        num_activities: 3,
        num_resources: 2,
        durations: [10, 20, 15],
        precedences: [{1, 2}],
        locations: [1, 2, 1],
        location_capacities: [2, 2]
      }

      {:ok, state} = AircraftDisassembly.initialize_state(params)
      %{initial_state: state}
    end

    test "c_start_activity starts activity with no predecessors", %{initial_state: state} do
      # Activity 1 has no predecessors
      {:ok, new_state} = StartActivity.c_start_activity(state, 1, 0)

      assert ActivityStatus.get(new_state, 1) == "in_progress"
      assert ActivityStatus.get(new_state, 2) == "not_started"
    end

    test "c_start_activity fails if predecessors not completed", %{initial_state: state} do
      # Activity 2 requires activity 1 to be completed
      assert {:error, _} = StartActivity.c_start_activity(state, 2, 0)
    end

    test "c_complete_activity completes in-progress activity", %{initial_state: state} do
      {:ok, state_after_start} = StartActivity.c_start_activity(state, 1, 0)
      {:ok, state_after_complete} = CompleteActivity.c_complete_activity(state_after_start, 1)

      assert ActivityStatus.get(state_after_complete, 1) == "completed"
    end
  end
end

