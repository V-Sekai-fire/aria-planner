# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Item do
  @moduledoc """
  Plain struct for item entities using RFC 9562 UUIDv7 primary keys.

  Items represent collectible objects in the planning system.
  Uses separate table structure avoiding EAV anti-pattern.

  Stored in ETS (Elixir Term Storage) for in-memory persistence.
  """

  alias AriaPlanner.Storage.EtsStorage

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          active: boolean(),
          entity_type: String.t(),
          item_type: String.t(),
          durability: float(),
          max_durability: float(),
          stack_size: integer(),
          current_stack: integer(),
          properties: map(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :name,
    :inserted_at,
    :updated_at,
    active: true,
    entity_type: "item",
    item_type: "unknown",
    durability: 100.0,
    max_durability: 100.0,
    stack_size: 1,
    current_stack: 1,
    properties: %{}
  ]

  @doc """
  Validates item attributes and returns {:ok, item} or {:error, reason}.
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

    errors =
      if Map.has_key?(attrs, :durability) and attrs.durability < 0 do
        ["durability must be greater than or equal to 0" | errors]
      else
        errors
      end

    errors =
      if Map.has_key?(attrs, :current_stack) and attrs.current_stack <= 0 do
        ["current_stack must be greater than 0" | errors]
      else
        errors
      end

    if Enum.empty?(errors) do
      now = DateTime.utc_now()
      item = %__MODULE__{
        id: Map.get(attrs, :id),
        name: Map.get(attrs, :name),
        active: Map.get(attrs, :active, true),
        entity_type: Map.get(attrs, :entity_type, "item"),
        item_type: Map.get(attrs, :item_type, "unknown"),
        durability: Map.get(attrs, :durability, 100.0),
        max_durability: Map.get(attrs, :max_durability, 100.0),
        stack_size: Map.get(attrs, :stack_size, 1),
        current_stack: Map.get(attrs, :current_stack, 1),
        properties: Map.get(attrs, :properties, %{}),
        inserted_at: Map.get(attrs, :inserted_at, now),
        updated_at: now
      }

      {:ok, item}
    else
      {:error, Enum.join(errors, "; ")}
    end
  end

  defp valid_uuid_v7?(value) when is_binary(value) do
    String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
  end

  defp valid_uuid_v7?(_), do: false

  @doc """
  Creates new item with UUIDv7 ID.
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
      {:ok, item} ->
        case EtsStorage.insert(:items, item.id, item) do
          {:ok, _} -> {:ok, item}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Updates existing item.
  """
  @spec update(item :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def update(item, attrs) do
    # Merge existing item with new attrs
    merged_attrs =
      item
      |> Map.from_struct()
      |> Map.merge(attrs)
      |> Map.put(:id, item.id)
      |> Map.put(:inserted_at, item.inserted_at)

    case validate(merged_attrs) do
      {:ok, updated_item} ->
        case EtsStorage.insert(:items, updated_item.id, updated_item) do
          {:ok, _} -> {:ok, updated_item}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Gets an item by ID.
  """
  @spec get(String.t()) :: {:ok, %__MODULE__{}} | {:error, :not_found}
  def get(id) do
    EtsStorage.get(:items, id)
  end

  @doc """
  Gets all items.
  """
  @spec all() :: [%__MODULE__{}]
  def all do
    EtsStorage.all(:items)
  end

  @doc """
  Deletes an item by ID.
  """
  @spec delete(String.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    EtsStorage.delete(:items, id)
  end

  @doc """
  Converts item to SPO format for multigoal system compatibility.
  """
  @spec to_spo(%__MODULE__{}) :: [{AriaCore.Predicate.t(), AriaCore.Subject.id(), AriaCore.Object.t()}]
  def to_spo(%__MODULE__{} = item) do
    item_map = Map.from_struct(item)

    item_map
    |> Map.drop([:id, :entity_type, :name, :active, :inserted_at, :updated_at])
    |> Enum.map(fn {property, value} ->
      predicate = AriaCore.Predicate.new!(%{name: Atom.to_string(property)})
      subject = AriaCore.Subject.from_entity(item.id)
      object = AriaCore.Object.from_value(value)
      {predicate, subject, object}
    end)
  end
end
