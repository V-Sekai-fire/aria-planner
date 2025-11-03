# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.ManagementTest do
  use ExUnit.Case, async: true

  alias AriaCore.Entity.Management

  describe "new_registry/0" do
    test "creates an empty entity registry with correct structure" do
      registry = Management.new_registry()

      assert is_map(registry)
      assert Map.has_key?(registry, :entities)
      assert Map.has_key?(registry, :types)
      assert Map.has_key?(registry, :relationships)

      assert registry.entities == %{}
      assert registry.types == %{}
      assert registry.relationships == []
    end
  end

  describe "register_entity_type/2" do
    test "registers a new entity type with atom name" do
      registry = Management.new_registry()
      entity_type = %{name: :player, properties: [:health, :inventory]}

      updated_registry = Management.register_entity_type(registry, entity_type)

      assert updated_registry.types[:player] == entity_type
      assert updated_registry.entities == %{}
      assert updated_registry.relationships == []
    end

    test "registers a new entity type with string name" do
      registry = Management.new_registry()
      entity_type = %{"name" => "tool", "properties" => ["durability", "type"]}

      updated_registry = Management.register_entity_type(registry, entity_type)

      assert updated_registry.types["tool"] == entity_type
    end

    test "overwrites existing entity type with same name" do
      registry = Management.new_registry()
      type1 = %{name: :item, properties: [:weight]}
      type2 = %{name: :item, properties: [:weight, :value]}

      registry = Management.register_entity_type(registry, type1)
      registry = Management.register_entity_type(registry, type2)

      assert registry.types[:item] == type2
    end

    test "preserves other entity types when registering new one" do
      registry = Management.new_registry()
      player_type = %{name: :player, properties: [:health]}
      tool_type = %{name: :tool, properties: [:durability]}

      registry = Management.register_entity_type(registry, player_type)
      registry = Management.register_entity_type(registry, tool_type)

      assert registry.types[:player] == player_type
      assert registry.types[:tool] == tool_type
    end
  end

  describe "normalize_requirement/1" do
    test "normalizes requirement with atom keys" do
      requirement = %{
        type: :player,
        capabilities: [:move, :interact],
        constraints: [health: 100]
      }

      normalized = Management.normalize_requirement(requirement)

      assert normalized.type == :player
      assert normalized.capabilities == [:move, :interact]
      assert normalized.constraints == [health: 100]
    end

    test "normalizes requirement with string keys" do
      requirement = %{
        "type" => "tool",
        "capabilities" => ["craft", "repair"],
        "constraints" => [%{"durability" => 50}]
      }

      normalized = Management.normalize_requirement(requirement)

      assert normalized.type == "tool"
      assert normalized.capabilities == ["craft", "repair"]
      assert normalized.constraints == [%{"durability" => 50}]
    end

    test "provides defaults for missing keys" do
      requirement = %{type: :resource}

      normalized = Management.normalize_requirement(requirement)

      assert normalized.type == :resource
      assert normalized.capabilities == []
      assert normalized.constraints == []
    end

    test "handles empty requirement map" do
      requirement = %{}

      normalized = Management.normalize_requirement(requirement)

      assert normalized.type == nil
      assert normalized.capabilities == []
      assert normalized.constraints == []
    end

    test "preserves existing normalized values" do
      requirement = %{
        type: :building,
        capabilities: [:construct],
        constraints: [size: :large]
      }

      normalized = Management.normalize_requirement(requirement)

      assert normalized == requirement
    end

    test "handles mixed atom and string keys" do
      requirement = %{
        "type" => :vehicle,
        "constraints" => [%{speed: 100}],
        capabilities: ["drive"]
      }

      normalized = Management.normalize_requirement(requirement)

      assert normalized.type == :vehicle
      assert normalized.capabilities == ["drive"]
      assert normalized.constraints == [%{speed: 100}]
    end
  end
end
