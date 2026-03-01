# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.GltfInteractivity.RunTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.Interactivity
  alias AriaPlanner.GltfInteractivity.Export
  alias AriaPlanner.GltfInteractivity.Run

  describe "run/1" do
    test "rope graph: one flow/sequence -> one math/add, returns single result" do
      {:ok, domain} = Interactivity.create_domain()
      ext = Export.build_extension(domain, %{})
      assert {:ok, results} = Run.run(ext)
      assert results == [{:math_add, 1, 1.0, 2.0, 3.0}]
    end

    test "Minecraft-Player buildhouse: 6-step sequence, returns six math_add in order" do
      {:ok, domain} = Interactivity.create_domain()
      problem = %{"source" => "ipc2020", "domain" => "Minecraft-Player", "task" => "buildhouse"}
      ext = Export.build_extension(domain, problem)
      assert {:ok, results} = Run.run(ext)
      expected =
        Enum.map(1..6, fn i ->
          {:math_add, i, 0.0, float(i), float(i)}
        end)
      assert results == expected
    end

    test "no graph returns error" do
      assert Run.run(%{"graphs" => []}) == {:error, :no_graph}
      assert Run.run(%{}) == {:error, :no_graph}
    end

    test "unsupported op returns error" do
      ext = %{
        "graphs" => [
          %{
            "nodes" => [%{"declaration" => 0}],
            "declarations" => [%{"op" => "unknown/op"}]
          }
        ],
        "graph" => 0
      }
      assert {:error, {:unsupported_op, "unknown/op"}} = Run.run(ext)
    end

    test "respects graph index" do
      # Single graph at index 0
      ext = %{
        "graphs" => [
          %{
            "nodes" => [
              %{"declaration" => 0, "flows" => %{"0" => %{"node" => 1, "socket" => "in"}}},
              %{"declaration" => 1, "values" => %{"a" => %{"value" => [2.0]}, "b" => %{"value" => [3.0]}}}
            ],
            "declarations" => [%{"op" => "flow/sequence"}, %{"op" => "math/add"}]
          }
        ],
        "graph" => 0
      }
      assert {:ok, [{:math_add, 1, 2.0, 3.0, 5.0}]} = Run.run(ext)
    end
  end
end
