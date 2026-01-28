# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.SocketConnectedSchema do
  @moduledoc """
  Ecto schema for socket_connected predicate persistence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interactivity_socket_connected" do
    field(:from_node, :string)
    field(:from_socket, :string)
    field(:to_node, :string)
    field(:to_socket, :string)
    field(:connected, :boolean, default: false)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(socket_connected, attrs) do
    socket_connected
    |> cast(attrs, [:from_node, :from_socket, :to_node, :to_socket, :connected])
    |> validate_required([:from_node, :from_socket, :to_node, :to_socket, :connected])
    |> unique_constraint(
      [:from_node, :from_socket, :to_node, :to_socket],
      name: :interactivity_socket_connected_composite_index
    )
  end
end
