# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.StateHelpers do
  @moduledoc """
  Helper functions for working with aircraft disassembly state.
  """

  @type state :: map()
  @type activity_id :: String.t()
  @type activity :: non_neg_integer()
  @type status :: String.t()

  @doc """
  Checks if all activities are completed.
  """
  @spec all_activities_completed?(state()) :: boolean()
  def all_activities_completed?(state) do
    num_activities = Map.get(state, :num_activities, 0)
    Enum.all?(1..num_activities, fn activity ->
      activity_id = "activity_#{activity}"
      get_activity_status(state, activity_id) == "completed"
    end)
  end

  @doc """
  Gets the status of an activity.
  """
  @spec get_activity_status(state(), activity_id()) :: status()
  def get_activity_status(state, activity_id) do
    case Map.get(state, :facts, %{}) do
      facts when is_map(facts) ->
        case Map.get(facts, "activity_status", %{}) do
          status_map when is_map(status_map) ->
            Map.get(status_map, activity_id, "not_started")
          _ ->
            "not_started"
        end
      _ ->
        # Fallback to old state structure
        Map.get(state.activity_status || %{}, String.to_integer(String.replace(activity_id, "activity_", "")), "not_started")
    end
  end

  @doc """
  Gets all predecessors of an activity.
  """
  @spec get_predecessors(state(), activity()) :: [activity()]
  def get_predecessors(state, activity) do
    precedences = Map.get(state, :precedences, [])
    precedences
    |> Enum.filter(fn {_pred, succ} -> succ == activity end)
    |> Enum.map(fn {pred, _succ} -> pred end)
  end

  @doc """
  Gets all successors of an activity.
  """
  @spec get_successors(state(), activity()) :: [activity()]
  def get_successors(state, activity) do
    precedences = Map.get(state, :precedences, [])
    precedences
    |> Enum.filter(fn {pred, _succ} -> pred == activity end)
    |> Enum.map(fn {_pred, succ} -> succ end)
  end

  @doc """
  Checks if all predecessors of an activity are completed.
  """
  @spec all_predecessors_completed?(state(), activity()) :: boolean()
  def all_predecessors_completed?(state, activity) do
    predecessors = get_predecessors(state, activity)
    Enum.all?(predecessors, fn pred ->
      pred_id = "activity_#{pred}"
      get_activity_status(state, pred_id) == "completed"
    end)
  end
end

