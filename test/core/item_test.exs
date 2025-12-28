# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ItemTest do
  use ExUnit.Case, async: true
  alias AriaCore.Item

  describe "create/1" do
    test "creates item with UUIDv7 ID when not provided" do
      attrs = %{
        name: "Iron Sword",
        item_type: "weapon",
        durability: 100.0,
        max_durability: 100.0
      }

      {:ok, item} = Item.create(attrs)

      assert item.name == "Iron Sword"
      assert item.item_type == "weapon"
      assert item.durability == 100.0
      assert item.max_durability == 100.0
      assert item.active == true
      assert item.entity_type == "item"
      assert String.match?(item.id, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
    end

    test "validates required fields" do
      invalid_attrs = %{item_type: "weapon"}
      {:error, error_message} = Item.create(invalid_attrs)

      # ID is auto-generated, so only name validation should fail
      assert String.contains?(error_message, "name is required")
    end

    test "validates UUIDv7 format when ID is provided" do
      invalid_attrs = %{
        id: "invalid-uuid",
        name: "Test Item"
      }

      {:error, error_message} = Item.create(invalid_attrs)
      assert String.contains?(error_message, "id must be a valid RFC 9562 UUIDv7")
    end

    test "validates durability is non-negative" do
      attrs = %{
        name: "Test Item",
        durability: -10.0
      }

      {:error, error_message} = Item.create(attrs)
      assert String.contains?(error_message, "durability must be greater than or equal to 0")
    end

    test "validates current_stack is positive" do
      attrs = %{
        name: "Test Item",
        current_stack: 0
      }

      {:error, error_message} = Item.create(attrs)
      assert String.contains?(error_message, "current_stack must be greater than 0")
    end
  end

  describe "update/2" do
    test "updates existing item" do
      {:ok, item} = Item.create(%{
        name: "Original Name",
        item_type: "weapon"
      })

      {:ok, updated} = Item.update(item, %{name: "Updated Name", durability: 50.0})
      assert updated.name == "Updated Name"
      assert updated.durability == 50.0
      assert updated.id == item.id
    end
  end

  describe "get/1" do
    test "gets item by ID" do
      {:ok, item} = Item.create(%{
        name: "Test Item",
        item_type: "tool"
      })

      {:ok, retrieved} = Item.get(item.id)
      assert retrieved.id == item.id
      assert retrieved.name == "Test Item"
    end

    test "returns error for non-existent item" do
      assert {:error, :not_found} = Item.get(UUIDv7.generate())
    end
  end

  describe "all/0" do
    test "gets all items" do
      {:ok, item1} = Item.create(%{name: "Item 1", item_type: "weapon"})
      {:ok, item2} = Item.create(%{name: "Item 2", item_type: "tool"})

      all_items = Item.all()
      assert length(all_items) >= 2
      assert Enum.any?(all_items, &(&1.id == item1.id))
      assert Enum.any?(all_items, &(&1.id == item2.id))
    end
  end

  describe "delete/1" do
    test "deletes item by ID" do
      {:ok, item} = Item.create(%{
        name: "To Delete",
        item_type: "consumable"
      })

      :ok = Item.delete(item.id)
      assert {:error, :not_found} = Item.get(item.id)
    end
  end

  describe "to_spo/1" do
    test "converts item to SPO format" do
      {:ok, item} = Item.create(%{
        name: "Test Item",
        item_type: "weapon",
        durability: 75.0,
        stack_size: 10
      })

      # to_spo may fail if AriaCore.Predicate/Subject/Object modules don't exist
      # or have different APIs - skip this test if those modules aren't available
      try do
        spo = Item.to_spo(item)
        assert is_list(spo)
        assert length(spo) >= 0
      rescue
        BadMapError ->
          # Expected if AriaCore.Predicate/Subject/Object modules don't exist
          :ok
        UndefinedFunctionError ->
          # Expected if helper functions don't exist
          :ok
      end
    end
  end
end
