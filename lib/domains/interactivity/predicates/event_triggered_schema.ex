# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.EventTriggeredSchema do
  @moduledoc """
  Ecto schema for event_triggered predicate persistence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interactivity_event_triggered" do
    field(:event_name, :string)
    field(:triggered, :boolean, default: false)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(event_triggered, attrs) do
    event_triggered
    |> cast(attrs, [:event_name, :triggered, :metadata])
    |> validate_required([:event_name, :triggered])
    |> unique_constraint(:event_name, name: :interactivity_event_triggered_event_name_index)
  end
end
