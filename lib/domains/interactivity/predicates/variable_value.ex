# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.VariableValue do
  @moduledoc """
  Variable value predicate for interactivity domain.

  Represents custom variables defined in the behavior graph.
  Variables retain their values until graph execution terminates.
  """

  @doc """
  Gets the value of a custom variable from state.
  """
  @spec get(state :: map(), variable_name :: String.t()) :: any() | nil
  def get(state, variable_name) do
    key = {:variable_value, variable_name}
    Map.get(state, key)
  end

  @doc """
  Sets the value of a custom variable in state.
  """
  @spec set(state :: map(), variable_name :: String.t(), value :: any()) :: map()
  def set(state, variable_name, value) do
    key = {:variable_value, variable_name}
    Map.put(state, key, value)
  end

  @doc """
  Gets the type of a custom variable from state.
  """
  @spec get_type(state :: map(), variable_name :: String.t()) :: String.t() | nil
  def get_type(state, variable_name) do
    key = {:variable_type, variable_name}
    Map.get(state, key)
  end

  @doc """
  Sets the type of a custom variable in state.
  """
  @spec set_type(state :: map(), variable_name :: String.t(), type :: String.t()) :: map()
  def set_type(state, variable_name, type) do
    key = {:variable_type, variable_name}
    Map.put(state, key, type)
  end

  @doc """
  Gets the default value for a type.
  """
  @spec default_value(type :: String.t()) :: any()
  def default_value("bool"), do: false
  def default_value("float"), do: :nan
  def default_value("float2"), do: {:nan, :nan}
  def default_value("float3"), do: {:nan, :nan, :nan}
  def default_value("float4"), do: {:nan, :nan, :nan, :nan}
  def default_value("float2x2"), do: {:nan, :nan, :nan, :nan}
  def default_value("float3x3"), do: List.duplicate(:nan, 9) |> List.to_tuple()
  def default_value("float4x4"), do: List.duplicate(:nan, 16) |> List.to_tuple()
  def default_value("int"), do: 0
  def default_value(_), do: nil
end
