# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Predicates.TaskStatus do
  @moduledoc """
  Task status predicate for PERT planner domain.

  Represents the status of each task: not_started, in_progress, completed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:task_id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "pert_planner_task_status" do
    field(:status, :string, default: "not_started")

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating and updating task status facts.
  """
  @spec changeset(status :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(status \\ %__MODULE__{}, attrs) do
    status
    |> cast(attrs, [:task_id, :status])
    |> validate_required([:task_id, :status])
    |> validate_inclusion(:status, ["not_started", "in_progress", "completed"])
  end

  @doc """
  Creates a new task status fact.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates an existing task status fact.
  """
  @spec update(status :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(status, attrs) do
    status
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
