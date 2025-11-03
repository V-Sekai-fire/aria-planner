# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Character do
  @moduledoc """
  Character representation for 3D assets.

  A Character is a 3D asset representing a potentially animatable figure
  (human, animal, creature, etc.) including metadata related to usage of the model.

  Characters serve as the visual representation in 3D environments that can be
  controlled by entities through avatars.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          asset_path: String.t() | nil,
          animation_states: [String.t()],
          attachment_points: map(),
          physics_properties: map(),
          material_overrides: map(),
          metadata: map(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @enforce_keys [:id, :name]
  defstruct [
    :id,
    :name,
    :asset_path,
    :animation_states,
    :attachment_points,
    :physics_properties,
    :material_overrides,
    :metadata,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new character with basic properties.

  ## Parameters
  - `id`: Unique identifier for the character
  - `name`: Display name for the character
  - `asset_path`: Optional path to 3D asset file

  ## Returns
  New character struct with default properties
  """
  @spec new(String.t(), String.t(), String.t() | nil) :: t()
  def new(id, name, asset_path \\ nil) do
    now = DateTime.utc_now()

    %__MODULE__{
      id: id,
      name: name,
      asset_path: asset_path,
      animation_states: ["idle"],
      attachment_points: %{},
      physics_properties: %{},
      material_overrides: %{},
      metadata: %{},
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Creates a human player character.
  """
  @spec new_human_player(String.t(), String.t()) :: t()
  def new_human_player(id, name) do
    new(id, name)
    |> with_animation_states(["idle", "walking", "running", "mining", "crafting"])
    |> with_attachment_points(%{
      "right_hand" => "tool_attachment",
      "back" => "backpack_attachment",
      "head" => "helmet_attachment"
    })
    |> with_physics_properties(%{
      "mass" => 75.0,
      "height" => 1.8,
      "radius" => 0.3
    })
  end

  @doc """
  Creates an AI agent character (robot/bot).
  """
  @spec new_ai_agent(String.t(), String.t()) :: t()
  def new_ai_agent(id, name) do
    new(id, name)
    |> with_animation_states(["idle", "moving", "scanning", "interacting", "charging"])
    |> with_attachment_points(%{
      "head" => "sensor_attachment",
      "body" => "equipment_attachment",
      "arms" => "tool_attachment"
    })
    |> with_physics_properties(%{
      "mass" => 150.0,
      "height" => 2.1,
      "radius" => 0.4,
      "powered" => true
    })
  end

  @doc """
  Adds animation states to a character.
  """
  @spec with_animation_states(t(), [String.t()]) :: t()
  def with_animation_states(%__MODULE__{} = character, states) do
    %{character | animation_states: states}
    |> touch()
  end

  @doc """
  Adds attachment points to a character.
  """
  @spec with_attachment_points(t(), map()) :: t()
  def with_attachment_points(%__MODULE__{} = character, points) do
    %{character | attachment_points: points}
    |> touch()
  end

  @doc """
  Adds physics properties to a character.
  """
  @spec with_physics_properties(t(), map()) :: t()
  def with_physics_properties(%__MODULE__{} = character, properties) do
    %{character | physics_properties: properties}
    |> touch()
  end

  @doc """
  Adds material override data to a character.
  """
  @spec with_material_overrides(t(), map()) :: t()
  def with_material_overrides(%__MODULE__{} = character, overrides) do
    %{character | material_overrides: overrides}
    |> touch()
  end

  @doc """
  Updates the character's metadata.
  """
  @spec with_metadata(t(), map()) :: t()
  def with_metadata(%__MODULE__{} = character, new_metadata) do
    updated_metadata = Map.merge(character.metadata, new_metadata)

    %{character | metadata: updated_metadata}
    |> touch()
  end

  @doc """
  Updates character's timestamp.
  """
  @spec touch(t()) :: t()
  def touch(%__MODULE__{} = character) do
    %{character | updated_at: DateTime.utc_now()}
  end

  @doc """
  Validates character data.
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{id: id, name: name}) do
    cond do
      id == nil or id == "" ->
        {:error, "Character ID is required"}

      name == nil or name == "" ->
        {:error, "Character name is required"}

      true ->
        :ok
    end
  end
end
