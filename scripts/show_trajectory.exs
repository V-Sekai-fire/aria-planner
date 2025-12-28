# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Script to display locomotion trajectory data
# NOTE: Locomotion domain has been migrated to apps/patrol_solver
# This script needs to be updated to use PatrolSolver.Domains.Locomotion

Code.require_file("../../patrol_solver/lib/patrol_solver/domains/locomotion/domain.ex", __DIR__ <> "/../")
Code.require_file("../../patrol_solver/lib/patrol_solver/domains/locomotion/visualization/solution_tracker.ex", __DIR__ <> "/../")
Code.require_file("lib/core/plan.ex", __DIR__ <> "/../")

alias PatrolSolver.Domains.Locomotion
alias PatrolSolver.Domains.Locomotion.Visualization.SolutionTracker
alias AriaCore.Plan

require Logger
Logger.configure(level: :info)

IO.puts("=" <> String.duplicate("=", 80))
IO.puts("Locomotion Planning Domain - Solved Trajectory")
IO.puts("=" <> String.duplicate("=", 80))

# Step 1: Initialize locomotion domain
IO.puts("\n[1/3] Initializing locomotion domain...")
{:ok, _domain} = Locomotion.create_domain(100)
IO.puts("✓ Domain created with 100 Fibonacci sphere points")

# Step 2: Create initial state with entities and waypoints
IO.puts("\n[2/3] Creating initial state...")
initial_state_params = %{
  sphere_points: 100,
  entities: [
    %{
      id: "entity1",
      position: {0.0, 0.0, 0.0},
      rotation: %{x: 0.0, y: 0.0, z: 0.0, w: 1.0},
      speed: 2.0,
      movement_type: "walking"
    }
  ],
  waypoints: [
    %{id: "wp1", position_index: 10, rotation_index: 5},
    %{id: "wp2", position_index: 20, rotation_index: 15},
    %{id: "wp3", position_index: 30, rotation_index: 25}
  ]
}

{:ok, domain_state} = Locomotion.initialize_state(initial_state_params)
IO.puts("✓ State initialized with #{length(initial_state_params.entities)} entity and #{length(initial_state_params.waypoints)} waypoints")

# Step 3: Create a mock plan with solution graph
IO.puts("\n[3/3] Creating mock plan with solution graph...")
plan_attrs = %{
  name: "locomotion_navigation_test",
  persona_id: "test_persona",
  domain_type: "locomotion",
  objectives: [{"navigate_path", "entity1", ["wp1", "wp2", "wp3"]}],
  entity_capabilities: %{"entity1" => %{speed: 2.0, movement_type: "walking"}}
}

{:ok, plan} = Plan.create(plan_attrs)

# Create mock solution graph with navigation actions
solution_graph = %{
  0 => %{info: {:root}, type: :D, status: :NA, successors: [1]},
  1 => %{
    info: {"c_move_to", "entity1", 10},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:00Z],
    end_time: ~U[2025-01-01 10:00:05Z],
    duration: 5000
  },
  2 => %{
    info: {"c_rotate_to", "entity1", 5},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:05Z],
    end_time: ~U[2025-01-01 10:00:05.5Z],
    duration: 500
  },
  3 => %{
    info: {"c_mark_waypoint_reached", "entity1", "wp1"},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:05.5Z],
    end_time: ~U[2025-01-01 10:00:05.5Z],
    duration: 0
  },
  4 => %{
    info: {"c_move_to", "entity1", 20},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:05.5Z],
    end_time: ~U[2025-01-01 10:00:10.5Z],
    duration: 5000
  },
  5 => %{
    info: {"c_rotate_to", "entity1", 15},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:10.5Z],
    end_time: ~U[2025-01-01 10:00:11Z],
    duration: 500
  },
  6 => %{
    info: {"c_mark_waypoint_reached", "entity1", "wp2"},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:11Z],
    end_time: ~U[2025-01-01 10:00:11Z],
    duration: 0
  },
  7 => %{
    info: {"c_move_to", "entity1", 30},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:11Z],
    end_time: ~U[2025-01-01 10:00:16Z],
    duration: 5000
  },
  8 => %{
    info: {"c_rotate_to", "entity1", 25},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:16Z],
    end_time: ~U[2025-01-01 10:00:16.5Z],
    duration: 500
  },
  9 => %{
    info: {"c_mark_waypoint_reached", "entity1", "wp3"},
    type: :A,
    status: :C,
    start_time: ~U[2025-01-01 10:00:16.5Z],
    end_time: ~U[2025-01-01 10:00:16.5Z],
    duration: 0
  }
}

plan_with_graph = Map.put(plan, :solution_graph_data, solution_graph)
IO.puts("✓ Plan created with #{map_size(solution_graph)} solution nodes")

# Track trajectory
IO.puts("\n" <> String.duplicate("-", 80))
IO.puts("TRACKING TRAJECTORY")
IO.puts(String.duplicate("-", 80))

trajectory = case SolutionTracker.track_trajectory(plan_with_graph, domain_state) do
  {:ok, traj} ->
    IO.puts("✓ Tracked #{length(traj)} trajectory steps")
    IO.puts("  Total time: #{traj |> List.last() |> Map.get(:time, 0.0) |> :erlang.float_to_binary(decimals: 2)}s")
    traj

  {:error, reason} ->
    IO.puts("✗ Failed to track trajectory: #{reason}")
    System.halt(1)
end

# Display trajectory
IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("TRAJECTORY DATA")
IO.puts(String.duplicate("=", 80))

Enum.each(trajectory, fn step ->
  IO.puts("\n--- Step #{step.step} (Time: #{:erlang.float_to_binary(step.time, decimals: 2)}s) ---")
  
  IO.puts("\nEntities:")
  Enum.each(step.entities, fn entity ->
    {px, py, pz} = entity.position
    {rx, ry, rz} = entity.rotation
    IO.puts("  #{entity.id}:")
    IO.puts("    Position: (#{:erlang.float_to_binary(px, decimals: 3)}, #{:erlang.float_to_binary(py, decimals: 3)}, #{:erlang.float_to_binary(pz, decimals: 3)}) [index: #{entity.position_index}]")
    IO.puts("    Rotation: (#{:erlang.float_to_binary(rx, decimals: 3)}, #{:erlang.float_to_binary(ry, decimals: 3)}, #{:erlang.float_to_binary(rz, decimals: 3)}) [index: #{entity.rotation_index}]")
    IO.puts("    Speed: #{:erlang.float_to_binary(entity.speed, decimals: 1)} m/s, Type: #{entity.movement_type}")
  end)
  
  IO.puts("\nWaypoints:")
  Enum.each(step.waypoints, fn waypoint ->
    {px, py, pz} = waypoint.position
    {rx, ry, rz} = waypoint.rotation
    reached_status = if length(waypoint.reached_by) > 0, do: "✓ REACHED by #{Enum.join(waypoint.reached_by, ", ")}", else: "○ NOT REACHED"
    IO.puts("  #{waypoint.id}:")
    IO.puts("    Position: (#{:erlang.float_to_binary(px, decimals: 3)}, #{:erlang.float_to_binary(py, decimals: 3)}, #{:erlang.float_to_binary(pz, decimals: 3)}) [index: #{waypoint.position_index}]")
    IO.puts("    Rotation: (#{:erlang.float_to_binary(rx, decimals: 3)}, #{:erlang.float_to_binary(ry, decimals: 3)}, #{:erlang.float_to_binary(rz, decimals: 3)}) [index: #{waypoint.rotation_index}]")
    IO.puts("    Status: #{reached_status}")
  end)
end)

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 80))
IO.puts("Total Steps: #{length(trajectory)}")
IO.puts("Total Time: #{trajectory |> List.last() |> Map.get(:time, 0.0) |> :erlang.float_to_binary(decimals: 2)}s")
IO.puts("Entities: #{trajectory |> List.first() |> Map.get(:entities, []) |> length()}")
IO.puts("Waypoints: #{trajectory |> List.first() |> Map.get(:waypoints, []) |> length()}")

# Show path summary
if length(trajectory) > 0 do
  first_step = List.first(trajectory)
  last_step = List.last(trajectory)
  
  if length(first_step.entities) > 0 do
    first_entity = List.first(first_step.entities)
    last_entity = List.first(last_step.entities)
    {fx, fy, fz} = first_entity.position
    {lx, ly, lz} = last_entity.position
    
    distance = :math.sqrt((lx - fx) * (lx - fx) + (ly - fy) * (ly - fy) + (lz - fz) * (lz - fz))
    IO.puts("\nEntity Path:")
    IO.puts("  Start: (#{:erlang.float_to_binary(fx, decimals: 3)}, #{:erlang.float_to_binary(fy, decimals: 3)}, #{:erlang.float_to_binary(fz, decimals: 3)})")
    IO.puts("  End:   (#{:erlang.float_to_binary(lx, decimals: 3)}, #{:erlang.float_to_binary(ly, decimals: 3)}, #{:erlang.float_to_binary(lz, decimals: 3)})")
    IO.puts("  Distance: #{:erlang.float_to_binary(distance, decimals: 3)} units")
  end
end

IO.puts("\n" <> String.duplicate("=", 80))

