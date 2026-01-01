# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.Commands.AssignResource do
  @moduledoc """
  Command: c_assign_resource(activity, resource)

  Assign a resource to an activity.

  Preconditions:
  - Activity is in progress or not started
  - Resource is available (simplified for now)
  - Location capacity not exceeded (simplified for now)

  Effects:
  - resource_assigned[activity, resource] = true
  """

  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.ResourceAssigned
  alias AriaPlanner.Planner.MetadataHelpers
  alias AriaPlanner.Planner.PlannerMetadata

  @spec c_assign_resource(state :: map(), activity :: integer(), resource :: integer()) ::
          {:ok, map(), PlannerMetadata.t()} | {:error, String.t()}
  def c_assign_resource(state, activity, resource) do
    case check_resource_not_assigned(state, activity, resource) do
      :ok ->
        new_state = ResourceAssigned.set(state, activity, resource, true)

        # Return planner metadata - resource assignment is instant
        metadata = MetadataHelpers.instant_metadata("worker", [:disassembly])

        {:ok, new_state, metadata}

      error ->
        error
    end
  end

  # Private helper functions

  @spec check_resource_not_assigned(map(), integer(), integer()) :: :ok | {:error, String.t()}
  defp check_resource_not_assigned(state, activity, resource) do
    if ResourceAssigned.get(state, activity, resource) do
      {:error, "Resource #{resource} is already assigned to activity #{activity}"}
    else
      :ok
    end
  end
end
