# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Metadata.TemporalConstraints do
  @moduledoc """
  Temporal constraints for planning operations.

  Defines timing constraints including duration, start time, and end time
  for planning domain operations and computations.

  Uses ISO 8601 format for all temporal values:
  - duration: ISO 8601 duration string (e.g., "PT1H30M", "PT5S")
  - start: ISO 8601 datetime string (e.g., "2025-10-28T10:37:27Z")
  - end: ISO 8601 datetime string (e.g., "2025-10-28T10:37:27Z")
  """

  defstruct [
    :duration,
    :start,
    :end
  ]

  @type t :: %__MODULE__{
          duration: String.t() | nil,
          start: String.t() | nil,
          end: String.t() | nil
        }

  @doc """
  Creates a new TemporalConstraints struct.

  ## Parameters
  - `duration`: ISO 8601 duration string (optional, e.g., "PT1H30M")
  - `start`: ISO 8601 datetime string (optional, e.g., "2025-10-28T10:37:27Z")
  - `end`: ISO 8601 datetime string (optional, e.g., "2025-10-28T10:37:27Z")

  ## Examples

      iex> AriaCore.Metadata.TemporalConstraints.new(duration: "PT100MS")
      %AriaCore.Metadata.TemporalConstraints{duration: "PT100MS", start: nil, end: nil}

      iex> AriaCore.Metadata.TemporalConstraints.new(
      ...>   start: "2025-10-28T10:37:27Z",
      ...>   end: "2025-10-28T10:38:27Z"
      ...> )
      %AriaCore.Metadata.TemporalConstraints{
        duration: nil,
        start: "2025-10-28T10:37:27Z",
        end: "2025-10-28T10:38:27Z"
      }
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      duration: Keyword.get(opts, :duration),
      start: Keyword.get(opts, :start),
      end: Keyword.get(opts, :end)
    }
  end
end
