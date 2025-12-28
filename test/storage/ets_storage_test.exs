# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Storage.EtsStorageTest do
  use ExUnit.Case, async: true
  alias AriaPlanner.Storage.EtsStorage

  setup do
    # Clear all tables before each test
    EtsStorage.clear_all()
    :ok
  end

  describe "init/0" do
    test "initializes all ETS tables" do
      :ok = EtsStorage.init()

      # Verify tables exist
      assert :ets.whereis(:aria_planner_plans) != :undefined
      assert :ets.whereis(:aria_planner_personas) != :undefined
      assert :ets.whereis(:aria_planner_facts_allocentric) != :undefined
      assert :ets.whereis(:aria_planner_predicates) != :undefined
      assert :ets.whereis(:aria_planner_planning_domains) != :undefined
      assert :ets.whereis(:aria_planner_locations) != :undefined
      assert :ets.whereis(:aria_planner_items) != :undefined
    end
  end

  describe "insert/3" do
    test "inserts data into plans table" do
      id = UUIDv7.generate()
      data = %{id: id, name: "Test Plan"}

      {:ok, inserted} = EtsStorage.insert(:plans, id, data)
      assert inserted.id == id
      assert inserted.name == "Test Plan"
    end

    test "inserts data into personas table" do
      id = UUIDv7.generate()
      data = %{id: id, name: "Test Persona"}

      {:ok, inserted} = EtsStorage.insert(:personas, id, data)
      assert inserted.id == id
    end

    test "returns error for unknown table" do
      assert {:error, :unknown_table} = EtsStorage.insert(:unknown_table, "id", %{})
    end
  end

  describe "get/2" do
    test "gets data from plans table" do
      id = UUIDv7.generate()
      data = %{id: id, name: "Test Plan"}

      EtsStorage.insert(:plans, id, data)
      {:ok, retrieved} = EtsStorage.get(:plans, id)
      assert retrieved.id == id
      assert retrieved.name == "Test Plan"
    end

    test "returns error for non-existent data" do
      assert {:error, :not_found} = EtsStorage.get(:plans, UUIDv7.generate())
    end

    test "returns error for unknown table" do
      assert {:error, :unknown_table} = EtsStorage.get(:unknown_table, "id")
    end
  end

  describe "all/1" do
    test "gets all data from table" do
      id1 = UUIDv7.generate()
      id2 = UUIDv7.generate()

      EtsStorage.insert(:plans, id1, %{id: id1, name: "Plan 1"})
      EtsStorage.insert(:plans, id2, %{id: id2, name: "Plan 2"})

      all_plans = EtsStorage.all(:plans)
      assert length(all_plans) >= 2
      assert Enum.any?(all_plans, &(&1.id == id1))
      assert Enum.any?(all_plans, &(&1.id == id2))
    end

    test "returns empty list for empty table" do
      assert EtsStorage.all(:plans) == []
    end
  end

  describe "delete/2" do
    test "deletes data from table" do
      id = UUIDv7.generate()
      data = %{id: id, name: "To Delete"}

      EtsStorage.insert(:plans, id, data)
      :ok = EtsStorage.delete(:plans, id)
      assert {:error, :not_found} = EtsStorage.get(:plans, id)
    end

    test "returns error for unknown table" do
      assert {:error, :unknown_table} = EtsStorage.delete(:unknown_table, "id")
    end
  end

  describe "clear/1" do
    test "clears all data from table" do
      id1 = UUIDv7.generate()
      id2 = UUIDv7.generate()

      EtsStorage.insert(:plans, id1, %{id: id1})
      EtsStorage.insert(:plans, id2, %{id: id2})

      :ok = EtsStorage.clear(:plans)
      assert EtsStorage.all(:plans) == []
    end
  end

  describe "clear_all/0" do
    test "clears all tables" do
      # Insert data into multiple tables
      EtsStorage.insert(:plans, UUIDv7.generate(), %{id: UUIDv7.generate()})
      EtsStorage.insert(:personas, UUIDv7.generate(), %{id: UUIDv7.generate()})

      :ok = EtsStorage.clear_all()

      assert EtsStorage.all(:plans) == []
      assert EtsStorage.all(:personas) == []
    end
  end
end
