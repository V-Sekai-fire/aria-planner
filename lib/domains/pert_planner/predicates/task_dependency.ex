# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Predicates.TaskDependency do
  @moduledoc """
  Task dependency predicate for PERT planner domain.

  Represents dependencies between tasks: successor depends on predecessor.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :string

  schema "pert_planner_task_dependency" do
    field(:predecessor, :string)
    field(:successor, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating and updating task dependency facts.
  """
  @spec changeset(dependency :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(dependency \\ %__MODULE__{}, attrs) do
    dependency
    |> cast(attrs, [:predecessor, :successor])
    |> validate_required([:predecessor, :successor])
    |> unique_constraint([:predecessor, :successor])
  end

  @doc """
  Creates a new task dependency fact.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates an existing task dependency fact.
  """
  @spec update(dependency :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(dependency, attrs) do
    dependency
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
