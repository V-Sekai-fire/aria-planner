# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo.Migrations.CreateInteractivityNodeExecuted do
  use Ecto.Migration

  def up do
    create table(:interactivity_node_executed, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:node_id, :string, null: false)
      add(:executed, :boolean, default: false, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:interactivity_node_executed, [:node_id], name: :interactivity_node_executed_node_id_index))
  end

  def down do
    drop(table(:interactivity_node_executed))
  end
end
