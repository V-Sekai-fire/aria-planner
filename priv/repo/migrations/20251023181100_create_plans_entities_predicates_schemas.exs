# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo.Migrations.CreatePlannerSchemas do
  use Ecto.Migration

  def change do
    create table(:plans, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :persona_id, :string, null: false
      add :domain_type, :string, null: false
      add :objectives, {:array, :string}, default: []
      add :constraints, :map, default: %{}
      add :temporal_constraints, :map, default: %{}
      add :entity_capabilities, :map, default: %{}
      add :solution_graph_data, :map, default: %{}
      add :solution_plan, :string, default: "[]"
      add :planning_timestamp, :naive_datetime
      add :planning_duration_ms, :integer
      add :planner_state_snapshot, :string, default: "{}"
      add :execution_status, :string, default: "planned"
      add :execution_started_at, :naive_datetime
      add :execution_completed_at, :naive_datetime

      add :success_probability, :float, default: 0.0
      add :risk_assessment, :map, default: %{}
      add :performance_metrics, :map, default: %{}

      timestamps(type: :naive_datetime)
    end

    create index(:plans, [:persona_id])
    create index(:plans, [:domain_type])
    create index(:plans, [:execution_status])

    create table(:entities, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :type, :string, null: false
      add :active, :boolean, default: true
      add :properties, :map, default: %{}

      timestamps(type: :naive_datetime)
    end

    create index(:entities, [:type])
    create index(:entities, [:active])

    create table(:predicates, primary_key: false) do
      add :id, :string, primary_key: true
      add :category, :string, null: false
      add :name, :string, null: false
      add :entity_id, :string, null: false
      add :value, :string, null: false # Store all values as strings for flexibility

      timestamps(type: :naive_datetime)
    end

    create index(:predicates, [:category])
    create index(:predicates, [:name])
    create index(:predicates, [:entity_id])

    # Blocks World specific predicates
    create table(:blocks_world_pos, primary_key: false) do
      add :entity_id, :string, primary_key: true
      add :value, :string, null: false
      timestamps(type: :naive_datetime)
    end

    create table(:blocks_world_clear, primary_key: false) do
      add :entity_id, :string, primary_key: true
      add :value, :boolean, null: false
      timestamps(type: :naive_datetime)
    end

    create table(:blocks_world_holding, primary_key: false) do
      add :entity_id, :string, primary_key: true
      add :value, :string, null: false
      timestamps(type: :naive_datetime)
    end
  end
end
