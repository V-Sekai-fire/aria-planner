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
  def create_plan(persona_id, name, domain_type, opts \\ []) do
    objectives = Keyword.get(opts, :objectives, Keyword.get(opts, :todo, []))
    success_probability = Keyword.get(opts, :success_probability, 0.5)

    Plan.create(%{
      persona_id: persona_id,
      name: name,
      domain_type: domain_type,
      objectives: objectives,
      success_probability: success_probability,
      planning_timestamp: NaiveDateTime.utc_now()
    })
  end
end
