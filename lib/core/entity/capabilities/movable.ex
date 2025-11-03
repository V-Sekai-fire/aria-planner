# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Capabilities.Movable do
  @moduledoc """
  Spatial movement capability for entities in 3D environments.

  This module implements the fundamental capability for entities to change position
  and orientation in space, essential for navigation planning, collision avoidance,
  and spatial reasoning in HTN (Hierarchical Task Network) planning algorithms.

  ## Design Decisions

  - Plain map structure for solver compatibility and serialization flexibility
  - 3D coordinate system supporting full spatial planning in open worlds
  - Velocity and speed components for realistic movement simulation
  - Movement type classification for terrain-specific planning constraints
  - Boolean flags for dynamic movement capability adjustments

  ## Integration with Planning Systems

  The movable capability integrates with planning systems through:
  - Distance calculation for navigation planning
  - Speed constraints on temporal planning
  - Movement type restrictions (flying vs. walking vs. swimming)
  - Spatial collision and terrain awareness
  - Multi-agent coordination in shared spaces

  ## Example Usage

      movable = Movable.new(%{position: {10.0, 0.0, 5.0}, speed: 2.5})
      movable = Movable.move(movable, {15.0, 2.0, 8.0})
      distance = Movable.distance_to(movable, {20.0, 5.0, 10.0})
  """

  @type position :: {float(), float(), float()}
  @type velocity :: {float(), float(), float()}

  @type t :: %{
          position: position(),
          velocity: velocity(),
          speed: float(),
          can_move: boolean(),
          movement_type: String.t()
        }

  @doc """
  Creates a new movable capability with optional initial attributes.

  ## Parameters
  - `attrs`: Optional map of initial capability settings

  ## Returns
  - New movable capability struct with defaults or provided values

  ## Examples

      iex> Movable.new()
      %{position: {0.0, 0.0, 0.0}, velocity: {0.0, 0.0, 0.0},
        speed: 1.0, can_move: true, movement_type: "walking"}

      iex> Movable.new(%{position: {10.0, 0.0, 5.0}, speed: 2.5})
      %{position: {10.0, 0.0, 5.0}, velocity: {0.0, 0.0, 0.0},
        speed: 2.5, can_move: true, movement_type: "walking"}
  """
  @spec new(map()) :: t()
  def new(attrs \\ %{}) do
    %{
      position: Map.get(attrs, :position, {0.0, 0.0, 0.0}),
      velocity: Map.get(attrs, :velocity, {0.0, 0.0, 0.0}),
      speed: Map.get(attrs, :speed, 1.0),
      can_move: Map.get(attrs, :can_move, true),
      movement_type: Map.get(attrs, :movement_type, "walking")
    }
  end

  @doc """
  Updates the entity's position for spatial movement and navigation planning.

  ## Parameters
  - `movable`: Movable capability to update
  - `position`: New 3D position coordinates {x, y, z}

  ## Returns
  - Updated movable capability with new position

  ## Examples

      iex> movable = Movable.new()
      iex> Movable.move(movable, {10.5, 5.2, -3.8})
      %{movable | position: {10.5, 5.2, -3.8}}
  """
  @spec move(t(), position()) :: t()
  def move(movable, {x, y, z} = position)
      when is_float(x) and is_float(y) and is_float(z) do
    %{movable | position: position}
  end

  @doc """
  Sets the entity's velocity vector for directional movement planning.

  ## Parameters
  - `movable`: Movable capability to update
  - `velocity`: New velocity vector {vx, vy, vz}

  ## Returns
  - Updated movable capability with new velocity

  ## Examples

      iex> movable = Movable.new()
      iex> Movable.set_velocity(movable, {1.0, 0.5, -0.2})
      %{movable | velocity: {1.0, 0.5, -0.2}}
  """
  @spec set_velocity(t(), velocity()) :: t()
  def set_velocity(movable, {vx, vy, vz} = velocity)
      when is_float(vx) and is_float(vy) and is_float(vz) do
    %{movable | velocity: velocity}
  end

  @doc """
  Retrieves the current position from the movable capability.

  ## Parameters
  - `movable`: Movable capability to query

  ## Returns
  - Current position as {x, y, z} tuple

  ## Examples

      iex> movable = Movable.new(%{position: {5.0, 10.0, 2.0}})
      iex> Movable.get_position(movable)
      {5.0, 10.0, 2.0}
  """
  @spec get_position(t()) :: position()
  def get_position(%{position: position}) do
    position
  end

  @doc """
  Calculates Euclidean distance to a target position.

  ## Parameters
  - `movable`: Movable capability with current position
  - `target`: Target position {x, y, z}

  ## Returns
  - Euclidean distance as float

  ## Examples

      iex> movable = Movable.new(%{position: {0.0, 0.0, 0.0}})
      iex> Movable.distance_to(movable, {3.0, 4.0, 5.0})
      7.0710678118654755  # sqrt(9 + 16 + 25)
  """
  @spec distance_to(t(), position()) :: float()
  def distance_to(%{position: {x1, y1, z1}}, {x2, y2, z2})
      when is_float(x2) and is_float(y2) and is_float(z2) do
    dx = x2 - x1
    dy = y2 - y1
    dz = z2 - z1
    :math.sqrt(dx * dx + dy * dy + dz * dz)
  end

  @doc """
  Checks if the entity is currently capable of movement.

  ## Parameters
  - `movable`: Movable capability to check

  ## Returns
  - `true` if movement is allowed, `false` otherwise

  ## Examples

      iex> movable = Movable.new(%{can_move: true})
      iex> Movable.can_move?(movable)
      true

      iex> Movable.can_move?(%{movable | can_move: false})
      false
  """
  @spec can_move?(t()) :: boolean()
  def can_move?(%{can_move: can_move}) do
    can_move
  end
end
