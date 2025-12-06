# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.PlannerMetadata do
  @moduledoc """
  Rigid struct for planner metadata returned by actions, commands, and methods.

  This struct enforces that only valid temporal and entity requirement data
  can be specified in planner metadata. It prevents pollution with arbitrary
  domain-specific fields that should be handled through other mechanisms.

  ## Required Fields

  - `duration` - ISO 8601 duration string (e.g., "PT2H", "PT30M")
  - `requires_entities` - List of entity requirements for execution

  ## Optional Fields

  - `start_time` - ISO 8601 datetime for temporal constraints
  - `end_time` - ISO 8601 datetime for temporal constraints
  """

  alias AriaPlanner.Planner.EntityRequirement
  alias AriaPlanner.Client

  # Use Timex for proper datetime comparison and arithmetic
  use Timex

  @enforce_keys [:duration, :requires_entities]
  defstruct [
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
          duration: String.t(),
          requires_entities: [EntityRequirement.t()],
          start_time: String.t() | nil,
          end_time: String.t() | nil
        }

  @doc """
  Creates a new planner metadata struct with validation.

  ## Examples

      iex> AriaPlanner.Planner.PlannerMetadata.new("PT2H", [%AriaPlanner.Planner.EntityRequirement{type: "agent", capabilities: [:cooking]}])
      {:ok, %AriaPlanner.Planner.PlannerMetadata{duration: "PT2H", requires_entities: [...]}}

      iex> AriaPlanner.Planner.PlannerMetadata.new("", [])
      {:error, :invalid_duration}
  """
  @spec new(String.t(), [EntityRequirement.t()], keyword()) :: {:ok, t()} | {:error, atom()}
  def new(duration, requires_entities, opts \\ []) do
    start_time = Keyword.get(opts, :start_time)
    end_time = Keyword.get(opts, :end_time)

    cond do
      not is_binary(duration) or not (Client.iso8601_duration_to_microseconds(duration) |> elem(0) == :ok) ->
        {:error, :invalid_duration}

      not is_list(requires_entities) ->
        {:error, :no_entity_requirements}

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
           duration: duration,
           requires_entities: requires_entities,
           start_time: start_time,
           end_time: end_time
         }}
    end
  end

  @doc """
  Creates a new planner metadata struct, raising on validation errors.
  """
  @spec new!(String.t(), [EntityRequirement.t()], keyword()) :: t()
  def new!(duration, requires_entities, opts \\ []) do
    case new(duration, requires_entities, opts) do
      {:ok, metadata} -> metadata
      {:error, reason} -> raise ArgumentError, "Invalid planner metadata: #{reason}"
    end
  end

  @doc """
  Creates planner metadata from a legacy map format.

  This function helps migrate from the old map-based metadata to the new struct format.
  """
  def from_map(map) when is_map(map) do
    # Extract and validate required fields
    duration = Map.get(map, "duration") || Map.get(map, :duration)

    requires_entities =
      case Map.get(map, "requires_entities") || Map.get(map, :requires_entities) do
        entities when is_list(entities) ->
          # Convert legacy entity requirements if needed
          case entities do
            [%EntityRequirement{} | _] ->
              entities

            entity_list when is_list(entity_list) ->
              Enum.map(entity_list, &convert_entity_requirement/1)

            _ ->
              []
          end

        _ ->
          []
      end

    # Build options for new/3
    opts = []

    opts =
      if Map.has_key?(map, "start_time") or Map.has_key?(map, :start_time),
        do: Keyword.put(opts, :start_time, Map.get(map, "start_time") || Map.get(map, :start_time)),
        else: opts

    opts =
      if Map.has_key?(map, "end_time") or Map.has_key?(map, :end_time),
        do: Keyword.put(opts, :end_time, Map.get(map, "end_time") || Map.get(map, :end_time)),
        else: opts

    case new(duration, requires_entities, opts) do
      {:ok, metadata} -> {:ok, metadata}
      {:error, reason} -> raise ArgumentError, "Invalid planner metadata: #{reason}"
    end
  end

  def from_map(_), do: {:error, :invalid_map_format}

  @doc """
  Validates that a value is a valid planner metadata struct.
  """
  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{duration: duration, requires_entities: requires_entities})
      when is_binary(duration) and is_list(requires_entities) do
    Client.iso8601_duration_to_microseconds(duration) |> elem(0) == :ok and
      Enum.all?(requires_entities, &EntityRequirement.valid?/1)
  end

  def valid?(_), do: false

  @doc """
  Merges two planner metadata structs for temporal bridging using Allen relations.

  This function implements ADR-181 timeline bridging using Allen temporal algebra.
  The merge calculates the 13 possible Allen relations between intervals and creates
  the most precise merged temporal constraints. This enables sophisticated temporal
  planning and timeline composition.

  Allen Relations handled:
  - Before, After, Meets, Met_By, Starts, Started_By, Finishes, Finished_By
  - Overlaps, Overlapped_By, Contains, During, Equals
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{} = metadata1, %__MODULE__{} = metadata2) do
    # Calculate Allen relation and merge temporal intervals using sophisticated temporal reasoning
    merged_temporal = merge_temporal_using_allen(metadata1, metadata2)

    # Combine entity requirements (no duplicates by type and capabilities)
    combined_entities = merge_entity_requirements(metadata1.requires_entities, metadata2.requires_entities)

    # Choose duration from the merged temporal interval
    duration = merged_temporal.duration

    # Create merged metadata with proper temporal constraints
    new!(duration, combined_entities, start_time: merged_temporal.start_time, end_time: merged_temporal.end_time)
  end

  # Private function to merge temporal intervals using Allen relations
  defp merge_temporal_using_allen(metadata1, metadata2) do
    # Convert metadata to intervals for Allen relation analysis
    interval1 = metadata_to_interval(metadata1)
    interval2 = metadata_to_interval(metadata2)

    # Determine Allen relation between intervals
    allen_relation = determine_allen_relation(interval1, interval2)

    # Merge based on Allen relation to create tightest possible constraints
    merged_interval = merge_intervals_with_allen(interval1, interval2, allen_relation)

    # Convert back to metadata temporal format
    interval_to_temporal_metadata(
      merged_interval,
      metadata1.duration,
      metadata2.duration
    )
  end

  # Convert metadata temporal items to interval structure
  defp metadata_to_interval(metadata) do
    cond do
      # Both start and end defined - concrete interval
      metadata.start_time && metadata.end_time ->
        {metadata.start_time, metadata.end_time}

      # Only start defined - unknown duration interval
      metadata.start_time ->
        {metadata.start_time, :unknown}

      # Only duration defined - anchored to reference point
      metadata.duration ->
        # Use duration as an interval from some reference
        {:reference, metadata.duration}

      # No temporal info - unknown temporal scope
      true ->
        {:unknown}
    end
  end

  # Determine Allen relation between two intervals using Timex for accurate datetime comparison
  # Returns one of the 13 Allen relations as an atom
  defp determine_allen_relation({start1, end1}, {start2, end2}) do
    # Parse ISO 8601 strings to DateTime structs for proper comparison
    dt_start1 = parse_iso_datetime(start1)
    dt_end1 = parse_iso_datetime(end1)
    dt_start2 = parse_iso_datetime(start2)
    dt_end2 = parse_iso_datetime(end2)

    cond do
      # Before: interval1 ends before interval2 starts
      dt_end1 && dt_start2 && Timex.before?(dt_end1, dt_start2) ->
        :before

      # After: interval1 starts after interval2 ends
      dt_start1 && dt_end2 && Timex.after?(dt_start1, dt_end2) ->
        :after

      # Meets: interval1 ends exactly when interval2 starts
      dt_end1 && dt_start2 && Timex.equal?(dt_end1, dt_start2) ->
        :meets

      # Met_By: interval2 ends exactly when interval1 starts
      dt_end2 && dt_start1 && Timex.equal?(dt_end2, dt_start1) ->
        :met_by

      # Overlaps: interval1 starts before interval2, they overlap, interval1 ends during interval2
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.compare(dt_start1, dt_start2) <= 0 &&
        Timex.compare(dt_end1, dt_start2) > 0 &&
          Timex.compare(dt_end1, dt_end2) <= 0 ->
        :overlaps

      # Overlapped_By: interval2 starts before interval1, they overlap, interval2 ends during interval1
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.compare(dt_start2, dt_start1) <= 0 &&
        Timex.compare(dt_end2, dt_start1) > 0 &&
          Timex.compare(dt_end2, dt_end1) <= 0 ->
        :overlapped_by

      # Starts: intervals start at same time, interval1 ends before interval2
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.equal?(dt_start1, dt_start2) &&
          (Timex.before?(dt_end1, dt_end2) or Timex.equal?(dt_end1, dt_end2)) ->
        :starts

      # Started_By: intervals start at same time, interval2 ends before interval1
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.equal?(dt_start1, dt_start2) &&
          (Timex.before?(dt_end2, dt_end1) or Timex.equal?(dt_end2, dt_end1)) ->
        :started_by

      # Finishes: intervals end at same time, interval1 starts after interval2
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.equal?(dt_end1, dt_end2) &&
          (Timex.after?(dt_start1, dt_start2) or Timex.equal?(dt_start1, dt_start2)) ->
        :finishes

      # Finished_By: intervals end at same time, interval2 starts after interval1
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.equal?(dt_end1, dt_end2) &&
          (Timex.after?(dt_start2, dt_start1) or Timex.equal?(dt_start2, dt_start1)) ->
        :finished_by

      # Contains: interval1 completely contains interval2
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.compare(dt_start1, dt_start2) <= 0 &&
          Timex.compare(dt_end1, dt_end2) >= 0 ->
        :contains

      # During: interval1 is completely contained by interval2
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.compare(dt_start1, dt_start2) >= 0 &&
          Timex.compare(dt_end1, dt_end2) <= 0 ->
        :during

      # Equals: intervals are identical
      dt_start1 && dt_start2 && dt_end1 && dt_end2 &&
        Timex.equal?(dt_start1, dt_start2) &&
          Timex.equal?(dt_end1, dt_end2) ->
        :equals

      # Default fallback for unknown or incomplete temporal data
      true ->
        :overlaps
    end
  end

  # Parse ISO 8601 datetime string to DateTime struct using Timex
  defp parse_iso_datetime(nil), do: nil

  defp parse_iso_datetime(datetime_str) when is_binary(datetime_str) do
    case Timex.parse(datetime_str, "{ISO:Extended}") do
      {:ok, datetime} -> datetime
      _ -> nil
    end
  end

  defp parse_iso_datetime(%DateTime{} = dt), do: dt
  defp parse_iso_datetime(_), do: nil

  # Merge two intervals based on their Allen relation
  # Returns the tightest possible merged interval
  defp merge_intervals_with_allen(interval1, interval2, relation) do
    case relation do
      # Sequential relations - combine into larger interval
      :before ->
        merge_sequential_intervals(interval1, interval2)

      :after ->
        # Reverse order
        merge_sequential_intervals(interval2, interval1)

      :meets ->
        merge_meeting_intervals(interval1, interval2)

      :met_by ->
        merge_meeting_intervals(interval2, interval1)

      # Overlapping relations - find union of intervals
      :overlaps ->
        merge_overlapping_intervals(interval1, interval2)

      :overlapped_by ->
        merge_overlapping_intervals(interval2, interval1)

      # Starting/ending relations - adjust endpoints
      :starts ->
        # Second interval may be shorter/longer than first
        start = elem(interval1, 0)
        end1 = elem(interval1, 1)
        end2 = elem(interval2, 1)
        {start, max(end1, end2)}

      :started_by ->
        start = elem(interval1, 0)
        end1 = elem(interval1, 1)
        end2 = elem(interval2, 1)
        {start, min(end1, end2)}

      :finishes ->
        start1 = elem(interval1, 0)
        start2 = elem(interval2, 0)
        end_point = elem(interval1, 1)
        {min(start1, start2), end_point}

      :finished_by ->
        start1 = elem(interval1, 0)
        start2 = elem(interval2, 0)
        end_point = elem(interval1, 1)
        {max(start1, start2), end_point}

      # Containment relations
      :contains ->
        # First interval contains second
        interval1

      :during ->
        # First interval is contained by second
        interval1

      :equals ->
        # They are the same
        interval1

      # Default: conservative merge
      _ ->
        merge_conservative(interval1, interval2)
    end
  end

  # Helper functions for specific Allen relation merges

  defp merge_sequential_intervals({start1, end1}, {start2, end2}) do
    start = min_datetime(start1, start2)
    end_ = max_datetime(end1, end2)
    {start, end_}
  end

  defp merge_meeting_intervals({start1, end1}, {start2, end2}) do
    start = min_datetime(start1, start2)
    end_ = max_datetime(end1, end2)
    {start, end_}
  end

  defp merge_overlapping_intervals({start1, end1}, {start2, end2}) do
    start = min_datetime(start1, start2)
    end_ = max_datetime(end1, end2)
    {start, end_}
  end

  defp merge_conservative(interval1, interval2) do
    # Take the union for safety
    merge_overlapping_intervals(interval1, interval2)
  end

  # Helper functions for datetime comparison using Timex and DateTime.to_iso8601
  # DateTime.to_iso8601/1 produces compatible ISO strings for the validator
  defp min_datetime(dt1, dt2) do
    dt1_parsed = parse_iso_datetime(dt1)
    dt2_parsed = parse_iso_datetime(dt2)

    cond do
      dt1_parsed && dt2_parsed ->
        case Timex.compare(dt1_parsed, dt2_parsed) do
          -1 -> DateTime.to_iso8601(dt1_parsed)
          0 -> DateTime.to_iso8601(dt1_parsed)
          1 -> DateTime.to_iso8601(dt2_parsed)
        end

      dt1_parsed ->
        dt1

      dt2_parsed ->
        dt2

      true ->
        dt1 || dt2
    end
  end

  defp max_datetime(dt1, dt2) do
    dt1_parsed = parse_iso_datetime(dt1)
    dt2_parsed = parse_iso_datetime(dt2)

    cond do
      dt1_parsed && dt2_parsed ->
        case Timex.compare(dt1_parsed, dt2_parsed) do
          -1 -> DateTime.to_iso8601(dt2_parsed)
          0 -> DateTime.to_iso8601(dt2_parsed)
          1 -> DateTime.to_iso8601(dt1_parsed)
        end

      dt1_parsed ->
        dt1

      dt2_parsed ->
        dt2

      true ->
        dt1 || dt2
    end
  end

  # Convert merged interval back to temporal metadata format
  defp interval_to_temporal_metadata({start, end_}, _duration1, duration2) do
    # For merged metadata, we keep the more recent duration
    # and use the calculated start/end times
    # For Allen relation merges, we mainly use the original times when available
    %{
      start_time: start,
      end_time: end_,
      # Use second metadata's duration as the merged duration
      duration: duration2
    }
  end

  @doc """
  Converts a planner metadata struct to a plain map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = metadata) do
    %{
      "duration" => metadata.duration,
      "requires_entities" => Enum.map(metadata.requires_entities, &EntityRequirement.to_map/1),
      "start_time" => metadata.start_time,
      "end_time" => metadata.end_time
    }
  end

  @doc """
  Validates a planner metadata struct and returns detailed error information.
  """
  @spec validate(t()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{} = metadata) do
    cond do
      not is_binary(metadata.duration) or
          not (Client.iso8601_duration_to_microseconds(metadata.duration) |> elem(0) == :ok) ->
        {:error, :invalid_duration}

      not is_list(metadata.requires_entities) ->
        {:error, :no_entity_requirements}

      not Enum.all?(metadata.requires_entities, &EntityRequirement.valid?/1) ->
        {:error, :invalid_entity_requirements}

      metadata.start_time != nil and
          (not is_binary(metadata.start_time) or
             not (Client.iso8601_to_absolute_microseconds(metadata.start_time) |> elem(0) == :ok)) ->
        {:error, :invalid_start_time}

      metadata.end_time != nil and
          (not is_binary(metadata.end_time) or
             not (Client.iso8601_to_absolute_microseconds(metadata.end_time) |> elem(0) == :ok)) ->
        {:error, :invalid_end_time}

      true ->
        :ok
    end
  end

  # Private helper to convert legacy entity requirement maps
  defp convert_entity_requirement(%{type: type, capabilities: capabilities}) do
    EntityRequirement.new!(type, capabilities)
  end

  defp convert_entity_requirement(other) do
    raise ArgumentError, "Cannot convert entity requirement: #{inspect(other)}"
  end

  # Private helper to merge entity requirements without duplicates
  defp merge_entity_requirements(entities1, entities2) do
    # Combine entities, removing duplicates by type and capabilities
    all_entities = entities1 ++ entities2
    Enum.uniq_by(all_entities, fn %{type: type, capabilities: caps} -> {type, Enum.sort(caps)} end)
  end
end
