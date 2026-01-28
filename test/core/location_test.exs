# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.LocationTest do
  use ExUnit.Case, async: true
  alias AriaCore.Location

  describe "create/1" do
    test "creates location with UUIDv7 ID when not provided" do
      attrs = %{
        name: "Forest Clearing",
        biome: "forest",
        difficulty: 3
      }

      {:ok, location} = Location.create(attrs)

      assert location.name == "Forest Clearing"
      assert location.biome == "forest"
      assert location.difficulty == 3
      assert location.active == true
      assert location.entity_type == "location"
      assert String.match?(location.id, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
    end

    test "validates required fields" do
      invalid_attrs = %{biome: "forest"}
      {:error, error_message} = Location.create(invalid_attrs)

      # ID is auto-generated, so only name validation should fail
      assert String.contains?(error_message, "name is required")
    end

    test "validates UUIDv7 format when ID is provided" do
      invalid_attrs = %{
        id: "invalid-uuid",
        name: "Test Location"
      }

      {:error, error_message} = Location.create(invalid_attrs)
      assert String.contains?(error_message, "id must be a valid RFC 9562 UUIDv7")
    end
  end

  describe "update/2" do
    test "updates existing location" do
      {:ok, location} =
        Location.create(%{
          name: "Original Name",
          biome: "forest"
        })

      {:ok, updated} = Location.update(location, %{name: "Updated Name", difficulty: 5})
      assert updated.name == "Updated Name"
      assert updated.difficulty == 5
      assert updated.id == location.id
    end
  end

  describe "get/1" do
    test "gets location by ID" do
      {:ok, location} =
        Location.create(%{
          name: "Test Location",
          biome: "desert"
        })

      {:ok, retrieved} = Location.get(location.id)
      assert retrieved.id == location.id
      assert retrieved.name == "Test Location"
    end

    test "returns error for non-existent location" do
      assert {:error, :not_found} = Location.get(UUIDv7.generate())
    end
  end

  describe "all/0" do
    test "gets all locations" do
      {:ok, loc1} = Location.create(%{name: "Location 1", biome: "forest"})
      {:ok, loc2} = Location.create(%{name: "Location 2", biome: "desert"})

      all_locations = Location.all()
      assert length(all_locations) >= 2
      assert Enum.any?(all_locations, &(&1.id == loc1.id))
      assert Enum.any?(all_locations, &(&1.id == loc2.id))
    end
  end

  describe "delete/1" do
    test "deletes location by ID" do
      {:ok, location} =
        Location.create(%{
          name: "To Delete",
          biome: "forest"
        })

      :ok = Location.delete(location.id)
      assert {:error, :not_found} = Location.get(location.id)
    end
  end

  describe "to_spo/1" do
    test "converts location to SPO format" do
      {:ok, location} =
        Location.create(%{
          name: "Test Location",
          biome: "forest",
          difficulty: 3,
          resources: ["wood", "stone"]
        })

      spo = Location.to_spo(location)
      assert is_list(spo)
<<<<<<< HEAD
      assert length(spo) > 0
=======
      assert spo != []
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
    end
  end
end
