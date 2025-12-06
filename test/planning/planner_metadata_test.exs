# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.PlannerMetadataTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.PlannerMetadata
  alias AriaPlanner.Planner.EntityRequirement

  describe "new!/3" do
    test "creates metadata successfully with valid inputs" do
      duration = "PT2H"
      entities = [%EntityRequirement{type: "agent", capabilities: [:cooking]}]

      metadata = PlannerMetadata.new!(duration, entities)

      assert metadata.duration == duration
      assert metadata.requires_entities == entities
    end

    test "raises on invalid duration" do
      entities = [%EntityRequirement{type: "agent", capabilities: []}]

      assert_raise ArgumentError, fn ->
        PlannerMetadata.new!("invalid", entities)
      end
    end

    test "allows empty entity requirements" do
      metadata = PlannerMetadata.new!("PT2H", [])
      assert metadata.duration == "PT2H"
      assert metadata.requires_entities == []
    end
  end

  describe "validate/1" do
    test "validates correct metadata" do
      metadata = %PlannerMetadata{
        duration: "PT2H",
        requires_entities: [%EntityRequirement{type: "agent", capabilities: [:cooking]}]
      }

      assert PlannerMetadata.validate(metadata) == :ok
    end

    test "rejects invalid duration" do
      metadata = %PlannerMetadata{
        duration: "invalid",
        requires_entities: [%EntityRequirement{type: "agent", capabilities: []}]
      }

      assert PlannerMetadata.validate(metadata) == {:error, :invalid_duration}
    end

    test "allows empty entity requirements" do
      metadata = %PlannerMetadata{
        duration: "PT2H",
        requires_entities: []
      }

      assert PlannerMetadata.validate(metadata) == :ok
    end
  end

  describe "valid?/1" do
    test "returns true for valid metadata" do
      metadata = %PlannerMetadata{
        duration: "PT2H",
        requires_entities: [%EntityRequirement{type: "agent", capabilities: [:cooking]}]
      }

      assert PlannerMetadata.valid?(metadata)
    end

    test "returns false for invalid duration" do
      metadata = %PlannerMetadata{
        duration: "invalid",
        requires_entities: [%EntityRequirement{type: "agent", capabilities: []}]
      }

      refute PlannerMetadata.valid?(metadata)
    end

    test "returns false for invalid entity requirements" do
      metadata = %PlannerMetadata{
        duration: "PT2H",
        requires_entities: [%{invalid: "structure"}]
      }

      refute PlannerMetadata.valid?(metadata)
    end

    test "returns false for non-metadata structs" do
      refute PlannerMetadata.valid?(%{duration: "PT2H"})
      refute PlannerMetadata.valid?("string")
      refute PlannerMetadata.valid?(nil)
    end
  end

  describe "merge/2" do
    test "merges two metadata structs" do
      metadata1 = %PlannerMetadata{
        duration: "PT1H",
        requires_entities: [%EntityRequirement{type: "agent", capabilities: [:cooking]}],
        start_time: "2025-09-27T10:00:00Z",
        end_time: "2025-09-27T11:00:00Z"
      }

      metadata2 = %PlannerMetadata{
        duration: "PT2H",
        requires_entities: [%EntityRequirement{type: "tool", capabilities: [:hammering]}],
        start_time: "2025-09-27T11:00:00Z",
        end_time: "2025-09-27T13:00:00Z"
      }

      merged = PlannerMetadata.merge(metadata1, metadata2)

      # Takes from second
      assert merged.duration == "PT2H"
      # Combines entities
      assert length(merged.requires_entities) >= 1
      # Allen relation merges overlapping intervals to create union
      # metadata1: 10:00-11:00, metadata2: 11:00-13:00 (meets/overlaps)
      # merged should be: min start to max end
      refute is_nil(merged.start_time)
      refute is_nil(merged.end_time)
    end
  end

  describe "to_map/1" do
    test "converts metadata to map" do
      metadata = %PlannerMetadata{
        duration: "PT2H",
        requires_entities: [%EntityRequirement{type: "agent", capabilities: []}],
        start_time: "2025-09-27T10:00:00Z"
      }

      map = PlannerMetadata.to_map(metadata)

      assert map["duration"] == "PT2H"
      assert map["start_time"] == "2025-09-27T10:00:00Z"
      assert is_list(map["requires_entities"])
    end
  end

  describe "from_map/1" do
    test "validates map data" do
      invalid_map = %{
        "duration" => "invalid",
        "requires_entities" => []
      }

      assert_raise ArgumentError, fn ->
        PlannerMetadata.from_map(invalid_map)
      end
    end
  end
end
