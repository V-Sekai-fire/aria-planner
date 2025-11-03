# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Subject do
  @moduledoc """
  Lightweight subject representation for the planning system.

  Subjects represent the entities that have properties or participate in
  relationships within the planning domain. Examples include entities,
  locations, tools, resources, etc.

  Built as a scrappy, lightweight alternative to database-backed entities.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          identifier: String.t(),
          name: String.t(),
          subject_type: String.t(),
          entity_id: String.t() | nil,
          active: boolean(),
          metadata: map(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @enforce_keys [:identifier, :subject_type]
  defstruct [
    :id,
    :identifier,
    :name,
    :subject_type,
    :entity_id,
    :active,
    :metadata,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new subject with automatic ID generation.
  """
  @spec new(map()) :: t()
  def new(attrs) do
    id = Map.get(attrs, :id, generate_id())
    now = DateTime.utc_now()

    %__MODULE__{
      id: id,
      identifier: Map.fetch!(attrs, :identifier),
      name: Map.get(attrs, :name),
      subject_type: Map.fetch!(attrs, :subject_type),
      entity_id: Map.get(attrs, :entity_id),
      active: Map.get(attrs, :active, true),
      metadata: Map.get(attrs, :metadata, %{}),
      created_at: Map.get(attrs, :created_at, now),
      updated_at: now
    }
  end

  @doc """
  Validates subject data.
  """
  @spec validate(map()) :: {:ok, t()} | {:error, String.t()}
  def validate(attrs) when is_map(attrs) do
    try do
      subject = new(attrs)
      # Simple validation checks
      if String.length(subject.identifier) == 0 do
        {:error, "identifier cannot be empty"}
      else
        {:ok, subject}
      end
    rescue
      KeyError -> {:error, "identifier and subject_type are required"}
      _ -> {:error, "invalid subject attributes"}
    end
  end

  @doc """
  Creates a subject from an entity.
  """
  @spec from_entity(any()) :: t()
  def from_entity(entity) do
    # Handle both old Entity format and new Entity behaviour
    {entity_id, entity_name, entity_type} =
      if Map.has_key?(entity, :__struct__) && entity.__struct__ == AriaCore.Entity do
        # Old entity format
        {entity.id, entity.name, entity.entity_type}
      else
        # Assume new behaviour - extract what we can
        {Map.get(entity, :id, "unknown"), Map.get(entity, :name, "unknown"), :entity}
      end

    new(%{
      identifier: "entity_#{entity_id}",
      name: entity_name,
      subject_type: Atom.to_string(entity_type),
      entity_id: entity_id,
      active: true,
      metadata: %{source_type: "entity"}
    })
  end

  @doc """
  Updates the subject's timestamp.
  """
  @spec touch(t()) :: t()
  def touch(%__MODULE__{} = subject) do
    %{subject | updated_at: DateTime.utc_now()}
  end

  # Private helper to generate IDs
  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
