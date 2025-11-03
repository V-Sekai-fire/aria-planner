# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.Actions do
  @moduledoc """
  Placeholder module for planner actions.
  """

  @type t :: %__MODULE__{}

  defstruct [:action_dict]

  @spec new() :: t()
  def new(), do: %__MODULE__{action_dict: %{}}

  @spec add_action(t(), atom(), fun()) :: t()
  def add_action(actions, action_name, fun), do: %{actions | action_dict: Map.put(actions.action_dict, action_name, fun)}
end
