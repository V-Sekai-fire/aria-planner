# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.MetadataAttachment do
  @moduledoc """
  Unified metadata attachment for planner elements.

  Matches Godot planner's `PlannerPlan.attach_metadata()` method, which provides
  a unified way to attach temporal and/or entity constraints to any planner element
  (action, task, goal, multigoal).

  Uses ISO 8601 strings for temporal constraints (matching PlannerMetadata) instead
  of integer microseconds (Godot's format).
  """

  alias AriaPlanner.Planner.{PlannerMetadata, EntityRequirement}

  @doc """
  Attach metadata (temporal and/or entity constraints) to a planner element.

  Supports attaching to:
  - Actions (tuples like `{:action_name, arg1, arg2}`)
  - Tasks (tuples like `{:task_name, arg1, arg2}`)
  - Goals (tuples like `["predicate", "subject", value]`)
  - Multigoals (lists of goal tuples)

  Temporal constraints: Map with optional keys:
  - `duration`: ISO 8601 duration string (e.g., "PT5M")
  - `start_time`: ISO 8601 datetime string (e.g., "2025-01-01T10:00:00Z")
  - `end_time`: ISO 8601 datetime string

  Entity constraints: Map with either:
  - Convenience format: `%{"type" => "agent", "capabilities" => [:cooking]}`
  - Full format: `%{"requires_entities" => [%EntityRequirement{...}]}`

  Matches Godot planner's `attach_metadata(item, temporal_constraints, entity_constraints)`.

  ## Examples

      iex> temporal = %{"duration" => "PT5M", "start_time" => "2025-01-01T10:00:00Z"}
      iex> entity = %{"type" => "agent", "capabilities" => [:cooking]}
      iex> action = {:cook, "meal"}
      iex> {_, _, metadata} = AriaPlanner.Planner.MetadataAttachment.attach_metadata(action, temporal, entity)
      iex> metadata.duration
      "PT5M"
  """
  @spec attach_metadata(term(), map(), map()) :: term()
  def attach_metadata(item, temporal_constraints \\ %{}, entity_constraints \\ %{}) do
    # Extract temporal metadata
    metadata = extract_temporal_metadata(temporal_constraints)

    # Extract entity requirements
    entity_reqs = extract_entity_requirements(entity_constraints)

    # Create PlannerMetadata
    planner_metadata = create_planner_metadata(metadata, entity_reqs)

    # Attach to item based on type
    attach_to_item(item, planner_metadata)
  end

  # Extract temporal metadata from constraints map
  defp extract_temporal_metadata(constraints) when is_map(constraints) do
    %{
      duration: Map.get(constraints, "duration") || Map.get(constraints, :duration),
      start_time: Map.get(constraints, "start_time") || Map.get(constraints, :start_time),
      end_time: Map.get(constraints, "end_time") || Map.get(constraints, :end_time)
    }
  end

  defp extract_temporal_metadata(_), do: %{duration: nil, start_time: nil, end_time: nil}

  # Extract entity requirements from constraints map
  defp extract_entity_requirements(constraints) when is_map(constraints) do
    # Check for full format first
    case Map.get(constraints, "requires_entities") || Map.get(constraints, :requires_entities) do
      reqs when is_list(reqs) ->
        # Already EntityRequirement structs or maps
        Enum.map(reqs, fn req ->
          if is_struct(req, EntityRequirement) do
            req
          else
            # Convert map to EntityRequirement
            EntityRequirement.new!(
              Map.get(req, "type") || Map.get(req, :type),
              Map.get(req, "capabilities") || Map.get(req, :capabilities) || []
            )
          end
        end)

      _ ->
        # Check for convenience format
        case {Map.get(constraints, "type") || Map.get(constraints, :type),
              Map.get(constraints, "capabilities") || Map.get(constraints, :capabilities)} do
          {type, capabilities} when is_binary(type) and is_list(capabilities) ->
            [EntityRequirement.new!(type, capabilities)]

          _ ->
            []
        end
    end
  end

  defp extract_entity_requirements(_), do: []

  # Create PlannerMetadata from extracted data
  defp create_planner_metadata(temporal, entity_reqs) do
    duration = temporal.duration || "PT0S"
    opts = []
    opts = if temporal.start_time, do: Keyword.put(opts, :start_time, temporal.start_time), else: opts
    opts = if temporal.end_time, do: Keyword.put(opts, :end_time, temporal.end_time), else: opts

    PlannerMetadata.new!(duration, entity_reqs, opts)
  end

  # Attach metadata to item based on type
  defp attach_to_item(item, metadata) when is_tuple(item) do
    # Action or task tuple - append metadata as last element
    # Use Tuple.insert_at instead of deprecated Tuple.append
    Tuple.insert_at(item, tuple_size(item), metadata)
  end

  defp attach_to_item(item, metadata) when is_list(item) do
    # Goal or multigoal - wrap in map with metadata
    %{"item" => item, "metadata" => metadata}
  end

  defp attach_to_item(item, metadata) when is_map(item) do
    # Already wrapped - add metadata
    Map.put(item, "metadata", metadata)
  end

  defp attach_to_item(item, metadata) do
    # Fallback - wrap in map
    %{"item" => item, "metadata" => metadata}
  end

  @doc """
  Extract metadata from a planner element.

  Returns the PlannerMetadata struct if attached, nil otherwise.
  """
  @spec extract_metadata(term()) :: PlannerMetadata.t() | nil
  def extract_metadata(item) when is_tuple(item) do
    # Check if last element is PlannerMetadata
    case Tuple.to_list(item) do
      [_ | _] = list ->
        last = List.last(list)
        if is_struct(last, PlannerMetadata), do: last, else: nil

      _ ->
        nil
    end
  end

  def extract_metadata(item) when is_map(item) do
    Map.get(item, "metadata") || Map.get(item, :metadata)
  end

  def extract_metadata(_), do: nil

  @doc """
  Check if item has metadata attached.
  """
  @spec has_metadata?(term()) :: boolean()
  def has_metadata?(item) do
    not is_nil(extract_metadata(item))
  end
end
