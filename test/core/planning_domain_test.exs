# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PlanningDomainTest do
  use ExUnit.Case, async: true
  alias AriaCore.PlanningDomain

  describe "create/1" do
    test "creates domain with UUIDv7 ID when not provided" do
      attrs = %{
        domain_type: "blocks_world",
        name: "Test Domain",
        description: "A test planning domain"
      }

      {:ok, domain} = PlanningDomain.create(attrs)

      assert domain.domain_type == "blocks_world"
      assert domain.name == "Test Domain"
      assert domain.description == "A test planning domain"
      assert domain.state == :active
      assert domain.version == 1
      assert String.match?(domain.id, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
    end

    test "validates required fields" do
      invalid_attrs = %{name: "Test"}
      {:error, error_message} = PlanningDomain.create(invalid_attrs)

      # ID is auto-generated, so only domain_type validation should fail
      assert String.contains?(error_message, "domain_type is required")
    end

    test "accepts any ID format when provided" do
      invalid_attrs = %{
        id: "invalid-uuid",
        domain_type: "blocks_world"
      }

      # PlanningDomain doesn't validate UUID format, so it accepts any string
      {:ok, domain} = PlanningDomain.create(invalid_attrs)
      assert domain.id == "invalid-uuid"
    end

    test "validates domain_type inclusion" do
      attrs = %{
        domain_type: "invalid_type"
      }

      {:error, error_message} = PlanningDomain.create(attrs)
      assert String.contains?(error_message, "domain_type must be one of")
    end

    test "validates state inclusion" do
      attrs = %{
        domain_type: "blocks_world",
        state: :invalid_state
      }

      {:error, error_message} = PlanningDomain.create(attrs)
      assert String.contains?(error_message, "state must be one of")
    end

    test "validates version is positive" do
      attrs = %{
        domain_type: "blocks_world",
        version: 0
      }

      {:error, error_message} = PlanningDomain.create(attrs)
      assert String.contains?(error_message, "version must be greater than 0")
    end
  end

  describe "update/2" do
    test "updates existing domain" do
      {:ok, domain} =
        PlanningDomain.create(%{
          domain_type: "blocks_world",
          name: "Original Name"
        })

      {:ok, updated} = PlanningDomain.update(domain, %{name: "Updated Name"})
      assert updated.name == "Updated Name"
      assert updated.id == domain.id
    end
  end

  describe "add_element/3" do
    test "adds task element to domain" do
      {:ok, domain} =
        PlanningDomain.create(%{
          domain_type: "blocks_world",
          tasks: []
        })

      {:ok, updated} = PlanningDomain.add_element(domain, :task, %{name: "move_block"})
      assert length(updated.tasks) == 1
      task = updated.tasks |> List.first()
      # Element is a map with atom or string keys
      assert is_map(task) and (Map.has_key?(task, :name) or Map.has_key?(task, "name"))
    end

    test "adds action element to domain" do
      {:ok, domain} =
        PlanningDomain.create(%{
          domain_type: "blocks_world",
          actions: []
        })

      {:ok, updated} = PlanningDomain.add_element(domain, :action, %{name: "pickup"})
      assert length(updated.actions) == 1
    end

    test "adds command element to domain" do
      {:ok, domain} =
        PlanningDomain.create(%{
          domain_type: "blocks_world",
          commands: []
        })

      {:ok, updated} = PlanningDomain.add_element(domain, :command, %{name: "c_pickup"})
      assert length(updated.commands) == 1
    end

    test "adds multigoal element to domain" do
      {:ok, domain} =
        PlanningDomain.create(%{
          domain_type: "blocks_world",
          multigoals: []
        })

      {:ok, updated} = PlanningDomain.add_element(domain, :multigoal, %{name: "m_move_blocks"})
      assert length(updated.multigoals) == 1
    end

    test "returns error for invalid element type" do
      {:ok, domain} =
        PlanningDomain.create(%{
          domain_type: "blocks_world"
        })

      assert {:error, _} = PlanningDomain.add_element(domain, :invalid_type, %{})
    end
  end

  describe "get/1" do
    test "gets domain by ID" do
      {:ok, domain} =
        PlanningDomain.create(%{
          domain_type: "blocks_world",
          name: "Test Domain"
        })

      {:ok, retrieved} = PlanningDomain.get(domain.id)
      assert retrieved.id == domain.id
      assert retrieved.name == "Test Domain"
    end

    test "returns error for non-existent domain" do
      assert {:error, :not_found} = PlanningDomain.get(UUIDv7.generate())
    end
  end

  describe "all/0" do
    test "gets all domains" do
      {:ok, domain1} = PlanningDomain.create(%{domain_type: "blocks_world", name: "Domain 1"})
      {:ok, domain2} = PlanningDomain.create(%{domain_type: "tactical", name: "Domain 2"})

      all_domains = PlanningDomain.all()
      assert length(all_domains) >= 2
      assert Enum.any?(all_domains, &(&1.id == domain1.id))
      assert Enum.any?(all_domains, &(&1.id == domain2.id))
    end
  end

  describe "delete/1" do
    test "deletes domain by ID" do
      {:ok, domain} =
        PlanningDomain.create(%{
          domain_type: "blocks_world",
          name: "To Delete"
        })

      :ok = PlanningDomain.delete(domain.id)
      assert {:error, :not_found} = PlanningDomain.get(domain.id)
    end
  end
end
