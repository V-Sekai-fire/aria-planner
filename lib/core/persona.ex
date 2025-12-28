# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Persona do
  @moduledoc """
  Core persona entity struct for multiagent belief systems.

  This represents the fundamental persona structure for belief-immersed entities,
  providing the foundation for ego-centric planning and allocentric allocation.

  Stored in ETS (Elixir Term Storage) for in-memory persistence.
  """

  alias AriaPlanner.Storage.EtsStorage

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          active: boolean(),
          entity_type: String.t(),
          capabilities: [String.t()],
          beliefs_about_others: map(),
          belief_confidence: map(),
          last_observations: map(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :name,
    active: true,
    entity_type: "persona",
    capabilities: ["movable"],
    beliefs_about_others: %{},
    belief_confidence: %{},
    last_observations: %{},
    inserted_at: nil,
    updated_at: nil
  ]

  @doc """
  Validates persona attributes and returns {:ok, persona} or {:error, reason}.
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

    errors =
      if not Map.has_key?(attrs, :id) or attrs.id == nil do
        ["id is required" | errors]
      else
        errors
      end

    errors =
      if not Map.has_key?(attrs, :name) or attrs.name == nil or String.length(attrs.name) < 1 do
        ["name is required and must be at least 1 character" | errors]
      else
        errors
      end

    if Enum.empty?(errors) do
      now = DateTime.utc_now()
      persona = %__MODULE__{
        id: Map.get(attrs, :id),
        name: Map.get(attrs, :name),
        active: Map.get(attrs, :active, true),
        entity_type: Map.get(attrs, :entity_type, "persona"),
        capabilities: Map.get(attrs, :capabilities, ["movable"]),
        beliefs_about_others: Map.get(attrs, :beliefs_about_others, %{}),
        belief_confidence: Map.get(attrs, :belief_confidence, %{}),
        last_observations: Map.get(attrs, :last_observations, %{}),
        inserted_at: Map.get(attrs, :inserted_at, now),
        updated_at: now
      }

      {:ok, persona}
    else
      {:error, Enum.join(errors, "; ")}
    end
  end

  defp valid_uuid_v7?(value) when is_binary(value) do
    String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
  end

  defp valid_uuid_v7?(_), do: false

  @doc """
  Creates new persona with UUIDv7 ID if not provided.
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
      {:ok, persona} ->
        case EtsStorage.insert(:personas, persona.id, persona) do
          {:ok, _} -> {:ok, persona}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Updates existing persona.
  """
  @spec update(persona :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def update(persona, attrs) do
    # Merge existing persona with new attrs
    merged_attrs =
      persona
      |> Map.from_struct()
      |> Map.merge(attrs)
      |> Map.put(:id, persona.id)
      |> Map.put(:inserted_at, persona.inserted_at)

    case validate(merged_attrs) do
      {:ok, updated_persona} ->
        case EtsStorage.insert(:personas, updated_persona.id, updated_persona) do
          {:ok, _} -> {:ok, updated_persona}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Gets a persona by ID.
  """
  @spec get(String.t()) :: {:ok, %__MODULE__{}} | {:error, :not_found}
  def get(id) do
    EtsStorage.get(:personas, id)
  end

  @doc """
  Gets all personas.
  """
  @spec all() :: [%__MODULE__{}]
  def all do
    EtsStorage.all(:personas)
  end

  @doc """
  Deletes a persona by ID.
  """
  @spec delete(String.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    EtsStorage.delete(:personas, id)
  end

  @doc """
  Get ego-centric beliefs about another entity.

  Returns what this persona believes about the target entity.
  Beliefs are ego-centric - each persona has their own model of others.
  Beliefs are hidden from other personas (information asymmetry).
  """
  @spec get_beliefs_about(t(), String.t()) :: map()
  def get_beliefs_about(%__MODULE__{} = persona, target_entity_id) when is_binary(target_entity_id) do
    Map.get(persona.beliefs_about_others, target_entity_id, %{})
  end

  def get_beliefs_about(_persona, _target_entity_id) do
    %{}
  end

  @doc """
  Get planner state for information asymmetry demonstration.

  Returns hidden error - personas cannot access others' internal planning states.
  This demonstrates information asymmetry in the belief-based ego architecture.
  """
  @spec get_planner_state(String.t(), String.t()) :: {:error, :hidden}
  def get_planner_state(_target_persona_id, _requesting_persona_id) do
    # Information asymmetry: persona internal states are hidden
    {:error, :hidden}
  end

  @doc """
  Process observation to update persona beliefs.

  Observations are the mechanism through which personas learn about others
  while maintaining information asymmetry (no direct state access).
  """
  @spec process_observation(t(), map()) :: {:ok, t()} | {:error, String.t()}
  def process_observation(%__MODULE__{} = persona, observation) when is_map(observation) do
    AriaPlanner.PersonaObserver.process_observation(persona, observation)
  end

  def process_observation(_persona, _observation) do
    {:error, "persona must be a Persona struct and observation must be a map"}
  end

  @doc """
  Process communication to update beliefs.

  Communications between personas update sender beliefs about receivers
  without revealing internal states.
  """
  @spec process_communication(t(), map()) :: {:ok, t()} | {:error, String.t()}
  def process_communication(%__MODULE__{} = persona, communication) when is_map(communication) do
    AriaPlanner.PersonaObserver.process_communication(persona, communication)
  end

  def process_communication(_persona, _communication) do
    {:error, "persona must be a Persona struct and communication must be a map"}
  end

  @doc """
  Update beliefs from execution outcomes.
  """
  @spec update_beliefs_from_outcomes(t(), [map()]) :: {:ok, t()}
  def update_beliefs_from_outcomes(%__MODULE__{} = persona, outcomes) when is_list(outcomes) do
    AriaPlanner.PersonaObserver.update_beliefs_from_outcomes(persona, outcomes)
  end

  def update_beliefs_from_outcomes(_persona, _outcomes) do
    {:error, "persona must be a Persona struct and outcomes must be a list"}
  end

end
