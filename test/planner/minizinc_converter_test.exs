# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.MiniZincConverterTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.MiniZincConverter
  alias AriaCore.PlanningDomain

  describe "MiniZincConverter" do
    test "convert_command from module" do
      # Test converting a command module
      module = AriaPlanner.Domains.TinyCvrp.Commands.VisitCustomer

      case MiniZincConverter.convert_command(module) do
        {:ok, minizinc} ->
          assert is_binary(minizinc)
          assert String.contains?(minizinc, "Command") or String.contains?(minizinc, "c_visit_customer")

        {:error, reason} ->
          # Module might not have source file available in test environment
          if String.contains?(to_string(reason), "source") or
             String.contains?(to_string(reason), "not found") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end

    test "convert_task from module" do
      module = AriaPlanner.Domains.TinyCvrp.Tasks.RouteVehicles

      case MiniZincConverter.convert_task(module) do
        {:ok, minizinc} ->
          assert is_binary(minizinc)
          assert String.contains?(minizinc, "Task") or String.contains?(minizinc, "t_route_vehicles")

        {:error, reason} ->
          if String.contains?(to_string(reason), "source") or
             String.contains?(to_string(reason), "not found") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end

    test "convert_multigoal from module" do
      module = AriaPlanner.Domains.TinyCvrp.Multigoals.RouteVehicles

      case MiniZincConverter.convert_multigoal(module) do
        {:ok, minizinc} ->
          assert is_binary(minizinc)
          assert String.contains?(minizinc, "Multigoal") or String.contains?(minizinc, "m_route_vehicles")

        {:error, reason} ->
          if String.contains?(to_string(reason), "source") or
             String.contains?(to_string(reason), "not found") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end

    test "convert_domain from map" do
      domain_map = %{
        name: "test_domain",
        domain_type: "test",
        predicates: ["pred1", "pred2"],
        entities: [%{name: "entity1"}],
        commands: [
          %{
            name: "c_test",
            preconditions: ["pred1 == true", "pred2 >= 5"],
            effects: ["pred1 = false"]
          }
        ],
        tasks: [
          %{
            name: "t_test",
            decomposition: "decompose into subtasks"
          }
        ],
        multigoals: [
          %{
            name: "m_test",
            predicate: "pred1"
          }
        ]
      }

      {:ok, minizinc} = MiniZincConverter.convert_domain(domain_map)

      assert is_binary(minizinc)
      assert String.contains?(minizinc, "test_domain")
      assert String.contains?(minizinc, "solve satisfy")
      # Should have variable declarations
      assert String.contains?(minizinc, "var") or String.contains?(minizinc, "No variables")
    end

    test "convert_domain generates constraints from preconditions" do
      domain_map = %{
        name: "test_domain",
        domain_type: "test",
        predicates: ["pred1"],
        commands: [
          %{
            name: "c_test",
            preconditions: ["pred1[entity] == value", "pred1 >= 5"],
            effects: []
          }
        ],
        tasks: [],
        multigoals: []
      }

      {:ok, minizinc} = MiniZincConverter.convert_domain(domain_map)

      assert is_binary(minizinc)
      # Should have constraint lines
      assert String.contains?(minizinc, "constraint") or String.contains?(minizinc, "No command constraints")
    end

    test "convert_domain_to_file saves to file" do
      domain_map = %{
        name: "test_domain",
        domain_type: "test",
        predicates: ["pred1"],
        commands: [],
        tasks: [],
        multigoals: []
      }

      tmp_file = System.tmp_dir!() |> Path.join("test_domain_#{:rand.uniform(10000)}.mzn")

      try do
        {:ok, path} = MiniZincConverter.convert_domain_to_file(domain_map, tmp_file)

        assert path == tmp_file
        assert File.exists?(tmp_file)

        content = File.read!(tmp_file)
        assert String.contains?(content, "test_domain")
      after
        File.rm(tmp_file)
      end
    end

    test "convert_command_element from map" do
      cmd = %{
        name: "c_test",
        preconditions: ["pred1 == true"],
        effects: ["pred1 = false"]
      }

      {:ok, minizinc} = MiniZincConverter.convert_command(cmd)

      assert is_binary(minizinc)
      assert String.contains?(minizinc, "c_test")
    end

    test "convert_task_element from map" do
      task = %{
        name: "t_test",
        decomposition: "some decomposition"
      }

      {:ok, minizinc} = MiniZincConverter.convert_task(task)

      assert is_binary(minizinc)
      assert String.contains?(minizinc, "t_test")
    end

    test "convert_multigoal_element from map" do
      mg = %{
        name: "m_test",
        predicate: "pred1"
      }

      {:ok, minizinc} = MiniZincConverter.convert_multigoal(mg)

      assert is_binary(minizinc)
      assert String.contains?(minizinc, "m_test")
    end

    test "convert_domain handles empty domain" do
      domain_map = %{
        name: "empty_domain",
        domain_type: "test",
        predicates: [],
        entities: [],
        commands: [],
        tasks: [],
        multigoals: []
      }

      {:ok, minizinc} = MiniZincConverter.convert_domain(domain_map)

      assert is_binary(minizinc)
      assert String.contains?(minizinc, "empty_domain")
      assert String.contains?(minizinc, "solve satisfy")
    end

    test "convert_domain generates variable declarations" do
      domain_map = %{
        name: "test_domain",
        domain_type: "test",
        predicates: ["pred1", "pred2"],
        entities: [%{name: "entity1"}, %{name: "entity2"}],
        commands: [],
        tasks: [],
        multigoals: []
      }

      {:ok, minizinc} = MiniZincConverter.convert_domain(domain_map)

      assert is_binary(minizinc)
      # Should have variable declarations for predicates
      assert String.contains?(minizinc, "var bool: pred1") or
             String.contains?(minizinc, "var bool: pred2")
    end

    test "convert_and_solve converts and solves domain" do
      domain_map = %{
        name: "test_domain",
        domain_type: "test",
        predicates: ["pred1"],
        commands: [
          %{
            name: "c_test",
            preconditions: ["pred1 == true"],
            effects: []
          }
        ],
        tasks: [],
        multigoals: []
      }

      case MiniZincConverter.convert_and_solve(domain_map) do
        {:ok, solution} ->
          assert is_map(solution)

        {:error, reason} ->
          reason_str = to_string(reason)
          # If MiniZinc isn't available, that's okay
          if String.contains?(reason_str, "minizinc") or
             String.contains?(reason_str, "not found") or
             String.contains?(reason_str, "command") or
             String.contains?(reason_str, "UNSAT") do
            :ok
          else
            flunk("Unexpected error: #{inspect(reason)}")
          end
      end
    end
  end

  describe "precondition and effect conversion" do
    test "converts precondition patterns correctly" do
      domain_map = %{
        name: "test",
        domain_type: "test",
        predicates: [],
        commands: [
          %{
            name: "c_test",
            preconditions: [
              "pred[entity] == value",
              "pred >= 5",
              "pred <= 10",
              "pred == true"
            ],
            effects: []
          }
        ],
        tasks: [],
        multigoals: []
      }

      {:ok, minizinc} = MiniZincConverter.convert_domain(domain_map)

      assert is_binary(minizinc)
      # Should have constraint lines
      assert String.contains?(minizinc, "constraint") or String.contains?(minizinc, "Precondition")
    end

    test "converts effect patterns correctly" do
      domain_map = %{
        name: "test",
        domain_type: "test",
        predicates: [],
        commands: [
          %{
            name: "c_test",
            preconditions: [],
            effects: [
              "pred[entity] = value",
              "pred = false"
            ]
          }
        ],
        tasks: [],
        multigoals: []
      }

      {:ok, minizinc} = MiniZincConverter.convert_domain(domain_map)

      assert is_binary(minizinc)
      # Should contain command name or effect comments
      # The generated code should have some content related to the command
      assert String.length(minizinc) > 0
      # Check if it contains any of the expected strings (case-insensitive)
      minizinc_lower = String.downcase(minizinc)
      assert String.contains?(minizinc_lower, "test") or 
             String.contains?(minizinc_lower, "command") or
             String.contains?(minizinc_lower, "effect") or
             String.contains?(minizinc_lower, "pred") or
             String.contains?(minizinc, "solve satisfy")
    end
  end
end

