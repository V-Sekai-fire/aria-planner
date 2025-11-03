# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.AddDependency do
  @moduledoc """
  Add dependency command for PERT planner domain.

  Adds a dependency between two tasks: successor depends on predecessor.
  """

  alias AriaPlanner.Domains.PertPlanner.Predicates.TaskDependency
  alias AriaPlanner.Repo

  defstruct predecessor: nil, successor: nil

  @doc """
  Executes the add_dependency action.

  Preconditions: Both tasks exist
  Effects: Creates task_dependency fact
  """
  @spec c_add_dependency(predecessor :: String.t(), successor :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def c_add_dependency(predecessor, successor) when is_binary(predecessor) and is_binary(successor) do
    # Check if both tasks exist (have duration facts)
    pred_exists = Repo.get(TaskDependency, predecessor) != nil
    succ_exists = Repo.get(TaskDependency, successor) != nil

    if pred_exists and succ_exists do
      case TaskDependency.create(%{predecessor: predecessor, successor: successor}) do
        {:ok, _dependency} ->
          {:ok, %{predecessor: predecessor, successor: successor}}
        {:error, changeset} ->
          {:error, "Failed to create dependency: #{inspect(changeset.errors)}"}
      end
    else
      {:error, "Both predecessor and successor tasks must exist"}
    end
  rescue
    e -> {:error, "Failed to add dependency: #{inspect(e)}"}
  end
end
