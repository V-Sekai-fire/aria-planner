# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo.Migrations.CreateInteractivityEventTriggered do
  use Ecto.Migration

  def up do
    create table(:interactivity_event_triggered, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:event_name, :string, null: false)
      add(:triggered, :boolean, default: false, null: false)
      add(:metadata, :map, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:interactivity_event_triggered, [:event_name], name: :interactivity_event_triggered_event_name_index)
    )
  end

  def down do
    drop(table(:interactivity_event_triggered))
  end
end
