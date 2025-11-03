# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

  defmodule AriaPlanner.Domains.PertPlanner do
  @moduledoc """
  PERT (Program Evaluation and Review Technique) planning domain.

  This module implements a PERT planner for project management with tasks,
  dependencies, durations, and critical path analysis.

  The domain includes:
  - Predicates: task_duration, task_dependency, task_status, task_earliest_start, etc.
  - Actions: add_task, add_dependency, start_task, complete_task, calculate_schedule
  - Methods: plan_project, schedule_tasks, critical_path
  """

  # Aliases for commands
  require AriaPlanner.Domains.PertPlanner.Commands.AddTask
  require AriaPlanner.Domains.PertPlanner.Commands.AddDependency
  require AriaPlanner.Domains.PertPlanner.Commands.StartTask
  require AriaPlanner.Domains.PertPlanner.Commands.CompleteTask
  require AriaPlanner.Domains.PertPlanner.Commands.CalculateSchedule
  require AriaPlanner.Domains.PertPlanner.Commands.CreateTaskDuration
  require AriaPlanner.Domains.PertPlanner.Commands.CreateTaskDependency
  require AriaPlanner.Domains.PertPlanner.Commands.CreateTaskStatus
  require AriaPlanner.Domains.PertPlanner.Commands.CreateAtom

  require AriaPlanner.Domains.BlocksWorld.Predicates.Atom

  alias AriaPlanner.Repo

  @doc """
  Creates and registers the PERT planning domain.

  This function sets up the domain with all actions, methods, and goal methods.
  """
  @spec create_domain() :: {:ok, map()} | {:error, String.t()}
  def create_domain do
    # Create the domain
    case create_planning_domain() do
      {:ok, domain} ->
        # Register actions
        domain = register_actions(domain)
        # Register task-based methods
        domain = register_task_methods(domain)
        # Register goal-based methods
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
       type: "pert_planner",
       predicates: [
         "task_duration",
         "task_dependency",
         "task_status",
         "task_earliest_start",
         "task_latest_start",
         "task_earliest_finish",
         "task_latest_finish",
         "task_slack"
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
        name: "add_task",
        arity: 2,
        preconditions: [],
        effects: ["task_duration[task_id] = duration", "task_status[task_id] = 'not_started'"]
      },
      %{
        name: "add_dependency",
        arity: 2,
        preconditions: ["task_duration[predecessor] != nil", "task_duration[successor] != nil"],
        effects: ["task_dependency[predecessor] = successor"]
      },
      %{
        name: "start_task",
        arity: 1,
        preconditions: ["task_status[task_id] == 'not_started'"],
        effects: ["task_status[task_id] = 'in_progress'"]
      },
      %{
        name: "complete_task",
        arity: 1,
        preconditions: ["task_status[task_id] == 'in_progress'"],
        effects: ["task_status[task_id] = 'completed'"]
      },
      %{
        name: "calculate_schedule",
        arity: 0,
        preconditions: [],
        effects: ["task_earliest_start[*] = calculated", "task_latest_finish[*] = calculated"]
      }
    ]

    Map.put(domain, :actions, actions)
  end

  defp register_task_methods(domain) do
    methods = [
      %{
        name: "plan_project",
        type: "task",
        arity: 0,
        decomposition: "schedule all tasks and ensure completion"
      },
      %{
        name: "schedule_tasks",
        type: "task",
        arity: 0,
        decomposition: "calculate earliest and latest start/finish times"
      },
      %{
        name: "critical_path",
        type: "task",
        arity: 0,
        decomposition: "identify tasks on the critical path"
      }
    ]

    Map.update(domain, :methods, methods, &(&1 ++ methods))
  end

  defp register_goal_methods(domain) do
    goal_methods = [
      %{
        name: "project_completed",
        type: "multigoal",
        arity: 0,
        predicate: "task_status",
        decomposition: "all tasks completed"
      },
      %{
        name: "gm_schedule_task",
        type: "goal",
        arity: 1,
        predicate: "task_earliest_start",
        decomposition: "schedule individual task"
      },
      %{
        name: "gm_complete_task",
        type: "goal",
        arity: 1,
        predicate: "task_status",
        decomposition: "ensure task is completed"
      }
    ]

    Map.update(domain, :goal_methods, goal_methods, &(&1 ++ goal_methods))
  end

  @doc """
  Initializes the PERT project state with given tasks.

  Creates initial task facts for all tasks.
  """
  @spec initialize_project(tasks :: [%{id: String.t(), duration: integer()}], dependencies :: [%{predecessor: String.t(), successor: String.t()}]) :: {:ok, map()} | {:error, String.t()}
  def initialize_project(tasks, dependencies) when is_list(tasks) and is_list(dependencies) do
    alias AriaPlanner.Domains.PertPlanner.Predicates.{TaskDuration, TaskDependency, TaskStatus}
    alias AriaPlanner.Repo

    try do
      # Create task duration facts
      Enum.each(tasks, fn %{id: id, duration: duration} ->
        TaskDuration.create(%{task_id: id, duration: duration})
        TaskStatus.create(%{task_id: id, status: "not_started"})
      end)

      # Create dependency facts
      Enum.each(dependencies, fn %{predecessor: pred, successor: succ} ->
        TaskDependency.create(%{predecessor: pred, successor: succ})
      end)

      {:ok, %{tasks: tasks, dependencies: dependencies, initialized: true}}
    rescue
      e ->
        {:error, "Failed to initialize project: #{inspect(e)}"}
    end
  end

  @doc """
  Gets the current state of the project.
  """
  @spec get_project_state() :: {:ok, map()} | {:error, String.t()}
  def get_project_state do
    alias AriaPlanner.Domains.PertPlanner.Predicates.{TaskDuration, TaskDependency, TaskStatus}
    alias AriaPlanner.Repo

    try do
      durations = Repo.all(TaskDuration) |> Map.new(&{&1.task_id, &1.duration})
      dependencies = Repo.all(TaskDependency) |> Enum.group_by(& &1.successor, & &1.predecessor)
      statuses = Repo.all(TaskStatus) |> Map.new(&{&1.task_id, &1.status})

      state = %{
        durations: durations,
        dependencies: dependencies,
        statuses: statuses
      }

      {:ok, state}
    rescue
      e ->
        {:error, "Failed to get project state: #{inspect(e)}"}
    end
  end

  @doc """
  Resets the PERT project state (clears all facts).
  """
  @spec reset_project() :: {:ok, String.t()} | {:error, String.t()}
  def reset_project do
    alias AriaPlanner.Domains.PertPlanner.Predicates.{TaskDuration, TaskDependency, TaskStatus}
    alias AriaPlanner.Repo

    try do
      Repo.delete_all(TaskDuration)
      Repo.delete_all(TaskDependency)
      Repo.delete_all(TaskStatus)
      {:ok, "Project reset successfully"}
    rescue
      e ->
        {:error, "Failed to reset project: #{inspect(e)}"}
    end
  end

  @doc """
  Calculates the PERT schedule including earliest/latest times and critical path.
  """
  @spec calculate_schedule() :: {:ok, map()} | {:error, String.t()}
  def calculate_schedule do
    with {:ok, state} <- get_project_state() do
      # Forward pass: calculate earliest start/finish
      earliest_times = forward_pass(state)

      # Backward pass: calculate latest start/finish
      latest_times = backward_pass(state, earliest_times)

      # Calculate slack and critical path
      slack_and_critical = calculate_slack_and_critical(earliest_times, latest_times)

      {:ok, %{
        earliest_times: earliest_times,
        latest_times: latest_times,
        slack: slack_and_critical.slack,
        critical_path: slack_and_critical.critical_path
      }}
    end
  end

  defp forward_pass(state) do
    # Forward pass: Calculate earliest start and finish times
    # Uses backtracking-driven approach: if predecessor not scheduled, planner backtracks
    durations = state.durations
    dependencies = state.dependencies
    task_ids = Map.keys(durations)

    # Initialize earliest times for all tasks
    earliest_times =
      task_ids
      |> Enum.reduce(%{}, fn task_id, acc ->
        Map.put(acc, task_id, %{es: 0, ef: 0})
      end)

    # Calculate earliest times with dependency resolution
    calculate_earliest_times(task_ids, durations, dependencies, earliest_times)
  end

  defp backward_pass(state, earliest_times) do
    # Backward pass: Calculate latest start and finish times
    # Uses backtracking-driven approach: if successor not scheduled, planner backtracks
    durations = state.durations
    dependencies = state.dependencies
    task_ids = Map.keys(durations)

    # Find project end time (max EF)
    project_end =
      earliest_times
      |> Enum.map(fn {_task_id, times} -> times.ef end)
      |> Enum.max(fn -> 0 end)

    # Initialize latest times (all tasks can finish by project end)
    latest_times =
      task_ids
      |> Enum.reduce(%{}, fn task_id, acc ->
        Map.put(acc, task_id, %{ls: project_end, lf: project_end})
      end)

    # Calculate latest times with dependency resolution
    calculate_latest_times(task_ids, durations, dependencies, latest_times, project_end)
  end

  defp calculate_slack_and_critical(earliest_times, latest_times) do
    # Calculate slack for each task and identify critical path
    slack =
      earliest_times
      |> Enum.reduce(%{}, fn {task_id, es_ef}, acc ->
        ls_lf = Map.get(latest_times, task_id, %{ls: 0, lf: 0})
        task_slack = ls_lf.lf - es_ef.ef
        Map.put(acc, task_id, task_slack)
      end)

    # Critical path: tasks with zero slack
    critical_path =
      slack
      |> Enum.filter(fn {_task_id, slack_value} -> slack_value == 0 end)
      |> Enum.map(fn {task_id, _} -> task_id end)

    %{slack: slack, critical_path: critical_path}
  end

  # Helper: Calculate earliest times for all tasks
  # Planner backtracks if predecessor not yet scheduled
  defp calculate_earliest_times(task_ids, durations, dependencies, earliest_times) do
    Enum.reduce(task_ids, earliest_times, fn task_id, acc ->
      duration = Map.get(durations, task_id, 0)

      # Get predecessors for this task
      predecessors =
        dependencies
        |> Enum.filter(fn {_pred, succ} -> succ == task_id end)
        |> Enum.map(fn {pred, _succ} -> pred end)

      # Calculate ES: max(EF of all predecessors), or 0 if no predecessors
      es =
        if Enum.empty?(predecessors) do
          0
        else
          predecessors
          |> Enum.map(fn pred ->
            case Map.get(acc, pred) do
              %{ef: ef} -> ef
              _ -> 0  # If predecessor not yet calculated, use 0 (planner will backtrack)
            end
          end)
          |> Enum.max(fn -> 0 end)
        end

      # Calculate EF: ES + Duration
      ef = es + duration

      Map.put(acc, task_id, %{es: es, ef: ef})
    end)
  end

  # Helper: Calculate latest times for all tasks
  # Planner backtracks if successor not yet scheduled
  defp calculate_latest_times(task_ids, durations, dependencies, latest_times, project_end) do
    Enum.reduce(task_ids, latest_times, fn task_id, acc ->
      duration = Map.get(durations, task_id, 0)

      # Get successors for this task
      successors =
        dependencies
        |> Enum.filter(fn {pred, _succ} -> pred == task_id end)
        |> Enum.map(fn {_pred, succ} -> succ end)

      # Calculate LF: min(LS of all successors), or project_end if no successors
      lf =
        if Enum.empty?(successors) do
          project_end
        else
          successors
          |> Enum.map(fn succ ->
            case Map.get(acc, succ) do
              %{ls: ls} -> ls
              _ -> project_end  # If successor not yet calculated, use project_end (planner will backtrack)
            end
          end)
          |> Enum.min(fn -> project_end end)
        end

      # Calculate LS: LF - Duration
      ls = lf - duration

      Map.put(acc, task_id, %{ls: ls, lf: lf})
    end)
  end

  @doc """
  Handles domain-specific commands for PertPlanner.
  """
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.AddTask{} = command) do
    AriaPlanner.Domains.PertPlanner.Commands.AddTask.c_add_task(command.task, command.duration)
  end
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.AddDependency{} = command) do
    AriaPlanner.Domains.PertPlanner.Commands.AddDependency.c_add_dependency(command.predecessor, command.successor)
  end
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.StartTask{} = command) do
    AriaPlanner.Domains.PertPlanner.Commands.StartTask.c_start_task(command.task)
  end
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.CompleteTask{} = command) do
    AriaPlanner.Domains.PertPlanner.Commands.CompleteTask.c_complete_task(command.task)
  end
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.CalculateSchedule{} = _command) do
    AriaPlanner.Domains.PertPlanner.Commands.CalculateSchedule.c_calculate_schedule()
  end

  # Placeholders for new state creation commands which will be defined next
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.CreateTaskDuration{} = command) do
    AriaPlanner.Domains.PertPlanner.Commands.CreateTaskDuration.c_create_task_duration(command.task, command.duration)
  end
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.CreateTaskDependency{} = command) do
    AriaPlanner.Domains.PertPlanner.Commands.CreateTaskDependency.c_create_task_dependency(command.predecessor, command.successor)
  end
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.CreateTaskStatus{} = command) do
    AriaPlanner.Domains.PertPlanner.Commands.CreateTaskStatus.c_create_task_status(command.task, command.status)
  end
  def handle_command(%AriaPlanner.Domains.PertPlanner.Commands.CreateAtom{} = command) do
    AriaPlanner.Domains.PertPlanner.Commands.CreateAtom.c_create_atom(command.name)
  end

  def handle_command(command) do
    {:error, "Unknown command: #{inspect(command)}"}
  end
end
