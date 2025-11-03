# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Temporal.STN.Operations do
  @moduledoc """
  Core STN operations for interval and constraint management.

  This module handles the fundamental operations of Simple Temporal Networks:
  - Adding and removing intervals
  - Managing time points
  - Adding and updating constraints
  - Constraint intersection and validation
  """

  alias AriaPlanner.Planner.Temporal.Interval
  alias AriaPlanner.Planner.Temporal.STN
  use Timex # Add Timex for datetime parsing

  @type constraint :: {number(), number()}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}

  @doc """
  Adds a temporal constraint between two time points.

  The constraint represents the allowable distance between the time points
  as {min_distance, max_distance}. Supports :infinity for unbounded constraints.
  """
  @spec add_constraint(STN.t(), time_point(), time_point(), constraint()) :: STN.t()
  def add_constraint(stn, from_point, to_point, {min_dist, max_dist} = constraint)
      when (is_number(min_dist) or min_dist == :neg_infinity) and
             (is_number(max_dist) or max_dist == :infinity) do
    unless valid_constraint_bounds?(min_dist, max_dist) do
      raise ArgumentError, "Invalid constraint bounds: #{inspect(constraint)}"
    end

    stn = stn |> add_time_point(from_point) |> add_time_point(to_point)
    current_constraints = stn.constraints
    is_consistent = stn.consistent

    {updated_constraints_1, consistent_1} =
      update_single_constraint(current_constraints, {from_point, to_point}, constraint)

    reverse_constraint = {negate_constraint_value(max_dist), negate_constraint_value(min_dist)}

    {updated_constraints_2, consistent_2} =
      update_single_constraint(updated_constraints_1, {to_point, from_point}, reverse_constraint)

    final_consistent = is_consistent and consistent_1 and consistent_2

    # Debug logging
    if not final_consistent do
      require Logger

      Logger.debug("Constraint inconsistency detected: #{from_point} -> #{to_point} #{inspect(constraint)}")

      Logger.debug("Initial consistent: #{is_consistent}, step1: #{consistent_1}, step2: #{consistent_2}")

      Logger.debug("Reverse constraint: #{inspect(reverse_constraint)}")
    end

    updated_stn = %{stn | constraints: updated_constraints_2, consistent: final_consistent}
    updated_stn
  end

  @doc """
  Adds an interval to the STN with automatic unit conversion and LOD rescaling.

  This creates two time points (start and end) and adds the necessary
  temporal constraints. Then applies constraint solving to maintain consistency.

  The interval's DateTime values are automatically converted to the STN's
  declared time units and rescaled according to the LOD level.
  """
  @spec add_interval(STN.t(), Interval.t()) :: STN.t()
  def add_interval(stn, interval) do
    start_point = "#{interval.id}_start"
    end_point = "#{interval.id}_end"

    # Convert ISO 8601 strings to DateTime if needed
    start_dt = convert_to_datetime(interval.start_time)
    end_dt = convert_to_datetime(interval.end_time)

    # Handle duration constraint
    duration_constraint =
      if start_dt && end_dt do
        # Calculate duration from DateTime start and end
        duration =
          STN.Units.convert_datetime_duration_to_stn_units(
            start_dt,
            end_dt,
            stn.time_unit,
            stn.lod_level,
            stn.lod_resolution
          )

        # Ensure minimum duration of 1 STN unit
        duration = max(duration, 1)
        {duration, duration}
      else
        # Use ISO 8601 duration string
        case STN.Units.convert_iso8601_duration_to_stn_units(
               interval.duration,
               stn.time_unit,
               stn.lod_level,
               stn.lod_resolution
             ) do
          {min_dur, max_dur} ->
            {max(min_dur, 1), max(max_dur, 1)}
        end
      end

    stn_with_points =
      stn
      |> add_time_point(start_point)
      |> add_time_point(end_point)
      |> add_constraint(start_point, end_point, duration_constraint)

    # Handle calendar time anchoring
    stn_with_anchors =
      if start_dt do
        anchor_to_reference_datetime(stn_with_points, start_point, start_dt)
      else
        stn_with_points
      end

    stn_with_anchors =
      if end_dt do
        anchor_to_reference_datetime(stn_with_anchors, end_point, end_dt)
      else
        stn_with_anchors
      end

    stn_with_anchors
  end

  @doc """
  Adds a time point to the STN.
  """
  @spec add_time_point(STN.t(), time_point()) :: STN.t()
  def add_time_point(stn, time_point) do
    updated_time_points = MapSet.put(stn.time_points, time_point)
    # No self-constraint needed - distance from point to itself is implicitly zero
    %{stn | time_points: updated_time_points}
  end

  @doc """
  Gets all time points in the STN.
  """
  @spec time_points(STN.t()) :: [time_point()]
  def time_points(stn) do
    MapSet.to_list(stn.time_points)
  end

  # Private helper functions

  defp valid_constraint_bounds?(min_dist, max_dist) do
    case {min_dist, max_dist} do
      {:neg_infinity, :infinity} ->
        true

      {:neg_infinity, max_dist} when is_number(max_dist) ->
        true

      {min_dist, :infinity} when is_number(min_dist) ->
        true

      {min_dist, max_dist} when is_number(min_dist) and is_number(max_dist) ->
        min_dist <= max_dist

      _ ->
        false
    end
  end

  # Note: intersect_constraints moved to public function below

  defp constraint_max(:neg_infinity, other) do
    other
  end

  defp constraint_max(other, :neg_infinity) do
    other
  end

  defp constraint_max(:infinity, _) do
    :infinity
  end

  defp constraint_max(_, :infinity) do
    :infinity
  end

  defp constraint_max(a, b) when is_number(a) and is_number(b) do
    max(a, b)
  end

  defp constraint_min(:infinity, other) do
    other
  end

  defp constraint_min(other, :infinity) do
    other
  end

  defp constraint_min(:neg_infinity, _) do
    :neg_infinity
  end

  defp constraint_min(_, :neg_infinity) do
    :neg_infinity
  end

  defp constraint_min(a, b) when is_number(a) and is_number(b) do
    min(a, b)
  end

  defp constraint_greater_than?(:infinity, _) do
    false
  end

  defp constraint_greater_than?(_, :neg_infinity) do
    false
  end

  defp constraint_greater_than?(:neg_infinity, _) do
    true
  end

  defp constraint_greater_than?(_, :infinity) do
    true
  end

  defp constraint_greater_than?(a, b) when is_number(a) and is_number(b) do
    a > b
  end

  defp negate_constraint_value(:infinity) do
    :neg_infinity
  end

  defp negate_constraint_value(:neg_infinity) do
    :infinity
  end

  defp negate_constraint_value(value) when is_number(value) do
    -value
  end

  defp update_single_constraint(constraints, key, new_constraint) do
    case Map.get(constraints, key) do
      nil ->
        {Map.put(constraints, key, new_constraint), true}

      existing_constraint ->
        case intersect_constraints(existing_constraint, new_constraint) do
          :empty ->
            {constraints, false}

          intersected_constraint ->
            {Map.put(constraints, key, intersected_constraint), true}
        end
    end
  end

  @doc """
  Anchors a time point to a reference datetime by setting up the reference time point
  and adding the appropriate constraint.
  """
  @spec anchor_to_reference_datetime(STN.t(), STN.time_point(), DateTime.t()) :: STN.t()
  def anchor_to_reference_datetime(stn, time_point, datetime) do
    reference_point = "unix_epoch"

    # Calculate offset from Unix epoch (1970-01-01 00:00:00Z)
    epoch = ~U[1970-01-01 00:00:00Z]
    offset_microseconds = DateTime.diff(datetime, epoch, :microsecond)

    offset_stn_units =
      STN.Units.convert_microseconds_to_stn_units(
        offset_microseconds,
        stn.time_unit,
        stn.lod_resolution
      )

    # Add reference time point and constraint
    stn
    |> add_time_point(reference_point)
    |> add_constraint(reference_point, time_point, {offset_stn_units, offset_stn_units})
  end

  @doc """
  Removes a constraint between two time points.

  Returns updated STN with constraint removed, or :not_found if constraint
  doesn't exist between these points.
  """
  @spec remove_constraint(STN.t(), time_point(), time_point()) :: STN.t()
  def remove_constraint(stn, from_point, to_point) do
    key = {from_point, to_point}
    reverse_key = {to_point, from_point}

    case {Map.has_key?(stn.constraints, key), Map.has_key?(stn.constraints, reverse_key)} do
      {true, true} ->
        # Remove both forward and reverse constraints
        updated_constraints =
          stn.constraints
          |> Map.delete(key)
          |> Map.delete(reverse_key)

        %{stn | constraints: updated_constraints}

      _ ->
        # Return original STN if constraint doesn't exist
        stn
    end
  end

  @doc """
  Gets the constraint between two time points.

  Returns {:ok, constraint} if found, or {:error, :constraint_not_found} if not.
  """
  @spec get_constraint(STN.t(), time_point(), time_point()) ::
          {:ok, constraint()} | {:error, :constraint_not_found}
  def get_constraint(stn, from_point, to_point) do
    case Map.fetch(stn.constraints, {from_point, to_point}) do
      :error -> {:error, :constraint_not_found}
      {:ok, constraint} -> {:ok, constraint}
    end
  end

  @doc """
  Tightens an existing constraint if the new constraint is stricter.

  The "tightening" constraint will narrow the bounds if it creates
  a smaller interval than the existing constraint.
  """
  @spec tighten_constraint(constraint(), constraint()) :: constraint() | :cannot_tighten
  def tighten_constraint(existing, tightening) do
    new_min = constraint_max(elem(existing, 0), elem(tightening, 0))
    new_max = constraint_min(elem(existing, 1), elem(tightening, 1))

    if constraint_less_or_equal?(new_min, new_max) do
      {new_min, new_max}
    else
      :cannot_tighten
    end
  end

  @doc """
  Intersects two constraints to find the most restrictive common constraint.

  Returns the intersection if constraints are compatible, or :inconsistent if not.
  """
  @spec intersect_constraints(constraint(), constraint()) :: constraint() | :empty
  def intersect_constraints({min1, max1}, {min2, max2}) do
    new_min = constraint_max(min1, min2)
    new_max = constraint_min(max1, max2)

    if constraint_greater_than?(new_min, new_max) do
      :empty
    else
      {new_min, new_max}
    end
  end

  # Private helper for tighten_constraint
  defp constraint_less_or_equal?(:neg_infinity, _), do: true
  defp constraint_less_or_equal?(_, :infinity), do: true
  defp constraint_less_or_equal?(a, b) when is_number(a) and is_number(b), do: a <= b
  defp constraint_less_or_equal?(_, _), do: false

  @doc """
  Converts ISO 8601 datetime string or DateTime struct to DateTime struct.
  Returns nil if input is nil or invalid.
  """
  @spec convert_to_datetime(String.t() | DateTime.t() | nil) :: DateTime.t() | nil
  def convert_to_datetime(nil), do: nil
  def convert_to_datetime(%DateTime{} = dt), do: dt

  def convert_to_datetime(datetime_string) when is_binary(datetime_string) do
    case Timex.parse(datetime_string, "{ISO:Extended}") do
      {:ok, datetime} -> datetime
      {:error, _} -> nil
    end
  end

  def convert_to_datetime(_), do: nil
end
