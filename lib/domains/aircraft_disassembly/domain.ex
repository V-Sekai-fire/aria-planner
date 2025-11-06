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

  alias AriaPlanner.Domains.AircraftDisassembly.Predicates.{
    ActivityStart,
    ActivityDuration,
    ActivityStatus,
    Precedence,
    ResourceAssigned,
    LocationCapacity
  }

  @doc """
  Creates and registers the aircraft-disassembly planning domain.
  """
  @spec create_domain() :: {:ok, map()} | {:error, String.t()}
  def create_domain do
    case create_planning_domain() do
      {:ok, domain} ->
        domain = register_actions(domain)
        domain = register_task_methods(domain)
        domain = register_goal_methods(domain)
        {:ok, domain}

      error ->
        error
    end
  end

  @doc """
  Creates the base planning domain structure.
  """
  @spec create_planning_domain() :: {:ok, map()} | {:error, String.t()}
  def create_planning_domain do
    {:ok,
     %{
       type: "aircraft_disassembly",
       predicates: [
         "activity_start",
         "activity_duration",
         "activity_status",
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
          "activity_start[activity] = current_time"
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
          "activity_duration elapsed",
          "all required resources assigned"
        ],
        effects: [
          "activity_status[activity] = 'completed'"
        ]
      }
    ]

    Map.put(domain, :actions, actions)
  end

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
    try do
      num_activities = params.num_activities || params.nActs || 0
      num_resources = params.num_resources || params.nResources || 0
      durations = params.durations || params.dur || []
      precedences = params.precedences || []
      locations = params.locations || params.loc || []
      location_capacities = params.location_capacities || params.loc_cap || []

      # Initialize activity states
      activity_start = for activity <- 1..num_activities, into: %{} do
        {activity, 0}
      end

      activity_duration = for {activity, idx} <- Enum.with_index(1..num_activities, 0), into: %{} do
        duration = Enum.at(durations, idx, 0)
        {activity, duration}
      end

      activity_status = for activity <- 1..num_activities, into: %{} do
        {activity, "not_started"}
      end

      # Initialize precedence relationships
      precedence = for {pred, succ} <- precedences, into: %{} do
        key = {pred, succ}
        {key, true}
      end

      # Initialize resource assignments (all false initially)
      resource_assigned = for activity <- 1..num_activities,
                              resource <- 1..num_resources,
                              into: %{} do
        {{activity, resource}, false}
      end

      # Initialize location capacities
      location_capacity = for {location, idx} <- Enum.with_index(1..(length(location_capacities)), 0), into: %{} do
        capacity = Enum.at(location_capacities, idx, 1)
        {location, capacity}
      end

      state = %{
        num_activities: num_activities,
        durations: durations,
        precedences: precedences,
        num_resources: num_resources,
        locations: locations,
        num_locations: length(location_capacities),
        activity_start: activity_start,
        activity_duration: activity_duration,
        activity_status: activity_status,
        precedence: precedence,
        resource_assigned: resource_assigned,
        location_capacity: location_capacity,
        current_time: 0
      }

      {:ok, state}
    rescue
      e -> {:error, "Failed to initialize state: #{inspect(e)}"}
    end
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
    Enum.all?(1..state.num_activities, fn activity ->
      ActivityStatus.get(state, activity) == "completed"
    end)
  end

  @doc """
  Gets all predecessors of an activity.
  """
  @spec get_predecessors(state :: map(), activity :: integer()) :: [integer()]
  def get_predecessors(state, activity) do
    state.precedences
    |> Enum.filter(fn {_pred, succ} -> succ == activity end)
    |> Enum.map(fn {pred, _succ} -> pred end)
  end

  @doc """
  Gets all successors of an activity.
  """
  @spec get_successors(state :: map(), activity :: integer()) :: [integer()]
  def get_successors(state, activity) do
    state.precedences
    |> Enum.filter(fn {pred, _succ} -> pred == activity end)
    |> Enum.map(fn {_pred, succ} -> succ end)
  end

  @doc """
  Checks if all predecessors of an activity are completed.
  """
  @spec all_predecessors_completed?(state :: map(), activity :: integer()) :: boolean()
  def all_predecessors_completed?(state, activity) do
    predecessors = get_predecessors(state, activity)
    Enum.all?(predecessors, fn pred ->
      ActivityStatus.get(state, pred) == "completed"
    end)
  end
end

