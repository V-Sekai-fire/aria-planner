# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.CompleteTask do
  @moduledoc """
  Complete task command for PERT planner domain.

  Completes a task by changing its status from in_progress to completed.
  """

  alias AriaPlanner.Domains.PertPlanner.Predicates.TaskStatus
  alias AriaPlanner.Repo

  defstruct task: nil

  @doc """
  Executes the complete_task action.

  Preconditions: Task status is in_progress.
  Effects: Sets task_status to 'completed'.
  """
  @spec c_complete_task(task_id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_complete_task(task_id) when is_binary(task_id) do
    case Repo.get(TaskStatus, task_id) do
      nil ->
        {:error, "Task does not exist"}

      %TaskStatus{status: "in_progress"} = task_status ->
        case TaskStatus.update(task_status, %{status: "completed"}) do
          {:ok, _updated} ->
            {:ok, %{task_id: task_id, status: "completed"}}
          {:error, changeset} ->
            {:error, "Failed to complete task: #{inspect(changeset.errors)}"}
        end

      %TaskStatus{status: current_status} ->
        {:error, "Cannot complete task with status #{current_status}"}
    end
  rescue
    e -> {:error, "Failed to complete task: #{inspect(e)}"}
  end
end
