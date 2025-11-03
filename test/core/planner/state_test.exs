# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.StateTest do
  use ExUnit.Case, async: true
  alias AriaCore.Planner.State

  describe "State creation and manipulation" do
    test "creates a new state with initial values" do
      current_time = DateTime.utc_now()
      timeline = %{"event1" => %{start: current_time, end: DateTime.add(current_time, 10, :second)}}
      entity_capabilities = %{"robot_arm" => %{"lift_capacity" => "10kg"}}
      facts = %{"robot1" => %{location: :kitchen, status: :idle}}

      state = State.new(current_time, timeline, entity_capabilities, facts)

      assert state.current_time == current_time
      assert state.timeline == timeline
      assert state.entity_capabilities == entity_capabilities
      assert state.facts == facts
    end

    test "copies a state correctly" do
      current_time = DateTime.utc_now()
      facts = %{"robot1" => %{location: :kitchen}}
      state = State.new(current_time, %{}, %{}, facts)
      copied_state = State.copy(state)

      assert copied_state.current_time == state.current_time
      assert copied_state.facts == state.facts

      # Assert that modifying the copied state does not affect the original state
      modified_copied_state = State.update_fact(copied_state, "robot1", :location, :garage)
      assert State.get_fact(state, "robot1", :location) == :kitchen
      assert State.get_fact(modified_copied_state, "robot1", :location) == :garage
    end

    test "updates a state correctly" do
      current_time = DateTime.utc_now()
      state = State.new(current_time, %{}, %{}, %{"robot1" => %{location: :kitchen}})
      new_state_data = %{current_time: DateTime.add(current_time, 1, :hour), facts: %{"robot1" => %{status: :working}}}
      updated_state = State.update(state, new_state_data)

      assert updated_state.current_time == new_state_data.current_time
      assert updated_state.facts == %{"robot1" => %{location: :kitchen, status: :working}}
    end
  end

  describe "fact management" do
    test "updates a fact for a given subject and predicate" do
      state = State.new(DateTime.utc_now(), %{}, %{}, %{"robot1" => %{location: :kitchen}})
      updated_state = State.update_fact(state, "robot1", :status, :moving)

      assert State.get_fact(updated_state, "robot1", :location) == :kitchen
      assert State.get_fact(updated_state, "robot1", :status) == :moving
    end

    test "adds a new fact for a given subject and predicate" do
      state = State.new(DateTime.utc_now(), %{}, %{}, %{})
      updated_state = State.update_fact(state, "robot2", :location, :garage)

      assert State.get_fact(updated_state, "robot2", :location) == :garage
    end

    test "retrieves a fact correctly" do
      state = State.new(DateTime.utc_now(), %{}, %{}, %{"robot1" => %{location: :kitchen, status: :idle}})

      assert State.get_fact(state, "robot1", :location) == :kitchen
      assert State.get_fact(state, "robot1", :status) == :idle
      assert State.get_fact(state, "robot1", :non_existent_predicate) == nil
      assert State.get_fact(state, "non_existent_subject", :location) == nil
    end
  end
end
