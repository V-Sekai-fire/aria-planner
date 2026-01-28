# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.GraphActiveSchema do
  @moduledoc """
  Ecto schema for graph_active predicate persistence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interactivity_graph_active" do
    field(:graph_id, :string)
    field(:active, :boolean, default: false)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(graph_active, attrs) do
    graph_active
    |> cast(attrs, [:graph_id, :active])
    |> validate_required([:graph_id, :active])
    |> unique_constraint(:graph_id, name: :interactivity_graph_active_graph_id_index)
  end
end
