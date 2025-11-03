# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlannerTest do
  use ExUnit.Case, async: true
  doctest AriaPlanner.Domains.PertPlanner

  alias AriaPlanner.Domains.PertPlanner
  alias AriaPlanner.Domains.PertPlanner.Predicates.{TaskDuration, TaskDependency, TaskStatus}
  alias AriaPlanner.Domains.PertPlanner.Commands.{AddTask, AddDependency, StartTask, CompleteTask}
  alias AriaPlanner.Domains.PertPlanner.Tasks.{PlanProject, ScheduleTasks, CompleteAllTasks, CompleteTask}
  alias AriaPlanner.Domains.PertPlanner.Unigoals.{GmScheduleTask, GmCompleteTask}
  alias AriaPlanner.Repo
  alias AriaCore.Plan
  alias Jason
  alias MCP.AriaForge.ToolHandlers

  setup do
    :ok
  end

  describe "domain creation" do
    test "creates planning domain with correct structure" do
      {:ok, domain} = PertPlanner.create_domain()

      assert domain.type == "pert_planner"
      assert "task_duration" in domain.predicates
      assert "task_dependency" in domain.predicates
      assert "task_status" in domain.predicates
      assert length(domain.actions) == 5
      assert length(domain.methods) == 3
      assert length(domain.goal_methods) == 3
    end

    test "domain has all required actions" do
      {:ok, domain} = PertPlanner.create_domain()
      action_names = Enum.map(domain.actions, & &1.name)

      assert "add_task" in action_names
      assert "add_dependency" in action_names
      assert "start_task" in action_names
      assert "complete_task" in action_names
      assert "calculate_schedule" in action_names
    end

    test "domain has all required task methods" do
      {:ok, domain} = PertPlanner.create_domain()
      method_names = Enum.map(domain.methods, & &1.name)

      assert "plan_project" in method_names
      assert "schedule_tasks" in method_names
      assert "critical_path" in method_names
    end

    test "domain has all required goal methods" do
      {:ok, domain} = PertPlanner.create_domain()
      goal_method_names = Enum.map(domain.goal_methods, & &1.name)

      assert "project_completed" in goal_method_names
      assert "gm_schedule_task" in goal_method_names
      assert "gm_complete_task" in goal_method_names
    end
  end

  describe "state initialization" do
    test "initializes project with tasks and dependencies" do
      tasks = [
        %{id: "task_a", duration: 5},
        %{id: "task_b", duration: 3},
        %{id: "task_c", duration: 4}
      ]
      dependencies = [
        %{predecessor: "task_a", successor: "task_b"},
        %{predecessor: "task_a", successor: "task_c"}
      ]

      {:ok, result} = PertPlanner.initialize_project(tasks, dependencies)

      assert result.initialized == true
      assert length(result.tasks) == 3
      assert length(result.dependencies) == 2

      # Verify duration facts
      duration_facts = Repo.all(TaskDuration)
      assert length(duration_facts) == 3

      # Verify status facts
      status_facts = Repo.all(TaskStatus)
      assert length(status_facts) == 3
      Enum.each(status_facts, fn fact -> assert fact.status == "not_started" end)

      # Verify dependency facts
      dependency_facts = Repo.all(TaskDependency)
      assert length(dependency_facts) == 2
    end

    test "get_project_state returns current state" do
      tasks = [
        %{id: "task_a", duration: 5},
        %{id: "task_b", duration: 3}
      ]
      dependencies = [%{predecessor: "task_a", successor: "task_b"}]

      PertPlanner.initialize_project(tasks, dependencies)

      {:ok, state} = PertPlanner.get_project_state()

      assert state.durations["task_a"] == 5
      assert state.durations["task_b"] == 3
      assert state.statuses["task_a"] == "not_started"
      assert state.statuses["task_b"] == "not_started"
      assert "task_a" in state.dependencies["task_b"]
    end

    test "reset_project clears all facts" do
      tasks = [%{id: "task_a", duration: 5}]
      PertPlanner.initialize_project(tasks, [])

      {:ok, _} = PertPlanner.reset_project()

      assert Repo.all(TaskDuration) == []
      assert Repo.all(TaskStatus) == []
      assert Repo.all(TaskDependency) == []
    end
  end

  describe "actions" do
    setup do
      PertPlanner.reset_project()
      :ok
    end

    test "add_task creates task with duration and status" do
      {:ok, result} = AddTask.execute("task_a", 5)

      assert result.task_id == "task_a"
      assert result.duration == 5
      assert result.status == "not_started"

      # Verify facts created
      assert Repo.get_by(TaskDuration, task_id: "task_a")
      assert Repo.get_by(TaskStatus, task_id: "task_a")
    end

    test "start_task changes status to in_progress" do
      AddTask.execute("task_a", 5)
      {:ok, result} = StartTask.execute("task_a")

      assert result.task_id == "task_a"
      assert result.status == "in_progress"

      # Verify status changed
      task_status = Repo.get_by(TaskStatus, task_id: "task_a")
      assert task_status.status == "in_progress"
    end

    test "complete_task changes status to completed" do
      AddTask.execute("task_a", 5)
      StartTask.execute("task_a")
      {:ok, result} = CompleteTask.execute("task_a")

      assert result.task_id == "task_a"
      assert result.status == "completed"

      # Verify status changed
      task_status = Repo.get_by(TaskStatus, task_id: "task_a")
      assert task_status.status == "completed"
    end
  end

  describe "task methods" do
    setup do
      PertPlanner.reset_project()
      :ok
    end

    test "plan_project decomposes into schedule and complete tasks" do
      subtasks = PlanProject.t_plan_project()

      assert length(subtasks) == 2
      assert Enum.at(subtasks, 0) == {"t_schedule_tasks"}
      assert Enum.at(subtasks, 1) == {"t_complete_all_tasks"}
    end

    test "schedule_tasks triggers schedule calculation" do
      subtasks = ScheduleTasks.t_schedule_tasks()

      assert length(subtasks) == 1
      assert Enum.at(subtasks, 0) == {"calculate_schedule"}
    end

    test "complete_all_tasks generates subtasks for all tasks" do
      tasks = [
        %{id: "task_a", duration: 5},
        %{id: "task_b", duration: 3}
      ]
      PertPlanner.initialize_project(tasks, [])

      subtasks = CompleteAllTasks.t_complete_all_tasks()

      assert length(subtasks) == 2
      task_ids = Enum.map(subtasks, fn {_, id} -> id end)
      assert "task_a" in task_ids
      assert "task_b" in task_ids
    end
  end

  describe "unigoal methods" do
    setup do
      PertPlanner.reset_project()
      :ok
    end

    test "gm_schedule_task returns goal for task scheduling" do
      AddTask.execute("task_a", 5)

      goals = GmScheduleTask.gm_schedule_task("task_a")

      assert is_list(goals)
      assert length(goals) == 1
      assert Enum.at(goals, 0) == {"task_earliest_start", "task_a", :calculated}
    end

    test "gm_complete_task returns nil if predecessors not completed" do
      tasks = [
        %{id: "task_a", duration: 5},
        %{id: "task_b", duration: 3}
      ]
      dependencies = [%{predecessor: "task_a", successor: "task_b"}]
      PertPlanner.initialize_project(tasks, dependencies)

      # task_b depends on task_a, which is not completed
      result = GmCompleteTask.gm_complete_task("task_b")

      assert result == nil
    end

    test "gm_complete_task returns goals when predecessors completed" do
      tasks = [
        %{id: "task_a", duration: 5},
        %{id: "task_b", duration: 3}
      ]
      dependencies = [%{predecessor: "task_a", successor: "task_b"}]
      PertPlanner.initialize_project(tasks, dependencies)

      # Complete task_a first
      StartTask.execute("task_a")
      CompleteTask.execute("task_a")

      # Now task_b can be completed
      goals = GmCompleteTask.gm_complete_task("task_b")

      assert is_list(goals)
      assert length(goals) == 2
    end
  end

  describe "complex job shop scheduling scenario" do
    test "plans a job shop scheduling problem with multiple jobs and machines" do
      # Job Shop Problem: 3 jobs, 3 machines
      # Job 1: Machine A (5s) -> Machine B (3s) -> Machine C (2s)
      # Job 2: Machine B (4s) -> Machine A (2s) -> Machine C (3s)
      # Job 3: Machine C (3s) -> Machine B (2s) -> Machine A (4s)

      tasks = [
        # Job 1 tasks
        %{id: "job1_machine_a", duration: 5},
        %{id: "job1_machine_b", duration: 3},
        %{id: "job1_machine_c", duration: 2},
        # Job 2 tasks
        %{id: "job2_machine_b", duration: 4},
        %{id: "job2_machine_a", duration: 2},
        %{id: "job2_machine_c", duration: 3},
        # Job 3 tasks
        %{id: "job3_machine_c", duration: 3},
        %{id: "job3_machine_b", duration: 2},
        %{id: "job3_machine_a", duration: 4}
      ]

      dependencies = [
        # Job 1 sequence
        %{predecessor: "job1_machine_a", successor: "job1_machine_b"},
        %{predecessor: "job1_machine_b", successor: "job1_machine_c"},
        # Job 2 sequence
        %{predecessor: "job2_machine_b", successor: "job2_machine_a"},
        %{predecessor: "job2_machine_a", successor: "job2_machine_c"},
        # Job 3 sequence
        %{predecessor: "job3_machine_c", successor: "job3_machine_b"},
        %{predecessor: "job3_machine_b", successor: "job3_machine_a"}
      ]

      {:ok, result} = PertPlanner.initialize_project(tasks, dependencies)

      assert result.initialized == true
      assert length(result.tasks) == 9
      assert length(result.dependencies) == 6

      # Verify all tasks created
      Enum.each(tasks, fn %{id: id} ->
        assert Repo.get_by(TaskDuration, task_id: id)
        assert Repo.get_by(TaskStatus, task_id: id)
      end)

      # Verify all dependencies created
      Enum.each(dependencies, fn %{predecessor: pred, successor: succ} ->
        assert Repo.get_by(TaskDependency, predecessor: pred, successor: succ)
      end)
    end
  end

  describe "employee scheduling scenario" do
    test "plans an employee scheduling problem with shifts and constraints" do
      # Employee Scheduling: 3 employees, 5 shifts per day
      # Employee 1: Can work shifts 1, 2, 3
      # Employee 2: Can work shifts 2, 3, 4
      # Employee 3: Can work shifts 3, 4, 5

      tasks = [
        # Shift assignments
        %{id: "shift_1_employee_1", duration: 8},
        %{id: "shift_2_employee_1", duration: 8},
        %{id: "shift_3_employee_1", duration: 8},
        %{id: "shift_2_employee_2", duration: 8},
        %{id: "shift_3_employee_2", duration: 8},
        %{id: "shift_4_employee_2", duration: 8},
        %{id: "shift_3_employee_3", duration: 8},
        %{id: "shift_4_employee_3", duration: 8},
        %{id: "shift_5_employee_3", duration: 8}
      ]

      dependencies = [
        # Employee 1 can only work one shift at a time
        %{predecessor: "shift_1_employee_1", successor: "shift_2_employee_1"},
        %{predecessor: "shift_2_employee_1", successor: "shift_3_employee_1"},
        # Employee 2 can only work one shift at a time
        %{predecessor: "shift_2_employee_2", successor: "shift_3_employee_2"},
        %{predecessor: "shift_3_employee_2", successor: "shift_4_employee_2"},
        # Employee 3 can only work one shift at a time
        %{predecessor: "shift_3_employee_3", successor: "shift_4_employee_3"},
        %{predecessor: "shift_4_employee_3", successor: "shift_5_employee_3"}
      ]

      {:ok, result} = PertPlanner.initialize_project(tasks, dependencies)

      assert result.initialized == true
      assert length(result.tasks) == 9
      assert length(result.dependencies) == 6

      # Verify project state
      {:ok, state} = PertPlanner.get_project_state()

      # All tasks should have durations
      assert map_size(state.durations) == 9

      # All tasks should be not_started
      Enum.each(state.statuses, fn {_task_id, status} ->
        assert status == "not_started"
      end)
    end
  end

  describe "beamserver integration test" do
    test "plans a complex PERT project via MCP tool handler" do
      # Create a complex project with multiple dependencies
      tasks = [
        %{id: "design", duration: 10},
        %{id: "frontend", duration: 15},
        %{id: "backend", duration: 20},
        %{id: "database", duration: 12},
        %{id: "testing", duration: 8},
        %{id: "deployment", duration: 5}
      ]

      dependencies = [
        %{predecessor: "design", successor: "frontend"},
        %{predecessor: "design", successor: "backend"},
        %{predecessor: "backend", successor: "database"},
        %{predecessor: "frontend", successor: "testing"},
        %{predecessor: "database", successor: "testing"},
        %{predecessor: "testing", successor: "deployment"}
      ]

      PertPlanner.reset_project()
      {:ok, _} = PertPlanner.initialize_project(tasks, dependencies)

      # Create plan via MCP tool handler
      plan_objective = Jason.encode!(["plan_project"])
      objectives = [plan_objective]

      {:ok, result, _state} = ToolHandlers.handle_tool_call(
        "create_plan",
        %{
          "persona_id" => "test_persona",
          "name" => "Complex PERT Project",
          "domain_type" => "pert_planner",
          "objectives" => objectives,
          "run_lazy" => false
        },
        %{prompt_uses: %{}}
      )

      [content] = result[:content]
      {:ok, plan_data} = Jason.decode(content["text"])
      plan_id = plan_data["id"]

      {:ok, plan_struct} = Repo.get(Plan, plan_id)

      # Verify plan was created
      assert plan_struct.solution_plan != "[]"

      # Verify final state
      {:ok, final_state_snapshot} = Jason.decode(plan_struct.planner_state_snapshot)

      # All tasks should be completed
      Enum.each(tasks, fn %{id: id} ->
        assert Map.get(final_state_snapshot["task_status"], id) == "completed",
               "Task #{id} should be completed"
      end)
    end
  end
end
