# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.SolutionGraphHelpers do
  @moduledoc """
  Helper functions for working with temporal metadata in solution graph nodes.

  Matches Godot planner's pattern where solution graph nodes have start_time,
  end_time, and duration fields that are populated from PlannerMetadata.

  In aria-planner, these fields use ISO 8601 strings (matching PlannerMetadata)
  instead of integer microseconds (Godot's format).
  """

  alias AriaPlanner.Planner.PlannerMetadata

  @doc """
  Updates a solution graph node with temporal metadata from PlannerMetadata.

  Sets start_time, end_time, and duration fields on the node from the metadata.
  All values are in ISO 8601 format (strings).

  ## Examples

      iex> metadata = AriaPlanner.Planner.PlannerMetadata.new!("PT5M", [], start_time: "2025-01-01T10:00:00Z")
      iex> node = %{type: :A, status: :O, info: :action1}
      iex> AriaPlanner.Planner.SolutionGraphHelpers.apply_temporal_metadata(node, metadata)
      %{type: :A, status: :O, info: :action1, start_time: "2025-01-01T10:00:00Z", duration: "PT5M", end_time: nil}
  """
  @spec apply_temporal_metadata(map(), PlannerMetadata.t() | nil) :: map()
  def apply_temporal_metadata(node, %PlannerMetadata{} = metadata) do
    node
    |> Map.put(:duration, metadata.duration)
    |> Map.put(:start_time, metadata.start_time)
    |> Map.put(:end_time, metadata.end_time)
  end

  def apply_temporal_metadata(node, nil), do: node
  def apply_temporal_metadata(node, _), do: node

  @doc """
  Extracts temporal metadata from a solution graph node.

  Returns a PlannerMetadata struct with the temporal fields from the node.
  Entity requirements must be provided separately (not stored in nodes).

  ## Examples

      iex> node = %{start_time: "2025-01-01T10:00:00Z", duration: "PT5M", end_time: "2025-01-01T10:05:00Z"}
      iex> entity_reqs = [%AriaPlanner.Planner.EntityRequirement{type: "agent", capabilities: [:cooking]}]
      iex> AriaPlanner.Planner.SolutionGraphHelpers.extract_temporal_metadata(node, entity_reqs)
      %AriaPlanner.Planner.PlannerMetadata{
        duration: "PT5M",
        start_time: "2025-01-01T10:00:00Z",
        end_time: "2025-01-01T10:05:00Z",
        requires_entities: [%AriaPlanner.Planner.EntityRequirement{type: "agent", capabilities: [:cooking]}]
      }
  """
  @spec extract_temporal_metadata(map(), [AriaPlanner.Planner.EntityRequirement.t()]) :: PlannerMetadata.t()
  def extract_temporal_metadata(node, requires_entities) do
    duration = Map.get(node, :duration) || Map.get(node, "duration")
    start_time = Map.get(node, :start_time) || Map.get(node, "start_time")
    end_time = Map.get(node, :end_time) || Map.get(node, "end_time")

    opts = []
    opts = if start_time, do: Keyword.put(opts, :start_time, start_time), else: opts
    opts = if end_time, do: Keyword.put(opts, :end_time, end_time), else: opts

    # Duration is required, use "PT0S" if not set
    duration = duration || "PT0S"

    PlannerMetadata.new!(duration, requires_entities, opts)
  end

  @doc """
  Creates a new solution graph node with temporal metadata applied.

  Convenience function that combines node creation with temporal metadata application.

  ## Examples

      iex> metadata = AriaPlanner.Planner.PlannerMetadata.new!("PT5M", [])
      iex> node = AriaPlanner.Planner.SolutionGraphHelpers.create_node_with_metadata(:A, :action1, metadata)
      iex> node.type == :A and node.info == :action1 and node.duration == "PT5M"
      true
  """
  @spec create_node_with_metadata(atom(), term(), PlannerMetadata.t() | nil, keyword()) :: map()
  def create_node_with_metadata(node_type, node_info, metadata \\ nil, opts \\ []) do
    base_node = %{
      type: node_type,
      info: node_info,
      status: Keyword.get(opts, :status, :O),
      tag: Keyword.get(opts, :tag, :new),
      successors: Keyword.get(opts, :successors, []),
      state: Keyword.get(opts, :state),
      selected_method: Keyword.get(opts, :selected_method),
      available_methods: Keyword.get(opts, :available_methods),
      action: Keyword.get(opts, :action)
    }

    apply_temporal_metadata(base_node, metadata)
  end

  @doc """
  Updates temporal fields on a solution graph node from a TimeRange.

  Uses AriaPlanner.Planner.TimeRange to set start_time, end_time, and duration.

  ## Examples

      iex> time_range = AriaPlanner.Planner.TimeRange.new()
      ...>   |> AriaPlanner.Planner.TimeRange.set_start_now()
      ...>   |> AriaPlanner.Planner.TimeRange.set_duration("PT30M")
      ...>   |> AriaPlanner.Planner.TimeRange.calculate_end_from_duration()
      iex> node = %{type: :A, status: :O}
      iex> result = AriaPlanner.Planner.SolutionGraphHelpers.apply_time_range(node, time_range)
      iex> result.duration
      "PT30M"
  """
  @spec apply_time_range(map(), AriaPlanner.Planner.TimeRange.t()) :: map()
  def apply_time_range(node, time_range) do
    node
    |> Map.put(:start_time, time_range.start_time)
    |> Map.put(:end_time, time_range.end_time)
    |> Map.put(:duration, time_range.duration)
  end

  @doc """
  Checks if a solution graph node has temporal constraints set.

  Returns true if any of start_time, end_time, or duration are set.

  ## Examples

      iex> node = %{start_time: "2025-01-01T10:00:00Z", duration: "PT5M"}
      iex> AriaPlanner.Planner.SolutionGraphHelpers.has_temporal?(node)
      true
      
      iex> node = %{type: :A, status: :O}
      iex> AriaPlanner.Planner.SolutionGraphHelpers.has_temporal?(node)
      false
  """
  @spec has_temporal?(map()) :: boolean()
  def has_temporal?(node) do
    start_time = Map.get(node, :start_time) || Map.get(node, "start_time")
    end_time = Map.get(node, :end_time) || Map.get(node, "end_time")
    duration = Map.get(node, :duration) || Map.get(node, "duration")

    not is_nil(start_time) or not is_nil(end_time) or not is_nil(duration)
  end

  @doc """
  Gets all nodes from a solution graph that have temporal constraints.

  Returns a list of {node_id, node} tuples for nodes with temporal metadata.

  ## Examples

      iex> graph = %{
      ...>   1 => %{type: :A, duration: "PT5M"},
      ...>   2 => %{type: :T, status: :O},
      ...>   3 => %{type: :A, start_time: "2025-01-01T10:00:00Z"}
      ...> }
      iex> AriaPlanner.Planner.SolutionGraphHelpers.nodes_with_temporal(graph)
      [{1, %{type: :A, duration: "PT5M"}}, {3, %{type: :A, start_time: "2025-01-01T10:00:00Z"}}]
  """
  @spec nodes_with_temporal(map()) :: [{integer(), map()}]
  def nodes_with_temporal(solution_graph) when is_map(solution_graph) do
    Enum.filter(solution_graph, fn {_node_id, node} -> has_temporal?(node) end)
  end
end
