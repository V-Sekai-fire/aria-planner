# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Location do
  @moduledoc """
  Ecto schema for location entities using RFC 9562 UUIDv7 primary keys.

  Locations represent game world areas, territories, and map zones.
  Uses separate table structure avoiding EAV anti-pattern.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "locations" do
    field(:name, :string)
    field(:active, :boolean, default: true)
    field(:entity_type, :string, default: "location")

    # Location-specific properties
    field(:biome, :string)
    field(:difficulty, :integer, default: 1)
    field(:resources, {:array, :string}, default: [])
    field(:connected_locations, {:array, :string}, default: [])
    field(:explored, :boolean, default: false)
    field(:properties, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(location :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(location \\ %__MODULE__{}, attrs) do
    location
    |> cast(attrs, [
      :id,
      :entity_type,
      :name,
      :active,
      :biome,
      :difficulty,
      :resources,
      :connected_locations,
      :explored,
      :properties
    ])
    |> validate_required([:id, :name])
    |> validate_length(:name, min: 1)
    |> validate_uuid_v7(:id)
    |> put_change(:updated_at, DateTime.utc_now())
  end

  @doc """
  Creates new location with UUIDv7 ID.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    id = generate_uuid_v7()
    attrs = Map.put(attrs, :id, id)

    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates existing location.
  """
  @spec update(location :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(location, attrs) do
    location
    |> changeset(attrs)
    |> apply_action(:update)
  end

  @doc """
  Converts location to SPO format for multigoal system compatibility.
  """
  @spec to_spo(%__MODULE__{}) :: [{AriaCore.Predicate.t(), AriaCore.Subject.t(), AriaCore.Object.t()}]
  def to_spo(%__MODULE__{} = location) do
    location_map = Map.from_struct(location)

    location_map
    |> Map.drop([:id, :entity_type, :name, :active, :__meta__, :inserted_at, :updated_at])
    |> Enum.map(fn {property, value} ->
      predicate = AriaCore.Predicate.new!(%{name: Atom.to_string(property)})
      subject = AriaCore.Subject.from_entity(location)
      object = AriaCore.Object.from_value(value)
      {predicate, subject, object}
    end)
  end

  # RFC 9562 compliant UUIDv7 generation
  @spec generate_uuid_v7() :: String.t()
  def generate_uuid_v7 do
    timestamp_ms = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    rand_bytes = :crypto.strong_rand_bytes(10)
    uuid_128 = <<timestamp_ms::48, 7::4, rand_bytes::binary>>
    <<a::32, b::16, c::16, d::16, e::32>> = uuid_128

    :io_lib.format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~8.16.0b", [a, b, c, d, e])
    |> to_string()
  end

  # UUID v7 validation for Ecto changesets
  @spec validate_uuid_v7(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_uuid_v7(changeset, field) do
    Ecto.Changeset.validate_change(changeset, field, fn _, value ->
      if String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/) do
        []
      else
        [{field, "must be a valid RFC 9562 UUIDv7"}]
      end
    end)
  end
end
