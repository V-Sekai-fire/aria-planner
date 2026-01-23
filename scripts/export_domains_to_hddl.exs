#!/usr/bin/env elixir

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Script to export existing domain implementations to HDDL format
# and replace stub domain files

alias AriaCore.PlanningDomain
alias AriaPlanner.HDDL

defmodule DomainExporter do
  def export_all do
    IO.puts("Exporting existing domains to HDDL...\n")

    # Domains with existing implementations
    domains_to_export = [
      {"aircraft_disassembly", "AriaPlanner.Domains.AircraftDisassembly"},
      {"fox_geese_corn", "AriaPlanner.Domains.FoxGeeseCorn"},
      {"neighbours", "AriaPlanner.Domains.Neighbours"},
      {"tiny_cvrp", "AriaPlanner.Domains.TinyCvrp"}
    ]

    Enum.each(domains_to_export, fn {domain_name, module_name} ->
      export_domain(domain_name, module_name)
    end)

    IO.puts("\n✅ Export complete!")
  end

  defp export_domain(domain_name, module_name) do
    IO.puts("Exporting: #{domain_name}")

    try do
      # Get the module
      module = String.to_existing_atom("Elixir.#{module_name}")

      # Create domain (returns {:ok, map()})
      case apply(module, :create_domain, []) do
        {:ok, domain_map} ->
          # Convert map to PlanningDomain struct
          planning_domain = map_to_planning_domain(domain_map, domain_name)

          # Export to HDDL
          hddl_string = HDDL.export_to_string(planning_domain)

          # Write to file
          domain_file = "test/fixtures/hddl/domains/#{domain_name}.hddl"
          File.write!(domain_file, hddl_string)

          IO.puts("  ✅ Exported to #{domain_file}")

        error ->
          IO.puts("  ❌ Failed to create domain: #{inspect(error)}")
      end
    rescue
      e ->
        IO.puts("  ❌ Error: #{Exception.message(e)}")
    end
  end

  defp map_to_planning_domain(domain_map, domain_name) do
    # Convert domain map to PlanningDomain struct
    %PlanningDomain{
      id: UUIDv7.generate(),
      domain_type: Map.get(domain_map, :type, domain_name),
      name: Map.get(domain_map, :type, domain_name),
      description: extract_description(domain_map),
      entities: Map.get(domain_map, :entities, []),
      tasks: convert_tasks(domain_map),
      actions: convert_actions(domain_map),
      commands: Map.get(domain_map, :commands, []),
      multigoals: convert_multigoals(domain_map),
      state: :active,
      version: 1,
      metadata: %{}
    }
  end

  defp extract_description(domain_map) do
    # Try to get description from metadata or use default
    case Map.get(domain_map, :description) do
      nil -> "HDDL domain for #{Map.get(domain_map, :type, "unknown")} problem"
      desc -> desc
    end
  end

  defp convert_tasks(domain_map) do
    # Convert methods to tasks format
    methods = Map.get(domain_map, :methods, [])
    Enum.map(methods, fn method ->
      %{
        name: Map.get(method, :name, "unknown_task"),
        parameters: Map.get(method, :parameters, []),
        type: "task"
      }
    end)
  end

  defp convert_actions(domain_map) do
    # Convert actions map format to PlanningDomain format
    actions = Map.get(domain_map, :actions, [])
    Enum.map(actions, fn action ->
      %{
        name: Map.get(action, :name, "unknown_action"),
        parameters: extract_parameters(action),
        preconditions: Map.get(action, :preconditions, []),
        effects: Map.get(action, :effects, [])
      }
    end)
  end

  defp extract_parameters(action) do
    # Extract parameters from arity or preconditions/effects
    case Map.get(action, :arity) do
      nil -> []
      arity -> Enum.map(1..arity, fn i -> "?param#{i}" end)
    end
  end

  defp convert_multigoals(domain_map) do
    # Convert goal_methods to multigoals format
    goal_methods = Map.get(domain_map, :goal_methods, [])
    Enum.map(goal_methods, fn method ->
      %{
        name: Map.get(method, :name, "unknown_goal"),
        parameters: Map.get(method, :parameters, []),
        type: "multigoal"
      }
    end)
  end
end

DomainExporter.export_all()
