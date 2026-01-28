# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.NodeExecutedSchema do
  @moduledoc """
  Ecto schema for node_executed predicate persistence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interactivity_node_executed" do
    field(:node_id, :string)
    field(:executed, :boolean, default: false)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(node_executed, attrs) do
    node_executed
    |> cast(attrs, [:node_id, :executed])
    |> validate_required([:node_id, :executed])
    |> unique_constraint(:node_id, name: :interactivity_node_executed_node_id_index)
  end
end
