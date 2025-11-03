# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Management do
  @moduledoc """
  Entity management utilities for AriaCore.

  This module provides functions for managing entities, entity types,
  and entity registries in the AriaCore system.
  """

  @type entity_registry :: map()
  @type entity_type :: map()

  @doc """
  Creates a new empty entity registry.
  """
  @spec new_registry() :: entity_registry()
  def new_registry do
    %{
      entities: %{},
      types: %{},
      relationships: []
    }
  end

  @doc """
  Registers a new entity type in the registry.

  ## Parameters
  - `registry`: The entity registry
  - `entity_type`: The entity type specification

  ## Returns
  Updated registry with the new entity type
  """
  @spec register_entity_type(entity_registry(), entity_type()) :: entity_registry()
  def register_entity_type(registry, entity_type) do
    type_name = Map.get(entity_type, :name) || Map.get(entity_type, "name")
    updated_types = Map.put(registry.types, type_name, entity_type)
    %{registry | types: updated_types}
  end

  @doc """
  Normalizes an entity requirement specification.

  ## Parameters
  - `requirement`: The entity requirement to normalize

  ## Returns
  Normalized entity requirement
  """
  @spec normalize_requirement(map()) :: map()
  def normalize_requirement(requirement) do
    # Ensure the requirement has the expected structure
    requirement
    |> Map.put_new(:type, requirement[:type] || requirement["type"])
    |> Map.put_new(:capabilities, requirement[:capabilities] || requirement["capabilities"] || [])
    |> Map.put_new(:constraints, requirement[:constraints] || requirement["constraints"] || [])
  end
end
