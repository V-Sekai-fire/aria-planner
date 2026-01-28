# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo.Migrations.CreateFunWithFlagsToggles do
  use Ecto.Migration

  # Migration for FunWithFlags feature flag storage
  # This creates the table that FunWithFlags uses to persist feature flags

  def up do
    create table(:fun_with_flags_toggles, primary_key: false) do
<<<<<<< HEAD
      add :id, :binary_id, primary_key: true
      add :flag_name, :string, null: false
      add :gate_type, :string, null: false
      add :target, :string, null: false
      add :enabled, :boolean, null: false
    end

    create index(
      :fun_with_flags_toggles,
      [:flag_name, :gate_type, :target],
      unique: true,
      name: "fwf_flag_name_gate_target_idx"
=======
      add(:id, :binary_id, primary_key: true)
      add(:flag_name, :string, null: false)
      add(:gate_type, :string, null: false)
      add(:target, :string, null: false)
      add(:enabled, :boolean, null: false)
    end

    create(
      index(
        :fun_with_flags_toggles,
        [:flag_name, :gate_type, :target],
        unique: true,
        name: "fwf_flag_name_gate_target_idx"
      )
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
    )
  end

  def down do
<<<<<<< HEAD
    drop table(:fun_with_flags_toggles)
=======
    drop(table(:fun_with_flags_toggles))
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  end
end
