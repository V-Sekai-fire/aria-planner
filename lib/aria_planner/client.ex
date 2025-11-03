# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Client do
  @moduledoc """
  Client module for AriaPlanner, responsible for converting civil time to absolute time
  (microseconds) for interaction with the AriaPlanner server.
  """
  use Timex

  @doc """
  Converts a civil DateTime struct to absolute microseconds since Unix epoch.
  """
  @spec civil_datetime_to_absolute_microseconds(DateTime.t()) :: integer()
  def civil_datetime_to_absolute_microseconds(%DateTime{} = datetime) do
    epoch = ~U[1970-01-01 00:00:00Z]
    DateTime.diff(datetime, epoch, :microsecond)
  end

  @doc """
  Converts an ISO 8601 datetime string (civil time) to absolute microseconds since Unix epoch.
  """
  @spec iso8601_to_absolute_microseconds(String.t()) :: {:ok, integer()} | {:error, String.t()}
  def iso8601_to_absolute_microseconds(iso8601_string) when is_binary(iso8601_string) do
    case Timex.parse(iso8601_string, "{ISO:Extended}") do
      {:ok, datetime} ->
        {:ok, civil_datetime_to_absolute_microseconds(datetime)}
      {:error, reason} ->
        {:error, "Invalid ISO 8601 datetime string: #{inspect(reason)}"}
    end
  end

  @doc """
  Converts an ISO 8601 duration string to absolute microseconds.
  """
  @spec iso8601_duration_to_microseconds(String.t()) :: {:ok, integer()} | {:error, atom() | String.t()}
  def iso8601_duration_to_microseconds(iso8601_duration_string) when is_binary(iso8601_duration_string) do
    if String.contains?(iso8601_duration_string, "/") do
      # Variable duration are not supported by this conversion to a single integer
      {:error, :variable_duration_not_supported}
    else
      case Timex.Duration.parse(iso8601_duration_string) do
        {:ok, %Timex.Duration{} = duration} ->
          {:ok, Timex.Duration.to_microseconds(duration)}
        {:error, reason} ->
          {:error, "Invalid ISO 8601 duration string: #{inspect(reason)}"}
      end
    end
  end
end
