# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.MultiGoal do
  @moduledoc """
  Placeholder module for multi-goal representation.
  """

  @type t :: %__MODULE__{}

  defstruct [:goal_tag, :goals]

  @spec new(atom(), list()) :: t()
  def new(goal_tag, goals), do: %__MODULE__{goal_tag: goal_tag, goals: goals}
end
