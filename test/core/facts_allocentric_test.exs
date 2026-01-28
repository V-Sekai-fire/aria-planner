# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.FactsAllocentricTest do
  use ExUnit.Case, async: true
  alias AriaCore.FactsAllocentric

  describe "create/1" do
    test "creates fact with UUIDv7 ID when not provided" do
      attrs = %{
        fact_id: UUIDv7.generate(),
        fact_type: "terrain",
        subject_id: UUIDv7.generate(),
        subject_type: "location",
        predicate: "located_at",
        object_value: "forest",
        object_type: "string"
      }

      {:ok, fact} = FactsAllocentric.create(attrs)

      assert fact.fact_type == "terrain"
      assert fact.subject_type == "location"
      assert fact.predicate == "located_at"
      assert String.match?(fact.id, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
    end

    test "validates required fields" do
      invalid_attrs = %{fact_type: "terrain"}
      {:error, error_message} = FactsAllocentric.create(invalid_attrs)

      assert String.contains?(error_message, "id is required")
      assert String.contains?(error_message, "fact_id is required")
      assert String.contains?(error_message, "subject_id is required")
    end

    test "validates fact_type inclusion" do
      attrs = %{
        fact_id: UUIDv7.generate(),
        fact_type: "invalid_type",
        subject_id: UUIDv7.generate(),
        subject_type: "location",
        predicate: "located_at",
        object_value: "forest",
        object_type: "string"
      }

      {:error, error_message} = FactsAllocentric.create(attrs)
      assert String.contains?(error_message, "fact_type must be one of")
    end

    test "validates confidence range" do
      attrs = %{
        fact_id: UUIDv7.generate(),
        fact_type: "terrain",
        subject_id: UUIDv7.generate(),
        subject_type: "location",
        predicate: "located_at",
        object_value: "forest",
        object_type: "string",
        confidence: 1.5
      }

      {:error, error_message} = FactsAllocentric.create(attrs)
      assert String.contains?(error_message, "confidence must be between 0.0 and 1.0")
    end
  end

  describe "update/2" do
    test "updates existing fact" do
      {:ok, fact} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "terrain",
          subject_id: UUIDv7.generate(),
          subject_type: "location",
          predicate: "located_at",
          object_value: "forest",
          object_type: "string"
        })

      {:ok, updated} = FactsAllocentric.update(fact, %{object_value: "desert"})
      assert updated.object_value == "desert"
      assert updated.id == fact.id
    end
  end

  describe "get/1" do
    test "gets fact by ID" do
      {:ok, fact} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "terrain",
          subject_id: UUIDv7.generate(),
          subject_type: "location",
          predicate: "located_at",
          object_value: "forest",
          object_type: "string"
        })

      {:ok, retrieved} = FactsAllocentric.get(fact.id)
      assert retrieved.id == fact.id
      assert retrieved.object_value == "forest"
    end

    test "returns error for non-existent fact" do
      assert {:error, :not_found} = FactsAllocentric.get(UUIDv7.generate())
    end
  end

  describe "all/0" do
    test "gets all facts" do
      # Clear existing facts
      FactsAllocentric.all() |> Enum.each(&FactsAllocentric.delete(&1.id))

      {:ok, fact1} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "terrain",
          subject_id: UUIDv7.generate(),
          subject_type: "location",
          predicate: "located_at",
          object_value: "forest",
          object_type: "string"
        })

      {:ok, fact2} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "object",
          subject_id: UUIDv7.generate(),
          subject_type: "item",
          predicate: "has_property",
          object_value: "durable",
          object_type: "string"
        })

      all_facts = FactsAllocentric.all()
      assert length(all_facts) >= 2
      assert Enum.any?(all_facts, &(&1.id == fact1.id))
      assert Enum.any?(all_facts, &(&1.id == fact2.id))
    end
  end

  describe "get_facts_about/1" do
    test "gets facts about specific entity" do
      entity_id = UUIDv7.generate()

      {:ok, _fact1} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "terrain",
          subject_id: entity_id,
          subject_type: "location",
          predicate: "located_at",
          object_value: "forest",
          object_type: "string"
        })

      {:ok, _fact2} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "object",
          # Different entity
          subject_id: UUIDv7.generate(),
          subject_type: "item",
          predicate: "has_property",
          object_value: "durable",
          object_type: "string"
        })

      {:ok, facts} = FactsAllocentric.get_facts_about(entity_id)
<<<<<<< HEAD
      assert length(facts) >= 1
=======
      assert facts != []
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
      assert Enum.all?(facts, &(&1.subject_id == entity_id))
    end
  end

  describe "get_entity_state/1" do
    test "gets complete entity state from facts" do
      entity_id = UUIDv7.generate()

      {:ok, _fact1} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "terrain",
          subject_id: entity_id,
          subject_type: "location",
          predicate: "located_at",
          object_value: "forest",
          object_type: "string"
        })

      {:ok, _fact2} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "object",
          subject_id: entity_id,
          subject_type: "location",
          predicate: "has_capability",
          object_value: "movable",
          object_type: "string"
        })

      {:ok, state} = FactsAllocentric.get_entity_state(entity_id)
      assert state.entity_id == entity_id
      # State uses string keys for predicates
      assert Map.has_key?(state, "located_at") or Map.has_key?(state, :located_at)
      assert Map.has_key?(state, "has_capability") or Map.has_key?(state, :has_capability)
    end
  end

  describe "query_observable/2" do
    test "queries observable facts about entity" do
      entity_id = UUIDv7.generate()
      observer_id = UUIDv7.generate()

      {:ok, _fact1} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "agent_observable",
          subject_id: entity_id,
          subject_type: "persona",
          predicate: "is_moving",
          object_value: "true",
          object_type: "boolean"
        })

      {:ok, _fact2} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "event",
          subject_id: entity_id,
          subject_type: "persona",
          predicate: "performed_action",
          object_value: "attack",
          object_type: "string"
        })

      {:ok, observable} = FactsAllocentric.query_observable(observer_id, entity_id)
      assert length(observable) >= 2
      assert Enum.all?(observable, &(&1.subject_id == entity_id))
    end
  end

  describe "record_communication/1" do
    test "records communication as allocentric fact" do
      sender_id = UUIDv7.generate()

      message = %{
        sender: sender_id,
        content: "Let's coordinate the attack",
        recipients: ["persona_2"],
        message_type: "tactical"
      }

      {:ok, fact} = FactsAllocentric.record_communication(message)

      assert fact.fact_type == "event"
      assert fact.subject_id == sender_id
      assert fact.predicate == "sent_communication"
      assert fact.confidence == 1.0
    end
  end

  describe "record_event/1" do
    test "records environmental event" do
      event = %{
        region: "battlefield",
        type: "weather_shift",
        new_condition: "heavy_rain",
        game_session_id: "test_session"
      }

      {:ok, fact} = FactsAllocentric.record_event(event)

      assert fact.fact_type == "environmental"
      assert fact.subject_type == "environmental"
      assert fact.predicate == "environmental_event"
    end
  end

  describe "validate_world_state/0" do
    test "validates consistent world state" do
      # Clear existing facts
      FactsAllocentric.all() |> Enum.each(&FactsAllocentric.delete(&1.id))

      entity_id = UUIDv7.generate()

      {:ok, _fact1} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "terrain",
          subject_id: entity_id,
          subject_type: "location",
          predicate: "located_at",
          object_value: "forest",
          object_type: "string"
        })

      assert FactsAllocentric.validate_world_state() == :consistent
    end
  end

  describe "conflicting_facts/1" do
    test "finds conflicting facts about subject" do
      subject_id = UUIDv7.generate()

      {:ok, _fact1} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "terrain",
          subject_id: subject_id,
          subject_type: "location",
          predicate: "located_at",
          object_value: "forest",
          object_type: "string"
        })

      {:ok, _fact2} =
        FactsAllocentric.create(%{
          fact_id: UUIDv7.generate(),
          fact_type: "terrain",
          subject_id: subject_id,
          subject_type: "location",
          predicate: "located_at",
          object_value: "desert",
          object_type: "string"
        })

      conflicts = FactsAllocentric.conflicting_facts(subject_id)
      assert length(conflicts) >= 2
    end
  end
end
