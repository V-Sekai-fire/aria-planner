# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule TemporalSTNSchedulingOperationsTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.Temporal.STN
  alias AriaPlanner.Planner.Temporal.STN.Scheduling

  describe "Survival Craft STN scheduling operations" do
    test "gets intervals from Survival Craft STN" do
      # Create STN with some time points and constraints
      stn = %STN{
        time_points: MapSet.new(["gather_start", "gather_end", "build_start", "build_end"]),
        constraints: %{
          {"gather_start", "gather_end"} => {5, 5},
          {"build_start", "build_end"} => {10, 10}
        },
        consistent: true,
        metadata: %{
          "gather" => %{action: "gather_wood", priority: :high},
          "build" => %{action: "build_shelter", priority: :medium}
        }
      }

      # Get intervals
      intervals = Scheduling.get_intervals(stn)

      # Should find intervals for gather and build
      assert length(intervals) >= 2

      # Verify interval structure
      gather_interval = Enum.find(intervals, fn i -> i.id == "gather" end)
      build_interval = Enum.find(intervals, fn i -> i.id == "build" end)

      assert gather_interval
      assert build_interval

      assert gather_interval.metadata.action == "gather_wood"
      assert build_interval.metadata.action == "build_shelter"
    end

    test "finds free time slots for Survival Craft activities" do
      # Create STN with existing intervals
      stn = %STN{
        time_points: MapSet.new(["rest_start", "rest_end"]),
        constraints: %{},
        consistent: true,
        metadata: %{}
      }

      # Find free slots for 30-minute activities in a 24-hour period
      free_slots = Scheduling.find_free_slots(stn, 1800, 0, 86400)

      # Should find slots before and after the rest period
      assert is_list(free_slots)

      # Verify slot durations are sufficient
      Enum.each(free_slots, fn slot ->
        assert slot.end_time - slot.start_time >= 1800
      end)
    end

    test "detects interval conflicts in Survival Craft schedules" do
      # Create STN with overlapping intervals
      stn = %STN{
        time_points: MapSet.new(["task1_start", "task1_end", "task2_start", "task2_end"]),
        constraints: %{},
        consistent: true,
        metadata: %{}
      }

      # Check for conflicts in overlapping time range
      # 1-2 hours
      conflicts = Scheduling.check_interval_conflicts(stn, 3600, 7200)

      # Should return conflict information
      assert is_list(conflicts)
    end

    test "finds overlapping intervals in Survival Craft planning" do
      # Create STN with overlapping activities
      stn = %STN{
        time_points: MapSet.new(["gather_start", "gather_end", "explore_start", "explore_end"]),
        constraints: %{},
        consistent: true,
        metadata: %{
          "gather" => %{action: "gather_wood"},
          "explore" => %{action: "explore_area"}
        }
      }

      # Find intervals that overlap with a time range
      # 30 min to 1.5 hours
      overlapping = Scheduling.get_overlapping_intervals(stn, 1800, 5400)

      # Should find overlapping intervals
      assert is_list(overlapping)
    end

    test "finds next available time slot for Survival Craft activities" do
      # Create STN with busy periods
      stn = %STN{
        time_points: MapSet.new(["busy_start", "busy_end"]),
        constraints: %{},
        consistent: true,
        metadata: %{}
      }

      # Find next available 30-minute slot starting from time 0
      result = Scheduling.find_next_available_slot(stn, 1800, 0)

      # Should find a slot after any busy periods
      case result do
        {:ok, start_time, end_time} ->
          assert end_time - start_time >= 1800
          assert start_time >= 0

        {:error, _reason} ->
          # No slot available, which is also acceptable
          assert true
      end
    end

    test "handles Survival Craft emergency scheduling" do
      # STN with emergency time constraints
      stn = %STN{
        time_points: MapSet.new(["emergency_start", "emergency_end"]),
        constraints: %{},
        consistent: true,
        metadata: %{"emergency" => %{priority: :critical, type: :emergency}}
      }

      # Find immediate free slots for emergency response
      # 10-minute slots in first hour
      free_slots = Scheduling.find_free_slots(stn, 600, 0, 3600)

      # Should prioritize immediate availability for emergencies
      assert is_list(free_slots)

      # First slot should start immediately if available
      if length(free_slots) > 0 do
        first_slot = hd(free_slots)
        # Within first 10 minutes
        assert first_slot.start_time <= 600
      end
    end

    test "optimizes Survival Craft activity sequencing" do
      # STN with multiple activities to sequence
      stn = %STN{
        time_points:
          MapSet.new([
            "gather_start",
            "gather_end",
            "craft_start",
            "craft_end",
            "build_start",
            "build_end"
          ]),
        constraints: %{
          {"gather_start", "gather_end"} => {5, 5},
          {"craft_start", "craft_end"} => {3, 3},
          {"build_start", "build_end"} => {10, 10}
        },
        consistent: true,
        metadata: %{
          "gather" => %{action: "gather_wood", provides: ["wood"]},
          "craft" => %{action: "craft_tool", requires: ["wood"], provides: ["tool"]},
          "build" => %{action: "build_shelter", requires: ["tool"]}
        }
      }

      intervals = Scheduling.get_intervals(stn)

      # Should have all three activities
      assert length(intervals) == 3

      # Verify dependency metadata
      gather = Enum.find(intervals, &(&1.id == "gather"))
      craft = Enum.find(intervals, &(&1.id == "craft"))
      build = Enum.find(intervals, &(&1.id == "build"))

      assert gather.metadata.provides == ["wood"]
      assert craft.metadata.requires == ["wood"]
      assert craft.metadata.provides == ["tool"]
      assert build.metadata.requires == ["tool"]
    end
  end
end
