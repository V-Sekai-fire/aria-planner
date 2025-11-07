# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly do
  @moduledoc """
  Aircraft Disassembly planning domain.
  
  This domain models aircraft disassembly scheduling with:
  - Activities (tasks) with durations
  - Precedence constraints (predecessor/successor relationships)
  - Resource assignment with skill requirements
  - Location capacity constraints
  - Goal: Schedule all activities respecting precedence and resource constraints
  """


  @doc """
  Creates and registers the aircraft-disassembly planning domain.
  """
  @spec create_domain() :: {:ok, map()}
  def create_domain do
    {:ok, domain} = create_planning_domain()
    domain = register_actions(domain)
    domain = register_task_methods(domain)
    domain = register_goal_methods(domain)
    {:ok, domain}
  end

  @doc """
  Creates the base planning domain structure.
  """
  @spec create_planning_domain() :: {:ok, map()}
  def create_planning_domain do
    {:ok,
     %{
       type: "aircraft_disassembly",
       predicates: [
         "activity_status",  # Uses planner's state facts system
         "precedence",
         "resource_assigned",
         "location_capacity"
       ],
       actions: [],
       methods: [],
       goal_methods: [],
       created_at: DateTime.utc_now()
     }}
  end

  @spec register_actions(map()) :: map()
  defp register_actions(domain) do
    actions = [
      %{
        name: "a_start_activity",
        arity: 2,
        preconditions: [
          "activity_status[activity] == 'not_started'",
          "all predecessors completed",
          "sufficient resources available"
        ],
        effects: [
          "activity_status[activity] = 'in_progress'",
          "temporal constraints set via PlannerMetadata"
        ]
      },
      %{
        name: "a_assign_resource",
        arity: 2,
        preconditions: [
          "resource has required skills",
          "resource is available",
          "location capacity not exceeded"
        ],
        effects: [
          "resource_assigned[activity, resource] = true"
        ]
      },
      %{
        name: "a_complete_activity",
        arity: 1,
        preconditions: [
          "activity_status[activity] == 'in_progress'",
          "temporal duration elapsed (via PlannerMetadata)",
          "all required resources assigned"
        ],
        effects: [
          "activity_status[activity] = 'completed'"
        ]
      }
    ]

    Map.put(domain, :actions, actions)
  end

  @spec register_task_methods(map()) :: map()
  defp register_task_methods(domain) do
    methods = [
      %{
        name: "schedule_activities",
        type: "task",
        arity: 1,
        decomposition: "schedule all activities respecting precedence constraints"
      }
    ]

    Map.update(domain, :methods, methods, &(&1 ++ methods))
  end

  @spec register_goal_methods(map()) :: map()
  defp register_goal_methods(domain) do
    goal_methods = [
      %{
        name: "schedule_activities",
        type: "multigoal",
        arity: 1,
        predicate: nil,
        decomposition: "schedule all activities (goal-based)"
      }
    ]

    Map.update(domain, :goal_methods, goal_methods, &(&1 ++ goal_methods))
  end

  @doc """
  Initializes the aircraft disassembly state with given parameters.
  """
  @spec initialize_state(params :: map()) :: {:ok, map()} | {:error, String.t()}
  def initialize_state(params) do
    alias AriaPlanner.Domains.AircraftDisassembly.StateInitialization
    StateInitialization.initialize_state(params)
  end

  @doc """
  Parses a MiniZinc .dzn data file for aircraft disassembly.
  """
  @spec parse_dzn_file(path :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse_dzn_file(path) do
    alias AriaPlanner.Domains.AircraftDisassembly.DznParser
    DznParser.parse_file(path)
  end

  @doc """
  Checks if all activities are completed.
  """
  @spec all_activities_completed?(state :: map()) :: boolean()
  def all_activities_completed?(state) do
    alias AriaPlanner.Domains.AircraftDisassembly.StateHelpers
    StateHelpers.all_activities_completed?(state)
  end

  @doc """
  Gets all predecessors of an activity.
  """
  @spec get_predecessors(state :: map(), activity :: integer()) :: [integer()]
  def get_predecessors(state, activity) do
    alias AriaPlanner.Domains.AircraftDisassembly.StateHelpers
    StateHelpers.get_predecessors(state, activity)
  end

  @doc """
  Gets all successors of an activity.
  """
  @spec get_successors(state :: map(), activity :: integer()) :: [integer()]
  def get_successors(state, activity) do
    alias AriaPlanner.Domains.AircraftDisassembly.StateHelpers
    StateHelpers.get_successors(state, activity)
  end

  @doc """
  Checks if all predecessors of an activity are completed.
  """
  @spec all_predecessors_completed?(state :: map(), activity :: integer()) :: boolean()
  def all_predecessors_completed?(state, activity) do
    alias AriaPlanner.Domains.AircraftDisassembly.StateHelpers
    StateHelpers.all_predecessors_completed?(state, activity)
  end
end

