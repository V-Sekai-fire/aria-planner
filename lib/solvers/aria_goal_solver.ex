# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaGoalSolver do
  @moduledoc """
  Goal Solver for planning with entity requirements.

  This module solves goals while checking that required entities and capabilities are available.
  """

  # alias AriaPlanner.Planner.PlannerMetadata  # Unused - removed to fix compilation warning
  alias AriaPlanner.Planner.EntityRequirement
  alias AriaPlanner.Planner.State

  @doc """
  Solves goals with entity requirement validation.

  Returns {:ok, solution} when all requirements are met, or {:error, reason} otherwise.
  """
  @spec solve_goals(map(), State.t(), list(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def solve_goals(domain, initial_state, goals, options) do
    planner_metadata = Keyword.get(options, :planner_metadata)

    if planner_metadata do
      case validate_entity_requirements(planner_metadata.requires_entities || [], initial_state) do
        :ok ->
          {:ok, %{solution: "stub", goals: goals, domain: domain}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      # No requirements, always succeed
      {:ok, %{solution: "stub", goals: goals, domain: domain}}
    end
  end

  defp validate_entity_requirements([], _state), do: :ok

  defp validate_entity_requirements([requirement | rest], state) do
    case validate_single_requirement(requirement, state) do
      :ok -> validate_entity_requirements(rest, state)
      error -> error
    end
  end

  defp validate_single_requirement(%EntityRequirement{type: required_type, capabilities: required_caps}, state) do
    # Find entities of the required type
    entities_of_type = find_entities_by_type(state, required_type)

    if Enum.empty?(entities_of_type) do
      {:error, "No entity of type #{required_type} available"}
    else
      # Check if any entity has all required capabilities
      has_capable_entity =
        Enum.any?(entities_of_type, fn entity_id ->
          entity_caps = get_entity_capabilities(state, entity_id)
          Enum.all?(required_caps, fn cap -> cap in entity_caps end)
        end)

      if has_capable_entity do
        :ok
      else
        {:error, "No entity with required capabilities #{inspect(required_caps)} available"}
      end
    end
  end

  defp find_entities_by_type(state, required_type) do
    # Get all facts for "type" predicate
    type_facts = Map.get(state.facts, "type", %{})

    # Find entities matching the required type
    Enum.filter(type_facts, fn {_entity_id, type_value} ->
      type_value == to_string(required_type) or type_value == required_type
    end)
    |> Enum.map(fn {entity_id, _} -> entity_id end)
  end

  defp get_entity_capabilities(state, entity_id) do
    # Get capabilities for the entity
    capability_facts = Map.get(state.facts, "has_capability", %{})
    capabilities = Map.get(capability_facts, entity_id, [])

    # Normalize to atoms for comparison
    List.wrap(capabilities)
    |> Enum.map(fn
      val when is_atom(val) ->
        val

      val when is_binary(val) ->
        try do
          String.to_existing_atom(val)
        rescue
          ArgumentError -> String.to_atom(val)
        end

      val ->
        val
    end)
  end
end
