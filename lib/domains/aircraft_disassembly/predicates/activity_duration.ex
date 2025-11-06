# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Predicates.ActivityDuration do
  @moduledoc """
  Activity Duration predicate for aircraft-disassembly domain.
  
  Represents the duration of an activity.
  """

  @doc """
  Gets the duration of an activity from state.
  """
  @spec get(state :: map(), activity :: integer()) :: integer()
  def get(state, activity) do
    Map.get(state.activity_duration, activity, 0)
  end

  @doc """
  Sets the duration of an activity in state.
  """
  @spec set(state :: map(), activity :: integer(), duration :: integer()) :: map()
  def set(state, activity, duration) do
    new_activity_duration = Map.put(state.activity_duration, activity, duration)
    Map.put(state, :activity_duration, new_activity_duration)
  end
end

