# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.PertPlanner.Commands.CalculateSchedule do
  @moduledoc """
  Calculate schedule command for PERT planner domain.

  Calculates the PERT schedule including earliest/latest times and critical path.
  """

  alias AriaPlanner.Domains.PertPlanner

  defstruct []

  @doc """
  Executes the calculate_schedule action.

  Preconditions: None
  Effects: Updates earliest/latest start/finish times for all tasks
  """
  @spec c_calculate_schedule() :: {:ok, map()} | {:error, String.t()}
  def c_calculate_schedule do
    PertPlanner.calculate_schedule()
  rescue
    e -> {:error, "Failed to calculate schedule: #{inspect(e)}"}
  end
end
