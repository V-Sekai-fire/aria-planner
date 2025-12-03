defmodule AriaPlanner.Repo.Migrations.CreatePlansTable do
  use Ecto.Migration

  def change do
    create table(:plans, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :persona_id, :string, null: false
      add :domain_type, :string, null: false
      add :objectives, :text
      add :constraints, :text
      add :temporal_constraints, :text
      add :entity_capabilities, :text
      add :solution_graph_data, :text
      add :solution_plan, :string, default: "[]"
      add :planning_timestamp, :naive_datetime_usec
      add :planning_duration_ms, :integer
      add :planner_state_snapshot, :string, default: "{}"
      add :execution_status, :string, default: "planned"
      add :execution_started_at, :naive_datetime_usec
      add :execution_completed_at, :naive_datetime_usec
      add :success_probability, :float, default: 0.0
      add :risk_assessment, :text
      add :performance_metrics, :text
      add :inserted_at, :naive_datetime_usec, null: false
      add :updated_at, :naive_datetime_usec, null: false
    end
  end
end
