# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ExecutionState do
  @moduledoc """
  Execution state representation for world state manipulation.

  This module provides concrete data structures for executing actions and
  changing the actual world state, separate from the abstract planning facts
  used by the planning algorithms.

  Unlike planning state (AriaPlanner.Planner.State) which uses abstract
  facts, execution state uses concrete data structures that can be directly
  manipulated to change the world.
  """

  @type t :: %__MODULE__{
          world_name: String.t(),
          game_mode: String.t(),
          world_time: integer(),
          day_count: integer(),
          time_of_day: String.t(),
          difficulty: String.t(),
          spawn_monsters: boolean(),
          spawn_animals: boolean(),
          spawn_npcs: boolean(),
          temperature: float(),
          weather_type: String.t(),
          is_raining: boolean(),
          is_thundering: boolean(),
          discovered_locations: MapSet.t(String.t()),
          entities: %{optional(String.t()) => AriaCore.Execution.Entity.t()},
          players: %{optional(String.t()) => AriaCore.Execution.Entity.t()},
          total_entities: integer(),
          total_players: integer(),
          total_mobs_killed: integer(),
          total_entity_deaths: integer()
        }

  @enforce_keys [:world_name, :game_mode]
  defstruct world_name: "Planning World",
            game_mode: "planning",
            world_time: 0,
            day_count: 0,
            time_of_day: "day",
            difficulty: "normal",
            spawn_monsters: true,
            spawn_animals: true,
            spawn_npcs: true,
            temperature: 20.0,
            weather_type: "clear",
            is_raining: false,
            is_thundering: false,
            discovered_locations: MapSet.new(),
            entities: %{},
            players: %{},
            total_entities: 0,
            total_players: 0,
            total_mobs_killed: 0,
            total_entity_deaths: 0

  @doc """
  Create a new execution state with default values.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      world_name: "Planning World",
      game_mode: "planning"
    }
  end

  @doc """
  Create a new execution state with custom values.
  """
  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) do
    struct(__MODULE__, attrs)
  end

  @doc """
  Add an entity to the execution state.
  """
  @spec add_entity(t(), String.t(), AriaCore.Entity.t()) :: t()
  def add_entity(%__MODULE__{} = state, entity_id, entity) do
    updated_entities = Map.put(state.entities, entity_id, entity)
    %{state | entities: updated_entities, total_entities: map_size(updated_entities)}
  end

  @doc """
  Add a player to the execution state (deprecated, use add_entity instead).
  """
  @spec add_player(t(), String.t(), AriaCore.Entity.t()) :: t()
  def add_player(%__MODULE__{} = state, player_id, player) do
    updated_players = Map.put(state.players, player_id, player)
    updated_entities = Map.put(state.entities, player_id, player)
    %{state | 
      players: updated_players, 
      entities: updated_entities, 
      total_players: map_size(updated_players),
      total_entities: map_size(updated_entities)
    }
  end

  @doc """
  Get an entity from the execution state.
  """
  @spec get_entity(t(), String.t()) :: AriaCore.Entity.t() | nil
  def get_entity(%__MODULE__{} = state, entity_id) do
    Map.get(state.entities, entity_id)
  end

  @doc """
  Get a player from the execution state (deprecated, use get_entity instead).
  """
  @spec get_player(t(), String.t()) :: AriaCore.Entity.t() | nil
  def get_player(%__MODULE__{} = state, player_id) do
    get_entity(state, player_id)
  end

  @doc """
  Update an entity in the execution state.
  """
  @spec update_entity(t(), String.t(), (AriaCore.Entity.t() -> AriaCore.Entity.t())) :: t()
  def update_entity(%__MODULE__{} = state, entity_id, update_fn) do
    case Map.get(state.entities, entity_id) do
      nil ->
        state

      entity ->
        updated_entity = update_fn.(entity)
        updated_entities = Map.put(state.entities, entity_id, updated_entity)
        %{state | entities: updated_entities}
    end
  end

  @doc """
  Update a player in the execution state (deprecated, use update_entity instead).
  """
  @spec update_player(t(), String.t(), (AriaCore.Entity.t() -> AriaCore.Entity.t())) :: t()
  def update_player(%__MODULE__{} = state, player_id, update_fn) do
    update_entity(state, player_id, update_fn)
  end

  @doc """
  Check if a location has been discovered.
  """
  @spec location_discovered?(t(), String.t()) :: boolean()
  def location_discovered?(%__MODULE__{} = state, location) do
    MapSet.member?(state.discovered_locations, location)
  end

  @doc """
  Mark a location as discovered.
  """
  @spec discover_location(t(), String.t()) :: t()
  def discover_location(%__MODULE__{} = state, location) do
    %{state | discovered_locations: MapSet.put(state.discovered_locations, location)}
  end

  @doc """
  Check if it's daytime.
  """
  @spec daytime?(t()) :: boolean()
  def daytime?(%__MODULE__{} = state) do
    state.time_of_day == "day"
  end

  @doc """
  Check if monsters can spawn based on time and difficulty.
  """
  @spec can_spawn_monsters?(t()) :: boolean()
  def can_spawn_monsters?(%__MODULE__{} = state) do
    state.spawn_monsters and not daytime?(state) and state.difficulty != "peaceful"
  end

  @doc """
  Advance world time and update derived state.
  """
  @spec advance_time(t(), integer()) :: t()
  def advance_time(%__MODULE__{} = state, minutes) do
    new_world_time = state.world_time + minutes
    # 24 hours in Minecraft time
    new_day_count = div(new_world_time, 24_000)
    new_time_of_day = if rem(new_world_time, 24_000) < 12_000, do: "day", else: "night"

    %{state | world_time: new_world_time, day_count: new_day_count, time_of_day: new_time_of_day}
  end

  @doc """
  Update weather state.
  """
  @spec update_weather(t(), String.t()) :: t()
  def update_weather(%__MODULE__{} = state, weather_type) do
    case weather_type do
      "clear" ->
        %{state | weather_type: "clear", is_raining: false, is_thundering: false}

      "rain" ->
        %{state | weather_type: "rain", is_raining: true, is_thundering: false}

      "thunderstorm" ->
        %{state | weather_type: "thunderstorm", is_raining: true, is_thundering: true}

      _ ->
        state
    end
  end

  @doc """
  Check if it's safe to be outside (not raining, not thundering, and reasonable temperature).
  """
  @spec safe_outside?(t()) :: boolean()
  def safe_outside?(%__MODULE__{} = state) do
    not state.is_raining and not state.is_thundering and state.temperature > 0.0 and state.temperature < 40.0
  end

end
