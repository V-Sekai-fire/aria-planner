# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.FactsAllocentric do
  @moduledoc """
  Allocentric facts struct - Platonic truth/shared reality for multiagent gameplay.

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

  Stored in ETS (Elixir Term Storage) for in-memory persistence.
  """

  alias AriaPlanner.Storage.EtsStorage

  @type t :: %__MODULE__{
          id: String.t(),
          fact_id: String.t(),
          fact_type: String.t(),
          subject_id: String.t(),
          subject_type: String.t(),
          predicate: String.t(),
          object_value: String.t(),
          object_type: String.t(),
          confidence: float(),
          expires_at: DateTime.t() | nil,
          metadata: map(),
          game_session_id: String.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :fact_id,
    :fact_type,
    :subject_id,
    :subject_type,
    :predicate,
    :object_value,
    :object_type,
    :expires_at,
    :game_session_id,
    :inserted_at,
    :updated_at,
    confidence: 1.0,
    metadata: %{}
  ]

  @doc """
  Validates fact attributes and returns {:ok, fact} or {:error, reason}.
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

    required_fields = [
      :id,
      :fact_id,
      :fact_type,
      :subject_id,
      :subject_type,
      :predicate,
      :object_value,
      :object_type
    ]

    errors =
      Enum.reduce(required_fields, errors, fn field, acc ->
        if not Map.has_key?(attrs, field) or Map.get(attrs, field) == nil do
          ["#{field} is required" | acc]
        else
          acc
        end
      end)

    valid_fact_types = ["terrain", "object", "environmental", "event", "agent_observable"]

    errors =
      if Map.has_key?(attrs, :fact_type) and attrs.fact_type not in valid_fact_types do
        ["fact_type must be one of: #{Enum.join(valid_fact_types, ", ")}" | errors]
      else
        errors
      end

    valid_subject_types = ["persona", "item", "location", "environmental"]

    errors =
      if Map.has_key?(attrs, :subject_type) and attrs.subject_type not in valid_subject_types do
        ["subject_type must be one of: #{Enum.join(valid_subject_types, ", ")}" | errors]
      else
        errors
      end

    valid_object_types = ["string", "number", "boolean", "location", "entity_ref"]

    errors =
      if Map.has_key?(attrs, :object_type) and attrs.object_type not in valid_object_types do
        ["object_type must be one of: #{Enum.join(valid_object_types, ", ")}" | errors]
      else
        errors
      end

    errors =
      if Map.has_key?(attrs, :confidence) and
           (attrs.confidence < 0.0 or attrs.confidence > 1.0) do
        ["confidence must be between 0.0 and 1.0" | errors]
      else
        errors
      end

    if Enum.empty?(errors) do
      now = DateTime.utc_now()

      fact = %__MODULE__{
        id: Map.get(attrs, :id),
        fact_id: Map.get(attrs, :fact_id),
        fact_type: Map.get(attrs, :fact_type),
        subject_id: Map.get(attrs, :subject_id),
        subject_type: Map.get(attrs, :subject_type),
        predicate: Map.get(attrs, :predicate),
        object_value: Map.get(attrs, :object_value),
        object_type: Map.get(attrs, :object_type),
        confidence: Map.get(attrs, :confidence, 1.0),
        expires_at: Map.get(attrs, :expires_at),
        metadata: Map.get(attrs, :metadata, %{}),
        game_session_id: Map.get(attrs, :game_session_id),
        inserted_at: Map.get(attrs, :inserted_at, now),
        updated_at: now
      }

      {:ok, fact}
    else
      {:error, Enum.join(errors, "; ")}
    end
  end

  defp valid_uuid_v7?(value) when is_binary(value) do
    String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
  end

  defp valid_uuid_v7?(_), do: false

  @doc """
  Creates new allocentric fact.
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
      {:ok, fact} ->
        case EtsStorage.insert(:facts_allocentric, fact.id, fact) do
          {:ok, _} -> {:ok, fact}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Updates existing allocentric fact.
  """
  @spec update(fact :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def update(fact, attrs) do
    # Merge existing fact with new attrs
    merged_attrs =
      fact
      |> Map.from_struct()
      |> Map.merge(attrs)
      |> Map.put(:id, fact.id)
      |> Map.put(:inserted_at, fact.inserted_at)

    case validate(merged_attrs) do
      {:ok, updated_fact} ->
        case EtsStorage.insert(:facts_allocentric, updated_fact.id, updated_fact) do
          {:ok, _} -> {:ok, updated_fact}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Gets a fact by ID.
  """
  @spec get(String.t()) :: {:ok, %__MODULE__{}} | {:error, :not_found}
  def get(id) do
    EtsStorage.get(:facts_allocentric, id)
  end

  @doc """
  Gets all facts.
  """
  @spec all() :: [%__MODULE__{}]
  def all do
    EtsStorage.all(:facts_allocentric)
  end

  @doc """
  Deletes a fact by ID.
  """
  @spec delete(String.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    EtsStorage.delete(:facts_allocentric, id)
  end

  @doc """
  Record communication as an allocentric fact.

  Some communications become observable facts that all personas can observe,
  serving as temporal bridges for belief updating.
  """
  @spec record_communication(map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
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
        all()
        |> Enum.filter(fn fact ->
          fact.expires_at == nil or DateTime.compare(fact.expires_at, now) == :gt
        end)
        |> Enum.sort_by(& &1.updated_at, {:desc, DateTime})

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
        all()
        |> Enum.filter(fn fact ->
          (fact.subject_id == entity_id or
             (fact.object_type == "entity_ref" and fact.object_value == entity_id)) and
            (fact.expires_at == nil or DateTime.compare(fact.expires_at, now) == :gt)
        end)
        |> Enum.sort_by(& &1.updated_at, {:desc, DateTime})

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
        all()
        |> Enum.filter(fn fact ->
          fact.subject_id == target_entity_id and fact.fact_type in observable_types and
            (fact.expires_at == nil or DateTime.compare(fact.expires_at, now) == :gt)
        end)
        |> Enum.sort_by(& &1.updated_at, {:desc, DateTime})

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

      active_facts =
        all()
        |> Enum.filter(fn fact ->
          fact.expires_at == nil or DateTime.compare(fact.expires_at, now) == :gt
        end)

      conflicts =
        active_facts
        |> Enum.group_by(fn fact -> {fact.subject_id, fact.predicate} end)
        |> Enum.filter(fn {_key, facts} -> length(facts) > 1 end)
        |> Enum.map(fn {{subject_id, predicate}, facts} ->
          {subject_id, predicate, length(facts)}
        end)

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
      active_facts =
        all()
        |> Enum.filter(fn fact ->
          fact.subject_id == subject_id and
            (fact.expires_at == nil or DateTime.compare(fact.expires_at, now) == :gt)
        end)

      predicates_with_conflicts =
        active_facts
        |> Enum.group_by(& &1.predicate)
        |> Enum.filter(fn {_predicate, facts} -> length(facts) > 1 end)
        |> Enum.map(fn {predicate, _facts} -> predicate end)

      # Get all facts for those predicates
      if Enum.empty?(predicates_with_conflicts) do
        []
      else
        active_facts
        |> Enum.filter(fn fact -> fact.predicate in predicates_with_conflicts end)
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
  @spec record_event(map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
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
