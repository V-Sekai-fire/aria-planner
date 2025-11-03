# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Temporal.STN.SchedulingTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.Temporal.STN
  alias AriaPlanner.Planner.Temporal.STN.Scheduling

  describe "get_intervals/1" do
    test "returns empty list for STN with no intervals" do
      stn = STN.new()

      intervals = Scheduling.get_intervals(stn)

      assert intervals == []
    end

    test "extracts intervals from time points" do
      stn = STN.new()
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {10, 10})
      stn = STN.add_constraint(stn, "task2_start", "task2_end", {20, 20})

      # Add metadata
      stn = %{stn | metadata: %{"task1" => %{action: "action1"}, "task2" => %{action: "action2"}}}

      intervals = Scheduling.get_intervals(stn)

      assert length(intervals) == 2

      task1 = Enum.find(intervals, fn i -> i.id == "task1" end)
      task2 = Enum.find(intervals, fn i -> i.id == "task2" end)

      # Default start time
      assert task1.start_time == 0
      assert task1.end_time == 10
      assert task1.metadata.action == "action1"

      assert task2.start_time == 0
      assert task2.end_time == 20
      assert task2.metadata.action == "action2"
    end
  end

  describe "get_overlapping_intervals/3" do
    test "finds intervals overlapping with query window" do
      stn = STN.new()
      # Add some intervals (all start at time 0)
      # task1: 0-10
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {10, 10})
      # task2: 0-15
      stn = STN.add_constraint(stn, "task2_start", "task2_end", {15, 15})
      # task3: 0-25
      stn = STN.add_constraint(stn, "task3_start", "task3_end", {25, 25})

      overlapping = Scheduling.get_overlapping_intervals(stn, 12, 18)

      # Query window 12-18 overlaps with task2 (0-15) and task3 (0-25)
      assert length(overlapping) == 2
      ids = Enum.map(overlapping, & &1.id)
      assert "task2" in ids
      assert "task3" in ids
    end

    test "returns empty list when no overlaps" do
      stn = STN.new()
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {10, 10})

      overlapping = Scheduling.get_overlapping_intervals(stn, 20, 30)

      assert overlapping == []
    end
  end

  describe "find_free_slots/4" do
    test "finds free time slots between existing intervals" do
      stn = STN.new()
      # Add interval from 0-10 (task1 starts at 0 and has duration 10)
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {10, 10})

      free_slots = Scheduling.find_free_slots(stn, 5, 0, 30)

      # Should find slots after the interval (from 10-30)
      assert length(free_slots) >= 1
    end

    test "returns empty list when no free slots available" do
      stn = STN.new()
      # Fill the entire window from 0-10
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {10, 10})

      # Try to find a slot larger than what could possibly fit after subtracting the occupied interval
      free_slots = Scheduling.find_free_slots(stn, 5, 0, 10)

      # Should return empty list (no slots >= 5 seconds available after task1 occupies 0-10)
      assert free_slots == []
    end
  end

  describe "check_interval_conflicts/3" do
    test "detects conflicts with existing intervals" do
      stn = STN.new()
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {10, 10})

      conflicts = Scheduling.check_interval_conflicts(stn, 5, 15)

      # Should find the conflicting interval
      assert length(conflicts) == 1
      assert List.first(conflicts).id == "task1"
    end

    test "returns empty list when no conflicts" do
      stn = STN.new()
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {10, 10})

      conflicts = Scheduling.check_interval_conflicts(stn, 20, 25)

      assert conflicts == []
    end
  end

  describe "merge_overlapping_intervals/1" do
    test "leaves non-overlapping intervals unchanged" do
      intervals = [
        %{start_time: 0, end_time: 5},
        %{start_time: 10, end_time: 15},
        %{start_time: 20, end_time: 25}
      ]

      merged = Scheduling.merge_overlapping_intervals(intervals)

      assert length(merged) == 3
    end
  end

  describe "calculate_interval_gaps/2" do
    test "calculates gaps between intervals" do
      intervals = [
        %{start_time: 0, end_time: 5},
        %{start_time: 10, end_time: 15}
      ]

      gaps = Scheduling.calculate_interval_gaps(intervals, 20)

      assert length(gaps) >= 1
      # Should have a gap from 5-10
      gap = Enum.find(gaps, fn g -> g.start_time == 5 end)
      assert gap.end_time == 10
    end
  end
end
