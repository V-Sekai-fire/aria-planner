# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.EntityRequirement do
  @moduledoc """
  Rigid struct for entity requirements in planner metadata.

  Defines what type of entity and capabilities are required for a planner operation.
  This struct enforces that only valid entity requirement data can be specified.
  """

  @enforce_keys [:type, :capabilities]
  defstruct [:type, :capabilities]

  @type t :: %__MODULE__{
          type: String.t(),
          capabilities: [atom()]
        }

  @doc """
  Creates a new entity requirement with validation.

  ## Examples

      iex> AriaPlanner.Planner.EntityRequirement.new("agent", [:cooking])
      {:ok, %AriaPlanner.Planner.EntityRequirement{type: "agent", capabilities: [:cooking]}}

      iex> AriaPlanner.Planner.EntityRequirement.new("", [:cooking])
      {:error, :invalid_type}

      iex> AriaPlanner.Planner.EntityRequirement.new("agent", [])
      {:error, :empty_capabilities}
  """
  @spec new(String.t(), [atom()]) :: {:ok, t()} | {:error, atom()}
  def new(type, capabilities) when is_binary(type) and is_list(capabilities) do
    cond do
      String.trim(type) == "" ->
        {:error, :invalid_type}

      Enum.empty?(capabilities) ->
        {:error, :empty_capabilities}

      not Enum.all?(capabilities, &is_atom/1) ->
        {:error, :invalid_capabilities}

      true ->
        {:ok, %__MODULE__{type: type, capabilities: capabilities}}
    end
  end

  def new(_, _), do: {:error, :invalid_arguments}

  @doc """
  Creates a new entity requirement, raising on validation errors.

  ## Examples

      iex> AriaPlanner.Planner.EntityRequirement.new!("agent", [:cooking])
      %AriaPlanner.Planner.EntityRequirement{type: "agent", capabilities: [:cooking]}
  """
  @spec new!(String.t(), [atom()]) :: t()
  def new!(type, capabilities) do
    case new(type, capabilities) do
      {:ok, requirement} -> requirement
      {:error, reason} -> raise ArgumentError, "Invalid entity requirement: #{reason}"
    end
  end

  @doc """
  Validates that a value is a valid entity requirement struct.
  """
  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{type: type, capabilities: capabilities})
      when is_binary(type) and is_list(capabilities) do
    String.trim(type) != "" and
      not Enum.empty?(capabilities) and
      Enum.all?(capabilities, &is_atom/1)
  end

  def valid?(_), do: false

  @doc """
  Converts an entity requirement struct to a plain map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = requirement) do
    %{
      "type" => requirement.type,
      "capabilities" => requirement.capabilities
    }
  end
end
