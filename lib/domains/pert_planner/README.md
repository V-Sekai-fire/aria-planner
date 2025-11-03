# PERT Planner Domain

This domain implements Program Evaluation and Review Technique (PERT) for project management planning.

## Features

- Task management with durations
- Dependency relationships between tasks
- Critical path analysis
- Earliest and latest start/finish time calculations
- Task status tracking (not_started, in_progress, completed)

## Predicates

- `task_duration(task_id, duration)` - Duration of task in seconds
- `task_dependency(predecessor, successor)` - Successor depends on predecessor
- `task_status(task_id, status)` - Current status of task
- `task_earliest_start(task_id, time)` - Earliest start time
- `task_latest_start(task_id, time)` - Latest start time
- `task_earliest_finish(task_id, time)` - Earliest finish time
- `task_latest_finish(task_id, time)` - Latest finish time
- `task_slack(task_id, slack)` - Slack time for task

## Actions

- `add_task(task_id, duration)` - Add a new task
- `add_dependency(predecessor, successor)` - Add dependency between tasks
- `start_task(task_id)` - Start a task
- `complete_task(task_id)` - Complete a task
- `calculate_schedule()` - Calculate PERT schedule

## Task Methods

- `t_plan_project()` - Main entry point: schedule tasks and complete all tasks
- `t_schedule_tasks()` - Calculate PERT schedule (earliest/latest times)
- `t_complete_all_tasks()` - Complete all tasks using planner backtracking
- `t_complete_task(task_id)` - Complete a specific task (start + complete)

## Unigoal Methods

- `gm_schedule_task(task_id)` - Achieve earliest start time for a task
- `gm_complete_task(task_id)` - Achieve completed status for a task (handles dependencies)

## Usage

### Direct API Usage

```elixir
# Create domain
{:ok, domain} = AriaPlanner.Domains.PertPlanner.create_domain()

# Initialize project
tasks = [%{id: "A", duration: 5}, %{id: "B", duration: 3}, %{id: "C", duration: 4}]
dependencies = [%{predecessor: "A", successor: "B"}, %{predecessor: "A", successor: "C"}]
{:ok, _} = AriaPlanner.Domains.PertPlanner.initialize_project(tasks, dependencies)

# Calculate schedule
{:ok, schedule} = AriaPlanner.Domains.PertPlanner.calculate_schedule()
```

### MCP Tool Usage

When using the `create_plan` MCP tool, the `todo` parameter should contain a sequence of setup commands as JSON objects with action names as keys and argument arrays as values:

```elixir
use_mcp_tool(
  server_name: "aria-mcp-server",
  tool_name: "create_plan",
  arguments: %{
    "persona_id" => "pm_001",
    "name" => "Website Redesign Project",
    "domain_type" => "pert_planner",
    "todo" => [
      {"add_task", ["design", "PT10S"]},
      {"add_task", ["frontend", "PT15S"]},
      {"add_task", ["backend", "PT20S"]},
      {"add_task", ["testing", "PT5S"]},
      {"add_dependency", ["design", "frontend"]},
      {"add_dependency", ["design", "backend"]},
      {"add_dependency", ["frontend", "testing"]},
      {"add_dependency", ["backend", "testing"]},
      {"plan_project", []}
    ],
    "window_size" => 20
  }
)
```

Note: Durations use ISO 8601 format (e.g., "PT10S" for 10 seconds, "PT1H30M" for 1 hour 30 minutes).
