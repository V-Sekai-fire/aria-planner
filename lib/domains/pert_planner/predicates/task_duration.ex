# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Predicates.TaskDuration do
  @moduledoc """
  Task duration predicate for PERT planner domain.

  Represents the duration of each task in seconds.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:task_id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "pert_planner_task_duration" do
    field(:duration, :integer)

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating and updating task duration facts.
  """
  @spec changeset(duration :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(duration \\ %__MODULE__{}, attrs) do
    duration
    |> cast(attrs, [:task_id, :duration])
    |> validate_required([:task_id, :duration])
    |> validate_number(:duration, greater_than: 0)
  end

  @doc """
  Creates a new task duration fact.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates an existing task duration fact.
  """
  @spec update(duration :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(duration, attrs) do
    duration
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
