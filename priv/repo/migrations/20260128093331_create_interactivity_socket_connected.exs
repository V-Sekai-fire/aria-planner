# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo.Migrations.CreateInteractivitySocketConnected do
  use Ecto.Migration

  def up do
    create table(:interactivity_socket_connected, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:from_node, :string, null: false)
      add(:from_socket, :string, null: false)
      add(:to_node, :string, null: false)
      add(:to_socket, :string, null: false)
      add(:connected, :boolean, default: false, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:interactivity_socket_connected, [:from_node, :from_socket, :to_node, :to_socket],
        name: :interactivity_socket_connected_composite_index
      )
    )
  end

  def down do
    drop(table(:interactivity_socket_connected))
  end
end
