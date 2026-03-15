# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Types.PersonaTest do
  use ExUnit.Case, async: true
  alias AriaCore.Entity.Types.Persona

  @human_caps [:movable, :inventory, :craft, :mine, :build, :interact]
  @ai_caps [:movable, :compute, :optimize, :predict, :learn, :navigate]

  describe "Persona.new/3" do
    test "creates persona with explicit capabilities (ReBAC)" do
      persona = Persona.new("basic1", "BasicBob", capabilities: [:movable])
      assert persona.id == "basic1"
      assert persona.name == "BasicBob"
      assert AriaCore.Entity.position(persona) == {0.0, 0.0, 0.0}
      assert AriaCore.Entity.has_capability?(persona, :movable)
      refute AriaCore.Entity.has_capability?(persona, :inventory)
      refute AriaCore.Entity.has_capability?(persona, :compute)
    end

    test "creates persona with no capabilities when opts empty" do
      persona = Persona.new("minimal", "Minimal", [])
      assert persona.capabilities == []
      assert AriaCore.Entity.capabilities(persona) == []
    end
  end

  describe "Capability management via update_capability" do
    test "add capabilities via Entity.update_capability" do
      persona = Persona.new("flex1", "Flex", capabilities: [:movable])
      refute AriaCore.Entity.has_capability?(persona, :inventory)

      persona = AriaCore.Entity.update_capability(persona, :inventory, [])
      assert AriaCore.Entity.has_capability?(persona, :inventory)
      assert AriaCore.Entity.has_capability?(persona, :movable)
      assert Persona.get_inventory(persona) == []
    end

    test "add AI-style capabilities via update_capability" do
      persona = Persona.new("flex2", "Flex", capabilities: [:movable])
      persona = AriaCore.Entity.update_capability(persona, :compute, %{})
      assert AriaCore.Entity.has_capability?(persona, :compute)
      assert AriaCore.Entity.has_capability?(persona, :optimize) == false
      persona = AriaCore.Entity.update_capability(persona, :optimize, %{})
      assert AriaCore.Entity.has_capability?(persona, :optimize)
    end

    test "remove capability by setting data to nil/false" do
      persona = Persona.new("hybrid", "Hybrid", capabilities: @human_caps ++ @ai_caps)
      assert AriaCore.Entity.has_capability?(persona, :inventory)
      assert AriaCore.Entity.has_capability?(persona, :compute)

      # Remove all human capabilities
      persona =
        Enum.reduce([:inventory, :craft, :mine, :build, :interact], persona, fn cap, acc ->
          AriaCore.Entity.update_capability(acc, cap, nil)
        end)

      refute AriaCore.Entity.has_capability?(persona, :inventory)
      assert AriaCore.Entity.has_capability?(persona, :compute)

      # Remove all AI capabilities
      persona =
        Enum.reduce([:compute, :optimize, :predict, :learn, :navigate], persona, fn cap, acc ->
          AriaCore.Entity.update_capability(acc, cap, nil)
        end)

      refute AriaCore.Entity.has_capability?(persona, :compute)
      assert AriaCore.Entity.has_capability?(persona, :movable)
    end

    test "persona can have mixed capabilities and transform via update_capability" do
      persona = Persona.new("t1", "T", capabilities: [:movable, :inventory])
      assert AriaCore.Entity.has_capability?(persona, :inventory)
      persona = Persona.add_to_inventory(persona, "sword")
      persona = AriaCore.Entity.update_capability(persona, :compute, %{})
      assert AriaCore.Entity.has_capability?(persona, :compute)
      assert Persona.get_inventory(persona) == ["sword"]
      persona = AriaCore.Entity.update_capability(persona, :compute, nil)
      refute AriaCore.Entity.has_capability?(persona, :compute)
      assert Persona.get_inventory(persona) == ["sword"]
    end
  end

  describe "inventory management" do
    test "works for personas with inventory capability" do
      persona = Persona.new("inv1", "Inv", capabilities: [:movable, :inventory])

      with_items =
        persona
        |> Persona.add_to_inventory("sword")
        |> Persona.add_to_inventory("shield")

      assert Persona.get_inventory(with_items) == ["shield", "sword"]
      moved = AriaCore.Entity.move_to(with_items, {10.0, 20.0, 5.0})
      assert AriaCore.Entity.position(moved) == {10.0, 20.0, 5.0}
      assert Persona.get_inventory(moved) == ["shield", "sword"]
    end

    test "ignores inventory operations for personas without inventory capability" do
      persona = Persona.new("ai1", "Robot", capabilities: @ai_caps)
      unchanged = Persona.add_to_inventory(persona, "circuit_board")
      assert unchanged == persona
      assert Persona.get_inventory(unchanged) == []
    end
  end

  describe "Entity behaviour" do
    test "all personas work through Entity behaviour with explicit capabilities" do
      basic = Persona.new("basic666", "BasicBeast", capabilities: [:movable])
      human = Persona.new("human666", "HumanBeast", capabilities: @human_caps)
      ai = Persona.new("ai666", "AIBeast", capabilities: @ai_caps)
      hybrid = Persona.new("hybrid666", "HybridBeast", capabilities: @human_caps ++ @ai_caps)

      personas = [basic, human, ai, hybrid]

      for persona <- personas do
        assert AriaCore.Entity.entity_type(persona) == :persona
        assert AriaCore.Entity.active?(persona)

        moved = AriaCore.Entity.move_to(persona, {42.0, 24.0, 37.0})
        assert AriaCore.Entity.position(moved) == {42.0, 24.0, 37.0}
        assert AriaCore.Entity.has_capability?(moved, :movable)
      end

      assert AriaCore.Entity.has_capability?(basic, :movable)
      refute AriaCore.Entity.has_capability?(basic, :inventory)
      refute AriaCore.Entity.has_capability?(basic, :compute)

      assert AriaCore.Entity.has_capability?(human, :inventory)
      refute AriaCore.Entity.has_capability?(human, :compute)

      assert AriaCore.Entity.has_capability?(ai, :compute)
      refute AriaCore.Entity.has_capability?(ai, :inventory)

      assert AriaCore.Entity.has_capability?(hybrid, :inventory)
      assert AriaCore.Entity.has_capability?(hybrid, :compute)
    end
  end
end
