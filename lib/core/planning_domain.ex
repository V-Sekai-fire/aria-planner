# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PlanningDomain do
  @moduledoc """
  Ecto schema for planning domains with state changesets.

  Represents a planning domain with entities, tasks, actions, and other
  domain elements. Provides Ecto changesets for validation and state management.

  ## Domain Structure

  A planning domain consists of:
  - **Entities**: Objects that can be manipulated in the domain
  - **Tasks**: High-level goals to be decomposed into subtasks
  - **Actions**: Primitive operations that change the world state
  - **Commands**: Special actions with side effects
  - **Multigoals**: Complex goals requiring multiple subgoals

  ## State Management

  Domains support multiple states:
  - `:active` - Domain is available for planning
  - `:archived` - Domain preserved for historical reference
  - `:deprecated` - Domain should not be used for new planning

  ## Versioning

  Domains include version numbers for tracking changes and ensuring
  compatibility with existing plans.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  @type t :: %__MODULE__{}

  schema "planning_domains" do
    field(:domain_type, :string)
    field(:name, :string)
    field(:description, :string, default: "")

    # Domain entities
    field(:entities, {:array, :map}, default: [])

    # Domain elements (tasks, actions, commands, multigoals)
    field(:tasks, {:array, :map}, default: [])
    field(:actions, {:array, :map}, default: [])
    field(:commands, {:array, :map}, default: [])
    field(:multigoals, {:array, :map}, default: [])

    # Domain metadata
    field(:state, Ecto.Enum, values: [:active, :archived, :deprecated], default: :active)
    field(:version, :integer, default: 1)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating and updating planning domains.
  """
  @spec changeset(domain :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(domain \\ %__MODULE__{}, attrs) do
    domain
    |> cast(attrs, [
      :id,
      :domain_type,
      :name,
      :description,
      :entities,
      :tasks,
      :actions,
      :commands,
      :multigoals,
      :state,
      :version,
      :metadata
    ])
    |> validate_required([:id, :domain_type])
    |> validate_length(:domain_type, min: 1)
    |> validate_uuid_v7(:id)
    |> validate_inclusion(:domain_type, [
      "blocks_world",
      "tactical",
      "navigation",
      "social",
      "economic",
      "exploration",
      "stealth",
      "custom"
    ])
    |> validate_inclusion(:state, [:active, :archived, :deprecated])
    |> validate_number(:version, greater_than: 0)
    |> validate_entities()
    |> validate_domain_elements()
    |> put_change(:updated_at, DateTime.utc_now())
  end

  @doc """
  Changeset for adding domain elements (tasks, actions, etc).
  """
  @spec add_element_changeset(domain :: %__MODULE__{}, element_type :: atom(), attrs :: map()) ::
          Ecto.Changeset.t()
  def add_element_changeset(domain, element_type, attrs) do
    element = Map.merge(%{"id" => UUIDv7.generate()}, attrs)

    case element_type do
      :task ->
        domain
        |> cast(%{"tasks" => [element | domain.tasks]}, [:tasks])
        |> validate_domain_elements()

      :action ->
        domain
        |> cast(%{"actions" => [element | domain.actions]}, [:actions])
        |> validate_domain_elements()

      :command ->
        domain
        |> cast(%{"commands" => [element | domain.commands]}, [:commands])
        |> validate_domain_elements()

      :multigoal ->
        domain
        |> cast(%{"multigoals" => [element | domain.multigoals]}, [:multigoals])
        |> validate_domain_elements()

      _ ->
        add_error(domain |> change(), :element_type, "invalid element type")
    end
  end

  @doc """
  Creates new planning domain with UUIDv7 ID if not provided.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    # Normalize attrs to use string keys only
    normalized_attrs =
      attrs
      |> Enum.map(fn
        {key, value} when is_atom(key) -> {Atom.to_string(key), value}
        {key, value} -> {key, value}
      end)
      |> Map.new()

    # Add ID if not present
    normalized_attrs =
      if Map.has_key?(normalized_attrs, "id") do
        normalized_attrs
      else
        id = UUIDv7.generate()
        Map.put(normalized_attrs, "id", id)
      end

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates existing planning domain.
  """
  @spec update(domain :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(domain, attrs) do
    domain
    |> changeset(attrs)
    |> apply_action(:update)
  end

  @doc """
  Adds an element to the domain.
  """
  @spec add_element(domain :: %__MODULE__{}, element_type :: atom(), attrs :: map()) ::
          {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def add_element(domain, element_type, attrs) do
    domain
    |> add_element_changeset(element_type, attrs)
    |> apply_action(:update)
  end

  # Private validation functions

  @spec validate_entities(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_entities(changeset) do
    validate_change(changeset, :entities, fn :entities, entities ->
      if is_list(entities) and Enum.all?(entities, &is_map/1) do
        []
      else
        [entities: "must be a list of maps"]
      end
    end)
  end

  @spec validate_domain_elements(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_domain_elements(changeset) do
    changeset
    |> validate_change(:tasks, &validate_element_list/2)
    |> validate_change(:actions, &validate_element_list/2)
    |> validate_change(:commands, &validate_element_list/2)
    |> validate_change(:multigoals, &validate_element_list/2)
  end

  @spec validate_element_list(atom(), any()) :: [{atom(), String.t()}]
  defp validate_element_list(_field, elements) do
    if is_list(elements) and Enum.all?(elements, &is_map/1) do
      []
    else
      [elements: "must be a list of maps"]
    end
  end

  # UUID v7 validation for Ecto changesets
  @spec validate_uuid_v7(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  defp validate_uuid_v7(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/) do
        []
      else
        [{field, "must be a valid RFC 9562 UUIDv7"}]
      end
    end)
  end
end
