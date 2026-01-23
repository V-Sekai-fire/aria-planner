# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Persona do
  @moduledoc """
  Core persona entity struct for planning systems.

  This represents the fundamental persona structure for planning entities,
  providing the foundation for planning and execution.

  Stored in ETS (Elixir Term Storage) for in-memory persistence.
  """

  alias AriaPlanner.Storage.EtsStorage

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          active: boolean(),
          entity_type: String.t(),
          capabilities: [String.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :name,
    active: true,
    entity_type: "persona",
    capabilities: ["movable"],
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
        case EtsStorage.insert(:aria_planner_personas, persona.id, persona) do
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
        case EtsStorage.insert(:aria_planner_personas, updated_persona.id, updated_persona) do
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
    EtsStorage.get(:aria_planner_personas, id)
  end

  @doc """
  Gets all personas.
  """
  @spec all() :: [%__MODULE__{}]
  def all do
    EtsStorage.all(:aria_planner_personas)
  end

  @doc """
  Deletes a persona by ID.
  """
  @spec delete(String.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    EtsStorage.delete(:aria_planner_personas, id)
  end
end
