# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Types do
  @moduledoc """
  Type system for glTF Interactivity Extension.

  Provides type mapping, default values, and type validation for glTF types.
  """

  # Type index mapping (from glTF spec types array)
  @type_index %{
    0 => "bool",
    1 => "int",
    2 => "float",
    3 => "float2",
    4 => "float3",
    5 => "float4",
    6 => "float2x2",
    7 => "float3x3",
    8 => "float4x4"
  }

  @type_names Map.values(@type_index) |> Enum.with_index() |> Map.new(fn {name, idx} -> {name, idx} end)

  @doc """
  Gets the type name from a type index.

  Returns the type name string (e.g., "float3") or nil if invalid.
  """
  @spec type_name(type_index :: integer()) :: String.t() | nil
  def type_name(index) when is_integer(index) and index >= 0 do
    Map.get(@type_index, index)
  end

  def type_name(_), do: nil

  @doc """
  Gets the type index from a type name.

  Returns the type index integer or nil if invalid.
  """
  @spec type_index(type_name :: String.t()) :: integer() | nil
  def type_index(name) when is_binary(name) do
    Map.get(@type_names, name)
  end

  def type_index(_), do: nil

  @doc """
  Gets the default value for a type (used when isValid=false).

  Returns a value appropriate for the type that indicates invalid/NaN state.
  """
  @spec default_value(type_name :: String.t()) :: term()
  def default_value("bool"), do: false
  def default_value("int"), do: 0
  def default_value("float"), do: :nan
  def default_value("float2"), do: {:nan, :nan}
  def default_value("float3"), do: {:nan, :nan, :nan}
  def default_value("float4"), do: {:nan, :nan, :nan, :nan}
  def default_value("float2x2"), do: {:nan, :nan, :nan, :nan}
  def default_value("float3x3"), do: List.duplicate(:nan, 9) |> List.to_tuple()
  def default_value("float4x4"), do: List.duplicate(:nan, 16) |> List.to_tuple()
  def default_value(_), do: nil

  @doc """
  Gets the default value for a type index.
  """
  @spec default_value_for_index(type_index :: integer()) :: term()
  def default_value_for_index(index) do
    case type_name(index) do
      nil -> nil
      name -> default_value(name)
    end
  end

  @doc """
  Validates that a value matches the expected type.

  Returns true if the value matches the type, false otherwise.
  """
  @spec validate_type(value :: term(), type_name :: String.t()) :: boolean()
  def validate_type(value, "bool"), do: is_boolean(value)
  def validate_type(value, "int"), do: is_integer(value)
  def validate_type(value, "float"), do: is_number(value)
  def validate_type(value, "float2") when is_tuple(value), do: tuple_size(value) == 2
  def validate_type(value, "float2") when is_list(value), do: length(value) == 2
  def validate_type(value, "float3") when is_tuple(value), do: tuple_size(value) == 3
  def validate_type(value, "float3") when is_list(value), do: length(value) == 3
  def validate_type(value, "float4") when is_tuple(value), do: tuple_size(value) == 4
  def validate_type(value, "float4") when is_list(value), do: length(value) == 4
  def validate_type(value, "float2x2") when is_tuple(value), do: tuple_size(value) == 4
  def validate_type(value, "float2x2") when is_list(value), do: length(value) == 4
  def validate_type(value, "float3x3") when is_tuple(value), do: tuple_size(value) == 9
  def validate_type(value, "float3x3") when is_list(value), do: length(value) == 9
  def validate_type(value, "float4x4") when is_tuple(value), do: tuple_size(value) == 16
  def validate_type(value, "float4x4") when is_list(value), do: length(value) == 16
  def validate_type(_, _), do: false
end
