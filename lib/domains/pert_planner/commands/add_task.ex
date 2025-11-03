# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.AddTask do
  @moduledoc """
  Add task command for PERT planner domain.

  Adds a new task with its duration to the project.
  """

  alias AriaPlanner.Domains.PertPlanner.Predicates.{TaskDuration, TaskStatus}
  alias AriaPlanner.Repo

  defstruct task: nil, duration: nil

  @spec c_add_task(task_id :: String.t(), duration :: integer()) :: {:ok, map()} | {:error, String.t()}
  def c_add_task(task_id, duration) when is_binary(task_id) and is_integer(duration) and duration > 0 do
    Repo.transaction(fn ->
      # Create duration fact
      {:ok, _duration_fact} = TaskDuration.create(%{task_id: task_id, duration: duration})

      # Create status fact
      {:ok, _status_fact} = TaskStatus.create(%{task_id: task_id, status: "not_started"})

      %{task_id: task_id, duration: duration, status: "not_started"}
    end)
  rescue
    e -> {:error, "Failed to add task: #{inspect(e)}"}
  end
end
