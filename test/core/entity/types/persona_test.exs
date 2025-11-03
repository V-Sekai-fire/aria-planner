# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Types.PersonaTest do
  use ExUnit.Case, async: true
  alias AriaCore.Entity.Types.Persona

  describe "Persona.new/2" do
    test "creates basic persona with minimal capabilities" do
      persona = Persona.new("basic1", "BasicBob")
      assert persona.id == "basic1"
      assert persona.name == "BasicBob"
      assert AriaCore.Entity.position(persona) == {0.0, 0.0, 0.0}
      assert AriaCore.Entity.has_capability?(persona, :movable)
      # No inventory yet
      refute AriaCore.Entity.has_capability?(persona, :inventory)
      # No AI capabilities yet
      refute AriaCore.Entity.has_capability?(persona, :compute)
      assert Persona.identity_type(persona) == :basic
    end
  end

  describe "Dynamic capability management" do
    test "can enable human capabilities dynamically" do
      persona = Persona.new("flex1", "FlexibleEntity")

      # Start basic
      assert Persona.identity_type(persona) == :basic
      refute AriaCore.Entity.has_capability?(persona, :inventory)

      # Enable human capabilities
      human_persona = Persona.enable_human_capabilities(persona)

      assert AriaCore.Entity.has_capability?(human_persona, :inventory)
      assert AriaCore.Entity.has_capability?(human_persona, :craft)
      assert AriaCore.Entity.has_capability?(human_persona, :mine)
      assert AriaCore.Entity.has_capability?(human_persona, :build)
      assert AriaCore.Entity.has_capability?(human_persona, :interact)
      assert Persona.identity_type(human_persona) == :human
      assert Persona.get_inventory(human_persona) == []
    end

    test "can enable AI capabilities dynamically" do
      persona = Persona.new("flex2", "FlexibleEntity")

      # Start basic
      assert Persona.identity_type(persona) == :basic
      refute AriaCore.Entity.has_capability?(persona, :compute)

      # Enable AI capabilities
      ai_persona = Persona.enable_ai_capabilities(persona)

      assert AriaCore.Entity.has_capability?(ai_persona, :compute)
      assert AriaCore.Entity.has_capability?(ai_persona, :optimize)
      assert AriaCore.Entity.has_capability?(ai_persona, :predict)
      assert AriaCore.Entity.has_capability?(ai_persona, :learn)
      assert AriaCore.Entity.has_capability?(ai_persona, :navigate)
      assert Persona.identity_type(ai_persona) == :ai
      assert Map.has_key?(ai_persona.metadata, :intelligence)
      assert Map.has_key?(ai_persona.metadata, :autonomy)
    end

    test "can disable capabilities dynamically" do
      # Start with both human and AI
      persona = Persona.new("flex3", "HybridEntity")

      hybrid =
        persona
        |> Persona.enable_human_capabilities()
        |> Persona.enable_ai_capabilities()

      assert AriaCore.Entity.has_capability?(hybrid, :inventory)
      assert AriaCore.Entity.has_capability?(hybrid, :compute)
      assert Persona.identity_type(hybrid) == :human_and_ai

      # Disable human capabilities
      no_human = Persona.disable_human_capabilities(hybrid)

      refute AriaCore.Entity.has_capability?(no_human, :inventory)
      refute AriaCore.Entity.has_capability?(no_human, :craft)
      assert AriaCore.Entity.has_capability?(no_human, :compute)
      assert Persona.identity_type(no_human) == :ai

      # Disable AI capabilities
      basic_again = Persona.disable_ai_capabilities(no_human)

      refute AriaCore.Entity.has_capability?(basic_again, :compute)
      refute AriaCore.Entity.has_capability?(basic_again, :optimize)
      # Still movable
      assert AriaCore.Entity.has_capability?(basic_again, :movable)
      assert Persona.identity_type(basic_again) == :basic
    end

    test "persona can transform from human to AI and back" do
      persona = Persona.new("transform1", "Transformer")

      # As human
      human = Persona.enable_human_capabilities(persona)
      assert Persona.identity_type(human) == :human
      human_with_gear = Persona.add_to_inventory(human, "magic_sword")

      # Become AI (but keep human capabilities)
      ai_human = Persona.enable_ai_capabilities(human_with_gear)
      assert Persona.identity_type(ai_human) == :human_and_ai
      assert AriaCore.Entity.has_capability?(ai_human, :inventory)
      assert AriaCore.Entity.has_capability?(ai_human, :compute)
      assert Persona.get_inventory(ai_human) == ["magic_sword"]

      # Remove AI, keep human
      just_human_again = Persona.disable_ai_capabilities(ai_human)
      assert Persona.identity_type(just_human_again) == :human
      assert AriaCore.Entity.has_capability?(just_human_again, :inventory)
      assert Persona.get_inventory(just_human_again) == ["magic_sword"]
    end
  end

  describe "inventory management" do
    test "works for personas with inventory capability" do
      persona = Persona.new("inv1", "InventoryTester")
      human_persona = Persona.enable_human_capabilities(persona)

      # Add items
      with_items =
        human_persona
        |> Persona.add_to_inventory("sword")
        |> Persona.add_to_inventory("shield")

      assert Persona.get_inventory(with_items) == ["shield", "sword"]

      # Add items and move (all actions use Entity behaviour)
      moved_with_items = AriaCore.Entity.move_to(with_items, {10.0, 20.0, 5.0})

      assert AriaCore.Entity.position(moved_with_items) == {10.0, 20.0, 5.0}
      assert Persona.get_inventory(moved_with_items) == ["shield", "sword"]
    end

    test "ignores inventory operations for personas without inventory capability" do
      ai_persona = Persona.new("ai1", "Robot") |> Persona.enable_ai_capabilities()

      # Try to add inventory item to AI (should be ignored)
      unchanged = Persona.add_to_inventory(ai_persona, "circuit_board")
      assert unchanged == ai_persona
      assert Persona.get_inventory(unchanged) == []
    end
  end

  describe "Convenience factory functions" do
    test "new_human_player/2 for quick human creation" do
      human = Persona.new_human_player("quick_human", "Quickie")
      assert AriaCore.Entity.has_capability?(human, :inventory)
      assert AriaCore.Entity.has_capability?(human, :craft)
      assert Persona.identity_type(human) == :human

      # Equivalent to manual approach
      manual = Persona.new("quick_human_manual", "Manual") |> Persona.enable_human_capabilities()
      assert AriaCore.Entity.capabilities(manual) == AriaCore.Entity.capabilities(human)

      assert AriaCore.Entity.position(human) == {0.0, 0.0, 0.0}
    end

    test "new_ai_agent/2 for quick AI creation" do
      ai = Persona.new_ai_agent("quick_ai", "BotBot")
      assert AriaCore.Entity.has_capability?(ai, :compute)
      assert AriaCore.Entity.has_capability?(ai, :optimize)
      assert Persona.identity_type(ai) == :ai

      # Equivalent to manual approach
      manual = Persona.new("quick_ai_manual", "ManualBot") |> Persona.enable_ai_capabilities()
      assert AriaCore.Entity.capabilities(manual) == AriaCore.Entity.capabilities(ai)

      # But AI can still interact with inventory if enabled
      ai_with_inventory = Persona.enable_human_capabilities(ai)
      assert AriaCore.Entity.has_capability?(ai_with_inventory, :inventory)
      assert AriaCore.Entity.has_capability?(ai_with_inventory, :compute)
    end
  end

  describe "Entity behaviour" do
    test "all personas work through Entity behaviour interface" do
      basic = Persona.new("basic666", "BasicBeast")
      human = Persona.new("human666", "HumanBeast") |> Persona.enable_human_capabilities()
      ai = Persona.new("ai666", "AIBeast") |> Persona.enable_ai_capabilities()

      hybrid =
        Persona.new("hybrid666", "HybridBeast")
        |> Persona.enable_human_capabilities()
        |> Persona.enable_ai_capabilities()

      personas = [basic, human, ai, hybrid]
      types = [:basic, :human, :ai, :human_and_ai]

      for {persona, expected_type} <- Enum.zip(personas, types) do
        assert AriaCore.Entity.entity_type(persona) == :persona
        assert AriaCore.Entity.active?(persona)
        assert Persona.identity_type(persona) == expected_type

        # All can move
        moved = AriaCore.Entity.move_to(persona, {42.0, 24.0, 37.0})
        assert AriaCore.Entity.position(moved) == {42.0, 24.0, 37.0}

        # Test capabilities
        assert AriaCore.Entity.has_capability?(moved, :movable)

        # Human capabilities check
        has_inventory = AriaCore.Entity.has_capability?(moved, :inventory)

        has_inventory_result =
          case expected_type do
            :human -> true
            :human_and_ai -> true
            _ -> false
          end

        assert has_inventory == has_inventory_result

        # AI capabilities check
        has_compute = AriaCore.Entity.has_capability?(moved, :compute)

        has_compute_result =
          case expected_type do
            :ai -> true
            :human_and_ai -> true
            _ -> false
          end

        assert has_compute == has_compute_result
      end
    end
  end
end
