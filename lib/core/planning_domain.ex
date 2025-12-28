# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PlanningDomain do
  @moduledoc """
  Plain struct for planning domains with state management.

  Represents a planning domain with entities, tasks, actions, and other
  domain elements. Provides validation and state management.

  Stored in ETS (Elixir Term Storage) for in-memory persistence.

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

  alias AriaPlanner.Storage.EtsStorage

  @type t :: %__MODULE__{
          id: String.t(),
          domain_type: String.t(),
          name: String.t() | nil,
          description: String.t(),
          entities: [map()],
          tasks: [map()],
          actions: [map()],
          commands: [map()],
          multigoals: [map()],
          state: :active | :archived | :deprecated,
          version: integer(),
          metadata: map(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :domain_type,
    :name,
    :inserted_at,
    :updated_at,
    description: "",
    entities: [],
    tasks: [],
    actions: [],
    commands: [],
    multigoals: [],
    state: :active,
    version: 1,
    metadata: %{}
  ]

  @doc """
  Validates domain attributes and returns {:ok, domain} or {:error, reason}.
  """
  @spec validate(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def validate(attrs) do
    errors = []

    errors =
      if not Map.has_key?(attrs, :id) or attrs.id == nil do
        ["id is required" | errors]
      else
        errors
      end

    errors =
      if not Map.has_key?(attrs, :domain_type) or attrs.domain_type == nil or
           String.length(attrs.domain_type) < 1 do
        ["domain_type is required and must be at least 1 character" | errors]
      else
        errors
      end

    valid_domain_types = [
      "blocks_world",
      "tactical",
      "navigation",
      "social",
      "economic",
      "exploration",
      "stealth",
      "custom"
    ]

    errors =
      if Map.has_key?(attrs, :domain_type) and attrs.domain_type not in valid_domain_types do
        ["domain_type must be one of: #{Enum.join(valid_domain_types, ", ")}" | errors]
      else
        errors
      end

    valid_states = [:active, :archived, :deprecated]
    errors =
      if Map.has_key?(attrs, :state) and attrs.state not in valid_states do
        ["state must be one of: #{Enum.join(Enum.map(valid_states, &Atom.to_string/1), ", ")}" | errors]
      else
        errors
      end

    errors =
      if Map.has_key?(attrs, :version) and attrs.version <= 0 do
        ["version must be greater than 0" | errors]
      else
        errors
      end

    # Validate entities
    errors =
      if Map.has_key?(attrs, :entities) and
           not (is_list(attrs.entities) and Enum.all?(attrs.entities, &is_map/1)) do
        ["entities must be a list of maps" | errors]
      else
        errors
      end

    # Validate domain elements
    element_fields = [:tasks, :actions, :commands, :multigoals]
    errors =
      Enum.reduce(element_fields, errors, fn field, acc ->
        if Map.has_key?(attrs, field) and
             not (is_list(Map.get(attrs, field)) and
                    Enum.all?(Map.get(attrs, field), &is_map/1)) do
          ["#{field} must be a list of maps" | acc]
        else
          acc
        end
      end)

    if Enum.empty?(errors) do
      now = DateTime.utc_now()
      domain = %__MODULE__{
        id: Map.get(attrs, :id),
        domain_type: Map.get(attrs, :domain_type),
        name: Map.get(attrs, :name),
        description: Map.get(attrs, :description, ""),
        entities: Map.get(attrs, :entities, []),
        tasks: Map.get(attrs, :tasks, []),
        actions: Map.get(attrs, :actions, []),
        commands: Map.get(attrs, :commands, []),
        multigoals: Map.get(attrs, :multigoals, []),
        state: Map.get(attrs, :state, :active),
        version: Map.get(attrs, :version, 1),
        metadata: Map.get(attrs, :metadata, %{}),
        inserted_at: Map.get(attrs, :inserted_at, now),
        updated_at: now
      }

      {:ok, domain}
    else
      {:error, Enum.join(errors, "; ")}
    end
  end

  @doc """
  Creates new planning domain with UUIDv7 ID if not provided.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def create(attrs) do
    # Normalize attrs to use atom keys
    normalized_attrs =
      attrs
      |> Enum.map(fn
        {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
        {key, value} -> {key, value}
      end)
      |> Map.new()

    # Add ID if not present
    normalized_attrs =
      if Map.has_key?(normalized_attrs, :id) or Map.has_key?(normalized_attrs, "id") do
        normalized_attrs
      else
        id = UUIDv7.generate()
        Map.put(normalized_attrs, :id, id)
      end

    case validate(normalized_attrs) do
      {:ok, domain} ->
        case EtsStorage.insert(:planning_domains, domain.id, domain) do
          {:ok, _} -> {:ok, domain}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Updates existing planning domain.
  """
  @spec update(domain :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def update(domain, attrs) do
    # Merge existing domain with new attrs
    merged_attrs =
      domain
      |> Map.from_struct()
      |> Map.merge(attrs)
      |> Map.put(:id, domain.id)
      |> Map.put(:inserted_at, domain.inserted_at)

    case validate(merged_attrs) do
      {:ok, updated_domain} ->
        case EtsStorage.insert(:planning_domains, updated_domain.id, updated_domain) do
          {:ok, _} -> {:ok, updated_domain}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Adds an element to the domain.
  """
  @spec add_element(domain :: %__MODULE__{}, element_type :: atom(), attrs :: map()) ::
          {:ok, %__MODULE__{}} | {:error, String.t()}
  def add_element(domain, element_type, attrs) do
    element = Map.merge(%{id: UUIDv7.generate()}, attrs)

    updated_attrs =
      case element_type do
        :task ->
          Map.put(domain, :tasks, [element | domain.tasks])

        :action ->
          Map.put(domain, :actions, [element | domain.actions])

        :command ->
          Map.put(domain, :commands, [element | domain.commands])

        :multigoal ->
          Map.put(domain, :multigoals, [element | domain.multigoals])

        _ ->
          {:error, "invalid element type"}
      end

    case updated_attrs do
      {:error, _} = error ->
        error

      updated_domain ->
        update(domain, Map.from_struct(updated_domain))
    end
  end

  @doc """
  Gets a domain by ID.
  """
  @spec get(String.t()) :: {:ok, %__MODULE__{}} | {:error, :not_found}
  def get(id) do
    EtsStorage.get(:planning_domains, id)
  end

  @doc """
  Gets all domains.
  """
  @spec all() :: [%__MODULE__{}]
  def all do
    EtsStorage.all(:planning_domains)
  end

  @doc """
  Deletes a domain by ID.
  """
  @spec delete(String.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    EtsStorage.delete(:planning_domains, id)
  end
end
