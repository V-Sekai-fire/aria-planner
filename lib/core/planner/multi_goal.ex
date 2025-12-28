# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.MultiGoal do
  @moduledoc """
  Represents a multi-goal in HTN (Hierarchical Task Network) planning.

  A multi-goal is a collection of goals that must be achieved together.
  It contains a goal_tag (used to look up decomposition methods) and a list
  of individual goals that need to be satisfied.

  Used by `LazyRefinement` to represent goals that are decomposed together
  and verified as a group during plan execution.
  """

  @type t :: %__MODULE__{
          goal_tag: atom(),
          goals: list()
        }

  defstruct [:goal_tag, :goals]

  @spec new(atom(), list()) :: t()
  def new(goal_tag, goals), do: %__MODULE__{goal_tag: goal_tag, goals: goals}
end
