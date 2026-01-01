# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassemblyTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.AircraftDisassembly
  alias AriaPlanner.Domains.AircraftDisassembly.Commands.{AssignResource, CompleteActivity, StartActivity}
  alias AriaPlanner.Domains.AircraftDisassembly.StateInitialization

  describe "domain creation" do
    test "creates planning domain with correct structure" do
      {:ok, domain} = AircraftDisassembly.create_domain()

      assert domain.type == "aircraft_disassembly"
      assert "activity_status" in domain.predicates
      assert "precedence" in domain.predicates
      assert "resource_assigned" in domain.predicates
      assert "location_capacity" in domain.predicates
      assert length(domain.actions) >= 3
    end

    test "domain has required actions" do
      {:ok, domain} = AircraftDisassembly.create_domain()
      action_names = Enum.map(domain.actions, & &1.name)

      assert "a_start_activity" in action_names
      assert "a_assign_resource" in action_names
      assert "a_complete_activity" in action_names
    end
  end

  describe "state initialization" do
    test "initializes state with activities and resources" do
      {:ok, state} =
        StateInitialization.initialize_state(%{
          num_activities: 2,
          num_resources: 2,
          durations: [2, 1],
          precedences: [],
          locations: [1, 1],
          location_capacities: [5, 3],
          nSkills: 3
        })

      assert state.num_activities == 2
      assert state.num_resources == 2
      assert state.durations == [2, 1]
      assert Map.get(state.facts, "activity_status") != nil
      activity_status = Map.get(state.facts, "activity_status", %{})
      assert Map.get(activity_status, "activity_1") == "not_started"
      assert Map.get(activity_status, "activity_2") == "not_started"
    end
  end

  describe "commands" do
    setup do
      {:ok, state} =
        StateInitialization.initialize_state(%{
          num_activities: 2,
          num_resources: 2,
          durations: [2, 1],
          precedences: [],
          locations: [1, 1],
          location_capacities: [5, 3],
          nSkills: 3,
          # Activity 1 needs skill1
          sreq: [1, 0, 0, 0, 0, 0],
          # Resource 1 has skill1
          mastery: [1, 0, 0, 0, 0, 0]
        })

      %{initial_state: state}
    end

    test "c_start_activity starts an activity", %{initial_state: state} do
      current_time = DateTime.utc_now() |> DateTime.to_iso8601()

      {:ok, new_state, metadata} =
        StartActivity.c_start_activity(
          state,
          1,
          current_time,
          [1]
        )

      activity_status = Map.get(new_state.facts, "activity_status", %{})
      assert Map.get(activity_status, "activity_1") == "in_progress"
      assert metadata.duration != nil
      assert metadata.start_time != nil
    end

    test "c_assign_resource assigns resource to activity", %{initial_state: state} do
      {:ok, new_state, _metadata} =
        AssignResource.c_assign_resource(
          state,
          1,
          1
        )

      resource_assigned = Map.get(new_state, :resource_assigned, %{})
      assert Map.get(resource_assigned, {1, 1}) == true
    end

    test "c_complete_activity completes an activity", %{initial_state: state} do
      # First start the activity
      current_time = DateTime.utc_now() |> DateTime.to_iso8601()

      {:ok, state, _} =
        StartActivity.c_start_activity(
          state,
          1,
          current_time,
          [1]
        )

      {:ok, new_state, _metadata} = CompleteActivity.c_complete_activity(state, 1)

      activity_status = Map.get(new_state.facts, "activity_status", %{})
      assert Map.get(activity_status, "activity_1") == "completed"
    end
  end

  describe "tasks" do
    test "t_schedule_activities generates subtasks" do
      {:ok, state} =
        StateInitialization.initialize_state(%{
          num_activities: 2,
          num_resources: 1,
          durations: [2, 1],
          precedences: [],
          locations: [1, 1],
          location_capacities: [5],
          nSkills: 3
        })

      subtasks = AriaPlanner.Domains.AircraftDisassembly.Tasks.ScheduleActivities.t_schedule_activities(state)
      assert is_list(subtasks)
      # May return empty list if no activities to schedule
    end
  end

  describe "multigoals" do
    test "m_schedule_activities generates goals" do
      {:ok, state} =
        StateInitialization.initialize_state(%{
          num_activities: 2,
          num_resources: 1,
          durations: [2, 1],
          precedences: [],
          locations: [1, 1],
          location_capacities: [5],
          nSkills: 3
        })

      goals = AriaPlanner.Domains.AircraftDisassembly.Multigoals.ScheduleActivities.m_schedule_activities(state)
      assert is_list(goals)
      assert length(goals) > 0
    end
  end

  describe "precedence constraints" do
    test "enforces precedence relationships" do
      {:ok, state} =
        StateInitialization.initialize_state(%{
          num_activities: 2,
          num_resources: 1,
          durations: [1, 2],
          precedences: [{1, 2}],
          locations: [1, 1],
          location_capacities: [5],
          nSkills: 3
        })

      precedence = Map.get(state, :precedence, %{})
      assert Map.get(precedence, {1, 2}) == true
    end
  end

  describe "location capacity" do
    test "tracks location capacity" do
      {:ok, state} =
        StateInitialization.initialize_state(%{
          num_activities: 0,
          num_resources: 0,
          durations: [],
          precedences: [],
          locations: [],
          location_capacities: [5, 3],
          nSkills: 3
        })

      location_capacity = Map.get(state, :location_capacity, %{})
      assert Map.get(location_capacity, 1) == 5
      assert Map.get(location_capacity, 2) == 3
    end
  end
end
