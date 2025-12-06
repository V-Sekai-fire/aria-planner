# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Solvers.FlatZincGeneratorTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Solvers.FlatZincGenerator

  describe "generate/1" do
    test "generates FlatZinc for simple variables" do
      constraints = %{
        variables: [
          {:x, :int, 1, 10},
          {:y, :int, 1, 10}
        ],
        constraints: [],
        objective: nil
      }

      flatzinc = FlatZincGenerator.generate(constraints)

      assert String.contains?(flatzinc, "var 1..10: x;")
      assert String.contains?(flatzinc, "var 1..10: y;")
      assert String.contains?(flatzinc, "solve satisfy;")
    end

    test "generates FlatZinc with constraints" do
      constraints = %{
        variables: [
          {:x, :int, 1, 10},
          {:y, :int, 1, 10}
        ],
        constraints: [
          {:int_eq, {:+, :x, :y}, 10}
        ],
        objective: nil
      }

      flatzinc = FlatZincGenerator.generate(constraints)

      assert String.contains?(flatzinc, "var 1..10: x;")
      assert String.contains?(flatzinc, "var 1..10: y;")
      assert String.contains?(flatzinc, "constraint")
      assert String.contains?(flatzinc, "solve satisfy;")
    end

    test "generates FlatZinc with objective" do
      constraints = %{
        variables: [
          {:x, :int, 1, 10}
        ],
        constraints: [],
        objective: {:minimize, :x}
      }

      flatzinc = FlatZincGenerator.generate(constraints)

      assert String.contains?(flatzinc, "var 1..10: x;")
      assert String.contains?(flatzinc, "solve minimize x;")
    end

    test "handles boolean variables" do
      constraints = %{
        variables: [
          {:flag, :bool}
        ],
        constraints: [],
        objective: nil
      }

      flatzinc = FlatZincGenerator.generate(constraints)

      assert String.contains?(flatzinc, "var bool: flag;")
    end

    test "handles all_different constraint" do
      constraints = %{
        variables: [
          {:x, :int, 1, 5},
          {:y, :int, 1, 5},
          {:z, :int, 1, 5}
        ],
        constraints: [
          {:all_different, [:x, :y, :z]}
        ],
        objective: nil
      }

      flatzinc = FlatZincGenerator.generate(constraints)

      assert String.contains?(flatzinc, "all_different")
      assert String.contains?(flatzinc, "x")
      assert String.contains?(flatzinc, "y")
      assert String.contains?(flatzinc, "z")
    end

    test "handles empty constraints" do
      flatzinc = FlatZincGenerator.generate(%{})

      assert String.contains?(flatzinc, "solve satisfy;")
    end

    test "handles non-map input" do
      flatzinc = FlatZincGenerator.generate([])

      assert String.contains?(flatzinc, "solve satisfy;")
    end
  end
end
