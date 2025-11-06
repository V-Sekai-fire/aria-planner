# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Predicates.ResourceAssigned do
  @moduledoc """
  Resource Assigned predicate for aircraft-disassembly domain.
  
  Represents whether a resource is assigned to an activity.
  """

  @doc """
  Checks if a resource is assigned to an activity.
  """
  @spec get(state :: map(), activity :: integer(), resource :: integer()) :: boolean()
  def get(state, activity, resource) do
    Map.get(state.resource_assigned, {activity, resource}, false)
  end

  @doc """
  Sets whether a resource is assigned to an activity.
  """
  @spec set(state :: map(), activity :: integer(), resource :: integer(), assigned :: boolean()) :: map()
  def set(state, activity, resource, assigned) do
    new_resource_assigned = Map.put(state.resource_assigned, {activity, resource}, assigned)
    Map.put(state, :resource_assigned, new_resource_assigned)
  end
end

