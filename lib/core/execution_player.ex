# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Execution.Entity do
  @moduledoc """
  Generic entity representation for world state manipulation.

  This module provides concrete data structures for entities in the
  execution layer, supporting different entity types like entities, agents,
  and other game entities. Unlike planning facts, entity data can be
  directly manipulated to change the actual world state.
  """

  @type entity_type :: :player | :agent | :npc | :item | :structure

  @type t :: %__MODULE__{
          id: integer(),
          name: String.t(),
          entity_type: entity_type(),
          capabilities: [atom()] | nil
        }

  @enforce_keys [:id, :name, :entity_type]
  defstruct id: nil,
            name: "",
            entity_type: :player,
            capabilities: nil

  @doc """
  Create a new entity with default values based on entity type.
  """
  @spec new(integer(), String.t(), entity_type()) :: t()
  def new(id, name, entity_type) do
    defaults = default_attributes_for_type(entity_type)
    struct(__MODULE__, [id: id, name: name, entity_type: entity_type] ++ defaults)
  end

  @doc """
  Create a new entity with custom values.
  """
  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) do
    entity_type = Map.get(attrs, :entity_type, :player)
    defaults = default_attributes_for_type(entity_type)
    struct(__MODULE__, Map.merge(Enum.into(defaults, %{}), attrs))
  end

  @doc """
  Create a new player entity (convenience function).
  """
  @spec new_player(integer(), String.t()) :: t()
  def new_player(id, name) do
    new(id, name, :player)
  end

  # Private helper for default attributes based on entity type
  defp default_attributes_for_type(:player) do
    [capabilities: nil]
  end

  defp default_attributes_for_type(:agent) do
    [capabilities: []]
  end

  defp default_attributes_for_type(_) do
    [capabilities: nil]
  end

  @doc """
  Validate entity data.
  """
  @spec validate(map()) :: {:ok, t()} | {:error, String.t()}
  def validate(attrs) when is_map(attrs) do
    cond do
      Map.get(attrs, :id) == nil ->
        {:error, "Entity ID is required"}

      Map.get(attrs, :name) == "" ->
        {:error, "Entity name is required"}

      true ->
        try do
          entity = new(attrs)
          {:ok, entity}
        rescue
          _ -> {:error, "Invalid entity attributes"}
        end
    end
  end
end
