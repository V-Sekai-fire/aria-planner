# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.MetadataAttachmentTest do
  use ExUnit.Case, async: true
  doctest AriaPlanner.Planner.MetadataAttachment

  alias AriaPlanner.Planner.{MetadataAttachment, PlannerMetadata, EntityRequirement}

  describe "attach_metadata/3" do
    test "attaches metadata to action tuple" do
      action = {:cook, "meal"}
      temporal = %{"duration" => "PT5M", "start_time" => "2025-01-01T10:00:00Z"}
      entity = %{"type" => "agent", "capabilities" => [:cooking]}

      result = MetadataAttachment.attach_metadata(action, temporal, entity)

      assert is_tuple(result)
      assert elem(result, 0) == :cook
      assert elem(result, 1) == "meal"
      assert is_struct(elem(result, 2), PlannerMetadata)
    end

    test "attaches metadata to task tuple" do
      task = {:prepare_meal, "dinner"}
      temporal = %{"duration" => "PT30M"}
      entity = %{"type" => "agent", "capabilities" => [:cooking, :preparation]}

      result = MetadataAttachment.attach_metadata(task, temporal, entity)

      assert is_tuple(result)
      metadata = elem(result, 2)
      assert metadata.duration == "PT30M"
      assert length(metadata.requires_entities) == 1
    end

    test "attaches metadata to goal list" do
      goal = ["location", "agent", "kitchen"]
      temporal = %{"duration" => "PT10M"}
      entity = %{"type" => "agent", "capabilities" => [:movement]}

      result = MetadataAttachment.attach_metadata(goal, temporal, entity)

      assert is_map(result)
      assert result["item"] == goal
      assert is_struct(result["metadata"], PlannerMetadata)
    end

    test "attaches metadata to multigoal" do
      multigoal = [["location", "agent", "kitchen"], ["location", "agent", "bedroom"]]
      temporal = %{"duration" => "PT20M"}
      entity = %{"type" => "agent", "capabilities" => [:movement]}

      result = MetadataAttachment.attach_metadata(multigoal, temporal, entity)

      assert is_map(result)
      assert result["item"] == multigoal
      assert is_struct(result["metadata"], PlannerMetadata)
    end

    test "handles empty temporal constraints" do
      action = {:cook, "meal"}
      result = MetadataAttachment.attach_metadata(action, %{}, %{})

      metadata = elem(result, 2)
      assert metadata.duration == "PT0S"
      assert metadata.requires_entities == []
    end

    test "handles full entity requirements format" do
      action = {:cook, "meal"}
      temporal = %{"duration" => "PT5M"}

      entity = %{
        "requires_entities" => [
          %EntityRequirement{type: "agent", capabilities: [:cooking]}
        ]
      }

      result = MetadataAttachment.attach_metadata(action, temporal, entity)
      metadata = elem(result, 2)

      assert length(metadata.requires_entities) == 1
      assert hd(metadata.requires_entities).type == "agent"
    end
  end

  describe "extract_metadata/1" do
    test "extracts metadata from action tuple" do
      metadata =
        PlannerMetadata.new!("PT5M", [
          EntityRequirement.new!("agent", [:cooking])
        ])

      action = {:cook, "meal", metadata}

      extracted = MetadataAttachment.extract_metadata(action)
      assert extracted == metadata
    end

    test "extracts metadata from wrapped item" do
      metadata = PlannerMetadata.new!("PT5M", [])
      wrapped = %{"item" => ["location", "agent", "kitchen"], "metadata" => metadata}

      extracted = MetadataAttachment.extract_metadata(wrapped)
      assert extracted == metadata
    end

    test "returns nil if no metadata" do
      action = {:cook, "meal"}
      assert MetadataAttachment.extract_metadata(action) == nil
    end
  end

  describe "has_metadata?/1" do
    test "returns true if metadata attached" do
      metadata = PlannerMetadata.new!("PT5M", [])
      action = {:cook, "meal", metadata}

      assert MetadataAttachment.has_metadata?(action) == true
    end

    test "returns false if no metadata" do
      action = {:cook, "meal"}
      assert MetadataAttachment.has_metadata?(action) == false
    end
  end
end
