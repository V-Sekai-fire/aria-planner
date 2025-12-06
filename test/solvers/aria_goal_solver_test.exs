# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaGoalSolverTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.PlannerMetadata
  alias AriaPlanner.Planner.EntityRequirement
  alias AriaPlanner.Planner.State
  alias AriaGoalSolver

  setup do
    # Define a sample state with entities, types, and capabilities
    initial_state =
      State.new()
      |> State.set_fact("type", "maya", "agent")
      |> State.set_fact("has_capability", "maya", ["cooking", "cleaning"])
      |> State.set_fact("type", "alex", "robot")
      |> State.set_fact("has_capability", "alex", ["lifting", "moving"])

    {:ok, initial_state: initial_state}
  end

  test "solve_goals returns success when required entity is available", %{initial_state: initial_state} do
    # Define a goal that requires an agent with cooking capability
    required_entity = %EntityRequirement{type: :agent, capabilities: [:cooking]}
    planner_metadata = %PlannerMetadata{duration: "PT1H", requires_entities: [required_entity]}

    # A dummy goal and domain for the solver
    goals = [{:task_done, true}]
    domain = %{predicates: [:task_done]}

    options = [planner_metadata: planner_metadata]

    assert {:ok, _solution} = AriaGoalSolver.solve_goals(domain, initial_state, goals, options)
  end

  test "solve_goals returns error when required entity is not available", %{initial_state: initial_state} do
    # Define a goal that requires an agent with a non-existent capability
    required_entity = %EntityRequirement{type: :agent, capabilities: [:flying]}
    planner_metadata = %PlannerMetadata{duration: "PT1H", requires_entities: [required_entity]}

    goals = [{:task_done, true}]
    domain = %{predicates: [:task_done]}

    options = [planner_metadata: planner_metadata]

    assert {:error, _reason} = AriaGoalSolver.solve_goals(domain, initial_state, goals, options)
  end

  test "solve_goals returns error when required entity type is not available", %{initial_state: initial_state} do
    # Define a goal that requires a non-existent entity type
    required_entity = %EntityRequirement{type: :dragon, capabilities: [:breathing_fire]}
    planner_metadata = %PlannerMetadata{duration: "PT1H", requires_entities: [required_entity]}

    goals = [{:task_done, true}]
    domain = %{predicates: [:task_done]}

    options = [planner_metadata: planner_metadata]

    assert {:error, _reason} = AriaGoalSolver.solve_goals(domain, initial_state, goals, options)
  end

  test "solve_goals returns success when multiple required capabilities are available", %{initial_state: initial_state} do
    # Define a goal that requires an agent with cooking and cleaning capabilities
    required_entity = %EntityRequirement{type: :agent, capabilities: [:cooking, :cleaning]}
    planner_metadata = %PlannerMetadata{duration: "PT1H", requires_entities: [required_entity]}

    goals = [{:task_done, true}]
    domain = %{predicates: [:task_done]}

    options = [planner_metadata: planner_metadata]

    assert {:ok, _solution} = AriaGoalSolver.solve_goals(domain, initial_state, goals, options)
  end

  test "solve_goals returns error when one of multiple required capabilities is missing", %{
    initial_state: initial_state
  } do
    # Define a goal that requires an agent with cooking and flying capabilities (flying is missing)
    required_entity = %EntityRequirement{type: :agent, capabilities: [:cooking, :flying]}
    planner_metadata = %PlannerMetadata{duration: "PT1H", requires_entities: [required_entity]}

    goals = [{:task_done, true}]
    domain = %{predicates: [:task_done]}

    options = [planner_metadata: planner_metadata]

    assert {:error, _reason} = AriaGoalSolver.solve_goals(domain, initial_state, goals, options)
  end
end
