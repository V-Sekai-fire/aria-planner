# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.PlanManager do
  @moduledoc """
  Plan Manager for ego-centric plan creation and management.

  Handles plan creation with persona-specific planning.
  """

  alias AriaCore.Plan

  @doc """
  Creates a persona-specific plan.
  """
  @spec create_plan(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, Plan.t()} | {:error, any()}
  def create_plan(persona_id, name, domain_type, opts \\ [])
  
  def create_plan(persona_id, name, domain_type, opts)
      when is_binary(persona_id) and is_binary(name) and is_binary(domain_type) do
    # Validate inputs
    cond do
      String.length(persona_id) == 0 ->
        {:error, "persona_id cannot be empty"}

      String.length(name) == 0 ->
        {:error, "name cannot be empty"}

      String.length(domain_type) == 0 ->
        {:error, "domain_type cannot be empty"}

      true ->
        objectives = Keyword.get(opts, :objectives, Keyword.get(opts, :todo, []))
        success_probability = Keyword.get(opts, :success_probability, 0.5)

        # Validate success_probability range
        validated_probability =
          if success_probability >= 0.0 and success_probability <= 1.0 do
            success_probability
          else
            0.5
          end

        # Validate objectives is a list
        validated_objectives =
          if is_list(objectives) do
            objectives
          else
            []
          end

        Plan.create(%{
          persona_id: persona_id,
          name: name,
          domain_type: domain_type,
          objectives: validated_objectives,
          success_probability: validated_probability,
          planning_timestamp: NaiveDateTime.utc_now()
        })
    end
  end

  def create_plan(_persona_id, _name, _domain_type, _opts) do
    {:error, "persona_id, name, and domain_type must be non-empty strings"}
  end
end
