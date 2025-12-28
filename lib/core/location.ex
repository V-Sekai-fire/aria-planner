# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Location do
  @moduledoc """
  Plain struct for location entities using RFC 9562 UUIDv7 primary keys.

  Locations represent game world areas, territories, and map zones.
  Uses separate table structure avoiding EAV anti-pattern.

  Stored in ETS (Elixir Term Storage) for in-memory persistence.
  """

  alias AriaPlanner.Storage.EtsStorage

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          active: boolean(),
          entity_type: String.t(),
          biome: String.t() | nil,
          difficulty: integer(),
          resources: [String.t()],
          connected_locations: [String.t()],
          explored: boolean(),
          properties: map(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :name,
    :biome,
    :inserted_at,
    :updated_at,
    active: true,
    entity_type: "location",
    difficulty: 1,
    resources: [],
    connected_locations: [],
    explored: false,
    properties: %{}
  ]

  @doc """
  Validates location attributes and returns {:ok, location} or {:error, reason}.
  """
  @spec validate(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def validate(attrs) do
    errors = []

    errors =
      if Map.has_key?(attrs, :id) and not valid_uuid_v7?(attrs.id) do
        ["id must be a valid RFC 9562 UUIDv7" | errors]
      else
        errors
      end

    errors =
      if not Map.has_key?(attrs, :id) or attrs.id == nil do
        ["id is required" | errors]
      else
        errors
      end

    errors =
      if not Map.has_key?(attrs, :name) or attrs.name == nil or String.length(attrs.name) < 1 do
        ["name is required and must be at least 1 character" | errors]
      else
        errors
      end

    if Enum.empty?(errors) do
      now = DateTime.utc_now()
      location = %__MODULE__{
        id: Map.get(attrs, :id),
        name: Map.get(attrs, :name),
        active: Map.get(attrs, :active, true),
        entity_type: Map.get(attrs, :entity_type, "location"),
        biome: Map.get(attrs, :biome),
        difficulty: Map.get(attrs, :difficulty, 1),
        resources: Map.get(attrs, :resources, []),
        connected_locations: Map.get(attrs, :connected_locations, []),
        explored: Map.get(attrs, :explored, false),
        properties: Map.get(attrs, :properties, %{}),
        inserted_at: Map.get(attrs, :inserted_at, now),
        updated_at: now
      }

      {:ok, location}
    else
      {:error, Enum.join(errors, "; ")}
    end
  end

  defp valid_uuid_v7?(value) when is_binary(value) do
    String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
  end

  defp valid_uuid_v7?(_), do: false

  @doc """
  Creates new location with UUIDv7 ID.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def create(attrs) do
    attrs =
      if Map.has_key?(attrs, :id) or Map.has_key?(attrs, "id") do
        attrs
      else
        id = UUIDv7.generate()
        Map.put(attrs, :id, id)
      end

    case validate(attrs) do
      {:ok, location} ->
        case EtsStorage.insert(:locations, location.id, location) do
          {:ok, _} -> {:ok, location}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Updates existing location.
  """
  @spec update(location :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def update(location, attrs) do
    # Merge existing location with new attrs
    merged_attrs =
      location
      |> Map.from_struct()
      |> Map.merge(attrs)
      |> Map.put(:id, location.id)
      |> Map.put(:inserted_at, location.inserted_at)

    case validate(merged_attrs) do
      {:ok, updated_location} ->
        case EtsStorage.insert(:locations, updated_location.id, updated_location) do
          {:ok, _} -> {:ok, updated_location}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Gets a location by ID.
  """
  @spec get(String.t()) :: {:ok, %__MODULE__{}} | {:error, :not_found}
  def get(id) do
    EtsStorage.get(:locations, id)
  end

  @doc """
  Gets all locations.
  """
  @spec all() :: [%__MODULE__{}]
  def all do
    EtsStorage.all(:locations)
  end

  @doc """
  Deletes a location by ID.
  """
  @spec delete(String.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    EtsStorage.delete(:locations, id)
  end

  @doc """
  Converts location to SPO format for multigoal system compatibility.
  """
  @spec to_spo(%__MODULE__{}) :: [{AriaCore.Predicate.t(), AriaCore.Subject.t(), AriaCore.Object.t()}]
  def to_spo(%__MODULE__{} = location) do
    location_map = Map.from_struct(location)

    location_map
    |> Map.drop([:id, :entity_type, :name, :active, :inserted_at, :updated_at])
    |> Enum.map(fn {property, value} ->
      predicate = AriaCore.Predicate.new!(%{name: Atom.to_string(property)})
      subject = AriaCore.Subject.from_entity(location)
      object = AriaCore.Object.from_value(value)
      {predicate, subject, object}
    end)
  end
end
