# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaRepo.Job do
  @moduledoc """
  Ecto schema for background jobs processed by the GenServer-based job system.

  Replaces Oban with a simpler, custom job processing system that integrates
  directly with Ecto and SQLite.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "jobs" do
    field(:queue, :string, default: "default")
    field(:worker, :string)
    field(:args, :map, default: %{})

    field(:state, Ecto.Enum,
      values: [:available, :scheduled, :executing, :completed, :discarded, :retryable],
      default: :available
    )

    field(:attempt, :integer, default: 0)
    field(:max_attempts, :integer, default: 3)
    field(:scheduled_at, :utc_datetime_usec)
    field(:attempted_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:discarded_at, :utc_datetime_usec)
    field(:errors, {:array, :map}, default: [])
    field(:tags, {:array, :string}, default: [])

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating new jobs.
  """
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:queue, :worker, :args, :state, :attempt, :max_attempts, :scheduled_at, :tags])
    |> validate_required([:worker])
    |> validate_inclusion(:state, [:available, :scheduled, :executing, :completed, :discarded, :retryable])
    |> validate_number(:attempt, greater_than_or_equal_to: 0)
    |> validate_number(:max_attempts, greater_than: 0)
  end

  @doc """
  Changeset for updating job state during execution.
  """
  def execution_changeset(job, attrs) do
    job
    |> cast(attrs, [:state, :attempt, :attempted_at, :completed_at, :discarded_at, :errors])
    |> validate_inclusion(:state, [:executing, :completed, :discarded, :retryable])
  end
end
