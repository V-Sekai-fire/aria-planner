# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ExecutionStateTest do
  use ExUnit.Case, async: true

  alias AriaCore.Execution.Entity
  alias AriaCore.ExecutionState

  describe "new/0" do
    test "creates execution state with default values" do
      state = ExecutionState.new()

      assert state.world_name == "Planning World"
      assert state.game_mode == "planning"
      assert state.world_time == 0
      assert state.day_count == 0
      assert state.time_of_day == "day"
      assert state.weather_type == "clear"
      assert state.is_raining == false
      assert state.is_thundering == false
      assert state.difficulty == "normal"
      assert state.temperature == 20.0
      assert state.discovered_locations == MapSet.new()
      assert state.players == %{}
      assert state.total_players == 0
    end
  end

  describe "new/1" do
    test "creates execution state with custom values" do
      attrs = %{
        world_name: "Custom World",
        game_mode: "creative",
        temperature: 25.0,
        difficulty: "hard"
      }

      state = ExecutionState.new(attrs)

      assert state.world_name == "Custom World"
      assert state.game_mode == "creative"
      assert state.temperature == 25.0
      assert state.difficulty == "hard"
    end
  end

  describe "add_player/3" do
    test "adds player to execution state" do
      state = ExecutionState.new()
      player = Entity.new(1, "TestPlayer", :player)

      updated = ExecutionState.add_player(state, "player_1", player)

      assert updated.players["player_1"] == player
      assert updated.total_players == 1
    end

    test "updates total_players count" do
      state = ExecutionState.new()
      player1 = Entity.new(1, "Player1", :player)
      player2 = Entity.new(2, "Player2", :player)

      state = ExecutionState.add_player(state, "player_1", player1)
      state = ExecutionState.add_player(state, "player_2", player2)

      assert state.total_players == 2
    end
  end

  describe "get_player/2" do
    test "returns player when exists" do
      state = ExecutionState.new()
      player = Entity.new(1, "TestPlayer", :player)
      state = ExecutionState.add_player(state, "player_1", player)

      assert ExecutionState.get_player(state, "player_1") == player
    end

    test "returns nil when player doesn't exist" do
      state = ExecutionState.new()

      assert ExecutionState.get_player(state, "nonexistent") == nil
    end
  end

  describe "update_player/3" do
    test "updates existing player" do
      state = ExecutionState.new()
      player = Entity.new(1, "TestPlayer", :player)
      state = ExecutionState.add_player(state, "player_1", player)

      updated =
        ExecutionState.update_player(state, "player_1", fn p ->
          # Return unchanged since entity has no modifiable attributes
          p
        end)

      updated_player = ExecutionState.get_player(updated, "player_1")
      # Should be unchanged
      assert updated_player == player
    end

    test "returns unchanged state when player doesn't exist" do
      state = ExecutionState.new()

      updated =
        ExecutionState.update_player(state, "nonexistent", fn p ->
          # Return unchanged
          p
        end)

      assert updated == state
    end
  end

  describe "location_discovered?/2" do
    test "returns true for discovered location" do
      state = ExecutionState.new()
      state = ExecutionState.discover_location(state, "forest")

      assert ExecutionState.location_discovered?(state, "forest")
    end

    test "returns false for undiscovered location" do
      state = ExecutionState.new()

      refute ExecutionState.location_discovered?(state, "forest")
    end
  end

  describe "discover_location/2" do
    test "adds location to discovered locations" do
      state = ExecutionState.new()
      updated = ExecutionState.discover_location(state, "forest")

      assert MapSet.member?(updated.discovered_locations, "forest")
    end

    test "handles duplicate discoveries gracefully" do
      state = ExecutionState.new()
      state = ExecutionState.discover_location(state, "forest")
      updated = ExecutionState.discover_location(state, "forest")

      assert MapSet.size(updated.discovered_locations) == 1
    end
  end

  describe "safe_outside?/1" do
    test "returns true for clear weather and reasonable temperature" do
      state = ExecutionState.new()

      assert ExecutionState.safe_outside?(state)
    end

    test "returns false when raining" do
      state = ExecutionState.new() |> ExecutionState.update_weather("rain")

      refute ExecutionState.safe_outside?(state)
    end

    test "returns false when thundering" do
      state = ExecutionState.new() |> ExecutionState.update_weather("thunderstorm")

      refute ExecutionState.safe_outside?(state)
    end

    test "returns false when too cold" do
      state = ExecutionState.new() |> Map.put(:temperature, 0.0)

      refute ExecutionState.safe_outside?(state)
    end

    test "returns false when too hot" do
      state = ExecutionState.new() |> Map.put(:temperature, 40.0)

      refute ExecutionState.safe_outside?(state)
    end
  end

  describe "daytime?/1" do
    test "returns true during day" do
      state = ExecutionState.new()

      assert ExecutionState.daytime?(state)
    end

    test "returns false during night" do
      state = ExecutionState.new() |> Map.put(:time_of_day, "night")

      refute ExecutionState.daytime?(state)
    end
  end

  describe "can_spawn_monsters?/1" do
    test "returns true for night time with monsters enabled and non-peaceful difficulty" do
      state = ExecutionState.new() |> Map.put(:time_of_day, "night")

      assert ExecutionState.can_spawn_monsters?(state)
    end

    test "returns false during day" do
      state = ExecutionState.new()

      refute ExecutionState.can_spawn_monsters?(state)
    end

    test "returns false when monsters disabled" do
      state = ExecutionState.new() |> Map.put(:spawn_monsters, false) |> Map.put(:time_of_day, "night")

      refute ExecutionState.can_spawn_monsters?(state)
    end

    test "returns false for peaceful difficulty" do
      state = ExecutionState.new() |> Map.put(:difficulty, "peaceful") |> Map.put(:time_of_day, "night")

      refute ExecutionState.can_spawn_monsters?(state)
    end
  end

  describe "advance_time/2" do
    test "advances world time and updates day count" do
      state = ExecutionState.new()
      # Half a day
      updated = ExecutionState.advance_time(state, 12_000)

      assert updated.world_time == 12_000
      assert updated.day_count == 0
      assert updated.time_of_day == "night"
    end

    test "advances to next day" do
      state = ExecutionState.new()
      # Full day
      updated = ExecutionState.advance_time(state, 24_000)

      assert updated.world_time == 24_000
      assert updated.day_count == 1
      assert updated.time_of_day == "day"
    end
  end

  describe "update_weather/2" do
    test "updates to clear weather" do
      state = ExecutionState.new() |> ExecutionState.update_weather("rain")
      updated = ExecutionState.update_weather(state, "clear")

      assert updated.weather_type == "clear"
      assert updated.is_raining == false
      assert updated.is_thundering == false
    end

    test "updates to rain" do
      state = ExecutionState.new()
      updated = ExecutionState.update_weather(state, "rain")

      assert updated.weather_type == "rain"
      assert updated.is_raining == true
      assert updated.is_thundering == false
    end

    test "updates to thunderstorm" do
      state = ExecutionState.new()
      updated = ExecutionState.update_weather(state, "thunderstorm")

      assert updated.weather_type == "thunderstorm"
      assert updated.is_raining == true
      assert updated.is_thundering == true
    end

    test "ignores unknown weather types" do
      state = ExecutionState.new()
      updated = ExecutionState.update_weather(state, "unknown")

      assert updated == state
    end
  end
end
