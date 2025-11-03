# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Types.Persona do
  @moduledoc """
  Unified Persona entity for both human and AI entities.

  A Persona represents an entity's personality expressed through their Avatar in a 3D environment.
  Personas can be either human-controlled (entities) or autonomous AI (agents), differentiated
  by their capability sets and metadata.

  ## Design Decisions

  - Implements Entity behaviour for polymorphic entity handling
  - Struct-based with enforced field types for type safety
  - Capability-based differentiation between human and AI personas
  - All persona data stored in metadata for maximum flexibility
  - Unified Avatar/Character system for 3D representation

  ## Persona Types

  ### Human Personas (Entities)
  - Capabilities: `[:movable, :inventory, :craft, :mine, :build, :interact]`
  - Metadata: `{character: Character.t(), position: {x,y,z}, inventory: [...], identity: %{...}}`

  ### AI Personas (Agents)
  - Capabilities: `[:movable, :compute, :optimize, :predict, :learn, :navigate]`
  - Metadata: `{character: Character.t(), movable: Movable.t(), intelligence: %{...}, autonomy: %{...}}`

  ## Example Usage

      # Create human entity persona
      persona = Persona.new_human_player("entity_001", "Alex")
      persona = AriaCore.Entity.move_to(persona, {10.5, 5.2, -3.8})
      can_craft = AriaCore.Entity.has_capability?(persona, :craft)

      # Create AI agent persona
      persona = Persona.new_ai_agent("agent_001", "GuardianBot")
      persona = AriaCore.Entity.move_to(persona, {15.0, 8.0, 2.1})
      can_optimize = AriaCore.Entity.has_capability?(persona, :optimize)

      # Generic capability management
      persona = AriaCore.Entity.update_capability(persona, :craft, enabled_state)
      capabilities = AriaCore.Entity.capabilities(persona)
  """

  @behaviour AriaCore.Entity

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
  Creates a new basic persona with minimal capabilities.

  ## Parameters
  - `id`: Unique identifier for the persona
  - `name`: Human-readable name for the persona

  ## Returns
  Basic persona that can have capabilities added dynamically
  """
  @spec new(String.t(), String.t()) :: t()
  def new(id, name) when is_binary(id) and is_binary(name) do
    base_entity = AriaCore.Entity.new(id, name, :persona)

    # Create basic human character (can be upgraded to AI later)
    character = Character.new_human_player(id <> "_char", name)

    # Basic persona metadata - minimal to start
    persona_metadata = %{
      # Character/avatar for 3D representation
      character: character,
      # Position always needed for movement
      position: {0.0, 0.0, 0.0},
      # Identity/authentication data (no explicit type - derived from capabilities)
      identity: %{
        verified: false,
        last_login: nil
      }
    }

    %__MODULE__{
      # Base entity fields
      id: base_entity.id,
      name: base_entity.name,
      type: base_entity.type,
      active: base_entity.active,
      metadata: Map.merge(base_entity.metadata, persona_metadata),
      created_at: base_entity.created_at,
      updated_at: base_entity.updated_at,
      # Start with minimal capabilities - can add more dynamically
      capabilities: [:movable]
    }
  end

  @doc """
  Enables human entity capabilities for a persona.

  ## Parameters
  - `persona`: Base persona to enable human capabilities on

  ## Returns
  Persona with human entity capabilities (inventory, crafting, etc.)
  """
  @spec enable_human_capabilities(t()) :: t()
  def enable_human_capabilities(%__MODULE__{} = persona) do
    updated_capabilities = Enum.uniq(persona.capabilities ++ [:inventory, :craft, :mine, :build, :interact])

    # Add inventory if not present
    updated_metadata =
      if Map.has_key?(persona.metadata, :inventory) do
        persona.metadata
      else
        Map.put(persona.metadata, :inventory, [])
      end

    %{persona | capabilities: updated_capabilities, metadata: updated_metadata}
    |> AriaCore.Entity.touch()
  end

  @doc """
  Enables AI agent capabilities for a persona.

  ## Parameters
  - `persona`: Base persona to enable AI capabilities on

  ## Returns
  Persona with AI agent capabilities (compute, optimize, predict, learn, navigate)
  """
  @spec enable_ai_capabilities(t()) :: t()
  def enable_ai_capabilities(%__MODULE__{} = persona) do
    updated_capabilities = Enum.uniq(persona.capabilities ++ [:compute, :optimize, :predict, :learn, :navigate])

    # Add AI-specific metadata if not present
    updated_metadata = persona.metadata
    updated_metadata = Map.update(updated_metadata, :movable, AriaCore.Entity.Capabilities.Movable.new(), & &1)

    updated_metadata =
      Map.update(updated_metadata, :intelligence, %{level: 1, experience_points: 0, learning_rate: 0.1}, & &1)

    updated_metadata =
      Map.update(updated_metadata, :autonomy, %{enabled: true, goal_oriented: true, decision_making: :reactive}, & &1)

    # Upgrade character to AI
    ai_character = Character.new_ai_agent(persona.id <> "_char", persona.name)
    updated_metadata = Map.put(updated_metadata, :character, ai_character)

    %{persona | capabilities: updated_capabilities, metadata: updated_metadata}
    |> AriaCore.Entity.touch()
  end

  @doc """
  Removes human player capabilities from a persona.

  ## Parameters
  - `persona`: Persona to remove human capabilities from

  ## Returns
  Persona without human player capabilities
  """
  @spec disable_human_capabilities(t()) :: t()
  def disable_human_capabilities(%__MODULE__{} = persona) do
    updated_capabilities = persona.capabilities -- [:inventory, :craft, :mine, :build, :interact]

    %{persona | capabilities: updated_capabilities}
    |> AriaCore.Entity.touch()
  end

  @doc """
  Removes AI agent capabilities from a persona.

  ## Parameters
  - `persona`: Persona to remove AI capabilities from

  ## Returns
  Persona without AI agent capabilities
  """
  @spec disable_ai_capabilities(t()) :: t()
  def disable_ai_capabilities(%__MODULE__{} = persona) do
    updated_capabilities = persona.capabilities -- [:compute, :optimize, :predict, :learn, :navigate]

    %{persona | capabilities: updated_capabilities}
    |> AriaCore.Entity.touch()
  end

  @doc """
  Creates a new human entity persona (convenience function).

  ## Parameters
  - `id`: Unique identifier for the persona
  - `name`: Human-readable name for the persona

  ## Returns
  Human entity persona with inventory and movement capabilities

  ## Note
  This is equivalent to calling `Persona.new(id, name) |> Persona.enable_human_capabilities()`
  """
  @spec new_human_player(String.t(), String.t()) :: t()
  def new_human_player(id, name) when is_binary(id) and is_binary(name) do
    new(id, name) |> enable_human_capabilities()
  end

  @doc """
  Creates a new AI agent persona (convenience function).

  ## Parameters
  - `id`: Unique identifier for the persona
  - `name`: Human-readable name for the persona

  ## Returns
  AI agent persona with intelligence and movement capabilities

  ## Note
  This is equivalent to calling `Persona.new(id, name) |> Persona.enable_ai_capabilities()`
  """
  @spec new_ai_agent(String.t(), String.t()) :: t()
  def new_ai_agent(id, name) when is_binary(id) and is_binary(name) do
    new(id, name) |> enable_ai_capabilities()
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

  @doc """
  Computes the identity type based on capabilities.

  ## Parameters
  - `persona`: Persona to analyze

  ## Returns
  Identity type: :basic, :human, :ai, or :human_and_ai
  """
  @spec identity_type(t()) :: :basic | :human | :ai | :human_and_ai
  def identity_type(%__MODULE__{capabilities: capabilities}) do
    has_human_caps = Enum.any?(capabilities, &Enum.member?([:inventory, :craft, :mine, :build, :interact], &1))
    has_ai_caps = Enum.any?(capabilities, &Enum.member?([:compute, :optimize, :predict, :learn, :navigate], &1))

    cond do
      has_human_caps and has_ai_caps -> :human_and_ai
      has_human_caps -> :human
      has_ai_caps -> :ai
      true -> :basic
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
        movable_data = Map.get(metadata, :movable, AriaCore.Entity.Capabilities.Movable.new())
        AriaCore.Entity.Capabilities.Movable.get_position(movable_data)

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
          current_movable = Map.get(persona.metadata, :movable, AriaCore.Entity.Capabilities.Movable.new())
          updated_movable = AriaCore.Entity.Capabilities.Movable.move(current_movable, new_position)
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
