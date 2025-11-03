# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Temporal.STNTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.Temporal.STN

  describe "new/1" do
    test "creates a new STN with default time unit" do
      stn = STN.new()

      assert is_map(stn)
      assert Map.has_key?(stn, :time_points)
      assert Map.has_key?(stn, :constraints)
      assert Map.has_key?(stn, :consistent)
      assert stn.consistent == true
    end

    test "creates a new STN with specified time unit" do
      stn = STN.new(time_unit: :millisecond)

      assert is_map(stn)
      assert stn.time_points == MapSet.new()
    end
  end

  describe "add_constraint/4" do
    test "adds a temporal constraint between time points" do
      stn = STN.new()
      # min 5, max 10
      constraint = {5, 10}

      result = STN.add_constraint(stn, :start, :end, constraint)

      assert Map.has_key?(result.constraints, {:start, :end})
      assert result.constraints[{:start, :end}] == constraint
    end
  end

  describe "consistent?/1" do
    test "returns true for empty STN" do
      stn = STN.new()
      assert STN.consistent?(stn) == true
    end

    test "returns true for simple consistent constraints" do
      stn = STN.new()
      stn = STN.add_constraint(stn, "a", "b", {1, 5})
      stn = STN.add_constraint(stn, "b", "c", {2, 8})

      assert STN.consistent?(stn) == true
    end
  end
end
