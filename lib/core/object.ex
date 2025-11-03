# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Object do
  @moduledoc """
  Simple object for planning system values.

  Uses plain maps for scrappy operation without database dependencies.
  """

  @type t :: %{
          id: String.t(),
          value: String.t(),
          value_type: String.t(),
          typed_value: map(),
          description: String.t() | nil,
          unit: String.t() | nil,
          is_range: boolean(),
          min_value: number() | nil,
          max_value: number() | nil,
          metadata: map()
        }

  @doc """
  Creates a new object with validation.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) do
    id = Map.get_lazy(attrs, :id, fn -> :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower) end)
    value = Map.get(attrs, :value)
    value_type = Map.get(attrs, :value_type, "string")

    if is_nil(value) or not is_binary(value) do
      {:error, "value is required and must be a string"}
    else
      object = %{
        id: id,
        value: value,
        value_type: value_type,
        typed_value: Map.get(attrs, :typed_value, %{}),
        description: Map.get(attrs, :description),
        unit: Map.get(attrs, :unit),
        is_range: Map.get(attrs, :is_range, false),
        min_value: Map.get(attrs, :min_value),
        max_value: Map.get(attrs, :max_value),
        metadata: Map.get(attrs, :metadata, %{})
      }

      case validate_object(object) do
        :ok -> {:ok, object}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Validates object data.
  """
  @spec validate(map()) :: {:ok, t()} | {:error, keyword()}
  def validate(attrs) do
    case new(attrs) do
      {:ok, object} -> {:ok, object}
      {:error, reason} -> {:error, reason: reason}
    end
  end

  @doc """
  Creates an object from a value with automatic type detection.
  """
  @spec from_value(term()) :: {:ok, t()} | {:error, String.t()}
  def from_value(value) do
    {string_value, value_type, typed_value} = normalize_value(value)

    new(%{
      value: string_value,
      value_type: value_type,
      typed_value: typed_value,
      description: "#{value_type} value: #{string_value}"
    })
  end

  @doc """
  Creates an object representing a range of values.
  """
  @spec from_range(number(), number(), String.t() | nil) :: {:ok, t()} | {:error, String.t()}
  def from_range(min_value, max_value, unit \\ nil)

  def from_range(min_value, max_value, unit) when min_value <= max_value do
    new(%{
      value: "#{min_value}..#{max_value}",
      value_type: "range",
      is_range: true,
      min_value: min_value,
      max_value: max_value,
      unit: unit,
      description: "Range: #{min_value} to #{max_value}#{if unit, do: " #{unit}", else: ""}"
    })
  end

  def from_range(_min, _max, _unit) do
    {:error, "min_value must be <= max_value"}
  end

  # Private validation
  defp validate_object(%{is_range: true, min_value: min, max_value: max})
       when is_number(min) and is_number(max) and min > max do
    {:error, "min_value must be <= max_value for ranges"}
  end

  defp validate_object(_object), do: :ok

  # Private value normalization
  defp normalize_value(value) when is_binary(value) do
    {value, "string", %{string: value}}
  end

  defp normalize_value(value) when is_integer(value) do
    {Integer.to_string(value), "integer", %{integer: value}}
  end

  defp normalize_value(value) when is_float(value) do
    {Float.to_string(value), "float", %{float: value}}
  end

  defp normalize_value(value) when is_boolean(value) do
    {Atom.to_string(value), "boolean", %{boolean: value}}
  end

  defp normalize_value(value) when is_atom(value) do
    {Atom.to_string(value), "atom", %{atom: value}}
  end

  defp normalize_value(value) do
    string_value = inspect(value)
    {string_value, "unknown", %{raw: string_value}}
  end
end
