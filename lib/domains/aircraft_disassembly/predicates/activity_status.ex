# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Predicates.ActivityStatus do
  @moduledoc """
  Activity Status predicate for aircraft-disassembly domain.
  
  Represents the status of an activity: "not_started", "in_progress", or "completed".
  """

  @doc """
  Gets the status of an activity from state.
  """
  @spec get(state :: map(), activity :: integer()) :: String.t()
  def get(state, activity) do
    Map.get(state.activity_status, activity, "not_started")
  end

  @doc """
  Sets the status of an activity in state.
  """
  @spec set(state :: map(), activity :: integer(), status :: String.t()) :: map()
  def set(state, activity, status) do
    new_activity_status = Map.put(state.activity_status, activity, status)
    Map.put(state, :activity_status, new_activity_status)
  end
end

