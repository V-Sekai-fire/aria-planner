# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo.Migrations.CreateInteractivityVariableValue do
  use Ecto.Migration

  def up do
    create table(:interactivity_variable_value, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:variable_name, :string, null: false)
      add(:value, :map)
      add(:value_type, :string)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:interactivity_variable_value, [:variable_name],
        name: :interactivity_variable_value_variable_name_index
      )
    )
  end

  def down do
    drop(table(:interactivity_variable_value))
  end
end
