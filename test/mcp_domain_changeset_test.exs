# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.MCPDomainChangesetTest do
  @moduledoc """
  MCP domain changeset tests for aria_planner.
  Tests Ecto changeset validation for planning domains via MCP tools.
  """

  use ExUnit.Case, async: false

  alias AriaCore.PlanningDomain
  alias MCP.AriaForge.ToolHandlers

  setup do
    {:ok, %{
      state: %{
        prompt_uses: 0,
        created_resources: %{},
        subscriptions: []
      }
    }}
  end

  describe "Planning domain changeset validation" do
    test "creates valid planning domain with changeset", %{state: state} do
      domain_attrs = %{
        "id" => UUIDv7.generate(),
        "domain_type" => "blocks_world",
        "name" => "Test Blocks World",
        "description" => "A test domain for block stacking",
        "entities" => [
          %{"id" => "block_a", "name" => "Block A", "type" => "block"},
          %{"id" => "block_b", "name" => "Block B", "type" => "block"}
        ]
      }

      {:ok, result, new_state} = ToolHandlers.handle_tool_call(
        "create_planning_domain",
        domain_attrs,
        state
      )

      assert is_map(result)
      assert Map.has_key?(result, :content)
      assert new_state.prompt_uses == 1
    end

    test "validates domain_type is required", %{state: _state} do
      domain_attrs = %{
        "id" => UUIDv7.generate(),
        "name" => "Invalid Domain"
      }

      changeset = PlanningDomain.changeset(%PlanningDomain{}, domain_attrs)
      refute changeset.valid?
      assert Enum.any?(changeset.errors, fn {field, _} -> field == :domain_type end)
    end

    test "validates domain_type is in allowed list", %{state: _state} do
      domain_attrs = %{
        "id" => UUIDv7.generate(),
        "domain_type" => "invalid_type",
        "name" => "Invalid Domain"
      }

      changeset = PlanningDomain.changeset(%PlanningDomain{}, domain_attrs)
      refute changeset.valid?
      assert Enum.any?(changeset.errors, fn {field, _} -> field == :domain_type end)
    end

    test "validates entities must be list of maps", %{state: _state} do
      domain_attrs = %{
        "id" => UUIDv7.generate(),
        "domain_type" => "tactical",
        "entities" => "not a list"
      }

      changeset = PlanningDomain.changeset(%PlanningDomain{}, domain_attrs)
      refute changeset.valid?
      assert Enum.any?(changeset.errors, fn {field, _} -> field == :entities end)
    end

    test "validates tasks must be list of maps", %{state: _state} do
      domain_attrs = %{
        "id" => UUIDv7.generate(),
        "domain_type" => "navigation",
        "tasks" => ["not", "maps"]
      }

      changeset = PlanningDomain.changeset(%PlanningDomain{}, domain_attrs)
      refute changeset.valid?
      assert Enum.any?(changeset.errors, fn {field, _} -> field == :tasks end)
    end

    test "accepts valid domain with all element types", %{state: _state} do
      domain_attrs = %{
        "id" => UUIDv7.generate(),
        "domain_type" => "tactical",
        "name" => "Full Domain",
        "entities" => [%{"id" => "e1", "name" => "Entity 1"}],
        "tasks" => [%{"id" => "t1", "name" => "Task 1"}],
        "actions" => [%{"id" => "a1", "name" => "Action 1"}],
        "commands" => [%{"id" => "c1", "name" => "Command 1"}],
        "multigoals" => [%{"id" => "m1", "name" => "Multigoal 1"}]
      }

      changeset = PlanningDomain.changeset(%PlanningDomain{}, domain_attrs)
      assert changeset.valid?
    end

    test "creates domain via PlanningDomain.create/1", %{state: _state} do
      domain_attrs = %{
        "domain_type" => "navigation",
        "name" => "Navigation Domain",
        "entities" => [%{"id" => "robot", "name" => "Robot"}]
      }

      {:ok, domain} = PlanningDomain.create(domain_attrs)
      assert domain.domain_type == "navigation"
      assert domain.name == "Navigation Domain"
      assert length(domain.entities) == 1
      assert String.match?(domain.id, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
    end

    test "updates domain via PlanningDomain.update/2", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "blocks_world",
        "name" => "Original Name"
      })

      {:ok, updated_domain} = PlanningDomain.update(domain, %{
        "name" => "Updated Name",
        "description" => "Updated description"
      })

      assert updated_domain.name == "Updated Name"
      assert updated_domain.description == "Updated description"
      assert updated_domain.domain_type == "blocks_world"
    end
  end

  describe "Domain element addition via changeset" do
    test "adds task element to domain", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "blocks_world",
        "name" => "Test Domain"
      })

      {:ok, updated_domain} = PlanningDomain.add_element(domain, :task, %{
        "name" => "Stack Blocks",
        "description" => "Stack three blocks"
      })

      assert length(updated_domain.tasks) == 1
      task = List.first(updated_domain.tasks)
      assert task["name"] == "Stack Blocks"
      assert Map.has_key?(task, "id")
    end

    test "adds action element to domain", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "blocks_world",
        "name" => "Test Domain"
      })

      {:ok, updated_domain} = PlanningDomain.add_element(domain, :action, %{
        "name" => "Pickup",
        "preconditions" => ["hand_empty"]
      })

      assert length(updated_domain.actions) == 1
      action = List.first(updated_domain.actions)
      assert action["name"] == "Pickup"
    end

    test "adds multiple elements sequentially", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "tactical",
        "name" => "Tactical Domain"
      })

      {:ok, domain1} = PlanningDomain.add_element(domain, :task, %{"name" => "Task 1"})
      {:ok, domain2} = PlanningDomain.add_element(domain1, :action, %{"name" => "Action 1"})
      {:ok, domain3} = PlanningDomain.add_element(domain2, :command, %{"name" => "Command 1"})

      assert length(domain3.tasks) == 1
      assert length(domain3.actions) == 1
      assert length(domain3.commands) == 1
    end

    test "validates element type", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "blocks_world",
        "name" => "Test Domain"
      })

      changeset = PlanningDomain.add_element_changeset(domain, :invalid_type, %{"name" => "Test"})
      refute changeset.valid?
      assert Enum.any?(changeset.errors, fn {field, _} -> field == :element_type end)
    end
  end

  describe "Domain state management" do
    test "domain defaults to active state", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "navigation",
        "name" => "Test Domain"
      })

      assert domain.state == :active
    end

    test "domain state can be updated", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "navigation",
        "name" => "Test Domain"
      })

      {:ok, updated_domain} = PlanningDomain.update(domain, %{"state" => :archived})
      assert updated_domain.state == :archived
    end

    test "domain version increments", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "navigation",
        "name" => "Test Domain",
        "version" => 1
      })

      assert domain.version == 1

      {:ok, updated_domain} = PlanningDomain.update(domain, %{"version" => 2})
      assert updated_domain.version == 2
    end

    test "validates version is greater than 0", %{state: _state} do
      domain_attrs = %{
        "id" => UUIDv7.generate(),
        "domain_type" => "navigation",
        "version" => 0
      }

      changeset = PlanningDomain.changeset(%PlanningDomain{}, domain_attrs)
      refute changeset.valid?
      assert Enum.any?(changeset.errors, fn {field, _} -> field == :version end)
    end
  end

  describe "Domain metadata" do
    test "domain accepts metadata map", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "blocks_world",
        "name" => "Test Domain",
        "metadata" => %{
          "author" => "test_user",
          "tags" => ["test", "blocks"],
          "difficulty" => "medium"
        }
      })

      assert domain.metadata["author"] == "test_user"
      assert domain.metadata["tags"] == ["test", "blocks"]
    end

    test "domain metadata can be updated", %{state: _state} do
      {:ok, domain} = PlanningDomain.create(%{
        "domain_type" => "navigation",
        "name" => "Test Domain",
        "metadata" => %{"version" => "1.0"}
      })

      {:ok, updated_domain} = PlanningDomain.update(domain, %{
        "metadata" => %{"version" => "2.0", "updated_by" => "admin"}
      })

      assert updated_domain.metadata["version"] == "2.0"
      assert updated_domain.metadata["updated_by"] == "admin"
    end
  end
end
