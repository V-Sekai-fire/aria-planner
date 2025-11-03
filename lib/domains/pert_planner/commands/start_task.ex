# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.StartTask do
  @moduledoc """
  Start task command for PERT planner domain.

  Starts a task by changing its status from not_started to in_progress.
  """

  alias AriaPlanner.Domains.PertPlanner.Predicates.TaskStatus
  alias AriaPlanner.Repo

  defstruct task: nil

  @doc """
  Executes the start_task action.

  Preconditions: Task status is not_started
  Effects: Changes task status to in_progress
  """
  @spec c_start_task(task_id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_start_task(task_id) when is_binary(task_id) do
    case Repo.get(TaskStatus, task_id) do
      nil ->
        {:error, "Task does not exist"}

      %TaskStatus{status: "not_started"} = task_status ->
        case TaskStatus.update(task_status, %{status: "in_progress"}) do
          {:ok, _updated} ->
            {:ok, %{task_id: task_id, status: "in_progress"}}
          {:error, changeset} ->
            {:error, "Failed to start task: #{inspect(changeset.errors)}"}
        end

      %TaskStatus{status: current_status} ->
        {:error, "Cannot start task with status #{current_status}"}
    end
  rescue
    e -> {:error, "Failed to start task: #{inspect(e)}"}
  end
end
