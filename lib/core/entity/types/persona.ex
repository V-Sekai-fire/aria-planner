# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Types.Persona do
  @moduledoc """
  Persona entity: an entity with capabilities in the ReBAC sense (relationship-based access control).

  A Persona has a capabilities list that defines what it can do—no special-case factories.
  Create with explicit capabilities via `new(id, name, capabilities: [...])` or
  grant/revoke via `AriaCore.Entity.update_capability/3`.

  ## Design

  - Implements Entity behaviour; capabilities are a first-class attribute.
  - ReBAC: capabilities express relationship-based access (what this entity can do), not "human" vs "AI" bundles.
  - No factory methods (no enable_human_capabilities, new_human_player, etc.); set capabilities when creating or via update_capability.

  ## Example

      persona = Persona.new("e1", "Alex", capabilities: [:movable, :inventory, :craft])
      AriaCore.Entity.has_capability?(persona, :craft)
      persona = AriaCore.Entity.update_capability(persona, :mine, %{})
      capabilities = AriaCore.Entity.capabilities(persona)
  """

  @behaviour AriaCore.Entity

  alias AriaCore.Entity.Capabilities.Movable
  alias AriaCore.Entity.Character

  # Unified Persona struct
  defstruct [
    # Base entity fields only - capability data lives in metadata!
    :id,
    :name,
    :type,
    :active,
    # Stores ALL persona data (character, position, movable, etc.)
    :metadata,
    :created_at,
    :updated_at,
    # List of active capabilities determines persona type
    :capabilities
  ]

  @type t :: %__MODULE__{
          # Base entity fields only - persona data lives in metadata!
          id: String.t(),
          name: String.t(),
          type: atom(),
          active: boolean(),
          metadata: map(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          capabilities: [atom()]
        }

  @doc """
  Creates a new persona with explicit capabilities (ReBAC: relationship-based access control).

  ## Parameters
  - `id`: Unique identifier for the persona
  - `name`: Human-readable name for the persona
  - `opts`: Keyword options; `:capabilities` (list of atoms) — no default bundles; pass the capabilities this entity has.

  ## Returns
  Persona with the given capabilities; add or remove later via `AriaCore.Entity.update_capability/3`.
  """
  @spec new(String.t(), String.t(), keyword()) :: t()
  def new(id, name, opts \\ []) when is_binary(id) and is_binary(name) do
    capabilities = Keyword.get(opts, :capabilities, []) |> List.wrap() |> Enum.uniq()
    base_entity = AriaCore.Entity.new(id, name, :persona, %{}, capabilities: capabilities)

    character = Character.new(id <> "_char", name)

    persona_metadata = %{
      character: character,
      position: {0.0, 0.0, 0.0},
      identity: %{verified: false, last_login: nil}
    }

    # Ensure metadata has inventory when :inventory capability is present
    persona_metadata =
      if :inventory in capabilities do
        Map.put(persona_metadata, :inventory, [])
      else
        persona_metadata
      end

    # Add Movable when :movable in capabilities (for position/move_to)
    persona_metadata =
      if :movable in capabilities do
        Map.put(persona_metadata, :movable, Movable.new())
      else
        Map.put(persona_metadata, :position, {0.0, 0.0, 0.0})
      end

    %__MODULE__{
      id: base_entity.id,
      name: base_entity.name,
      type: base_entity.type,
      active: base_entity.active,
      metadata: Map.merge(base_entity.metadata, persona_metadata),
      created_at: base_entity.created_at,
      updated_at: base_entity.updated_at,
      capabilities: capabilities
    }
  end

  @doc """
  Adds an item to a personas's inventory (for personas that have inventory capability).

  ## Parameters
  - `persona`: Persona entity to update
  - `item`: Item identifier to add

  ## Returns
  Updated persona with item added to inventory, or unchanged if persona doesn't have inventory capability
  """
  @spec add_to_inventory(t(), String.t()) :: t()
  def add_to_inventory(%__MODULE__{capabilities: capabilities} = persona, item)
      when is_binary(item) do
    if :inventory in capabilities do
      current_inventory = Map.get(persona.metadata, :inventory, [])
      updated_inventory = [item | current_inventory]
      updated_metadata = Map.put(persona.metadata, :inventory, updated_inventory)

      %{persona | metadata: updated_metadata}
      |> AriaCore.Entity.touch()
    else
      # No inventory capability, ignore
      persona
    end
  end

  @doc """
  Gets the inventory contents for personas that have inventory capability.

  ## Parameters
  - `persona`: Persona entity to query

  ## Returns
  List of inventory items, or empty list if persona doesn't have inventory capability
  """
  @spec get_inventory(t()) :: [String.t()]
  def get_inventory(%__MODULE__{capabilities: capabilities, metadata: metadata}) do
    if :inventory in capabilities do
      Map.get(metadata, :inventory, [])
    else
      []
    end
  end

  # Entity behaviour callbacks - unified implementation!

  @impl AriaCore.Entity
  @spec entity_type(t()) :: atom()
  def entity_type(_persona), do: :persona

  @impl AriaCore.Entity
  @spec capabilities(t()) :: [atom()]
  def capabilities(%__MODULE__{capabilities: capabilities}), do: capabilities

  @impl AriaCore.Entity
  @spec has_capability?(t(), atom()) :: boolean()
  def has_capability?(%__MODULE__{capabilities: capabilities}, capability) do
    capability in capabilities
  end

  @impl AriaCore.Entity
  @spec update_capability(t(), atom(), any()) :: t()
  def update_capability(%__MODULE__{} = persona, capability, data) do
    # Add/remove capabilities and update metadata
    if data do
      # Adding/updating capability
      updated_capabilities =
        if capability in persona.capabilities do
          persona.capabilities
        else
          [capability | persona.capabilities]
        end

      updated_metadata = Map.put(persona.metadata, capability, data)
      %{persona | capabilities: updated_capabilities, metadata: updated_metadata}
    else
      # Removing capability
      updated_capabilities = List.delete(persona.capabilities, capability)
      # Keep metadata but remove the capability key
      updated_metadata = Map.delete(persona.metadata, capability)
      %{persona | capabilities: updated_capabilities, metadata: updated_metadata}
    end
    |> AriaCore.Entity.touch()
  end

  @impl AriaCore.Entity
  @spec position(t()) :: AriaCore.Entity.position()
  def position(%__MODULE__{metadata: metadata}) do
    # Check metadata structure to determine position source
    cond do
      Map.has_key?(metadata, :position) ->
        # Direct position storage (human entities)
        Map.get(metadata, :position, {0.0, 0.0, 0.0})

      Map.has_key?(metadata, :movable) ->
        # Position from movable capability (AI agents)
        movable_data = Map.get(metadata, :movable, Movable.new())
        Movable.get_position(movable_data)

      true ->
        # Default fallback
        {0.0, 0.0, 0.0}
    end
  end

  @impl AriaCore.Entity
  @spec move_to(t(), AriaCore.Entity.position()) :: t()
  def move_to(%__MODULE__{} = persona, {x, y, z} = new_position)
      when is_float(x) and is_float(y) and is_float(z) do
    # Update position based on metadata structure
    updated_metadata =
      cond do
        Map.has_key?(persona.metadata, :position) ->
          # Direct position update (human entities)
          Map.put(persona.metadata, :position, new_position)

        Map.has_key?(persona.metadata, :movable) ->
          # Update movable capability (AI agents)
          current_movable = Map.get(persona.metadata, :movable, Movable.new())
          updated_movable = Movable.move(current_movable, new_position)
          Map.put(persona.metadata, :movable, updated_movable)

        true ->
          # Add position if neither exists (shouldn't happen)
          Map.put(persona.metadata, :position, new_position)
      end

    %{persona | metadata: updated_metadata}
    |> AriaCore.Entity.touch()
  end

  @impl AriaCore.Entity
  @spec active?(t()) :: boolean()
  def active?(%__MODULE__{active: active}), do: active

  @impl AriaCore.Entity
  @spec metadata(t()) :: map()
  def metadata(%__MODULE__{metadata: metadata}), do: metadata

  @impl AriaCore.Entity
  @spec update_metadata(t(), map()) :: t()
  def update_metadata(%__MODULE__{} = persona, new_metadata) do
    updated_metadata = Map.merge(persona.metadata, new_metadata)

    %{persona | metadata: updated_metadata}
    |> AriaCore.Entity.touch()
  end

  @impl AriaCore.Entity
  @spec destroy(t()) :: {:ok, t()} | {:error, String.t()}
  def destroy(%__MODULE__{} = persona) do
    if persona.active do
      {:error, "Cannot destroy active persona entity"}
    else
      {:ok, persona}
    end
  end
end
