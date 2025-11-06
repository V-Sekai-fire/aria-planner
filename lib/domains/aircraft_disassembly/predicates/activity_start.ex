# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Predicates.ActivityStart do
  @moduledoc """
  Activity Start predicate for aircraft-disassembly domain.
  
  Represents the start time of an activity.
  """

  @doc """
  Gets the start time of an activity from state.
  """
  @spec get(state :: map(), activity :: integer()) :: integer()
  def get(state, activity) do
    Map.get(state.activity_start, activity, 0)
  end

  @doc """
  Sets the start time of an activity in state.
  """
  @spec set(state :: map(), activity :: integer(), start_time :: integer()) :: map()
  def set(state, activity, start_time) do
    new_activity_start = Map.put(state.activity_start, activity, start_time)
    Map.put(state, :activity_start, new_activity_start)
  end
end

