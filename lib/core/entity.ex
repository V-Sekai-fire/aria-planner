# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity do
  @moduledoc """
  Core entity behaviour defining the interface for all entities in the planning system.

  This module defines the base Entity behaviour that all concrete entity types
  (Player, Agent, etc.) must implement. Entities represent active participants
  in the planning domain that can execute actions, have capabilities, and
  maintain state.

  ## Design Principles

  - **Behaviour-based polymorphism**: Common interface through behaviour callbacks
  - **Immutable state**: All entity operations return new entity instances
  - **Type safety**: Struct-based entities with enforced field types
  - **Capability composition**: Flexible capability attachment and querying
  - **Lifecycle management**: Proper entity creation, updating, and destruction

  ## Required Callbacks

  All entity types must implement:
  - `entity_type/1` - Return the entity's type atom (:player, :agent, etc.)
  - `capabilities/1` - Return list of capability atoms
  - `has_capability?/2` - Check if entity has specific capability
  - `update_capability/3` - Update or add a capability
  - `position/1` - Get current entity position
  - `move_to/2` - Move entity to new position
  - `active?/1` - Check if entity is currently active
  - `metadata/1` - Get entity metadata map

  ## Example Usage

      # Create and manipulate entities through the behaviour
      entity = SomeEntityType.create(id, name)
      entity = Entity.move_to(entity, {10.0, 5.0, 2.0})
      can_fly = Entity.has_capability?(entity, :flight)

  """

  # Define the base entity struct that all implementations must extend
  defstruct [
    # Unique entity identifier
    :id,
    # Human-readable name
    :name,
    # Entity type atom (:player, :agent, etc.)
    :type,
    # Boolean indicating if entity is active
    :active,
    # Additional entity-specific data
    :metadata,
    # Creation timestamp
    :created_at,
    # Last update timestamp
    :updated_at
  ]

  @typedoc """
  Base entity fields that all entity types must include.
  """
  @type base_fields :: %{
          id: String.t(),
          name: String.t(),
          type: atom(),
          active: boolean(),
          metadata: map(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @typedoc """
  Position type for 3D coordinates.
  """
  @type position :: {float(), float(), float()}

  @typedoc """
  Entity capability atom.
  """
  @type capability :: atom()

  @callback entity_type(entity :: term()) :: atom()
  @callback capabilities(entity :: term()) :: [capability()]
  @callback has_capability?(entity :: term(), capability()) :: boolean()
  @callback update_capability(entity :: term(), capability(), any()) :: term()
  @callback position(entity :: term()) :: position()
  @callback move_to(entity :: term(), position()) :: term()
  @callback active?(entity :: term()) :: boolean()
  @callback metadata(entity :: term()) :: map()
  @callback update_metadata(entity :: term(), map()) :: term()
  @callback destroy(entity :: term()) :: {:ok, term()} | {:error, String.t()}

  @doc """
  Creates a new entity with base fields initialized.

  This function creates the base entity struct that concrete implementations
  can extend with their specific fields.

  ## Parameters
  - `id`: Unique entity identifier
  - `name`: Human-readable entity name
  - `type`: Entity type atom
  - `metadata`: Optional initial metadata (default: %{})

  ## Returns
  Base entity struct with initialized fields
  """
  @spec new(String.t(), String.t(), atom(), map()) :: struct()
  def new(id, name, type, metadata \\ %{}) when is_binary(id) and is_binary(name) and is_atom(type) do
    now = DateTime.utc_now()

    %__MODULE__{
      id: id,
      name: name,
      type: type,
      active: true,
      metadata: metadata,
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Updates an entity's timestamp to current time.

  ## Parameters
  - `entity`: Entity to update

  ## Returns
  Entity with updated_at field set to current time
  """
  @spec touch(struct()) :: struct()
  def touch(%{__struct__: _} = entity) do
    Map.put(entity, :updated_at, DateTime.utc_now())
  end

  @doc """
  Checks if an entity implements the Entity behaviour correctly.

  ## Parameters
  - `entity`: Entity to validate

  ## Returns
  `:ok` if valid, `{:error, reason}` if invalid
  """
  @spec validate(struct()) :: :ok | {:error, String.t()}
  def validate(entity) do
    with {:ok, _} <- validate_required_fields(entity),
         {:ok, _} <- validate_behaviour_implementation(entity),
         {:ok, _} <- validate_type_consistency(entity) do
      :ok
    end
  end

  # Private validation functions
  defp validate_required_fields(%{id: id, name: name, type: type}) do
    cond do
      not is_binary(id) or String.length(id) == 0 ->
        {:error, "Entity id must be a non-empty string"}

      not is_binary(name) or String.length(name) == 0 ->
        {:error, "Entity name must be a non-empty string"}

      not is_atom(type) ->
        {:error, "Entity type must be an atom"}

      true ->
        {:ok, :valid}
    end
  end

  defp validate_behaviour_implementation(entity) do
    # Check if the entity's module implements the Entity behaviour
    module = entity.__struct__
    behaviours = Module.get_attribute(module, :behaviour) || []

    if __MODULE__ in behaviours do
      {:ok, :valid}
    else
      {:error, "Entity module #{inspect(module)} must @behaviour #{inspect(__MODULE__)}"}
    end
  end

  defp validate_type_consistency(%{type: :player} = _entity) do
    # Player validation - could check for specific capabilities or fields
    {:ok, :valid}
  end

  defp validate_type_consistency(%{type: :agent} = _entity) do
    # Agent validation - could check for intelligence capabilities
    {:ok, :valid}
  end

  defp validate_type_consistency(_entity) do
    # Default validation for custom entity types
    {:ok, :valid}
  end

  # Behaviour protocol functions that delegate to the specific entity implementation

  @doc """
  Delegates to the entity's entity_type/1 callback.
  """
  @spec entity_type(struct()) :: atom()
  def entity_type(%{__struct__: module} = entity) do
    module.entity_type(entity)
  end

  @doc """
  Delegates to the entity's capabilities/1 callback.
  """
  @spec capabilities(struct()) :: [capability()]
  def capabilities(%{__struct__: module} = entity) do
    module.capabilities(entity)
  end

  @doc """
  Delegates to the entity's has_capability?/2 callback.
  """
  @spec has_capability?(struct(), capability()) :: boolean()
  def has_capability?(%{__struct__: module} = entity, capability) do
    module.has_capability?(entity, capability)
  end

  @doc """
  Delegates to the entity's update_capability/3 callback.
  """
  @spec update_capability(struct(), capability(), any()) :: struct()
  def update_capability(%{__struct__: module} = entity, capability, data) do
    module.update_capability(entity, capability, data)
  end

  @doc """
  Delegates to the entity's position/1 callback.
  """
  @spec position(struct()) :: position()
  def position(%{__struct__: module} = entity) do
    module.position(entity)
  end

  @doc """
  Delegates to the entity's move_to/2 callback.
  """
  @spec move_to(struct(), position()) :: struct()
  def move_to(%{__struct__: module} = entity, position) do
    module.move_to(entity, position)
  end

  @doc """
  Delegates to the entity's active?/1 callback.
  """
  @spec active?(struct()) :: boolean()
  def active?(%{__struct__: module} = entity) do
    module.active?(entity)
  end

  @doc """
  Delegates to the entity's metadata/1 callback.
  """
  @spec metadata(struct()) :: map()
  def metadata(%{__struct__: module} = entity) do
    module.metadata(entity)
  end

  @doc """
  Delegates to the entity's update_metadata/2 callback.
  """
  @spec update_metadata(struct(), map()) :: struct()
  def update_metadata(%{__struct__: module} = entity, new_metadata) do
    module.update_metadata(entity, new_metadata)
  end

  @doc """
  Delegates to the entity's destroy/1 callback.
  """
  @spec destroy(struct()) :: {:ok, struct()} | {:error, String.t()}
  def destroy(%{__struct__: module} = entity) do
    module.destroy(entity)
  end
end
