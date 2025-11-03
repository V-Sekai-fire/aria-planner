# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Temporal.STN.UnitsTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.Temporal.STN
  alias AriaPlanner.Planner.Temporal.STN.Units

  describe "lod_resolution_for_level/1" do
    test "returns correct resolution for ultra_high" do
      assert Units.lod_resolution_for_level(:ultra_high) == 1
    end

    test "returns correct resolution for high" do
      assert Units.lod_resolution_for_level(:high) == 10
    end

    test "returns correct resolution for medium" do
      assert Units.lod_resolution_for_level(:medium) == 100
    end

    test "returns correct resolution for low" do
      assert Units.lod_resolution_for_level(:low) == 1000
    end

    test "returns correct resolution for very_low" do
      assert Units.lod_resolution_for_level(:very_low) == 10000
    end
  end

  describe "unit_to_microseconds/1" do
    test "converts microsecond correctly" do
      assert Units.unit_to_microseconds(:microsecond) == 1
    end

    test "converts millisecond correctly" do
      assert Units.unit_to_microseconds(:millisecond) == 1000
    end

    test "converts second correctly" do
      assert Units.unit_to_microseconds(:second) == 1_000_000
    end

    test "converts minute correctly" do
      assert Units.unit_to_microseconds(:minute) == 60_000_000
    end

    test "converts hour correctly" do
      assert Units.unit_to_microseconds(:hour) == 3_600_000_000
    end

    test "converts day correctly" do
      assert Units.unit_to_microseconds(:day) == 86_400_000_000
    end
  end

  describe "unit_conversion_factor/2" do
    test "converts from seconds to milliseconds" do
      assert Units.unit_conversion_factor(:second, :millisecond) == 1000.0
    end

    test "converts from milliseconds to seconds" do
      assert Units.unit_conversion_factor(:millisecond, :second) == 0.001
    end

    test "converts from minutes to seconds" do
      assert Units.unit_conversion_factor(:minute, :second) == 60.0
    end

    test "converts from hours to minutes" do
      assert Units.unit_conversion_factor(:hour, :minute) == 60.0
    end

    test "converts from days to hours" do
      assert Units.unit_conversion_factor(:day, :hour) == 24.0
    end
  end

  describe "unit_precision/1" do
    test "returns correct precision values" do
      assert Units.unit_precision(:microsecond) == 1
      assert Units.unit_precision(:millisecond) == 2
      assert Units.unit_precision(:second) == 3
      assert Units.unit_precision(:minute) == 4
      assert Units.unit_precision(:hour) == 5
      assert Units.unit_precision(:day) == 6
    end
  end

  describe "lod_precision/1" do
    test "returns correct precision values" do
      assert Units.lod_precision(:ultra_high) == 1
      assert Units.lod_precision(:high) == 2
      assert Units.lod_precision(:medium) == 3
      assert Units.lod_precision(:low) == 4
      assert Units.lod_precision(:very_low) == 5
    end
  end

  describe "convert_microseconds_to_stn_units/3" do
    test "converts microseconds to STN units with LOD resolution" do
      # 1 second = 1,000,000 microseconds
      # With LOD resolution 100, should be 100 STN units (1 second * 100 resolution)
      result = Units.convert_microseconds_to_stn_units(1_000_000, :second, 100)
      assert result == 100
    end

    test "converts with different LOD resolutions" do
      result = Units.convert_microseconds_to_stn_units(1_000_000, :second, 10)
      assert result == 10
    end
  end

  describe "convert_datetime_duration_to_stn_units/5" do
    test "converts DateTime duration to STN units" do
      start_dt = ~U[2025-09-26 10:00:00Z]
      # 1 hour difference
      end_dt = ~U[2025-09-26 11:00:00Z]

      result =
        Units.convert_datetime_duration_to_stn_units(
          start_dt,
          end_dt,
          :second,
          :medium,
          100
        )

      # 1 hour = 3600 seconds, with LOD 100 = 360,000 STN units
      assert result == 360_000
    end

    test "handles different time units" do
      start_dt = ~U[2025-09-26 10:00:00Z]
      # 1 minute difference
      end_dt = ~U[2025-09-26 10:01:00Z]

      result =
        Units.convert_datetime_duration_to_stn_units(
          start_dt,
          end_dt,
          :minute,
          :high,
          10
        )

      # 1 minute = 1 minute unit, with LOD 10 = 10 STN units
      assert result == 10
    end
  end

  describe "convert_iso8601_duration_to_stn_units/4" do
    test "converts fixed ISO 8601 duration" do
      result =
        Units.convert_iso8601_duration_to_stn_units(
          "PT30M",
          :second,
          :medium,
          100
        )

      # 30 minutes * 100 resolution = 180000 seconds in STN units
      assert result == {180_000, 180_000}
    end

    test "converts variable ISO 8601 duration" do
      result =
        Units.convert_iso8601_duration_to_stn_units(
          "PT15M/PT45M",
          :second,
          :medium,
          100
        )

      # 15-45 minutes in seconds * 100 resolution
      assert result == {90000, 270_000}
    end

    test "returns error for invalid ISO 8601 duration" do
      result =
        Units.convert_iso8601_duration_to_stn_units(
          "INVALID",
          :second,
          :medium,
          100
        )

      assert {:error, _} = result
    end
  end

  describe "rescale_lod/2" do
    test "rescales STN constraints when changing LOD level" do
      stn = STN.new(time_unit: :second, lod_level: :medium)
      # Create constraint without adding time points to avoid solver
      stn = %{stn | constraints: %{{"start", "end"} => {100, 200}}}

      rescaled_stn = Units.rescale_lod(stn, :low)

      # Medium resolution = 100, Low resolution = 1000
      # Scale factor = 100/1000 = 0.1
      # So {100, 200} becomes {10, 20}
      constraint = Map.get(rescaled_stn.constraints, {"start", "end"})
      assert constraint == {10, 20}
      assert rescaled_stn.lod_level == :low
      assert rescaled_stn.lod_resolution == 1000
    end

    test "returns same STN when LOD level unchanged" do
      stn = STN.new(time_unit: :second, lod_level: :medium)
      rescaled_stn = Units.rescale_lod(stn, :medium)

      assert rescaled_stn == stn
    end
  end

  describe "convert_units/2" do
    test "converts STN time units and scales constraints" do
      stn = STN.new(time_unit: :second)
      # Create constraint without adding time points to avoid solver
      stn = %{stn | constraints: %{{"start", "end"} => {60, 120}}}

      converted_stn = Units.convert_units(stn, :minute)

      # Converting from seconds to minutes: divide by 60
      # {60, 120} becomes {1, 2}
      constraint = Map.get(converted_stn.constraints, {"start", "end"})
      assert constraint == {1, 2}
      assert converted_stn.time_unit == :minute
    end

    test "returns same STN when time unit unchanged" do
      stn = STN.new(time_unit: :second)
      converted_stn = Units.convert_units(stn, :second)

      assert converted_stn == stn
    end
  end

  describe "from_datetime_intervals/2" do
    test "creates STN from DateTime intervals" do
      interval = %{
        id: "test_interval",
        start_time: ~U[2025-09-26 10:00:00Z],
        end_time: ~U[2025-09-26 11:00:00Z],
        duration: "PT1H"
      }

      result = Units.from_datetime_intervals([interval], time_unit: :second, lod_level: :medium)

      assert result.time_unit == :second
      assert result.lod_level == :medium
      assert MapSet.size(result.time_points) > 0
    end

    test "handles multiple intervals" do
      intervals = [
        %{
          id: "interval1",
          start_time: ~U[2025-09-26 10:00:00Z],
          end_time: ~U[2025-09-26 11:00:00Z],
          duration: "PT1H"
        },
        %{
          id: "interval2",
          start_time: ~U[2025-09-26 11:00:00Z],
          end_time: ~U[2025-09-26 12:00:00Z],
          duration: "PT1H"
        }
      ]

      result = Units.from_datetime_intervals(intervals, time_unit: :second, lod_level: :medium)

      assert result.time_unit == :second
      assert result.lod_level == :medium
      assert MapSet.size(result.time_points) > 0
    end
  end
end
