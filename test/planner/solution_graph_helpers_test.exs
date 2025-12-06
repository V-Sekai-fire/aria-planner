# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.SolutionGraphHelpersTest do
  use ExUnit.Case, async: true
  doctest AriaPlanner.Planner.SolutionGraphHelpers

  alias AriaPlanner.Planner.{SolutionGraphHelpers, PlannerMetadata, EntityRequirement, TimeRange}

  describe "apply_temporal_metadata/2" do
    test "applies temporal metadata to node" do
      node = %{type: :A, status: :O, info: :action1}

      metadata =
        PlannerMetadata.new!(
          "PT5M",
          [
            EntityRequirement.new!("agent", [:cooking])
          ],
          start_time: "2025-01-01T10:00:00Z"
        )

      result = SolutionGraphHelpers.apply_temporal_metadata(node, metadata)

      assert result.duration == "PT5M"
      assert result.start_time == "2025-01-01T10:00:00Z"
      assert result.type == :A
      assert result.status == :O
    end

    test "handles nil metadata" do
      node = %{type: :A, status: :O}
      result = SolutionGraphHelpers.apply_temporal_metadata(node, nil)
      assert result == node
    end
  end

  describe "extract_temporal_metadata/2" do
    test "extracts temporal metadata from node" do
      node = %{
        start_time: "2025-01-01T10:00:00Z",
        duration: "PT5M",
        end_time: "2025-01-01T10:05:00Z"
      }

      entity_reqs = [EntityRequirement.new!("agent", [:cooking])]

      metadata = SolutionGraphHelpers.extract_temporal_metadata(node, entity_reqs)

      assert metadata.duration == "PT5M"
      assert metadata.start_time == "2025-01-01T10:00:00Z"
      assert metadata.end_time == "2025-01-01T10:05:00Z"
      assert length(metadata.requires_entities) == 1
    end

    test "handles string keys in node" do
      node = %{
        "start_time" => "2025-01-01T10:00:00Z",
        "duration" => "PT5M"
      }

      entity_reqs = [EntityRequirement.new!("agent", [:cooking])]

      metadata = SolutionGraphHelpers.extract_temporal_metadata(node, entity_reqs)
      assert metadata.duration == "PT5M"
      assert metadata.start_time == "2025-01-01T10:00:00Z"
    end
  end

  describe "create_node_with_metadata/4" do
    test "creates node with metadata" do
      metadata =
        PlannerMetadata.new!("PT5M", [
          EntityRequirement.new!("agent", [:cooking])
        ])

      node = SolutionGraphHelpers.create_node_with_metadata(:A, :action1, metadata)

      assert node.type == :A
      assert node.info == :action1
      assert node.status == :O
      assert node.tag == :new
      assert node.duration == "PT5M"
    end

    test "creates node without metadata" do
      node = SolutionGraphHelpers.create_node_with_metadata(:A, :action1)

      assert node.type == :A
      assert node.info == :action1
      assert Map.get(node, :duration) == nil
    end
  end

  describe "apply_time_range/2" do
    test "applies time range to node" do
      node = %{type: :A, status: :O}

      time_range =
        TimeRange.new()
        |> TimeRange.set_start_time("2025-01-01T10:00:00Z")
        |> TimeRange.set_duration("PT30M")
        |> TimeRange.calculate_end_from_duration()

      result = SolutionGraphHelpers.apply_time_range(node, time_range)

      assert result.start_time == time_range.start_time
      assert result.duration == time_range.duration
      assert result.end_time == time_range.end_time
    end
  end

  describe "has_temporal?/1" do
    test "returns true if node has temporal constraints" do
      node = %{type: :A, duration: "PT5M"}
      assert SolutionGraphHelpers.has_temporal?(node) == true
    end

    test "returns true if node has start_time" do
      node = %{type: :A, start_time: "2025-01-01T10:00:00Z"}
      assert SolutionGraphHelpers.has_temporal?(node) == true
    end

    test "returns false if node has no temporal constraints" do
      node = %{type: :A, status: :O}
      assert SolutionGraphHelpers.has_temporal?(node) == false
    end

    test "handles string keys" do
      node = %{"duration" => "PT5M"}
      assert SolutionGraphHelpers.has_temporal?(node) == true
    end
  end

  describe "nodes_with_temporal/1" do
    test "filters nodes with temporal constraints" do
      graph = %{
        1 => %{type: :A, duration: "PT5M"},
        2 => %{type: :T, status: :O},
        3 => %{type: :A, start_time: "2025-01-01T10:00:00Z"}
      }

      result = SolutionGraphHelpers.nodes_with_temporal(graph)

      assert length(result) == 2
      assert Enum.any?(result, fn {id, _} -> id == 1 end)
      assert Enum.any?(result, fn {id, _} -> id == 3 end)
      refute Enum.any?(result, fn {id, _} -> id == 2 end)
    end

    test "returns empty list if no nodes have temporal constraints" do
      graph = %{
        1 => %{type: :A, status: :O},
        2 => %{type: :T, status: :O}
      }

      result = SolutionGraphHelpers.nodes_with_temporal(graph)
      assert result == []
    end
  end
end
