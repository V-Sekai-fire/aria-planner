# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo.Migrations.CreateInteractivitySocketValue do
  use Ecto.Migration

  def up do
    create table(:interactivity_socket_value, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:node_id, :string, null: false)
      add(:socket_id, :string, null: false)
      add(:value, :map)
      add(:value_type, :string)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:interactivity_socket_value, [:node_id, :socket_id],
        name: :interactivity_socket_value_composite_index
      )
    )
  end

  def down do
    drop(table(:interactivity_socket_value))
  end
end
