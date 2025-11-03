# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PredicateSchema do
  @moduledoc """
  Ecto schema for predicates table storing planning domain predicates with metadata and validation rules.

  Predicates define relationships and properties in the planning domain. This schema follows
  ETNF (Essential Tuple Normal Form) with single-attribute primary keys and proper validation
  constraints for predicate names and categories.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "predicates" do
    field(:name, :string)
    field(:description, :string)
    field(:category, :string, default: "state")
    field(:multi_valued, :boolean, default: false)
    field(:metadata, :map, default: %{})

    timestamps()
  end

  @spec changeset(predicate :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(predicate \\ %__MODULE__{}, attrs) do
    predicate
    |> cast(attrs, [
      :id,
      :name,
      :description,
      :category,
      :multi_valued,
      :metadata
    ])
    |> validate_required([:id, :name])
    |> validate_length(:name, min: 1)
    |> validate_format(:name, ~r/^[a-z][a-zA-Z0-9_]*$/, message: "must be a valid atom name (starting with lowercase letter)")
    |> validate_inclusion(:category, ["state", "action", "effect", "goal"])
    |> put_change(:updated_at, DateTime.utc_now())
  end

  @doc """
  Creates new predicate with UUIDv7 ID.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    attrs =
      if Map.has_key?(attrs, :id) do
        attrs
      else
        id = UUIDv7.generate()
        Map.put(attrs, :id, id)
      end

    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates existing predicate.
  """
  @spec update(predicate :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(predicate, attrs) do
    predicate
    |> changeset(attrs)
    |> apply_action(:update)
  end

  @doc """
  Checks if predicate is multi-valued.
  """
  @spec multi_valued?(predicate :: %__MODULE__{}) :: boolean()
  def multi_valued?(%__MODULE__{multi_valued: multi_valued}) do
    multi_valued
  end

  @doc """
  Gets predicate category.
  """
  @spec category(predicate :: %__MODULE__{}) :: String.t()
  def category(%__MODULE__{category: category}) do
    category
  end

  @doc """
  Updates predicate metadata.
  """
  @spec update_metadata(predicate :: %__MODULE__{}, metadata :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update_metadata(predicate, new_metadata) do
    merged_metadata = Map.merge(predicate.metadata, new_metadata)
    update(predicate, %{metadata: merged_metadata})
  end

  @doc """
  Sets predicate as multi-valued.
  """
  @spec set_multi_valued(predicate :: %__MODULE__{}, multi_valued :: boolean()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def set_multi_valued(predicate, multi_valued) do
    update(predicate, %{multi_valued: multi_valued})
  end

  @doc """
  Changes predicate category.
  """
  @spec change_category(predicate :: %__MODULE__{}, category :: String.t()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def change_category(predicate, category) do
    update(predicate, %{category: category})
  end

  @doc """
  Validates predicate name format.
  """
  @spec valid_name?(name :: String.t()) :: boolean()
  def valid_name?(name) when is_binary(name) do
    String.match?(name, ~r/^[a-z][a-zA-Z0-9_]*$/)
  end

  def valid_name?(_), do: false

  @doc """
  Gets all valid categories.
  """
  @spec valid_categories() :: [String.t()]
  def valid_categories do
    ["state", "action", "effect", "goal"]
  end

  @doc """
  Checks if category is valid.
  """
  @spec valid_category?(category :: String.t()) :: boolean()
  def valid_category?(category) do
    category in valid_categories()
  end
end
