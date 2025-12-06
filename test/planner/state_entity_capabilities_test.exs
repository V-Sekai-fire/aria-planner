# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.StateEntityCapabilitiesTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.State

  describe "entity capabilities" do
    test "new state has empty entity capabilities" do
      state = State.new()
      assert state.entity_capabilities == %{}
    end

    test "new state with facts has empty entity capabilities" do
      state = State.new(%{"location" => %{"agent" => "kitchen"}})
      assert state.entity_capabilities == %{}
    end

    test "new state with facts and entity capabilities" do
      state =
        State.new(
          %{"location" => %{"agent" => "kitchen"}},
          %{"agent1" => %{"cooking" => true, "cleaning" => false}}
        )

      assert state.entity_capabilities == %{"agent1" => %{"cooking" => true, "cleaning" => false}}
    end
  end

  describe "get_entity_capability/3" do
    test "gets entity capability value" do
      state =
        State.new()
        |> State.set_entity_capability("agent1", "cooking", true)

      assert State.get_entity_capability(state, "agent1", "cooking") == true
    end

    test "returns nil for non-existent entity" do
      state = State.new()
      assert State.get_entity_capability(state, "agent1", "cooking") == nil
    end

    test "returns nil for non-existent capability" do
      state =
        State.new()
        |> State.set_entity_capability("agent1", "cooking", true)

      assert State.get_entity_capability(state, "agent1", "cleaning") == nil
    end
  end

  describe "set_entity_capability/4" do
    test "sets entity capability" do
      state =
        State.new()
        |> State.set_entity_capability("agent1", "cooking", true)

      assert State.get_entity_capability(state, "agent1", "cooking") == true
    end

    test "updates existing entity capability" do
      state =
        State.new()
        |> State.set_entity_capability("agent1", "cooking", true)
        |> State.set_entity_capability("agent1", "cooking", false)

      assert State.get_entity_capability(state, "agent1", "cooking") == false
    end

    test "sets multiple capabilities for same entity" do
      state =
        State.new()
        |> State.set_entity_capability("agent1", "cooking", true)
        |> State.set_entity_capability("agent1", "cleaning", false)

      assert State.get_entity_capability(state, "agent1", "cooking") == true
      assert State.get_entity_capability(state, "agent1", "cleaning") == false
    end

    test "sets capabilities for multiple entities" do
      state =
        State.new()
        |> State.set_entity_capability("agent1", "cooking", true)
        |> State.set_entity_capability("agent2", "cleaning", true)

      assert State.get_entity_capability(state, "agent1", "cooking") == true
      assert State.get_entity_capability(state, "agent2", "cleaning") == true
    end
  end

  describe "has_entity/2" do
    test "returns true if entity exists" do
      state =
        State.new()
        |> State.set_entity_capability("agent1", "cooking", true)

      assert State.has_entity(state, "agent1") == true
    end

    test "returns false if entity does not exist" do
      state = State.new()
      assert State.has_entity(state, "agent1") == false
    end
  end

  describe "get_all_entities/1" do
    test "returns all entity IDs" do
      state =
        State.new()
        |> State.set_entity_capability("agent1", "cooking", true)
        |> State.set_entity_capability("agent2", "cleaning", true)

      entities = State.get_all_entities(state)
      assert length(entities) == 2
      assert "agent1" in entities
      assert "agent2" in entities
    end

    test "returns empty list if no entities" do
      state = State.new()
      assert State.get_all_entities(state) == []
    end
  end
end
