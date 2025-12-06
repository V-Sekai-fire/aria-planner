# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.TimeRangeTest do
  use ExUnit.Case, async: true
  doctest AriaPlanner.Planner.TimeRange

  alias AriaPlanner.Planner.TimeRange

  describe "new/1" do
    test "creates empty time range" do
      time_range = TimeRange.new()
      assert time_range.start_time == nil
      assert time_range.end_time == nil
      assert time_range.duration == nil
    end

    test "creates time range with options" do
      time_range =
        TimeRange.new(
          start_time: "2025-01-01T10:00:00Z",
          end_time: "2025-01-01T10:30:00Z",
          duration: "PT30M"
        )

      assert time_range.start_time == "2025-01-01T10:00:00Z"
      assert time_range.end_time == "2025-01-01T10:30:00Z"
      assert time_range.duration == "PT30M"
    end
  end

  describe "set_start_now/1" do
    test "sets start time to current time" do
      time_range = TimeRange.new() |> TimeRange.set_start_now()
      assert time_range.start_time != nil
      assert String.contains?(time_range.start_time, "T")
      assert String.contains?(time_range.start_time, "Z")
    end
  end

  describe "set_end_now/1" do
    test "sets end time to current time" do
      time_range = TimeRange.new() |> TimeRange.set_end_now()
      assert time_range.end_time != nil
      assert String.contains?(time_range.end_time, "T")
      assert String.contains?(time_range.end_time, "Z")
    end
  end

  describe "set_start_time/2 and get_start_time/1" do
    test "sets and gets start time" do
      time_range =
        TimeRange.new()
        |> TimeRange.set_start_time("2025-01-01T10:00:00Z")

      assert TimeRange.get_start_time(time_range) == "2025-01-01T10:00:00Z"
    end
  end

  describe "set_end_time/2 and get_end_time/1" do
    test "sets and gets end time" do
      time_range =
        TimeRange.new()
        |> TimeRange.set_end_time("2025-01-01T10:30:00Z")

      assert TimeRange.get_end_time(time_range) == "2025-01-01T10:30:00Z"
    end
  end

  describe "set_duration/2 and get_duration/1" do
    test "sets and gets duration" do
      time_range =
        TimeRange.new()
        |> TimeRange.set_duration("PT30M")

      assert TimeRange.get_duration(time_range) == "PT30M"
    end
  end

  describe "calculate_duration/1" do
    test "calculates duration from start and end time" do
      time_range =
        TimeRange.new(
          start_time: "2025-01-01T10:00:00Z",
          end_time: "2025-01-01T10:30:00Z"
        )

      result = TimeRange.calculate_duration(time_range)
      assert result.duration == "PT30M"
    end

    test "returns unchanged if start or end time missing" do
      time_range = TimeRange.new(start_time: "2025-01-01T10:00:00Z")
      result = TimeRange.calculate_duration(time_range)
      assert result.duration == nil
    end
  end

  describe "calculate_end_from_duration/1" do
    test "calculates end time from start and duration" do
      time_range =
        TimeRange.new(
          start_time: "2025-01-01T10:00:00Z",
          duration: "PT30M"
        )

      result = TimeRange.calculate_end_from_duration(time_range)
      assert result.end_time != nil
      assert result.end_time > time_range.start_time
    end

    test "returns unchanged if start or duration missing" do
      time_range = TimeRange.new(duration: "PT30M")
      result = TimeRange.calculate_end_from_duration(time_range)
      assert result.end_time == nil
    end
  end

  describe "now_iso8601/0" do
    test "returns current time in ISO 8601 format" do
      now = TimeRange.now_iso8601()
      assert String.contains?(now, "T")
      assert String.contains?(now, "Z")
    end
  end

  describe "to_map/1 and from_map/1" do
    test "converts to and from map" do
      time_range =
        TimeRange.new(
          start_time: "2025-01-01T10:00:00Z",
          end_time: "2025-01-01T10:30:00Z",
          duration: "PT30M"
        )

      map = TimeRange.to_map(time_range)
      restored = TimeRange.from_map(map)
      assert restored.start_time == time_range.start_time
      assert restored.end_time == time_range.end_time
      assert restored.duration == time_range.duration
    end

    test "handles nil values in map" do
      time_range = TimeRange.new()
      map = TimeRange.to_map(time_range)
      assert map_size(map) == 0
    end
  end
end
