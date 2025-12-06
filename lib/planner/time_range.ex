# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.TimeRange do
  @moduledoc """
  Time range management for planning operations.

  Matches Godot planner's PlannerTimeRange structure with helper methods for:
  - Managing start_time, end_time, and duration in ISO 8601 format
  - Calculating duration from start/end times
  - Calculating end_time from start_time and duration
  - Setting current time as start/end

  All times are in ISO 8601 format (datetime strings for absolute times,
  duration strings for durations), matching aria-planner's PlannerMetadata structure.
  """

  alias AriaPlanner.Client

  defstruct [
    # ISO 8601 datetime string (absolute time)
    :start_time,
    # ISO 8601 datetime string (absolute time)
    :end_time,
    # ISO 8601 duration string
    :duration
  ]

  @type t :: %__MODULE__{
          start_time: String.t() | nil,
          end_time: String.t() | nil,
          duration: String.t() | nil
        }

  @doc """
  Creates a new TimeRange struct.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      start_time: Keyword.get(opts, :start_time),
      end_time: Keyword.get(opts, :end_time),
      duration: Keyword.get(opts, :duration)
    }
  end

  @doc """
  Sets the start time to the current time (ISO 8601 datetime string).
  """
  @spec set_start_now(t()) :: t()
  def set_start_now(%__MODULE__{} = time_range) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    %{time_range | start_time: now}
  end

  @doc """
  Sets the end time to the current time (ISO 8601 datetime string).
  """
  @spec set_end_now(t()) :: t()
  def set_end_now(%__MODULE__{} = time_range) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    %{time_range | end_time: now}
  end

  @doc """
  Sets the start time (ISO 8601 datetime string).
  """
  @spec set_start_time(t(), String.t()) :: t()
  def set_start_time(%__MODULE__{} = time_range, start_time) when is_binary(start_time) do
    %{time_range | start_time: start_time}
  end

  @doc """
  Gets the start time (ISO 8601 datetime string).
  """
  @spec get_start_time(t()) :: String.t() | nil
  def get_start_time(%__MODULE__{start_time: start_time}), do: start_time

  @doc """
  Sets the end time (ISO 8601 datetime string).
  """
  @spec set_end_time(t(), String.t()) :: t()
  def set_end_time(%__MODULE__{} = time_range, end_time) when is_binary(end_time) do
    %{time_range | end_time: end_time}
  end

  @doc """
  Gets the end time (ISO 8601 datetime string).
  """
  @spec get_end_time(t()) :: String.t() | nil
  def get_end_time(%__MODULE__{end_time: end_time}), do: end_time

  @doc """
  Sets the duration (ISO 8601 duration string).
  """
  @spec set_duration(t(), String.t()) :: t()
  def set_duration(%__MODULE__{} = time_range, duration) when is_binary(duration) do
    %{time_range | duration: duration}
  end

  @doc """
  Gets the duration (ISO 8601 duration string).
  """
  @spec get_duration(t()) :: String.t() | nil
  def get_duration(%__MODULE__{duration: duration}), do: duration

  @doc """
  Calculates duration from start_time and end_time.

  Returns the time range with duration set to the ISO 8601 duration string
  representing the time between start_time and end_time.
  """
  @spec calculate_duration(t()) :: t()
  def calculate_duration(%__MODULE__{start_time: start_time, end_time: end_time} = time_range)
      when not is_nil(start_time) and not is_nil(end_time) do
    case {Client.iso8601_to_absolute_microseconds(start_time), Client.iso8601_to_absolute_microseconds(end_time)} do
      {{:ok, start_microseconds}, {:ok, end_microseconds}} ->
        duration_microseconds = end_microseconds - start_microseconds

        if duration_microseconds > 0 do
          case Client.microseconds_to_iso8601_duration(duration_microseconds) do
            {:ok, duration} -> %{time_range | duration: duration}
            _ -> time_range
          end
        else
          time_range
        end

      _ ->
        time_range
    end
  end

  def calculate_duration(time_range), do: time_range

  @doc """
  Calculates end_time from start_time and duration.

  Returns the time range with end_time set to start_time + duration.
  """
  @spec calculate_end_from_duration(t()) :: t()
  def calculate_end_from_duration(%__MODULE__{start_time: start_time, duration: duration} = time_range)
      when not is_nil(start_time) and not is_nil(duration) do
    case {Client.iso8601_to_absolute_microseconds(start_time), Client.iso8601_duration_to_microseconds(duration)} do
      {{:ok, start_microseconds}, {:ok, duration_microseconds}} ->
        end_microseconds = start_microseconds + duration_microseconds

        case Client.absolute_microseconds_to_iso8601(end_microseconds) do
          {:ok, end_time} -> %{time_range | end_time: end_time}
          _ -> time_range
        end

      _ ->
        time_range
    end
  end

  def calculate_end_from_duration(time_range), do: time_range

  @doc """
  Gets the current absolute time in ISO 8601 datetime format.
  """
  @spec now_iso8601() :: String.t()
  def now_iso8601 do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end

  @doc """
  Converts the time range to a map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = time_range) do
    %{
      "start_time" => time_range.start_time,
      "end_time" => time_range.end_time,
      "duration" => time_range.duration
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  @doc """
  Creates a time range from a map.
  """
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    new(
      start_time: Map.get(map, "start_time") || Map.get(map, :start_time),
      end_time: Map.get(map, "end_time") || Map.get(map, :end_time),
      duration: Map.get(map, "duration") || Map.get(map, :duration)
    )
  end
end
