# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.FactsAllocentric do
  @moduledoc """
  Allocentric facts schema - Platonic truth/shared reality for multiagent gameplay.

  This represents the true world state accessible to all personas. Agent states
  are hidden from each other, but the allocentric facts represent what can be
  observed by any agent (terrain, shared objects, public events, etc.).

  ## Belief-Immersed Projection Architecture

  ### Definitional Status (Allocentric Ground Truth)
  Allocentric facts represent the single source of truth for:
  - Terrain and environmental facts (observable by any persona)
  - Shared object states (items, locations available to all)
  - Public communication broadcasts (global announcements)
  - Observable entity capabilities (what can be seen through observation)

  ### Hidden vs Observable Entity States
  ```elixir
  # True entity states (allocentric - definitive)
  entity_truth = FactsAllocentric.get_entity_state(entity_id)
  # Includes: position, capabilities, ownership, observable effects

  # Ego projections (persona beliefs - may differ)
  ego_belief = Persona.get_belief_about(persona_a, entity_id)
  # May be: misrepresented, incomplete, or wrong
  ```

  ### Communication as Observable Events
  Communications become facts when they have allocentric impact:

  ```elixir
  # Interpersonal communication (ego-only)
  private_message = %{sender: a, recipients: [b], content: "secret_plan"}
  # Not stored allocentric - only sender and recipients beliefs updated

  # Global announcements (allocentric facts)
  broadcast = %{sender: command, recipients: :all, content: "mission_abort"}
  # Becomes allocentric fact - observable by all personas
  ```

  ## Schema Structure

  ### Primary Facts (Ground Truth)
  ```
  id: UUIDv7 (primary key for updates/references)
  fact_id: String (fact identifier for queries/updates)
  fact_type: Enum (terrain, object, environmental, event, agent_observable)
  subject_id: UUID7 (what/whom the fact is about)
  subject_type: Enum (persona, location, item, environmental)
  predicate: String (relationship - "located_at", "has_capability", etc.)
  object_value: String (fact value)
  object_type: Enum (string, number, boolean, location, entity_ref)
  confidence: Float (1.0 for ground truth)
  metadata: Map (additional fact properties)
  ```

  ### Temporal Progression
  ```
  expires_at: DateTime (when fact becomes stale/invalid)
  created_at/updated_at: Temporal progression tracking
  game_session_id: UUID7 (session context for multi-scenario support)
  ```

  ## Query Interfaces

  ### Public Observation Queries
  Any persona can observe allocentric facts based on their capabilities:

  ```elixir
  # What can persona A observe about entity B?
  observable = FactsAllocentric.query_observable(persona_a.id, entity_b.id)
  # Returns facts compatible with persona's observation capabilities
  ```

  ## Event-Driven Fact Updates

  ### Communication Propagation
  Some communications create allocentric facts:

  ```elixir
  # Tactical coordination (egocentric)
  coordination = Communication.send(team, %{type: :tactical, strategy: "pincer"})
  # Updates team members' beliefs only

  # Command broadcast (allocentric)
  command = Communication.broadcast(%{type: :command, order: "regroup_base"})
  # Creates allocentric facts for all personas
  ```

  ### Environmental Changes
  ```elixir
  # Environmental event (bridges ego worlds)
  environmental_change = %{type: :weather_shift, region: battlefield, new_condition: "heavy_rain"}
  FactsAllocentric.record_event(environmental_change)

  # All personas can now observe this change affects their plans
  # Ego beliefs about terrain difficulty may need updating
  ```

  ## Validation Properties

  ### Decay Prevention (Temporal Bridges)
  Allocentric facts prevent complete information divergence:

  ```
  ∀personas a,b; ∀allocentric_fact f:
    observable(f, a) ∧ observable(f, b) ⇒
    belief_conflict(f, a, b) prevents allocation execution
  ```

  ### Consistency Checks
  ```elixir
  # Validate allocentric consistency
  assert FactsAllocentric.validate_world_state() == :consistent

  # Check for conflicting facts about same subject
  assert FactsAllocentric.conflicting_facts(fact_subject_id) == []
  ```
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "facts_allocentric" do
    # Fact identity and updates
    field(:fact_id, :string)
    field(:fact_type, :string)
    field(:subject_id, :string)
    field(:subject_type, :string)
    field(:predicate, :string)
    field(:object_value, :string)
    field(:object_type, :string)
    field(:confidence, :float, default: 1.0)
    field(:expires_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})
    field(:game_session_id, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(fact :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(fact \\ %__MODULE__{}, attrs) do
    fact
    |> cast(attrs, [
      :id,
      :fact_id,
      :fact_type,
      :subject_id,
      :subject_type,
      :predicate,
      :object_value,
      :object_type,
      :confidence,
      :expires_at,
      :metadata,
      :game_session_id
    ])
    |> validate_required([
      :id,
      :fact_id,
      :fact_type,
      :subject_id,
      :subject_type,
      :predicate,
      :object_value,
      :object_type
    ])
    |> AriaCore.Validator.validate_uuid_v7(:id)
    |> validate_inclusion(:fact_type, ["terrain", "object", "environmental", "event", "agent_observable"])
    |> validate_inclusion(:subject_type, ["persona", "item", "location", "environmental"])
    |> validate_inclusion(:object_type, ["string", "number", "boolean", "location", "entity_ref"])
    |> validate_number(:confidence, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> put_change(:updated_at, DateTime.utc_now())
  end

  @doc """
  Creates new allocentric fact.
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
  Updates existing allocentric fact.
  """
  @spec update(fact :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(fact, attrs) do
    fact
    |> changeset(attrs)
    |> apply_action(:update)
  end

  @doc """
  Record communication as an allocentric fact.

  Some communications become observable facts that all personas can observe,
  serving as temporal bridges for belief updating.
  """
  @spec record_communication(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def record_communication(message) do
    # Create allocentric fact from communication
    sender_id =
      if is_map(message.sender) and Map.has_key?(message.sender, :id) do
        message.sender.id
      else
        message.sender
      end

    fact_attrs = %{
      fact_id: UUIDv7.generate(),
      fact_type: "event",
      subject_id: sender_id,
      subject_type: "persona",
      predicate: "sent_communication",
      object_value: Jason.encode!(message.content),
      object_type: "string",
      # Communications are directly observed
      confidence: 1.0,
      metadata: Map.take(message, [:recipients, :message_type]),
      game_session_id: "believer_ego_session"
    }

    create(fact_attrs)
  end

  @doc """
  Get all allocentric facts for observation.

  Allows personas to observe the shared allocentric reality,
  creating the foundation for ego belief formation.
  """
  @spec get_all_facts() :: {:ok, [%__MODULE__{}]} | {:error, String.t()}
  def get_all_facts do
    # In a real implementation, this would query the database
    # For now, return empty list as foundation for observation mechanisms
    {:ok, []}
  end

  @doc """
  Get facts related to specific entity for observation.

  Enables ego-centric observation of allocentric reality,
  allowing personas to build beliefs about specific other entities.
  """
  @spec get_facts_about(String.t()) :: {:ok, [%__MODULE__{}]} | {:error, String.t()}
  def get_facts_about(_entity_id) do
    # Entity-specific observation foundation
    # Returns facts where entity is subject or mentioned in object
    {:ok, []}
  end
end
