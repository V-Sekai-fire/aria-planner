# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Item do
  @moduledoc """
  Ecto schema for item entities using RFC 9562 UUIDv7 primary keys.

  Items represent collectible objects in the planning system.
  Uses separate table structure avoiding EAV anti-pattern.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "items" do
    field(:name, :string)
    field(:active, :boolean, default: true)
    field(:entity_type, :string, default: "item")

    # Item-specific properties
    field(:item_type, :string, default: "unknown")
    field(:durability, :float, default: 100.0)
    field(:max_durability, :float, default: 100.0)
    field(:stack_size, :integer, default: 1)
    field(:current_stack, :integer, default: 1)
    field(:properties, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(item :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(item \\ %__MODULE__{}, attrs) do
    item
    |> cast(attrs, [
      :id,
      :entity_type,
      :name,
      :active,
      :item_type,
      :durability,
      :max_durability,
      :stack_size,
      :current_stack,
      :properties
    ])
    |> validate_required([:id, :name])
    |> validate_length(:name, min: 1)
    |> validate_uuid_v7(:id)
    |> validate_number(:durability, greater_than_or_equal_to: 0)
    |> validate_number(:current_stack, greater_than: 0)
    |> put_change(:updated_at, DateTime.utc_now())
  end

  @doc """
  Creates new item with UUIDv7 ID.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    id = UUIDv7.generate()
    attrs = Map.put(attrs, :id, id)

    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates existing item.
  """
  @spec update(item :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(item, attrs) do
    item
    |> changeset(attrs)
    |> apply_action(:update)
  end

  @doc """
  Converts item to SPO format for multigoal system compatibility.
  """
  @spec to_spo(%__MODULE__{}) :: [{AriaCore.Predicate.t(), AriaCore.Subject.id(), AriaCore.Object.t()}]
  def to_spo(%__MODULE__{} = item) do
    item_map = Map.from_struct(item)

    item_map
    |> Map.drop([:id, :entity_type, :name, :active, :__meta__, :inserted_at, :updated_at])
    |> Enum.map(fn {property, value} ->
      predicate = AriaCore.Predicate.new!(%{name: Atom.to_string(property)})
      subject = AriaCore.Subject.from_entity(item.id)
      object = AriaCore.Object.from_value(value)
      {predicate, subject, object}
    end)
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
