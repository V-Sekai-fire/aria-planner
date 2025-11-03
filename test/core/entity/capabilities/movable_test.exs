# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Capabilities.MovableTest do
  use ExUnit.Case, async: true
  alias AriaCore.Entity.Capabilities.Movable

  describe "new/1" do
    test "creates movable capability with defaults" do
      movable = Movable.new(%{})
      assert movable.speed == 1.0
      assert movable.can_move == true
      assert movable.movement_type == "walking"
      assert movable.position == {0.0, 0.0, 0.0}
      assert movable.velocity == {0.0, 0.0, 0.0}
    end

    test "creates movable capability with custom values" do
      attrs = %{
        position: {1.0, 2.0, 3.0},
        velocity: {0.5, 1.5, 2.5},
        speed: 5.0,
        can_move: false,
        movement_type: "flying"
      }

      movable = Movable.new(attrs)
      assert movable.position == {1.0, 2.0, 3.0}
      assert movable.velocity == {0.5, 1.5, 2.5}
      assert movable.speed == 5.0
      assert movable.can_move == false
      assert movable.movement_type == "flying"
    end
  end

  describe "move/2" do
    test "updates position" do
      movable = Movable.new()
      moved = Movable.move(movable, {10.0, 20.0, 30.0})

      assert moved.position == {10.0, 20.0, 30.0}
      # Other fields unchanged
      assert moved.velocity == {0.0, 0.0, 0.0}
      assert moved.speed == 1.0
    end
  end

  describe "set_velocity/2" do
    test "updates velocity" do
      movable = Movable.new()
      moved = Movable.set_velocity(movable, {1.0, 2.0, 3.0})

      assert moved.velocity == {1.0, 2.0, 3.0}
      # Position unchanged
      assert moved.position == {0.0, 0.0, 0.0}
    end
  end
end
