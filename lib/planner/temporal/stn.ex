# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Temporal.STN do
  @moduledoc """
  Simple Temporal Network (STN) implementation for AriaPlanner.Planner.

  This module provides internal STN capabilities for temporal constraint solving
  within the hybrid planner. It supports:

  - Temporal constraint management
  - Interval scheduling and conflict detection
  - Time unit conversion and LOD scaling
  - Pure Elixir constraint solving using Floyd-Warshall algorithm
  - Parallel processing for large STNs

  ## Architecture

  STNs represent temporal constraints as a network of time points connected by
  distance constraints. The network maintains:

  - **Time Points**: Named temporal anchors (e.g., "action_start", "action_end")
  - **Constraints**: Minimum/maximum time distances between points
  - **Consistency**: Floyd-Warshall algorithm ensures no constraint violations

  ## Level of Detail (LOD)

  Supports multiple temporal resolutions:
  - `:ultra_high` - Microsecond precision (1µs resolution)
  - `:high` - Millisecond precision (1ms resolution)
  - `:medium` - Second precision (100ms resolution) [default]
  - `:low` - Minute precision (10s resolution)
  - `:very_low` - Hour precision (10min resolution)

  ## Usage

  STNs are used internally by AriaPlanner for:
  - Validating temporal consistency of action plans
  - Scheduling durative actions with resource constraints
  - Optimizing temporal execution sequences
  - Resolving temporal conflicts during planning

  ## Example

      # Create a new STN for internal planner use
      stn = AriaPlanner.Planner.Temporal.STN.new(time_unit: :second)

      # Add temporal constraints (used internally by planner)
      stn = AriaPlanner.Planner.Temporal.STN.add_constraint(stn, "action1_start", "action1_end", {10, 15})

      # Check consistency
      AriaPlanner.Planner.Temporal.STN.consistent?(stn)

      # Find free time slots
      slots = AriaPlanner.Planner.Temporal.STN.find_free_slots(stn, 30, 0, 100)
  """

  alias AriaPlanner.Planner.Temporal.STN.{Operations, Consistency, Scheduling, Units}

  @type constraint :: {number(), number()}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10000

  @type t :: %__MODULE__{
          time_points: MapSet.t(time_point()),
          constraints: constraint_matrix(),
          consistent: boolean(),
          time_unit: time_unit(),
          lod_level: lod_level(),
          lod_resolution: lod_resolution(),
          metadata: map()
        }

  defstruct time_points: MapSet.new(),
            constraints: %{},
            consistent: true,
            time_unit: :second,
            lod_level: :medium,
            lod_resolution: 100,
            metadata: %{}

  @doc """
  Creates a new empty Simple Temporal Network.

  Uses seconds as the default time unit for human-readable temporal constraints.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{time_points: MapSet.new(), constraints: %{}, consistent: true, time_unit: :second}
  end

  @doc """
  Creates a new Simple Temporal Network with specified units and LOD level.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    time_unit = Keyword.get(opts, :time_unit, :second)
    lod_level = Keyword.get(opts, :lod_level, :medium)

    %__MODULE__{
      time_points: MapSet.new(),
      constraints: %{},
      consistent: true,
      time_unit: time_unit,
      lod_level: lod_level,
      lod_resolution: Units.lod_resolution_for_level(lod_level),
      metadata: %{}
    }
  end

  # Delegate to Operations module
  defdelegate add_interval(stn, interval), to: Operations
  defdelegate add_constraint(stn, from_point, to_point, constraint), to: Operations

  # Delegate to Consistency module
  defdelegate consistent?(stn), to: Consistency

  # Delegate to Scheduling module
  defdelegate get_intervals(stn), to: Scheduling
  defdelegate get_overlapping_intervals(stn, query_start, query_end), to: Scheduling
  defdelegate find_free_slots(stn, duration, window_start, window_end), to: Scheduling
  defdelegate check_interval_conflicts(stn, new_start, new_end), to: Scheduling
  defdelegate find_next_available_slot(stn, duration, earliest_start), to: Scheduling

  # Delegate to Units module
  defdelegate rescale_lod(stn, new_lod_level), to: Units
  defdelegate convert_units(stn, new_unit), to: Units
  defdelegate from_datetime_intervals(intervals, opts), to: Units

  # Private implementation functions
end
