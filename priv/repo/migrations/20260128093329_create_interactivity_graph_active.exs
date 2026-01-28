# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo.Migrations.CreateInteractivityGraphActive do
  use Ecto.Migration

  def up do
    create table(:interactivity_graph_active, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:graph_id, :string, null: false)
      add(:active, :boolean, default: false, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:interactivity_graph_active, [:graph_id], name: :interactivity_graph_active_graph_id_index))
  end

  def down do
    drop(table(:interactivity_graph_active))
  end
end
