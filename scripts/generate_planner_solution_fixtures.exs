#!/usr/bin/env elixir

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# Script to generate planner solution fixtures for all HDDL problems
# Usage: mix run scripts/generate_planner_solution_fixtures.exs

defmodule PlannerSolutionGenerator do
  alias AriaPlanner.HDDL
  alias AriaCore.Planner.LazyRefinement
  alias AriaCore.Planner.Methods
  alias AriaCore.Planner.Actions
  alias AriaCore.Plan

  # Solution fixtures directory
  @solutions_dir "test/fixtures/hddl/solutions"

  # Domains with full implementations that can be planned
  @implemented_domains %{
    "fox_geese_corn" => %{
      module: AriaPlanner.Domains.FoxGeeseCorn,
      commands: ["c_cross_east", "c_cross_west"],
      tasks: ["t_transport_all"]
    },
    "neighbours" => %{
      module: AriaPlanner.Domains.Neighbours,
      commands: ["c_assign_value"],
      tasks: ["t_maximize_grid"]
    }
  }
  def generate_all do
    IO.puts("Generating planner solution fixtures for HDDL problems...\n")

    File.mkdir_p!(@solutions_dir)

    # Find all HDDL problem files (or specific problem for testing)
    problem_files = case System.get_env("PROBLEM_FILE") do
      nil -> Path.wildcard("test/fixtures/hddl/*_problem*.hddl")
      file -> [file]
    end

    IO.puts("Found #{length(problem_files)} problem files\n")

    results =
      Enum.map(problem_files, fn problem_file ->
        generate_solution_fixture(problem_file)
      end)

    successful = Enum.count(results, fn {status, _} -> status == :ok end)
    failed = Enum.count(results, fn {status, _} -> status == :error end)
    skipped = Enum.count(results, fn {status, _} -> status == :skipped end)

    IO.puts("\n✅ Generation complete!")
    IO.puts("  Successful: #{successful}")
    IO.puts("  Failed: #{failed}")
    IO.puts("  Skipped: #{skipped}")
  end

  defp generate_solution_fixture(problem_file) do
    problem_name = Path.basename(problem_file, ".hddl")
    domain_name = extract_domain_name(problem_file)

    IO.puts("Processing: #{problem_name}")

    # Check if domain is implemented
    if Map.has_key?(@implemented_domains, domain_name) do
      domain_config = @implemented_domains[domain_name]

      case generate_solution(problem_file, problem_name, domain_name, domain_config) do
        {:ok, solution_data} ->
          # Save solution fixture (ensure all tuple keys are converted first)
          serialized_data = serialize_for_json(solution_data, domain_name)

          # Deep serialize any remaining tuple keys in the entire data structure
          # This recursively converts all tuple keys to strings
          fully_serialized = deep_serialize_tuples(serialized_data)

          solution_file = Path.join(@solutions_dir, "#{problem_name}_solution.json")

          # Try encoding - if it fails, the deep_serialize didn't catch everything
          case Jason.encode(fully_serialized, pretty: true) do
            {:ok, json} ->
              File.write!(solution_file, json)
              IO.puts("  ✅ Generated solution fixture")
              {:ok, problem_name}
            {:error, reason} ->
              IO.puts("  ❌ JSON encoding failed: #{inspect(reason)}")
              {:error, problem_name, "JSON encoding failed: #{inspect(reason)}"}
          end

        {:error, reason} ->
          IO.puts("  ❌ Failed: #{reason}")
          {:error, problem_name, reason}

        :skip ->
          IO.puts("  ⏭️  Skipped (domain not fully implemented)")
          {:skipped, problem_name}
      end
    else
      IO.puts("  ⏭️  Skipped (domain not implemented)")
      {:skipped, problem_name}
    end
  end

  defp extract_domain_name(problem_file) do
    problem_file
    |> Path.basename()
    |> String.replace(~r/_problem.*/, "")
  end

  defp generate_solution(problem_file, problem_name, domain_name, domain_config) do
    # Read and parse HDDL problem
    case File.read(problem_file) do
      {:ok, content} ->
        case HDDL.Parser.parse(content) do
          {:ok, ast, _, _, _, _} ->
            # Extract initial state from HDDL
            initial_state = extract_initial_state(ast)

            # Create plan with valid domain type
            plan_domain_type = map_domain_to_plan_type(domain_name)

            {:ok, plan} =
              Plan.create(%{
                name: problem_name,
                persona_id: UUIDv7.generate(),
                domain_type: plan_domain_type,
                objectives: [Jason.encode!(["solve_problem"])],
                execution_status: "planned"
              })

            # Create domain spec (simplified - would need full domain setup)
            # For now, we'll create a basic structure
            domain_spec = create_domain_spec(domain_name, domain_config, initial_state)

            # Create initial planner state
            {:ok, current_time, _} = DateTime.from_iso8601("2025-01-01T10:00:00Z")

            initial_planner_state = %{
              current_time: current_time,
              timeline: %{},
              entity_capabilities: %{},
              facts: convert_to_planner_facts(initial_state, domain_name)
            }

            # Run planner
            case LazyRefinement.run_lazy_refineahead(domain_spec, initial_planner_state, plan, []) do
              {:ok, final_plan} ->
                # Extract solution data (pass initial_state for reconstruction)
                solution_data = extract_solution_data(final_plan, problem_name, domain_name, initial_state)
                {:ok, solution_data}

              {:error, reason} ->
                {:error, "Planning failed: #{reason}"}
            end

          {:error, reason} ->
            {:error, "Parse failed: #{reason}"}
        end

      {:error, reason} ->
        {:error, "File read failed: #{reason}"}
    end
  end

  defp extract_initial_state({:problem, _name, elements}) do
    case Enum.find(elements, fn {key, _} -> key == :aria_initial_state end) do
      {_, state_elements} ->
        facts = Keyword.get(state_elements, :facts, [])
        reduce_facts(facts)

      _ ->
        %{}
    end
  end

  defp reduce_facts(facts) do
    Enum.reduce(facts, %{}, fn fact, acc ->
      case fact do
        %{predicate: pred, value: val} ->
          normalized_val = normalize_fact_value(val)
          Map.put(acc, pred, normalized_val)

        _ ->
          acc
      end
    end)
  end

  defp normalize_fact_value(val) when is_binary(val) do
    case Integer.parse(val) do
      {int_val, ""} -> int_val
      _ -> val
    end
  end

  defp normalize_fact_value(val), do: val

  defp convert_to_planner_facts(initial_state, domain_name) do
    # Convert domain-specific initial state to planner facts format
    # Format: %{subject_id => %{predicate => value}}
    case domain_name do
      "fox_geese_corn" ->
        # Handle both short format (f, g, c) and long format (west_fox, west_geese, west_corn)
        west_fox = Map.get(initial_state, :west_fox) || Map.get(initial_state, :f, 0)
        west_geese = Map.get(initial_state, :west_geese) || Map.get(initial_state, :g, 0)
        west_corn = Map.get(initial_state, :west_corn) || Map.get(initial_state, :c, 0)
        boat_capacity = Map.get(initial_state, :boat_capacity) || Map.get(initial_state, :k, 2)

        boat_location = case Map.get(initial_state, :boat_location, "west") do
          atom when is_atom(atom) -> Atom.to_string(atom)
          str when is_binary(str) -> str
          other -> to_string(other)
        end

        %{
          "state" => %{
            west_fox: west_fox,
            west_geese: west_geese,
            west_corn: west_corn,
            east_fox: Map.get(initial_state, :east_fox, 0),
            east_geese: Map.get(initial_state, :east_geese, 0),
            east_corn: Map.get(initial_state, :east_corn, 0),
            boat_location: boat_location,
            boat_capacity: boat_capacity
          }
        }

      "neighbours" ->
        # Extract n and m, initialize grid
        n = case Map.get(initial_state, :n) do
          val when is_binary(val) -> String.to_integer(val)
          val when is_integer(val) -> val
          _ -> 4
        end
        m = case Map.get(initial_state, :m) do
          val when is_binary(val) -> String.to_integer(val)
          val when is_integer(val) -> val
          _ -> 2
        end

        {:ok, neighbours_state} = AriaPlanner.Domains.Neighbours.initialize_state(n, m)

        # Convert grid tuple keys to strings immediately to avoid JSON encoding issues
        serialized_grid = neighbours_state.grid
          |> Map.new(fn
            {{row, col}, value} when is_integer(row) and is_integer(col) ->
              {"#{row},#{col}", value}
            {key, value} when is_tuple(key) ->
              {inspect(key), value}
            {key, value} ->
              {to_string(key), value}
          end)

        %{
          "state" => %{
            n: n,
            m: m,
            grid: serialized_grid
          }
        }

      _ ->
        %{"state" => initial_state}
    end
  end

  defp create_domain_spec(domain_name, domain_config, initial_state) do
    case domain_name do
      "fox_geese_corn" ->
        create_fox_geese_corn_domain_spec(domain_config, initial_state)

      "neighbours" ->
        create_neighbours_domain_spec(domain_config, initial_state)

      _ ->
        # Generic domain spec (would need domain-specific implementation)
        %{
          methods: %Methods{
            task_method_dict: %{},
            goal_method_dict: %{},
            multigoal_method_dict: %{}
          },
          actions: %Actions{
            action_dict: %{}
          },
          initial_tasks: []
        }
    end
  end

  defp create_fox_geese_corn_domain_spec(_domain_config, _initial_state) do
    alias AriaPlanner.Domains.FoxGeeseCorn.Commands.{CrossEast, CrossWest}
    alias AriaPlanner.Domains.FoxGeeseCorn.Tasks.TransportAll

    # Create action wrappers
    action_cross_east = fn planner_state, "c_cross_east", fox, geese, corn ->
      state_facts = Map.get(planner_state.facts, "state", %{})
      domain_state = %{
        west_fox: Map.get(state_facts, :west_fox, 0),
        west_geese: Map.get(state_facts, :west_geese, 0),
        west_corn: Map.get(state_facts, :west_corn, 0),
        east_fox: Map.get(state_facts, :east_fox, 0),
        east_geese: Map.get(state_facts, :east_geese, 0),
        east_corn: Map.get(state_facts, :east_corn, 0),
        boat_location: Map.get(state_facts, :boat_location, "west"),
        boat_capacity: 2
      }

      case CrossEast.c_cross_east(domain_state, fox, geese, corn) do
        {:ok, new_domain_state} ->
          new_state_facts = %{
            west_fox: new_domain_state.west_fox,
            west_geese: new_domain_state.west_geese,
            west_corn: new_domain_state.west_corn,
            east_fox: new_domain_state.east_fox,
            east_geese: new_domain_state.east_geese,
            east_corn: new_domain_state.east_corn,
            boat_location: new_domain_state.boat_location
          }
          new_facts = Map.put(planner_state.facts, "state", new_state_facts)
          new_planner_state = %{planner_state | facts: new_facts}
          {:ok, new_planner_state, 300_000}

        error ->
          error
      end
    end

    action_cross_west = fn planner_state, "c_cross_west", fox, geese, corn ->
      state_facts = Map.get(planner_state.facts, "state", %{})
      domain_state = %{
        west_fox: Map.get(state_facts, :west_fox, 0),
        west_geese: Map.get(state_facts, :west_geese, 0),
        west_corn: Map.get(state_facts, :west_corn, 0),
        east_fox: Map.get(state_facts, :east_fox, 0),
        east_geese: Map.get(state_facts, :east_geese, 0),
        east_corn: Map.get(state_facts, :east_corn, 0),
        boat_location: Map.get(state_facts, :boat_location, "west"),
        boat_capacity: 2
      }

      case CrossWest.c_cross_west(domain_state, fox, geese, corn) do
        {:ok, new_domain_state} ->
          new_state_facts = %{
            west_fox: new_domain_state.west_fox,
            west_geese: new_domain_state.west_geese,
            west_corn: new_domain_state.west_corn,
            east_fox: new_domain_state.east_fox,
            east_geese: new_domain_state.east_geese,
            east_corn: new_domain_state.east_corn,
            boat_location: new_domain_state.boat_location
          }
          new_facts = Map.put(planner_state.facts, "state", new_state_facts)
          new_planner_state = %{planner_state | facts: new_facts}
          {:ok, new_planner_state, 300_000}

        error ->
          error
      end
    end

    # Create method wrapper
    defmodule MethodHelper do
      def method_transport_all(planner_state, "t_transport_all", _args \\ :unused) do
        state_facts = Map.get(planner_state.facts, "state", %{})

        # Ensure boat_location is a string
        boat_location = case Map.get(state_facts, :boat_location, "west") do
          atom when is_atom(atom) -> Atom.to_string(atom)
          str when is_binary(str) -> str
          other -> to_string(other)
        end

        domain_state = %{
          west_fox: Map.get(state_facts, :west_fox, 0),
          west_geese: Map.get(state_facts, :west_geese, 0),
          west_corn: Map.get(state_facts, :west_corn, 0),
          east_fox: Map.get(state_facts, :east_fox, 0),
          east_geese: Map.get(state_facts, :east_geese, 0),
          east_corn: Map.get(state_facts, :east_corn, 0),
          boat_location: boat_location,
          boat_capacity: 2
        }

        subtasks = TransportAll.t_transport_all(domain_state)

        Enum.map(subtasks, fn
          {"t_transport_all", _old_state} -> {"t_transport_all"}
          other -> other
        end)
      end
    end

    method_transport_all = &MethodHelper.method_transport_all/2

    %{
      methods: %Methods{
        task_method_dict: %{
          "t_transport_all" => method_transport_all
        },
        goal_method_dict: %{},
        multigoal_method_dict: %{}
      },
      actions: %Actions{
        action_dict: %{
          "c_cross_east" => action_cross_east,
          "c_cross_west" => action_cross_west
        }
      },
      initial_tasks: [{"t_transport_all"}]
    }
  end

  defp create_neighbours_domain_spec(_domain_config, initial_state) do
    alias AriaPlanner.Domains.Neighbours.Commands.AssignValue
    alias AriaPlanner.Domains.Neighbours.Tasks.MaximizeGrid

    # Extract n and m from initial state
    n = Map.get(initial_state, :n, 4)
    m = Map.get(initial_state, :m, 2)

    # Initialize neighbours state
    {:ok, neighbours_state} = AriaPlanner.Domains.Neighbours.initialize_state(n, m)

    # Create action wrapper
    action_assign_value = fn planner_state, "c_assign_value", row, col, value ->
      state_facts = Map.get(planner_state.facts, "state", %{})

      # Reconstruct neighbours state from planner facts
      # Grid is stored with string keys, convert back to tuple keys for domain operations
      grid_with_string_keys = Map.get(state_facts, :grid) || Map.get(state_facts, "grid") || %{}
      grid_with_tuple_keys = grid_with_string_keys
        |> Map.new(fn
          {key_str, value} when is_binary(key_str) ->
            # Convert "row,col" back to {row, col}
            case String.split(key_str, ",") do
              [row_str, col_str] ->
                case {Integer.parse(row_str), Integer.parse(col_str)} do
                  {{row, ""}, {col, ""}} -> {{row, col}, value}
                  _ -> {key_str, value}  # Keep as string if parsing fails
                end
              _ -> {key_str, value}
            end
          {key, value} -> {key, value}
        end)

      domain_state = %{
        n: Map.get(state_facts, :n, n),
        m: Map.get(state_facts, :m, m),
        grid: grid_with_tuple_keys
      }

      case AssignValue.c_assign_value(domain_state, row, col, value) do
        {:ok, new_domain_state} ->
          # Convert grid tuple keys back to strings for JSON serialization
          serialized_grid = new_domain_state.grid
            |> Map.new(fn
              {{row, col}, value} when is_integer(row) and is_integer(col) ->
                {"#{row},#{col}", value}
              {key, value} when is_tuple(key) ->
                {inspect(key), value}
              {key, value} ->
                {to_string(key), value}
            end)

          new_state_facts = %{
            n: new_domain_state.n,
            m: new_domain_state.m,
            grid: serialized_grid
          }
          new_facts = Map.put(planner_state.facts, "state", new_state_facts)
          new_planner_state = %{planner_state | facts: new_facts}
          {:ok, new_planner_state, 100_000}

        error ->
          error
      end
    end

    # Create method wrapper
    defmodule NeighboursMethodHelper do
      def method_maximize_grid(planner_state, "t_maximize_grid", _args \\ :unused) do
        state_facts = Map.get(planner_state.facts, "state", %{})

        # Grid is stored with string keys, convert back to tuple keys for domain operations
        grid_with_string_keys = Map.get(state_facts, :grid) || Map.get(state_facts, "grid") || %{}
        grid_with_tuple_keys = grid_with_string_keys
          |> Map.new(fn
            {key_str, value} when is_binary(key_str) ->
              # Convert "row,col" back to {row, col}
              case String.split(key_str, ",") do
                [row_str, col_str] ->
                  case {Integer.parse(row_str), Integer.parse(col_str)} do
                    {{row, ""}, {col, ""}} -> {{row, col}, value}
                    _ -> {key_str, value}  # Keep as string if parsing fails
                  end
                _ -> {key_str, value}
              end
            {key, value} -> {key, value}
          end)

        domain_state = %{
          n: Map.get(state_facts, :n, 4),
          m: Map.get(state_facts, :m, 2),
          grid: grid_with_tuple_keys
        }

        subtasks = MaximizeGrid.t_maximize_grid(domain_state)

        Enum.map(subtasks, fn
          {"t_maximize_grid", _old_state} -> {"t_maximize_grid"}
          other -> other
        end)
      end
    end

    method_maximize_grid = &NeighboursMethodHelper.method_maximize_grid/2

    %{
      methods: %Methods{
        task_method_dict: %{
          "t_maximize_grid" => method_maximize_grid
        },
        goal_method_dict: %{},
        multigoal_method_dict: %{}
      },
      actions: %Actions{
        action_dict: %{
          "c_assign_value" => action_assign_value
        }
      },
      initial_tasks: [{"t_maximize_grid"}]
    }
  end

  defp extract_solution_data(plan, problem_name, domain_name, initial_state \\ %{}) do
    # Extract solution sequence
    solution_plan =
      if plan.solution_graph_data do
        AriaCore.Planner.LazyRefinement.GraphOperations.extract_solution_plan(
          plan.solution_graph_data
        )
      else
        case Jason.decode(plan.solution_plan) do
          {:ok, plan_list} -> plan_list
          _ -> []
        end
      end

    # Extract solution graph nodes (simplified)
    solution_nodes =
      if plan.solution_graph_data do
        plan.solution_graph_data
        |> Enum.filter(fn {_id, node} -> node.type == :A and node.status == :C end)
        |> Enum.map(fn {id, node} ->
          %{
            id: id,
            type: to_string(node.type),
            status: to_string(node.status),
            info: format_node_info(node.info)
          }
        end)
        |> Enum.map(fn node ->
          # Ensure info is JSON-serializable (convert tuples to lists)
          case Map.get(node, :info) do
            info when is_tuple(info) -> Map.put(node, :info, Tuple.to_list(info))
            info when is_list(info) ->
              # Convert any tuple elements in list
              serialized_info = Enum.map(info, fn
                item when is_tuple(item) -> Tuple.to_list(item)
                item -> item
              end)
              Map.put(node, :info, serialized_info)
            _ -> node
          end
        end)
      else
        []
      end

    # Extract final state - try to get from last node, or reconstruct from solution
    final_state =
      if plan.solution_graph_data do
        final_nodes =
          Enum.filter(plan.solution_graph_data, fn {_id, node} ->
            node.status == :C and node.type == :A
          end)

        if final_nodes != [] do
          {_id, last_node} = Enum.max_by(final_nodes, fn {id, _} -> id end)

          if last_node.state do
            case last_node.state.facts do
              %{"state" => state_map} ->
                # Convert grid tuple keys to strings if present
                grid = Map.get(state_map, :grid) || Map.get(state_map, "grid")
                case grid do
                  grid_map when is_map(grid_map) ->
                    serialized_grid =
                      grid_map
                      |> Map.new(fn
                        {{row, col}, value} when is_integer(row) and is_integer(col) ->
                          {"#{row},#{col}", value}
                        {key, value} when is_tuple(key) ->
                          {inspect(key), value}
                        {key, value} ->
                          {to_string(key), value}
                      end)
                    state_map
                    |> Map.delete(:grid)
                    |> Map.delete("grid")
                    |> Map.put("grid", serialized_grid)
                  _ -> state_map
                end
              facts when is_map(facts) -> facts
              _ -> %{}
            end
          else
            # Reconstruct final state from solution sequence if not stored
            reconstruct_final_state(solution_plan, domain_name, initial_state)
          end
        else
          reconstruct_final_state(solution_plan, domain_name, initial_state)
        end
      else
        reconstruct_final_state(solution_plan, domain_name, initial_state)
      end

    # Ensure final_state is properly serialized before creating the data structure
    serialized_final_state = final_final_state(final_state, domain_name)

    %{
      problem_name: problem_name,
      domain_name: domain_name,
      execution_status: plan.execution_status,
      solution_sequence: format_solution_sequence(solution_plan),
      solution_nodes: solution_nodes,
      final_state: serialized_final_state,
      planning_metadata: %{
        planning_duration_ms: plan.planning_duration_ms || calculate_planning_duration(plan),
        planning_timestamp:
          if plan.execution_completed_at do
            DateTime.to_iso8601(plan.execution_completed_at)
          else
            nil
          end
      },
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp format_solution_sequence(solution_plan) do
    Enum.map(solution_plan, fn step ->
      case step do
        {action_name, arg1, arg2, arg3} when is_binary(action_name) ->
          %{action: action_name, args: [arg1, arg2, arg3]}

        {action_name, arg1, arg2} when is_binary(action_name) ->
          %{action: action_name, args: [arg1, arg2]}

        {action_name, arg1} when is_binary(action_name) ->
          %{action: action_name, args: [arg1]}

        [action_name | args] when is_list(args) ->
          %{action: to_string(action_name), args: args}

        other ->
          %{action: inspect(other), args: []}
      end
    end)
  end

  defp format_node_info(info) when is_tuple(info) do
    Tuple.to_list(info)
  end

  defp format_node_info(info), do: info

  defp final_final_state(state, domain_name) do
    # Convert atom keys to strings for JSON serialization
    case domain_name do
      "fox_geese_corn" ->
        state
        |> Map.new(fn {k, v} -> {to_string(k), v} end)

      "neighbours" ->
        # Convert grid map keys (tuples) to strings for JSON
        grid = case Map.get(state, :grid) || Map.get(state, "grid") do
          grid_map when is_map(grid_map) ->
            grid_map
            |> Map.new(fn
              {{row, col}, value} when is_integer(row) and is_integer(col) ->
                {"#{row},#{col}", value}
              {key, value} when is_tuple(key) ->
                # Handle tuple keys - convert to string
                {inspect(key), value}
              {key, value} ->
                # Handle already converted keys
                {to_string(key), value}
            end)
          nil -> %{}
          other -> other
        end

        # Convert all state keys to strings, replacing :grid with serialized grid
        state
        |> Map.delete(:grid)
        |> Map.delete("grid")
        |> Map.new(fn {k, v} -> {to_string(k), v} end)
        |> Map.put("grid", grid)

      _ ->
        state
        |> Map.new(fn {k, v} -> {to_string(k), v} end)
    end
  end

  defp map_domain_to_plan_type(domain_name) do
    # Map HDDL domain names to valid Plan domain types
    case domain_name do
      "fox_geese_corn" -> "navigation"
      "aircraft_disassembly" -> "tactical"
      "neighbours" -> "tactical"
      "tiny_cvrp" -> "navigation"
      "train_scheduling" -> "tactical"
      "hoist_benchmark" -> "tactical"
      "portal" -> "navigation"
      "graph_clear" -> "navigation"
      "cable_tree_wiring" -> "tactical"
      "yumi_dynamic" -> "navigation"
      _ -> "navigation" # Default fallback
    end
  end

  defp serialize_for_json(data, domain_name) do
    # Ensure all data is JSON-serializable
    case domain_name do
      "neighbours" ->
        # Recursively convert tuple keys in final_state.grid
        final_state = Map.get(data, :final_state, %{})

        # Check for grid with both atom and string keys
        grid = Map.get(final_state, :grid) || Map.get(final_state, "grid")

        if grid && is_map(grid) do
          serialized_grid =
            grid
            |> Map.new(fn
              {{row, col}, value} when is_integer(row) and is_integer(col) ->
                {"#{row},#{col}", value}
              {key, value} when is_tuple(key) ->
                {inspect(key), value}
              {key, value} ->
                {to_string(key), value}
            end)

          # Update final_state with serialized grid
          updated_final_state = final_state
            |> Map.delete(:grid)
            |> Map.put("grid", serialized_grid)

          Map.put(data, :final_state, updated_final_state)
        else
          data
        end
      _ -> data
    end
  end

  defp deep_serialize_tuples(data) when is_map(data) do
    data
    |> Enum.map(fn
      {key, value} when is_tuple(key) ->
        {inspect(key), deep_serialize_tuples(value)}
      {key, value} ->
        {to_string(key), deep_serialize_tuples(value)}
    end)
    |> Map.new()
  end

  defp deep_serialize_tuples(data) when is_list(data) do
    Enum.map(data, &deep_serialize_tuples/1)
  end

  defp deep_serialize_tuples(data), do: data

  defp reconstruct_final_state(solution_plan, domain_name, initial_state) do
    case domain_name do
      "neighbours" ->
        # Reconstruct grid by applying all actions
        n = case Map.get(initial_state, :n) do
          val when is_binary(val) -> String.to_integer(val)
          val when is_integer(val) -> val
          _ -> 4
        end
        m = case Map.get(initial_state, :m) do
          val when is_binary(val) -> String.to_integer(val)
          val when is_integer(val) -> val
          _ -> 2
        end

        {:ok, neighbours_state} = AriaPlanner.Domains.Neighbours.initialize_state(n, m)

        # Apply all actions to reconstruct final grid
        final_grid = Enum.reduce(solution_plan, neighbours_state.grid, fn step, grid ->
          case step do
            {"c_assign_value", row, col, value} ->
              domain_state = %{n: n, m: m, grid: grid}
              case AriaPlanner.Domains.Neighbours.Commands.AssignValue.c_assign_value(domain_state, row, col, value) do
                {:ok, new_state} -> new_state.grid
                _ -> grid
              end
            _ -> grid
          end
        end)

        # Convert grid tuple keys to strings
        serialized_grid = final_grid
          |> Map.new(fn
            {{row, col}, value} when is_integer(row) and is_integer(col) ->
              {"#{row},#{col}", value}
            {key, value} when is_tuple(key) ->
              {inspect(key), value}
            {key, value} ->
              {to_string(key), value}
          end)

        %{
          n: n,
          m: m,
          grid: serialized_grid
        }

      "fox_geese_corn" ->
        # Reconstruct state by applying all actions
        # Handle both short format (f, g, c) and long format (west_fox, west_geese, west_corn)
        west_fox = Map.get(initial_state, :west_fox) || Map.get(initial_state, :f, 1)
        west_geese = Map.get(initial_state, :west_geese) || Map.get(initial_state, :g, 1)
        west_corn = Map.get(initial_state, :west_corn) || Map.get(initial_state, :c, 1)
        boat_capacity = Map.get(initial_state, :boat_capacity) || Map.get(initial_state, :k, 2)

        initial_domain_state = %{
          west_fox: west_fox,
          west_geese: west_geese,
          west_corn: west_corn,
          east_fox: Map.get(initial_state, :east_fox, 0),
          east_geese: Map.get(initial_state, :east_geese, 0),
          east_corn: Map.get(initial_state, :east_corn, 0),
          boat_location: Map.get(initial_state, :boat_location, "west"),
          boat_capacity: boat_capacity
        }

        final_domain_state = Enum.reduce(solution_plan, initial_domain_state, fn step, state ->
          case step do
            {"c_cross_east", fox, geese, corn} ->
              case AriaPlanner.Domains.FoxGeeseCorn.Commands.CrossEast.c_cross_east(state, fox, geese, corn) do
                {:ok, new_state} -> new_state
                _ -> state
              end
            {"c_cross_west", fox, geese, corn} ->
              case AriaPlanner.Domains.FoxGeeseCorn.Commands.CrossWest.c_cross_west(state, fox, geese, corn) do
                {:ok, new_state} -> new_state
                _ -> state
              end
            _ -> state
          end
        end)

        %{
          west_fox: final_domain_state.west_fox,
          west_geese: final_domain_state.west_geese,
          west_corn: final_domain_state.west_corn,
          east_fox: final_domain_state.east_fox,
          east_geese: final_domain_state.east_geese,
          east_corn: final_domain_state.east_corn,
          boat_location: final_domain_state.boat_location
        }

      _ ->
        %{}
    end
  end

  defp calculate_planning_duration(plan) do
    if plan.solution_graph_data do
      plan.solution_graph_data
      |> Map.values()
      |> Enum.reduce(0, fn node, acc ->
        if node.type == :A and Map.has_key?(node, :duration) do
          duration = node.duration
          if is_number(duration) and duration >= 0 do
            acc + duration
          else
            acc
          end
        else
          acc
        end
      end)
    else
      0
    end
  end
end

# Run the generator
PlannerSolutionGenerator.generate_all()
