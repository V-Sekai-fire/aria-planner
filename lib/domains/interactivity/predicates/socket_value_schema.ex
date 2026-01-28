# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.SocketValueSchema do
  @moduledoc """
  Ecto schema for socket_value predicate persistence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interactivity_socket_value" do
    field(:node_id, :string)
    field(:socket_id, :string)
    field(:value, :map)
    field(:value_type, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(socket_value, attrs) do
    socket_value
    |> cast(attrs, [:node_id, :socket_id, :value, :value_type])
    |> validate_required([:node_id, :socket_id])
    |> unique_constraint(
      [:node_id, :socket_id],
      name: :interactivity_socket_value_composite_index
    )
  end
end
