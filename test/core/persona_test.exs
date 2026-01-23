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

  # Belief system tests removed - belief functionality has been removed
  # to simplify the codebase as it was not used in core planning execution
end
