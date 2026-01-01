# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Script to verify the fox-geese-corn solution using the planner

alias AriaPlanner.HDDL
alias AriaCore.Planner.LazyRefinement
alias AriaCore.Planner.Methods
alias AriaCore.Planner.Actions
alias AriaPlanner.Domains.FoxGeeseCorn.Commands.{CrossEast, CrossWest}
alias AriaPlanner.Domains.FoxGeeseCorn.Tasks.TransportAll

# Import the HDDL problem
IO.puts("Importing HDDL problem...")
hddl_content = File.read!("test/fixtures/hddl/fox_geese_corn_problem.hddl")

plan = case HDDL.import_from_string(hddl_content) do
  {:ok, imported_plan} ->
    IO.puts("Plan imported: #{imported_plan.name}")
    imported_plan

  {:error, reason} ->
    IO.puts("Import failed: #{reason}")
    IO.puts("Creating plan manually...")
    # Create a minimal plan for testing
    {:ok, created_plan} = AriaCore.Plan.create(%{
      name: "Transport All Items Plan",
      persona_id: UUIDv7.generate(),
      domain_type: "navigation",
      objectives: [Jason.encode!(["transport_all", "items"])],
      execution_status: "planned"
    })
    created_plan
end

# Extract initial state from the problem
# The problem has initial facts in :aria-initial-state
# For now, we'll create the initial state manually based on the problem file
initial_state = %{
  west_fox: 1,
  west_geese: 1,
  west_corn: 1,
  east_fox: 0,
  east_geese: 0,
  east_corn: 0,
  boat_location: "west",
  boat_capacity: 2
}

# Convert to planner state format
# The planner expects State struct with current_time, timeline, entity_capabilities, facts
{:ok, current_time, _} = DateTime.from_iso8601("2025-01-01T10:00:00Z")

# Create facts map from initial state
# State.facts structure: %{subject_id => %{predicate => value}}
# For fox_geese_corn, we'll use "state" as subject_id
facts = %{
  "state" => %{
    west_fox: initial_state.west_fox,
    west_geese: initial_state.west_geese,
    west_corn: initial_state.west_corn,
    east_fox: initial_state.east_fox,
    east_geese: initial_state.east_geese,
    east_corn: initial_state.east_corn,
    boat_location: initial_state.boat_location
  }
}

# Wrap commands to return duration (5 minutes = 300000 ms)
wrap_command = fn command_fn ->
  fn state, fox, geese, corn ->
    case command_fn.(state, fox, geese, corn) do
      {:ok, new_state} -> {:ok, new_state, 300_000}
      error -> error
    end
  end
end

# Create action wrappers that work with the planner's state format
# The planner passes State struct, but commands expect a map
# We need to convert between formats
action_cross_east = fn planner_state, "c_cross_east", fox, geese, corn ->
  # Convert planner state to domain state
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
      # Convert back to planner state format
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

    error -> error
  end
end

action_cross_west = fn planner_state, "c_cross_west", fox, geese, corn ->
  # Convert planner state to domain state
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
      # Convert back to planner state format
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

    error -> error
  end
end

# Create a helper module for the method to handle variable arity
defmodule VerifyHelper do
  # The planner uses apply() which can call with 2 or 3 args
  # We'll handle both cases - when called with 2 args, the 3rd will be missing
  # and Elixir will try to match the 2-arg clause. When called with 3 args,
  # it will match the 3-arg clause. But function captures have fixed arity,
  # so we need a different approach.

  # Solution: Create a function that uses apply internally to handle variable arity
  # But the planner already uses apply, so we need the registered function to work
  # with apply() calls of different arities.

  # Actually, the simplest: register a 3-arg function, and when the planner
  # calls with 2 args, it will fail. So we need to handle this at the registration level.

  # Better solution: Use a wrapper that catches FunctionClauseError and retries
  # But that's complex.

  # Best solution: Make the helper function work with both arities by using
  # a single function that accepts 3 args, where the 3rd can be anything
  def method_transport_all(planner_state, "t_transport_all", _args \\ :unused) do
    extract_and_decompose(planner_state)
  end

  defp extract_and_decompose(planner_state) do
    # Always use the current planner state, not the old state from the tuple
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

    # Get subtasks, but replace the recursive task to not include the old state
    subtasks = TransportAll.t_transport_all(domain_state)

    # Replace {"t_transport_all", old_state} with just {"t_transport_all"}
    # so the planner uses the current state
    Enum.map(subtasks, fn
      {"t_transport_all", _old_state} -> {"t_transport_all"}
      other -> other
    end)
  end
end

# Create method wrapper - use apply to handle variable arity
method_transport_all = fn planner_state, task_name, args ->
  # Use apply to call with 3 args, but the function has a default for the 3rd arg
  VerifyHelper.method_transport_all(planner_state, task_name, args)
end

# Also create a 2-arg version for when planner calls with 2 args
method_transport_all_2 = fn planner_state, task_name ->
  VerifyHelper.method_transport_all(planner_state, task_name)
end

# The planner expects a single function, so we need to register both
# But actually, the planner looks up by task name, so we can register the 3-arg version
# and handle the 2-arg case by making the function accept optional 3rd arg

# The planner uses apply(method, [current_state | Tuple.to_list(curr_node.info)])
# This constructs an argument list that can have 2 or 3 elements
# We need a function that can handle both cases
# Solution: Use a wrapper that uses Kernel.apply to dynamically call the helper
# But actually, the planner already uses apply(), so we need the function itself
# to work with both arities. Since we can't do that with anonymous functions,
# we'll create a wrapper module function that handles both cases via apply
defmodule MethodWrapper do
  def method_transport_all(args) when is_list(args) do
    case length(args) do
      2 -> apply(VerifyHelper, :method_transport_all, args)
      3 -> apply(VerifyHelper, :method_transport_all, args)
      _ -> nil
    end
  end
end

# But the planner calls apply(method, args_list), not method(args_list)
# So we need method to be a function that accepts the args directly
# The real solution: register a function that accepts 3 args and ignores the 3rd if not needed
# But Elixir doesn't support optional args in anonymous functions

# The planner uses apply(method, args_list) where args_list can have 2 or 3 elements
# We need to register a function that works with both
# Solution: Register the 2-arg version, which will use the default for the 3rd arg
# when called with 2 args, and can be called with 3 args if needed
method_transport_all = &VerifyHelper.method_transport_all/2

# Create domain spec
domain_spec = %{
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
  initial_tasks: [{"t_transport_all"}]  # Don't include state - method will use current planner state
}

# Create initial planner state
initial_planner_state_params = %{
  current_time: current_time,
  timeline: %{},
  entity_capabilities: %{},
  facts: facts
}

IO.puts("\nRunning planner...")
IO.puts("Initial state:")
IO.inspect(initial_state, label: "Domain State")

# Run the planner
case LazyRefinement.run_lazy_refineahead(domain_spec, initial_planner_state_params, plan, []) do
  {:ok, final_plan} ->
    IO.puts("\n✅ Planning completed!")
    IO.puts("Execution status: #{final_plan.execution_status}")

    # Extract solution plan directly from solution graph
    solution_plan = if final_plan.solution_graph_data do
      AriaCore.Planner.LazyRefinement.GraphOperations.extract_solution_plan(final_plan.solution_graph_data)
    else
      # Fallback to JSON-decoded solution_plan
      case Jason.decode(final_plan.solution_plan) do
        {:ok, plan_list} -> plan_list
        _ -> []
      end
    end

    IO.puts("\nSolution sequence (#{length(solution_plan)} steps):")
    Enum.each(solution_plan, fn step ->
      case step do
        {action_name, arg1, arg2, arg3} when is_binary(action_name) ->
          IO.puts("  #{action_name}(#{arg1}, #{arg2}, #{arg3})")
        {action_name, arg1, arg2} when is_binary(action_name) ->
          IO.puts("  #{action_name}(#{arg1}, #{arg2})")
        {action_name, arg1} when is_binary(action_name) ->
          IO.puts("  #{action_name}(#{arg1})")
        [action_name | args] when is_list(args) ->
          IO.puts("  #{action_name}(#{Enum.join(args, ", ")})")
        [action_name | args] ->
          IO.puts("  #{action_name}(#{inspect(args)})")
        other ->
          IO.puts("  #{inspect(other)}")
      end
    end)

    # Debug: Show solution graph structure
    if final_plan.solution_graph_data do
      IO.puts("\nSolution graph nodes:")
      Enum.each(final_plan.solution_graph_data, fn {id, node} ->
        if node.type == :A and node.status == :C do
          IO.puts("  Node #{id}: #{inspect(node.info)} (type: #{node.type}, status: #{node.status})")
        end
      end)
    end

    # Show final state from solution graph
    if final_plan.solution_graph_data do
      IO.puts("\nFinal state:")
      # Extract final state from the last completed action node
      final_nodes = Enum.filter(final_plan.solution_graph_data, fn {_id, node} ->
        node.status == :C and node.type == :A
      end)

      if final_nodes != [] do
        {_id, last_node} = Enum.max_by(final_nodes, fn {id, _} -> id end)
        if last_node.state do
          # Extract domain state from planner state
          domain_state = case last_node.state.facts do
            %{"state" => state_map} -> state_map
            facts when is_map(facts) -> facts
            _ -> %{}
          end

          IO.inspect(domain_state, label: "Domain State")
        else
          IO.puts("  (No state stored in last action node)")
        end
      else
        IO.puts("  (No completed action nodes found)")
      end
    end

  {:error, reason} ->
    IO.puts("\n❌ Planning failed: #{reason}")
end
