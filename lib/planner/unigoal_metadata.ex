# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.UnigoalMetadata do
  @moduledoc """
  Rigid struct for unigoal method metadata.

  This struct extends PlannerMetadata with a predicate field to identify
  which predicate the unigoal method handles. It enforces that only valid
  temporal, entity requirement, and predicate data can be specified.

  ## Required Fields

  - `predicate` - String identifying which predicate this method handles
  - `duration` - ISO 8601 duration string (e.g., "PT30M", "PT2H")
  - `requires_entities` - List of entity requirements for execution

  ## Optional Fields

  - `start_time` - ISO 8601 datetime for temporal constraints
  - `end_time` - ISO 8601 datetime for temporal constraints
  """

  alias AriaPlanner.Planner.EntityRequirement
  alias AriaPlanner.Client

  @enforce_keys [:predicate, :duration, :requires_entities]
  defstruct [
    # required - which predicate this handles
    :predicate,
    # required - ISO 8601 duration
    :duration,
    # required - list of entity requirements
    :requires_entities,
    # optional - ISO 8601 datetime
    :start_time,
    # optional - ISO 8601 datetime
    :end_time
  ]

  @type t :: %__MODULE__{
          predicate: String.t(),
          # ISO 8601 duration string
          duration: String.t(),
          requires_entities: [EntityRequirement.t()],
          # ISO 8601 datetime string
          start_time: String.t() | nil,
          # ISO 8601 datetime string
          end_time: String.t() | nil
        }

  @doc """
  Creates a new unigoal metadata struct with validation.

  ## Examples

      iex> AriaPlanner.Planner.UnigoalMetadata.new("location", "PT10M", [%AriaPlanner.Planner.EntityRequirement{type: "agent", capabilities: [:movement]}])
      {:ok, %AriaPlanner.Planner.UnigoalMetadata{predicate: "location", duration: "PT10M", requires_entities: [...]}}
      iex> AriaPlanner.Planner.UnigoalMetadata.new("", "PT10M", [])
      {:error, :invalid_predicate}
  """
  @spec new(String.t(), String.t(), [EntityRequirement.t()], keyword()) :: {:ok, t()} | {:error, atom()}
  def new(predicate, duration, requires_entities, opts \\ []) do
    start_time = Keyword.get(opts, :start_time)
    end_time = Keyword.get(opts, :end_time)

    cond do
      not is_binary(predicate) or String.trim(predicate) == "" ->
        {:error, :invalid_predicate}

      not is_binary(duration) or not (Client.iso8601_duration_to_microseconds(duration) |> elem(0) == :ok) ->
        {:error, :invalid_duration}

      not is_list(requires_entities) ->
        {:error, :invalid_requires_entities}

      not Enum.all?(requires_entities, &EntityRequirement.valid?/1) ->
        {:error, :invalid_entity_requirements}

      start_time != nil and
          (not is_binary(start_time) or not (Client.iso8601_to_absolute_microseconds(start_time) |> elem(0) == :ok)) ->
        {:error, :invalid_start_time}

      end_time != nil and
          (not is_binary(end_time) or not (Client.iso8601_to_absolute_microseconds(end_time) |> elem(0) == :ok)) ->
        {:error, :invalid_end_time}

      true ->
        {:ok,
         %__MODULE__{
           predicate: predicate,
           duration: duration,
           requires_entities: requires_entities,
           start_time: start_time,
           end_time: end_time
         }}
    end
  end

  @doc """
  Creates a new unigoal metadata struct, raising on validation errors.
  """
  @spec new!(String.t(), String.t(), [EntityRequirement.t()], keyword()) :: t()
  def new!(predicate, duration, requires_entities, opts \\ []) do
    case new(predicate, duration, requires_entities, opts) do
      {:ok, metadata} -> metadata
      {:error, reason} -> raise ArgumentError, "Invalid unigoal metadata: #{reason}"
    end
  end

  @doc """
  Creates unigoal metadata from a legacy map format.

  This function helps migrate from the old map-based metadata to the new struct format.
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, atom()}
  def from_map(%{} = map) do
    # Extract values, handling both atom and string keys
    predicate = Map.get(map, :predicate) || Map.get(map, "predicate")
    duration = Map.get(map, :duration) || Map.get(map, "duration")
    requires_entities = Map.get(map, :requires_entities) || Map.get(map, "requires_entities")

    # Validate required fields
    cond do
      predicate == nil or duration == nil or requires_entities == nil ->
        {:error, :missing_required_fields}

      not is_binary(predicate) or not is_binary(duration) or not is_list(requires_entities) ->
        {:error, :invalid_field_types}

      true ->
        # Convert legacy entity requirements if needed
        converted_entities =
          case requires_entities do
            [%EntityRequirement{} | _] ->
              requires_entities

            entities when is_list(entities) ->
              Enum.map(entities, &convert_entity_requirement/1)

            _ ->
              []
          end

        opts = []

        opts =
          if Map.has_key?(map, :start_time) or Map.has_key?(map, "start_time"),
            do: Keyword.put(opts, :start_time, Map.get(map, :start_time) || Map.get(map, "start_time")),
            else: opts

        opts =
          if Map.has_key?(map, :end_time) or Map.has_key?(map, "end_time"),
            do: Keyword.put(opts, :end_time, Map.get(map, :end_time) || Map.get(map, "end_time")),
            else: opts

        new(predicate, duration, converted_entities, opts)
    end
  end

  def from_map(_), do: {:error, :invalid_map_format}

  @doc """
  Validates that a value is a valid unigoal metadata struct.
  """
  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{predicate: predicate, duration: duration, requires_entities: requires_entities})
      when is_binary(predicate) and is_binary(duration) and is_list(requires_entities) do
    String.trim(predicate) != "" and
      Client.iso8601_duration_to_microseconds(duration) |> elem(0) == :ok and
      Enum.all?(requires_entities, &EntityRequirement.valid?/1)
  end

  def valid?(_), do: false

  # Private helper to convert legacy entity requirement maps
  defp convert_entity_requirement(%{type: type, capabilities: capabilities}) do
    EntityRequirement.new!(type, capabilities)
  end

  defp convert_entity_requirement(other) do
    raise ArgumentError, "Cannot convert entity requirement: #{inspect(other)}"
  end
end
