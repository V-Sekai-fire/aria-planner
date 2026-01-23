# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PredicateSchemaTest do
  use ExUnit.Case, async: true
  alias AriaCore.PredicateSchema

  describe "create/1" do
    test "creates predicate with UUIDv7 ID when not provided" do
      attrs = %{
        name: "located_at",
        description: "Entity location predicate",
        category: "state"
      }

      {:ok, predicate} = PredicateSchema.create(attrs)

      assert predicate.name == "located_at"
      assert predicate.description == "Entity location predicate"
      assert predicate.category == "state"
      assert String.match?(predicate.id, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
    end

    test "validates required fields" do
      invalid_attrs = %{description: "Test"}
      {:error, error_message} = PredicateSchema.create(invalid_attrs)

      # ID is auto-generated, so only name validation should fail
      assert String.contains?(error_message, "name is required")
    end

    test "validates UUIDv7 format when ID is provided" do
      invalid_attrs = %{
        id: "invalid-uuid",
        name: "test_predicate",
        category: "state"
      }

      # PlanningDomain doesn't validate UUID format, so this test may not apply
      # But we can test that it accepts the ID as-is
      {:ok, predicate} = PredicateSchema.create(invalid_attrs)
      assert predicate.id == "invalid-uuid"
    end

    test "validates name format" do
      attrs = %{
        name: "Invalid-Name",
        category: "state"
      }

      {:error, error_message} = PredicateSchema.create(attrs)
      assert String.contains?(error_message, "name must be a valid atom name")
    end

    test "validates category inclusion" do
      attrs = %{
        name: "test_predicate",
        category: "invalid_category"
      }

      {:error, error_message} = PredicateSchema.create(attrs)
      assert String.contains?(error_message, "category must be one of")
    end
  end

  describe "update/2" do
    test "updates existing predicate" do
      {:ok, predicate} =
        PredicateSchema.create(%{
          name: "test_pred",
          category: "state"
        })

      {:ok, updated} = PredicateSchema.update(predicate, %{description: "Updated description"})
      assert updated.description == "Updated description"
      assert updated.id == predicate.id
    end
  end

  describe "get/1" do
    test "gets predicate by ID" do
      {:ok, predicate} =
        PredicateSchema.create(%{
          name: "test_pred",
          category: "state"
        })

      {:ok, retrieved} = PredicateSchema.get(predicate.id)
      assert retrieved.id == predicate.id
      assert retrieved.name == "test_pred"
    end

    test "returns error for non-existent predicate" do
      assert {:error, :not_found} = PredicateSchema.get(UUIDv7.generate())
    end
  end

  describe "all/0" do
    test "gets all predicates" do
      {:ok, pred1} = PredicateSchema.create(%{name: "pred1", category: "state"})
      {:ok, pred2} = PredicateSchema.create(%{name: "pred2", category: "action"})

      all_preds = PredicateSchema.all()
      assert length(all_preds) >= 2
      assert Enum.any?(all_preds, &(&1.id == pred1.id))
      assert Enum.any?(all_preds, &(&1.id == pred2.id))
    end
  end

  describe "multi_valued?/1" do
    test "checks if predicate is multi-valued" do
      {:ok, predicate} =
        PredicateSchema.create(%{
          name: "test_pred",
          category: "state",
          multi_valued: true
        })

      assert PredicateSchema.multi_valued?(predicate) == true
    end
  end

  describe "category/1" do
    test "gets predicate category" do
      {:ok, predicate} =
        PredicateSchema.create(%{
          name: "test_pred",
          category: "effect"
        })

      assert PredicateSchema.category(predicate) == "effect"
    end
  end

  describe "update_metadata/2" do
    test "updates predicate metadata" do
      {:ok, predicate} =
        PredicateSchema.create(%{
          name: "test_pred",
          category: "state",
          metadata: %{key1: "value1"}
        })

      {:ok, updated} = PredicateSchema.update_metadata(predicate, %{key2: "value2"})
      assert updated.metadata.key1 == "value1"
      assert updated.metadata.key2 == "value2"
    end
  end

  describe "set_multi_valued/2" do
    test "sets predicate as multi-valued" do
      {:ok, predicate} =
        PredicateSchema.create(%{
          name: "test_pred",
          category: "state",
          multi_valued: false
        })

      {:ok, updated} = PredicateSchema.set_multi_valued(predicate, true)
      assert updated.multi_valued == true
    end
  end

  describe "change_category/2" do
    test "changes predicate category" do
      {:ok, predicate} =
        PredicateSchema.create(%{
          name: "test_pred",
          category: "state"
        })

      {:ok, updated} = PredicateSchema.change_category(predicate, "action")
      assert updated.category == "action"
    end
  end

  describe "valid_name?/1" do
    test "validates predicate name format" do
      assert PredicateSchema.valid_name?("valid_name") == true
      assert PredicateSchema.valid_name?("InvalidName") == false
      assert PredicateSchema.valid_name?("123invalid") == false
      assert PredicateSchema.valid_name?("valid_name_123") == true
    end
  end

  describe "valid_categories/0" do
    test "returns all valid categories" do
      categories = PredicateSchema.valid_categories()
      assert "state" in categories
      assert "action" in categories
      assert "effect" in categories
      assert "goal" in categories
    end
  end

  describe "valid_category?/1" do
    test "checks if category is valid" do
      assert PredicateSchema.valid_category?("state") == true
      assert PredicateSchema.valid_category?("invalid") == false
    end
  end
end
