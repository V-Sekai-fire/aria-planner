# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Plan do
  @moduledoc """
  Plain struct for persona-specific plans using RFC 9562 UUIDv7 primary keys.
  Plans are ego-centric structures representing individual persona perspectives,
  while run_lazy handles allocentric world execution. Plans contain solution
  tensor graphs and execution metadata.
  Stored in ETS (Elixir Term Storage) for in-memory persistence.
  """
  require Logger
  alias AriaPlanner.Storage.EtsStorage

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          persona_id: String.t(),
          domain_type: String.t(),
          objectives: list(),
          constraints: map(),
          temporal_constraints: map(),
          entity_capabilities: map(),
          solution_graph_data: map(),
          solution_plan: String.t(),
          planning_timestamp: NaiveDateTime.t() | nil,
          planning_duration_ms: integer() | nil,
          planner_state_snapshot: String.t(),
          execution_status: String.t(),
          execution_started_at: NaiveDateTime.t() | nil,
          execution_completed_at: NaiveDateTime.t() | nil,
          success_probability: float(),
          risk_assessment: map(),
          performance_metrics: map(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  defstruct [
    :id,
    :name,
    :persona_id,
    :domain_type,
    :planning_timestamp,
    :planning_duration_ms,
    :execution_started_at,
    :execution_completed_at,
    :inserted_at,
    :updated_at,
    objectives: [],
    constraints: %{},
    temporal_constraints: %{},
    entity_capabilities: %{},
    solution_graph_data: %{},
    solution_plan: "[]",
    planner_state_snapshot: "{}",
    execution_status: "planned",
    success_probability: 0.0,
    risk_assessment: %{},
    performance_metrics: %{}
  ]

  @doc """
  Validates plan attributes and returns {:ok, plan} or {:error, reason}.
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

    errors =
      if not Map.has_key?(attrs, :persona_id) or attrs.persona_id == nil do
        ["persona_id is required" | errors]
      else
        errors
      end

    errors =
      if not Map.has_key?(attrs, :domain_type) or attrs.domain_type == nil do
        ["domain_type is required" | errors]
      else
        errors
      end

    valid_domain_types = [
      "tactical",
      "navigation",
      "social",
      "economic",
      "exploration",
      "stealth",
      "blocks_world",
      "pert_planner",
      "workflow_test_domain",
      "test_domain_1",
      "empty_domain",
      "multi_entity_domain",
      "list_test_domain",
      "filter_test_domain",
      "restore_domain",
      "backtrack_domain",
      "locomotion",
      "custom"
    ]

    errors =
      if Map.has_key?(attrs, :domain_type) and attrs.domain_type not in valid_domain_types do
        ["domain_type must be one of: #{Enum.join(valid_domain_types, ", ")}" | errors]
      else
        errors
      end

    valid_statuses = ["planned", "executing", "completed", "failed"]

    errors =
      if Map.has_key?(attrs, :execution_status) and attrs.execution_status not in valid_statuses do
        ["execution_status must be one of: #{Enum.join(valid_statuses, ", ")}" | errors]
      else
        errors
      end

    errors =
      if Map.has_key?(attrs, :success_probability) and
           (attrs.success_probability < 0.0 or attrs.success_probability > 1.0) do
        ["success_probability must be between 0.0 and 1.0" | errors]
      else
        errors
      end

    errors =
      if Map.has_key?(attrs, :planning_duration_ms) and attrs.planning_duration_ms <= 0 do
        ["planning_duration_ms must be greater than 0" | errors]
      else
        errors
      end

    if Enum.empty?(errors) do
      now = NaiveDateTime.utc_now()

      plan = %__MODULE__{
        id: Map.get(attrs, :id),
        name: Map.get(attrs, :name),
        persona_id: Map.get(attrs, :persona_id),
        domain_type: Map.get(attrs, :domain_type),
        objectives: Map.get(attrs, :objectives, []),
        constraints: Map.get(attrs, :constraints, %{}),
        temporal_constraints: Map.get(attrs, :temporal_constraints, %{}),
        entity_capabilities: Map.get(attrs, :entity_capabilities, %{}),
        solution_graph_data: Map.get(attrs, :solution_graph_data, %{}),
        solution_plan: Map.get(attrs, :solution_plan, "[]"),
        planning_timestamp: Map.get(attrs, :planning_timestamp),
        planning_duration_ms: Map.get(attrs, :planning_duration_ms),
        planner_state_snapshot: Map.get(attrs, :planner_state_snapshot, "{}"),
        execution_status: Map.get(attrs, :execution_status, "planned"),
        execution_started_at: Map.get(attrs, :execution_started_at),
        execution_completed_at: Map.get(attrs, :execution_completed_at),
        success_probability: Map.get(attrs, :success_probability, 0.0),
        risk_assessment: Map.get(attrs, :risk_assessment, %{}),
        performance_metrics: Map.get(attrs, :performance_metrics, %{}),
        inserted_at: Map.get(attrs, :inserted_at, now),
        updated_at: now
      }

      {:ok, plan}
    else
      {:error, Enum.join(errors, "; ")}
    end
  end

  defp valid_uuid_v7?(value) when is_binary(value) do
    String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
  end

  defp valid_uuid_v7?(_), do: false

  @doc """
  Creates new plan with UUIDv7 ID.
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
      {:ok, plan} ->
        case EtsStorage.insert(:aria_planner_plans, plan.id, plan) do
          {:ok, _} -> {:ok, plan}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Updates existing plan.
  """
  @spec update(plan :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def update(plan, attrs) do
    # Merge existing plan with new attrs
    merged_attrs =
      plan
      |> Map.from_struct()
      |> Map.merge(attrs)
      |> Map.put(:id, plan.id)
      |> Map.put(:inserted_at, plan.inserted_at)

    case validate(merged_attrs) do
      {:ok, updated_plan} ->
        case EtsStorage.insert(:aria_planner_plans, updated_plan.id, updated_plan) do
          {:ok, _} -> {:ok, updated_plan}
          error -> error
        end

      error ->
        error
    end
  end

  @spec get(String.t()) :: {:ok, %__MODULE__{}} | {:error, :not_found}
  def get(id) do
    EtsStorage.get(:aria_planner_plans, id)
  end

  @doc """
  Gets all plans.
  """
  @spec all() :: [%__MODULE__{}]
  def all do
    EtsStorage.all(:aria_planner_plans)
  end

  @doc """
  Deletes a plan by ID.
  """
  @spec delete(String.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    EtsStorage.delete(:aria_planner_plans, id)
  end
end
