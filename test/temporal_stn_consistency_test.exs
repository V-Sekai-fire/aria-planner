# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Temporal.STN.ConsistencyTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.Temporal.STN
  alias AriaPlanner.Planner.Temporal.STN.Consistency

  describe "consistent?/1" do
    test "returns true for empty STN" do
      stn = STN.new()

      assert Consistency.consistent?(stn)
    end

    test "returns true for consistent constraints" do
      stn = STN.new()
      stn = STN.add_constraint(stn, "a", "b", {1, 5})
      stn = STN.add_constraint(stn, "b", "c", {2, 8})

      assert Consistency.consistent?(stn)
    end

    test "returns false for inconsistent constraints" do
      stn = STN.new()
      # Create a temporal paradox: added directly to test what we know is inconsistent
      stn = %STN{
        stn
        | constraints: %{
            # b starts at least 10 after a
            {"a", "b"} => {10, 10_000},
            # a starts at least 10 after b
            {"b", "a"} => {10, 10_000}
          },
          time_points: MapSet.new(["a", "b"])
      }

      refute Consistency.consistent?(stn)
    end

    test "returns false for error" do
      refute Consistency.consistent?({:error, "some error"})
    end

    test "returns false for invalid input" do
      refute Consistency.consistent?("not an stn")
      refute Consistency.consistent?(nil)
    end
  end
end
