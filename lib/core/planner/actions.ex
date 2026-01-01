# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.Actions do
  @moduledoc """
  Registry for planner actions in HTN (Hierarchical Task Network) planning.

  Actions are primitive operations that can be directly executed in the planning domain.
  This module maintains a dictionary mapping action names to their implementation functions.

  Used by `LazyRefinement` to look up and execute actions during plan refinement.
  """

  @type t :: %__MODULE__{action_dict: %{atom() => function()}}

  defstruct [:action_dict]

  @spec new :: t()
  def new, do: %__MODULE__{action_dict: %{}}

  @spec add_action(t(), atom(), fun()) :: t()
  def add_action(actions, action_name, fun),
    do: %{actions | action_dict: Map.put(actions.action_dict, action_name, fun)}
end
