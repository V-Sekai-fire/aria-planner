# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Plan do
  @moduledoc """
  Ecto schema for persona-specific plans using RFC 9562 UUIDv7 primary keys.

  Plans are ego-centric structures representing individual persona perspectives,
  while run_lazy handles allocentric world execution. Plans contain solution
  tensor graphs and execution metadata.
  """

  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "plans" do
    field(:name, :string)
    field(:persona_id, :string)

    # Ego-centric planning data (persona perspective)
    # tactical, navigation, social, etc.
    field(:domain_type, :string)
    field(:objectives, {:array, :string}, default: [])
    field(:constraints, :map, default: %{})
    field(:temporal_constraints, :map, default: %{})
    field(:entity_capabilities, :map, default: %{})

    # Solution tensor graph (persisted as tokenized representation)
    # Nx tensors exported to maps
    field(:solution_graph_data, :map, default: %{})
    field(:solution_plan, :string, default: "[]")

    # Planning metadata
    field(:planning_timestamp, :naive_datetime_usec)
    field(:planning_duration_ms, :integer)
    field(:planner_state_snapshot, :string, default: "{}")

    # Execution state (allocentric when run_lazy processes)
    # planned, executing, completed, failed
    field(:execution_status, :string, default: "planned")
    field(:execution_started_at, :naive_datetime_usec)
    field(:execution_completed_at, :naive_datetime_usec)

    # Success metrics
    field(:success_probability, :float, default: 0.0)
    field(:risk_assessment, :map, default: %{})
    field(:performance_metrics, :map, default: %{})

    timestamps(type: :naive_datetime_usec)
  end

  @spec changeset(plan :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(plan \\ %__MODULE__{}, attrs) do
    plan
    |> cast(attrs, [
      :id,
      :name,
      :persona_id,
      :domain_type,
      :objectives,
      :constraints,
      :temporal_constraints,
      :entity_capabilities,
      :solution_graph_data,
      :solution_plan,
      :planning_timestamp,
      :planning_duration_ms,
      :planner_state_snapshot,
      :execution_status,
      :execution_started_at,
      :execution_completed_at,
      :success_probability,
      :risk_assessment,
      :performance_metrics
    ])
    |> validate_required([:id, :name, :persona_id, :domain_type])
    |> validate_length(:name, min: 1)
     |> validate_uuid_v7(:id)
    |> validate_inclusion(:domain_type, ["tactical", "navigation", "social", "economic", "exploration", "stealth", "blocks_world", "pert_planner", "workflow_test_domain", "test_domain_1", "empty_domain", "multi_entity_domain", "list_test_domain", "filter_test_domain", "restore_domain", "backtrack_domain"])
    |> validate_inclusion(:execution_status, ["planned", "executing", "completed", "failed"])
    |> validate_number(:success_probability, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_number(:planning_duration_ms, greater_than: 0)
    |> put_change(:updated_at, DateTime.utc_now())
  end


  @doc """
  Creates new plan with UUIDv7 ID.
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
  Updates existing plan.
  """
  @spec update(plan :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(plan, attrs) do
    plan
    |> changeset(attrs)
    |> apply_action(:update)
  end

  # UUID v7 validation
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

  # UUID entries are generated using UUIDv7.generate()
end
