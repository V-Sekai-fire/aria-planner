# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.CreateTaskDependency do
  @moduledoc """
  Command: c_create_task_dependency(task_a, task_b)

  Creates a new task dependency predicate.
  """
  alias AriaPlanner.Domains.PertPlanner.Predicates.TaskDependency
  alias AriaPlanner.Repo

  defstruct predecessor: nil, successor: nil

  @spec c_create_task_dependency(predecessor :: String.t(), successor :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_create_task_dependency(predecessor, successor) do
    case Repo.insert(%TaskDependency{predecessor: predecessor, successor: successor}) do
      {:ok, _task_dependency} -> {:ok, %{command: "c_create_task_dependency", predecessor: predecessor, successor: successor}}
      {:error, changeset} -> {:error, "Failed to create task dependency: #{inspect(changeset)}"}
    end
  end
end
