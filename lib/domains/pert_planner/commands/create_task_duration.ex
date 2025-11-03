# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.CreateTaskDuration do
  @moduledoc """
  Command: c_create_task_duration(task, duration)

  Creates a new task duration predicate.
  """
  alias AriaPlanner.Domains.PertPlanner.Predicates.TaskDuration
  alias AriaPlanner.Repo

  defstruct task: nil, duration: nil

  @spec c_create_task_duration(task :: String.t(), duration :: integer()) :: {:ok, map()} | {:error, String.t()}
  def c_create_task_duration(task, duration) do
    case Repo.insert(%TaskDuration{task_id: task, duration: duration}) do
      {:ok, _task_duration} -> {:ok, %{command: "c_create_task_duration", task: task, duration: duration}}
      {:error, changeset} -> {:error, "Failed to create task duration: #{inspect(changeset)}"}
    end
  end
end
