# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Persona do
  @moduledoc """
  Core persona entity schema for multiagent belief systems.

  This represents the fundamental persona structure for belief-immersed entities,
  providing the foundation for ego-centric planning and allocentric allocation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  @type t :: %__MODULE__{}

  schema "personas" do
    field(:name, :string)
    field(:active, :boolean, default: true)
    field(:entity_type, :string, default: "persona")

    # Core capabilities
    field(:capabilities, {:array, :string}, default: ["movable"])

    # Ego-centric belief models about other agents (hidden information architecture)
    # Beliefs about other personas' states and intentions (not actual states)
    field(:beliefs_about_others, :map, default: %{})
    # Belief confidence levels (0.0 to 1.0) for each belief
    field(:belief_confidence, :map, default: %{})
    # Last observation timestamps for belief updates
    field(:last_observations, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(persona :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(persona \\ %__MODULE__{}, attrs) do
    persona
    |> cast(attrs, [
      :id,
      :entity_type,
      :name,
      :active,
      :capabilities,
      :beliefs_about_others,
      :belief_confidence,
      :last_observations
    ])
    |> validate_required([:id, :name])
    |> validate_length(:name, min: 1)
    |> validate_uuid_v7(:id)
    |> put_change(:updated_at, DateTime.utc_now())
  end

  @doc """
  Creates new persona with UUIDv7 ID if not provided.
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
  Updates existing persona.
  """
  @spec update(persona :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(persona, attrs) do
    persona
    |> changeset(attrs)
    |> apply_action(:update)
  end

  @doc """
  Get ego-centric beliefs about another entity.

  Returns what this persona believes about the target entity.
  Beliefs are hidden from other personas (information asymmetry).
  """
  @spec get_beliefs_about(t(), String.t()) :: map()
  def get_beliefs_about(persona, target_entity_id) do
    AriaPlanner.BeliefManager.get_beliefs_about(persona, target_entity_id)
  end

  @doc """
  Get planner state for information asymmetry demonstration.

  Returns hidden error - personas cannot access others' internal planning states.
  """
  @spec get_planner_state(String.t(), String.t()) :: {:error, :hidden}
  def get_planner_state(target_persona_id, requesting_persona_id) do
    AriaPlanner.BeliefManager.get_planner_state(target_persona_id, requesting_persona_id)
  end

  @doc """
  Process observation to update persona beliefs.

  Observations are the mechanism through which personas learn about others
  while maintaining information asymmetry (no direct state access).
  """
  @spec process_observation(t(), map()) :: {:ok, t()} | {:error, String.t()}
  def process_observation(persona, observation) do
    AriaPlanner.PersonaObserver.process_observation(persona, observation)
  end

  @doc """
  Process communication to update beliefs.

  Communications between personas update sender beliefs about receivers
  without revealing internal states.
  """
  @spec process_communication(t(), map()) :: {:ok, t()} | {:error, String.t()}
  def process_communication(persona, communication) do
    AriaPlanner.PersonaObserver.process_communication(persona, communication)
  end

  @doc """
  Update beliefs from execution outcomes.
  """
  @spec update_beliefs_from_outcomes(t(), [map()]) :: {:ok, t()}
  def update_beliefs_from_outcomes(persona, outcomes) do
    AriaPlanner.PersonaObserver.update_beliefs_from_outcomes(persona, outcomes)
  end

  # UUID v7 validation for Ecto changesets
  @spec validate_uuid_v7(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_uuid_v7(changeset, field) do
    Ecto.Changeset.validate_change(changeset, field, fn _, value ->
      if String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/) do
        []
      else
        [{field, "must be a valid RFC 9562 UUIDv7"}]
      end
    end)
  end
end
