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
  import Ecto.Query
  alias AriaPlanner.Repo

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
    try do
      now = DateTime.utc_now()

      facts =
        from(f in __MODULE__,
          where: is_nil(f.expires_at) or f.expires_at > ^now,
          order_by: [desc: f.updated_at]
        )
        |> Repo.all()

      {:ok, facts}
    rescue
      e -> {:error, "Failed to query facts: #{inspect(e)}"}
    end
  end

  @doc """
  Get facts related to specific entity for observation.

  Enables ego-centric observation of allocentric reality,
  allowing personas to build beliefs about specific other entities.
  Returns facts where entity is subject or mentioned in object.
  """
  @spec get_facts_about(String.t()) :: {:ok, [%__MODULE__{}]} | {:error, String.t()}
  def get_facts_about(entity_id) when is_binary(entity_id) do
    try do
      now = DateTime.utc_now()

      facts =
        from(f in __MODULE__,
          where:
            (f.subject_id == ^entity_id or
               (f.object_type == "entity_ref" and f.object_value == ^entity_id)) and
              (is_nil(f.expires_at) or f.expires_at > ^now),
          order_by: [desc: f.updated_at]
        )
        |> Repo.all()

      {:ok, facts}
    rescue
      e -> {:error, "Failed to query facts about entity: #{inspect(e)}"}
    end
  end

  def get_facts_about(_), do: {:error, "Invalid entity_id"}

  @doc """
  Get complete entity state from allocentric facts.

  Returns all observable facts about an entity including:
  - Position (located_at facts)
  - Capabilities (has_capability facts)
  - Ownership (owns/has facts)
  - Observable effects (agent_observable facts)
  """
  @spec get_entity_state(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_entity_state(entity_id) when is_binary(entity_id) do
    case get_facts_about(entity_id) do
      {:ok, facts} ->
        state =
          facts
          |> Enum.reduce(%{}, fn fact, acc ->
            predicate = fact.predicate
            value = parse_object_value(fact.object_value, fact.object_type)

            # Group facts by predicate
            current_values = Map.get(acc, predicate, [])
            updated_values = [value | current_values]
            Map.put(acc, predicate, updated_values)
          end)
          |> Map.put(:entity_id, entity_id)
          |> Map.put(:fact_count, length(facts))

        {:ok, state}

      error ->
        error
    end
  end

  def get_entity_state(_), do: {:error, "Invalid entity_id"}

  @doc """
  Query what a persona can observe about another entity.

  Returns facts compatible with persona's observation capabilities.
  Filters facts based on fact_type (agent_observable, event, environmental are always observable).
  """
  @spec query_observable(String.t(), String.t()) :: {:ok, [%__MODULE__{}]} | {:error, String.t()}
  def query_observable(observer_persona_id, target_entity_id)
      when is_binary(observer_persona_id) and is_binary(target_entity_id) do
    try do
      # Observable fact types: agent_observable, event, environmental are always observable
      # Terrain and object facts are observable by all
      observable_types = ["agent_observable", "event", "environmental", "terrain", "object"]
      now = DateTime.utc_now()

      facts =
        from(f in __MODULE__,
          where:
            f.subject_id == ^target_entity_id and f.fact_type in ^observable_types and
              (is_nil(f.expires_at) or f.expires_at > ^now),
          order_by: [desc: f.updated_at]
        )
        |> Repo.all()

      {:ok, facts}
    rescue
      e -> {:error, "Failed to query observable facts: #{inspect(e)}"}
    end
  end

  def query_observable(_, _), do: {:error, "Invalid persona_id or entity_id"}

  @doc """
  Validate world state consistency.

  Checks for:
  - No conflicting facts about the same subject with same predicate
  - All facts have valid confidence values
  - No expired facts are considered active
  """
  @spec validate_world_state() :: :consistent | {:inconsistent, String.t()}
  def validate_world_state do
    try do
      # Check for conflicting facts (same subject + predicate with different values)
      now = DateTime.utc_now()

      conflicts =
        from(f in __MODULE__,
          where: is_nil(f.expires_at) or f.expires_at > ^now,
          group_by: [f.subject_id, f.predicate],
          having: count(f.id) > 1,
          select: [f.subject_id, f.predicate, count(f.id)]
        )
        |> Repo.all()

      if Enum.empty?(conflicts) do
        :consistent
      else
        {:inconsistent, "Found conflicting facts: #{inspect(conflicts)}"}
      end
    rescue
      e -> {:inconsistent, "Validation error: #{inspect(e)}"}
    end
  end

  @doc """
  Find conflicting facts about a specific subject.

  Returns list of facts that conflict (same predicate, different values).
  """
  @spec conflicting_facts(String.t()) :: [%__MODULE__{}]
  def conflicting_facts(subject_id) when is_binary(subject_id) do
    try do
      now = DateTime.utc_now()

      # Find predicates with multiple values for the same subject
      predicates_with_conflicts =
        from(f in __MODULE__,
          where: f.subject_id == ^subject_id and (is_nil(f.expires_at) or f.expires_at > ^now),
          group_by: f.predicate,
          having: count(f.id) > 1,
          select: f.predicate
        )
        |> Repo.all()

      # Get all facts for those predicates
      if Enum.empty?(predicates_with_conflicts) do
        []
      else
        from(f in __MODULE__,
          where:
            f.subject_id == ^subject_id and f.predicate in ^predicates_with_conflicts and
              (is_nil(f.expires_at) or f.expires_at > ^now)
        )
        |> Repo.all()
      end
    rescue
      _ -> []
    end
  end

  def conflicting_facts(_), do: []

  @doc """
  Record environmental event as an allocentric fact.

  Environmental events are observable by all personas and serve as
  temporal bridges for belief updating.
  """
  @spec record_event(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def record_event(event) when is_map(event) do
    region = Map.get(event, :region, "unknown")
    event_type = Map.get(event, :type, "environmental_change")
    new_condition = Map.get(event, :new_condition, "")

    fact_attrs = %{
      fact_id: UUIDv7.generate(),
      fact_type: "environmental",
      subject_id: to_string(region),
      subject_type: "environmental",
      predicate: "environmental_event",
      object_value: Jason.encode!(%{type: event_type, condition: new_condition}),
      object_type: "string",
      confidence: 1.0,
      metadata: Map.take(event, [:region, :type, :new_condition]),
      game_session_id: Map.get(event, :game_session_id, "default_session")
    }

    create(fact_attrs)
  end

  def record_event(_), do: {:error, "Invalid event format"}

  # Helper function to parse object values based on type
  defp parse_object_value(value, "string"), do: value
  defp parse_object_value(value, "number"), do: parse_number(value)
  defp parse_object_value(value, "boolean"), do: parse_boolean(value)
  defp parse_object_value(value, "location"), do: value
  defp parse_object_value(value, "entity_ref"), do: value
  defp parse_object_value(value, _), do: value

  defp parse_number(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> value
    end
  end

  defp parse_number(value), do: value

  defp parse_boolean(value) when is_binary(value) do
    case String.downcase(value) do
      "true" -> true
      "false" -> false
      _ -> value
    end
  end

  defp parse_boolean(value), do: value
end
