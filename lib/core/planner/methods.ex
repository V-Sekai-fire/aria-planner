# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.Methods do
  @moduledoc """
  Placeholder module for planner methods.
  """

  @type t :: %__MODULE__{}

  defstruct [:task_method_dict, :goal_method_dict, :multigoal_method_dict]

  @spec new() :: t()
  def new(), do: %__MODULE__{task_method_dict: %{}, goal_method_dict: %{}, multigoal_method_dict: %{}}

  @spec add_task_method(t(), atom(), fun()) :: t()
  def add_task_method(methods, task_name, fun), do: %{methods | task_method_dict: Map.put(methods.task_method_dict, task_name, fun)}

  @spec add_goal_method(t(), atom(), fun()) :: t()
  def add_goal_method(methods, goal_name, fun), do: %{methods | goal_method_dict: Map.put(methods.goal_method_dict, goal_name, fun)}

  @spec add_multigoal_method(t(), atom(), fun()) :: t()
  def add_multigoal_method(methods, multigoal_name, fun), do: %{methods | multigoal_method_dict: Map.put(methods.multigoal_method_dict, multigoal_name, fun)}
end
