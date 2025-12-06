# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.MultiGoalHelpers do
  @moduledoc """
  Utility functions for working with multigoals.

  Matches Godot planner's PlannerMultigoal static methods:
  - Check if variant is a multigoal array
  - Get/set goal tags on multigoals
  - Check which goals are not achieved
  - Verify multigoal against state
  """

  alias AriaPlanner.Planner.State

  @doc """
  Check if a term is a multigoal array.

  A multigoal is an Array of unigoal arrays: [[predicate, subject, value], ...]
  Each unigoal is [predicate, subject, value].

  Matches Godot planner's `PlannerMultigoal.is_multigoal_array()`.

  ## Examples

      iex> AriaPlanner.Planner.MultiGoalHelpers.is_multigoal_array([["location", "agent", "kitchen"]])
      true
      
      iex> AriaPlanner.Planner.MultiGoalHelpers.is_multigoal_array(["location", "agent", "kitchen"])
      false
      
      iex> AriaPlanner.Planner.MultiGoalHelpers.is_multigoal_array(%{"item" => [["location", "agent", "kitchen"]], "goal_tag" => "tag1"})
      true
  """
  @spec is_multigoal_array(term()) :: boolean()
  def is_multigoal_array(term) when is_map(term) do
    # Check if it's a wrapped multigoal (Dictionary with "item" key)
    case Map.get(term, "item") || Map.get(term, :item) do
      nil -> false
      item -> is_multigoal_array(item)
    end
  end

  def is_multigoal_array(term) when is_list(term) do
    # Check if it's a non-empty list where first element is also a list (unigoal)
    case term do
      [] -> false
      [first | _] -> is_list(first) and length(first) >= 3
      _ -> false
    end
  end

  def is_multigoal_array(_), do: false

  @doc """
  Get goal tag from multigoal.

  Supports both Array and Dictionary-wrapped formats.
  Matches Godot planner's `PlannerMultigoal.get_goal_tag()`.

  ## Examples

      iex> AriaPlanner.Planner.MultiGoalHelpers.get_goal_tag(%{"item" => [["location", "agent", "kitchen"]], "goal_tag" => "tag1"})
      "tag1"
      
      iex> AriaPlanner.Planner.MultiGoalHelpers.get_goal_tag([["location", "agent", "kitchen"]])
      ""
  """
  @spec get_goal_tag(term()) :: String.t()
  def get_goal_tag(term) when is_map(term) do
    case Map.get(term, "goal_tag") || Map.get(term, :goal_tag) do
      nil -> ""
      tag when is_binary(tag) -> tag
      _ -> ""
    end
  end

  def get_goal_tag(_), do: ""

  @doc """
  Set goal tag on multigoal.

  Wraps multigoal in Dictionary if needed.
  Matches Godot planner's `PlannerMultigoal.set_goal_tag()`.

  ## Examples

      iex> multigoal = [["location", "agent", "kitchen"]]
      iex> AriaPlanner.Planner.MultiGoalHelpers.set_goal_tag(multigoal, "tag1")
      %{"item" => [["location", "agent", "kitchen"]], "goal_tag" => "tag1"}
      
      iex> wrapped = %{"item" => [["location", "agent", "kitchen"]], "goal_tag" => "old"}
      iex> AriaPlanner.Planner.MultiGoalHelpers.set_goal_tag(wrapped, "new")
      %{"item" => [["location", "agent", "kitchen"]], "goal_tag" => "new"}
  """
  @spec set_goal_tag(term(), String.t()) :: map()
  def set_goal_tag(term, tag) when is_binary(tag) do
    # Unwrap if already wrapped
    actual_multigoal =
      if is_map(term) and (Map.has_key?(term, "item") || Map.has_key?(term, :item)) do
        Map.get(term, "item") || Map.get(term, :item)
      else
        term
      end

    # Wrap in dictionary with tag
    %{"item" => actual_multigoal, "goal_tag" => tag}
  end

  @doc """
  Check which goals in multigoal are not achieved in state.

  Returns list of unigoals that are not satisfied.
  Matches Godot planner's `PlannerMultigoal.method_goals_not_achieved()`.

  ## Examples

      iex> state = AriaPlanner.Planner.State.new()
      ...>   |> AriaPlanner.Planner.State.set_fact("location", "agent", "kitchen")
      iex> multigoal = [["location", "agent", "kitchen"], ["location", "agent", "bedroom"]]
      iex> AriaPlanner.Planner.MultiGoalHelpers.goals_not_achieved(state, multigoal)
      [["location", "agent", "bedroom"]]
  """
  @spec goals_not_achieved(State.t(), term()) :: [list()]
  def goals_not_achieved(state, multigoal) do
    # Unwrap if needed
    actual_multigoal =
      if is_map(multigoal) and (Map.has_key?(multigoal, "item") || Map.has_key?(multigoal, :item)) do
        Map.get(multigoal, "item") || Map.get(multigoal, :item)
      else
        multigoal
      end

    if is_multigoal_array(actual_multigoal) do
      Enum.filter(actual_multigoal, fn unigoal ->
        not goal_achieved?(state, unigoal)
      end)
    else
      []
    end
  end

  @doc """
  Verify multigoal against state.

  Returns true if all goals in multigoal are achieved, false otherwise.
  Matches Godot planner's `PlannerMultigoal.method_verify_multigoal()`.

  ## Examples

      iex> state = AriaPlanner.Planner.State.new()
      ...>   |> AriaPlanner.Planner.State.set_fact("location", "agent1", "kitchen")
      ...>   |> AriaPlanner.Planner.State.set_fact("location", "agent2", "bedroom")
      iex> multigoal = [["location", "agent1", "kitchen"], ["location", "agent2", "bedroom"]]
      iex> AriaPlanner.Planner.MultiGoalHelpers.verify_multigoal(state, "method1", multigoal, 0, 0)
      true
  """
  @spec verify_multigoal(State.t(), String.t(), term(), integer(), integer()) :: boolean()
  def verify_multigoal(state, _method, multigoal, _depth, _verbose) do
    not_achieved = goals_not_achieved(state, multigoal)
    Enum.empty?(not_achieved)
  end

  # Helper: Check if a single unigoal is achieved in state
  defp goal_achieved?(state, [predicate, subject, value]) when is_binary(predicate) and is_binary(subject) do
    State.matches?(state, predicate, subject, value)
  end

  defp goal_achieved?(_state, _unigoal), do: false
end
