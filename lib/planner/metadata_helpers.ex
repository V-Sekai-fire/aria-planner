# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.MetadataHelpers do
  @moduledoc """
  Helper functions for creating and migrating planner metadata structs.

  This module provides convenient functions to create rigid metadata structs
  and migrate from legacy map-based metadata to the new struct format.
  """

  alias AriaPlanner.Planner.{EntityRequirement, PlannerMetadata, UnigoalMetadata}

  @doc """
  Creates a simple action metadata struct with basic entity requirements.

  ## Examples

      iex> AriaPlanner.Planner.MetadataHelpers.action_metadata("PT2H", "agent", [:cooking])
      %AriaPlanner.Planner.PlannerMetadata{duration: "PT2H", requires_entities: [...]}
  """
  @spec action_metadata(String.t(), String.t(), [atom()], keyword()) :: PlannerMetadata.t()
  def action_metadata(duration, entity_type, capabilities, opts \\ []) do
    entity_req = EntityRequirement.new!(entity_type, capabilities)
    PlannerMetadata.new!(duration, [entity_req], opts)
  end

  @doc """
  Creates command metadata struct with basic entity requirements.

  Commands are execution-time actions with failure handling.

  ## Examples

      iex> AriaPlanner.Planner.MetadataHelpers.command_metadata("PT15M", "agent", [:cooking])
      %AriaPlanner.Planner.PlannerMetadata{duration: "PT15M", requires_entities: [...]}
  """
  @spec command_metadata(String.t(), String.t(), [atom()], keyword()) :: PlannerMetadata.t()
  def command_metadata(duration, entity_type, capabilities, opts \\ []) do
    action_metadata(duration, entity_type, capabilities, opts)
  end

  @doc """
  Creates task metadata struct with basic entity requirements.

  Tasks are HTN decomposition methods that break complex goals into subtasks.

  ## Examples

      iex> AriaPlanner.Planner.MetadataHelpers.task_metadata("PT45M", "agent", [:cooking])
      %AriaPlanner.Planner.PlannerMetadata{duration: "PT45M", requires_entities: [...]}
  """
  @spec task_metadata(String.t(), String.t(), [atom()], keyword()) :: PlannerMetadata.t()
  def task_metadata(duration, entity_type, capabilities, opts \\ []) do
    action_metadata(duration, entity_type, capabilities, opts)
  end

  @doc """
  Creates instant action metadata (zero duration).

  ## Examples

      iex> AriaPlanner.Planner.MetadataHelpers.instant_metadata("agent", [:observation])
      %AriaPlanner.Planner.PlannerMetadata{duration: "PT0S", requires_entities: [...]}
  """
  @spec instant_metadata(String.t(), [atom()]) :: PlannerMetadata.t()
  def instant_metadata(entity_type, capabilities) do
    action_metadata("PT0S", entity_type, capabilities)
  end

  @doc """
  Creates a unigoal metadata struct with basic entity requirements.

  ## Examples

      iex> AriaPlanner.Planner.MetadataHelpers.unigoal_metadata("location", "PT10M", "agent", [:movement])
      %AriaPlanner.Planner.UnigoalMetadata{predicate: "location", duration: "PT10M", requires_entities: [...]}
  """
  @spec unigoal_metadata(String.t(), String.t(), String.t(), [atom()], keyword()) :: UnigoalMetadata.t()
  def unigoal_metadata(predicate, duration, entity_type, capabilities, opts \\ []) do
    entity_req = EntityRequirement.new!(entity_type, capabilities)
    UnigoalMetadata.new!(predicate, duration, [entity_req], opts)
  end
end
