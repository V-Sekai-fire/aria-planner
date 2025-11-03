# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.CreateTaskStatus do
  @moduledoc """
  Command: c_create_task_status(task, status)

  Creates a new task status predicate.
  """
  alias AriaPlanner.Domains.PertPlanner.Predicates.TaskStatus
  alias AriaPlanner.Repo

  defstruct task: nil, status: nil

  @spec c_create_task_status(task :: String.t(), status :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_create_task_status(task, status) do
    case Repo.insert(%TaskStatus{task_id: task, status: status}) do
      {:ok, _task_status} -> {:ok, %{command: "c_create_task_status", task: task, status: status}}
      {:error, changeset} -> {:error, "Failed to create task status: #{inspect(changeset)}"}
    end
  end
end
