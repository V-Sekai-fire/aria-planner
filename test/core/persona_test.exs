# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PersonaTest do
  use ExUnit.Case, async: true
  alias AriaCore.Persona

  describe "create/1" do
    test "creates persona with UUIDv7 ID when not provided" do
      attrs = %{
        name: "Test Persona",
        capabilities: ["movable", "inventory"]
      }

      {:ok, persona} = Persona.create(attrs)

      assert persona.name == "Test Persona"
      assert persona.capabilities == ["movable", "inventory"]
      assert persona.active == true
      assert persona.entity_type == "persona"
      assert String.match?(persona.id, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
    end

    test "validates required fields" do
      invalid_attrs = %{active: true}
      {:error, error_message} = Persona.create(invalid_attrs)

      # ID is auto-generated, so only name validation should fail
      assert String.contains?(error_message, "name is required")
    end

    test "validates name length" do
      attrs = %{name: ""}
      {:error, error_message} = Persona.create(attrs)
      assert String.contains?(error_message, "name is required and must be at least 1 character")
    end
  end

  describe "update/2" do
    test "updates existing persona" do
      {:ok, persona} =
        Persona.create(%{
          name: "Original Name",
          capabilities: ["movable"]
        })

      {:ok, updated} =
        Persona.update(persona, %{
          name: "Updated Name",
          capabilities: ["movable", "craft"]
        })

      assert updated.name == "Updated Name"
      assert updated.capabilities == ["movable", "craft"]
      assert updated.id == persona.id
    end
  end

  describe "get/1" do
    test "gets persona by ID" do
      {:ok, persona} =
        Persona.create(%{
          name: "Test Persona"
        })

      {:ok, retrieved} = Persona.get(persona.id)
      assert retrieved.id == persona.id
      assert retrieved.name == "Test Persona"
    end

    test "returns error for non-existent persona" do
      assert {:error, :not_found} = Persona.get(UUIDv7.generate())
    end
  end

  describe "all/0" do
    test "gets all personas" do
      {:ok, persona1} = Persona.create(%{name: "Persona 1"})
      {:ok, persona2} = Persona.create(%{name: "Persona 2"})

      all_personas = Persona.all()
      assert length(all_personas) >= 2
      assert Enum.any?(all_personas, &(&1.id == persona1.id))
      assert Enum.any?(all_personas, &(&1.id == persona2.id))
    end
  end

  describe "delete/1" do
    test "deletes persona by ID" do
      {:ok, persona} =
        Persona.create(%{
          name: "To Delete"
        })

      :ok = Persona.delete(persona.id)
      assert {:error, :not_found} = Persona.get(persona.id)
    end
  end

  describe "get_beliefs_about/2" do
    test "gets beliefs about another entity" do
      {:ok, persona} =
        Persona.create(%{
          name: "Persona A",
          beliefs_about_others: %{
            "persona_b" => %{
              "observed_action" => "movement",
              "confidence" => 0.8
            }
          }
        })

      beliefs = Persona.get_beliefs_about(persona, "persona_b")
      assert beliefs["observed_action"] == "movement"
      assert beliefs["confidence"] == 0.8
    end

    test "returns empty map for unknown entity" do
      {:ok, persona} = Persona.create(%{name: "Test Persona"})
      beliefs = Persona.get_beliefs_about(persona, "unknown_entity")
      assert beliefs == %{}
    end
  end

  describe "get_planner_state/2" do
    test "returns hidden error for information asymmetry" do
      result = Persona.get_planner_state("target_persona_id", "requesting_persona_id")
      assert result == {:error, :hidden}
    end
  end

  describe "process_observation/2" do
    test "processes observation through PersonaObserver" do
      {:ok, persona} = Persona.create(%{name: "Test Persona"})
      observation = %{entity: "other_entity", action: "movement", confidence: 0.9}

      # This will call PersonaObserver.process_observation
      result = Persona.process_observation(persona, observation)
      assert {:ok, _updated_persona} = result
    end
  end

  describe "process_communication/2" do
    test "processes communication through PersonaObserver" do
      {:ok, persona} = Persona.create(%{name: "Test Persona"})
      communication = %{sender: "other_persona", content: "Hello", type: :cooperative}

      # This will call PersonaObserver.process_communication
      result = Persona.process_communication(persona, communication)
      assert {:ok, _updated_persona} = result
    end
  end

  describe "update_beliefs_from_outcomes/2" do
    test "updates beliefs from execution outcomes" do
      {:ok, persona} = Persona.create(%{name: "Test Persona"})
      outcomes = [%{entity: "other_entity", outcome: "success", confidence: 0.95}]

      # This will call PersonaObserver.update_beliefs_from_outcomes
      {:ok, updated} = Persona.update_beliefs_from_outcomes(persona, outcomes)
      assert updated.id == persona.id
    end
  end
end
