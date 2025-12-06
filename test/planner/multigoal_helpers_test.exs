# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.MultiGoalHelpersTest do
  use ExUnit.Case, async: true
  doctest AriaPlanner.Planner.MultiGoalHelpers

  alias AriaPlanner.Planner.{MultiGoalHelpers, State}

  describe "is_multigoal_array/1" do
    test "returns true for multigoal array" do
      multigoal = [["location", "agent", "kitchen"], ["location", "agent", "bedroom"]]
      assert MultiGoalHelpers.is_multigoal_array(multigoal) == true
    end

    test "returns false for single unigoal" do
      unigoal = ["location", "agent", "kitchen"]
      assert MultiGoalHelpers.is_multigoal_array(unigoal) == false
    end

    test "returns false for empty array" do
      assert MultiGoalHelpers.is_multigoal_array([]) == false
    end

    test "returns false for non-array" do
      assert MultiGoalHelpers.is_multigoal_array("not an array") == false
    end

    test "returns true for wrapped multigoal" do
      wrapped = %{"item" => [["location", "agent", "kitchen"]]}
      assert MultiGoalHelpers.is_multigoal_array(wrapped) == true
    end

    test "returns false for wrapped non-multigoal" do
      wrapped = %{"item" => ["location", "agent", "kitchen"]}
      assert MultiGoalHelpers.is_multigoal_array(wrapped) == false
    end
  end

  describe "get_goal_tag/1" do
    test "gets goal tag from wrapped multigoal" do
      wrapped = %{"item" => [["location", "agent", "kitchen"]], "goal_tag" => "tag1"}
      assert MultiGoalHelpers.get_goal_tag(wrapped) == "tag1"
    end

    test "returns empty string if no tag" do
      multigoal = [["location", "agent", "kitchen"]]
      assert MultiGoalHelpers.get_goal_tag(multigoal) == ""
    end

    test "handles atom keys" do
      wrapped = %{item: [["location", "agent", "kitchen"]], goal_tag: "tag1"}
      assert MultiGoalHelpers.get_goal_tag(wrapped) == "tag1"
    end
  end

  describe "set_goal_tag/2" do
    test "wraps multigoal with tag" do
      multigoal = [["location", "agent", "kitchen"]]
      result = MultiGoalHelpers.set_goal_tag(multigoal, "tag1")

      assert result["goal_tag"] == "tag1"
      assert result["item"] == multigoal
    end

    test "updates tag on already wrapped multigoal" do
      wrapped = %{"item" => [["location", "agent", "kitchen"]], "goal_tag" => "old"}
      result = MultiGoalHelpers.set_goal_tag(wrapped, "new")

      assert result["goal_tag"] == "new"
      assert result["item"] == [["location", "agent", "kitchen"]]
    end
  end

  describe "goals_not_achieved/2" do
    test "returns goals not achieved in state" do
      state =
        State.new()
        |> State.set_fact("location", "agent", "kitchen")

      multigoal = [["location", "agent", "kitchen"], ["location", "agent", "bedroom"]]
      not_achieved = MultiGoalHelpers.goals_not_achieved(state, multigoal)

      assert length(not_achieved) == 1
      assert ["location", "agent", "bedroom"] in not_achieved
    end

    test "returns empty list if all goals achieved" do
      state =
        State.new()
        |> State.set_fact("location", "agent1", "kitchen")
        |> State.set_fact("location", "agent2", "bedroom")

      multigoal = [["location", "agent1", "kitchen"], ["location", "agent2", "bedroom"]]
      not_achieved = MultiGoalHelpers.goals_not_achieved(state, multigoal)

      assert not_achieved == []
    end

    test "handles wrapped multigoal" do
      state =
        State.new()
        |> State.set_fact("location", "agent", "kitchen")

      wrapped = %{"item" => [["location", "agent", "kitchen"], ["location", "agent", "bedroom"]]}
      not_achieved = MultiGoalHelpers.goals_not_achieved(state, wrapped)

      assert length(not_achieved) == 1
    end
  end

  describe "verify_multigoal/5" do
    test "returns true if all goals achieved" do
      state =
        State.new()
        |> State.set_fact("location", "agent1", "kitchen")
        |> State.set_fact("location", "agent2", "bedroom")

      multigoal = [["location", "agent1", "kitchen"], ["location", "agent2", "bedroom"]]
      assert MultiGoalHelpers.verify_multigoal(state, "method1", multigoal, 0, 0) == true
    end

    test "returns false if some goals not achieved" do
      state =
        State.new()
        |> State.set_fact("location", "agent", "kitchen")

      multigoal = [["location", "agent", "kitchen"], ["location", "agent", "bedroom"]]
      assert MultiGoalHelpers.verify_multigoal(state, "method1", multigoal, 0, 0) == false
    end
  end
end
