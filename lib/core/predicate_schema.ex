# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PredicateSchema do
  @moduledoc """
  Plain struct for predicates storing planning domain predicates with metadata and validation rules.
  Predicates define relationships and properties in the planning domain. This struct follows
  ETNF (Essential Tuple Normal Form) with single-attribute primary keys and proper validation
  constraints for predicate names and categories.
  Stored in ETS (Elixir Term Storage) for in-memory persistence.
  """
  alias AriaPlanner.Storage.EtsStorage
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          category: String.t(),
          multi_valued: boolean(),
          metadata: map(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }
  defstruct [
    :id,
    :name,
    :description,
    category: "state",
    multi_valued: false,
    metadata: %{},
    inserted_at: nil,
    updated_at: nil
  ]
  @doc """
  Validates predicate attributes and returns {:ok, predicate} or {:error, reason}.
  @spec validate(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def validate(attrs) do
    errors = []
    errors =
      if not Map.has_key?(attrs, :id) or attrs.id == nil do
        ["id is required" | errors]
      else
        errors
      end
      if not Map.has_key?(attrs, :name) or attrs.name == nil or String.length(attrs.name) < 1 do
        ["name is required and must be at least 1 character" | errors]
      if Map.has_key?(attrs, :name) and
           not String.match?(attrs.name, ~r/^[a-z][a-zA-Z0-9_]*$/) do
        ["name must be a valid atom name (starting with lowercase letter)" | errors]
    valid_categories = ["state", "action", "effect", "goal"]
      if Map.has_key?(attrs, :category) and attrs.category not in valid_categories do
        ["category must be one of: #{Enum.join(valid_categories, ", ")}" | errors]
    if Enum.empty?(errors) do
      now = DateTime.utc_now()
      predicate = %__MODULE__{
        id: Map.get(attrs, :id),
        name: Map.get(attrs, :name),
        description: Map.get(attrs, :description),
        category: Map.get(attrs, :category, "state"),
        multi_valued: Map.get(attrs, :multi_valued, false),
        metadata: Map.get(attrs, :metadata, %{}),
        inserted_at: Map.get(attrs, :inserted_at, now),
        updated_at: now
      }
      {:ok, predicate}
    else
      {:error, Enum.join(errors, "; ")}
    end
  end
  Creates new predicate with UUIDv7 ID.
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def create(attrs) do
    attrs =
      if Map.has_key?(attrs, :id) or Map.has_key?(attrs, "id") do
        attrs
        id = UUIDv7.generate()
        Map.put(attrs, :id, id)
    case validate(attrs) do
      {:ok, predicate} ->
        case EtsStorage.insert(:predicates, predicate.id, predicate) do
          {:ok, _} -> {:ok, predicate}
          error -> error
        end
      error ->
        error
  Updates existing predicate.
  @spec update(predicate :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def update(predicate, attrs) do
    # Merge existing predicate with new attrs
    merged_attrs =
      predicate
      |> Map.from_struct()
      |> Map.merge(attrs)
      |> Map.put(:id, predicate.id)
      |> Map.put(:inserted_at, predicate.inserted_at)
    case validate(merged_attrs) do
      {:ok, updated_predicate} ->
        case EtsStorage.insert(:predicates, updated_predicate.id, updated_predicate) do
          {:ok, _} -> {:ok, updated_predicate}
  Gets a predicate by ID.
  @spec get(String.t()) :: {:ok, %__MODULE__{}} | {:error, :not_found}
  def get(id) do
    EtsStorage.get(:predicates, id)
  Gets all predicates.
  @spec all() :: [%__MODULE__{}]
  def all do
    EtsStorage.all(:predicates)
  Deletes a predicate by ID.
  @spec delete(String.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    EtsStorage.delete(:predicates, id)
  Checks if predicate is multi-valued.
  @spec multi_valued?(predicate :: %__MODULE__{}) :: boolean()
  def multi_valued?(%__MODULE__{multi_valued: multi_valued}) do
    multi_valued
  Gets predicate category.
  @spec category(predicate :: %__MODULE__{}) :: String.t()
  def category(%__MODULE__{category: category}) do
    category
  Updates predicate metadata.
  @spec update_metadata(predicate :: %__MODULE__{}, metadata :: map()) ::
          {:ok, %__MODULE__{}} | {:error, String.t()}
  def update_metadata(predicate, new_metadata) do
    merged_metadata = Map.merge(predicate.metadata, new_metadata)
    update(predicate, %{metadata: merged_metadata})
  Sets predicate as multi-valued.
  @spec set_multi_valued(predicate :: %__MODULE__{}, multi_valued :: boolean()) ::
  def set_multi_valued(predicate, multi_valued) do
    update(predicate, %{multi_valued: multi_valued})
  Changes predicate category.
  @spec change_category(predicate :: %__MODULE__{}, category :: String.t()) ::
  def change_category(predicate, category) do
    update(predicate, %{category: category})
  Validates predicate name format.
  @spec valid_name?(name :: String.t()) :: boolean()
  def valid_name?(name) when is_binary(name) do
    String.match?(name, ~r/^[a-z][a-zA-Z0-9_]*$/)
  def valid_name?(_), do: false
  Gets all valid categories.
  @spec valid_categories() :: [String.t()]
  def valid_categories do
    ["state", "action", "effect", "goal"]
  Checks if category is valid.
  @spec valid_category?(category :: String.t()) :: boolean()
  def valid_category?(category) do
    category in valid_categories()
end
