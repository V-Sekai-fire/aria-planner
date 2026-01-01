#!/usr/bin/env elixir

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# Create HDDL fixtures for MiniZinc problems
# This script creates basic HDDL domain and problem files

defmodule MinizincHDDLGenerator do
  # Problem mappings: MiniZinc problem -> HDDL domain name
  @problem_mappings %{
    "aircraft-disassembly" => "aircraft_disassembly",
    "neighbours" => "neighbours",
    "tiny-cvrp" => "tiny_cvrp",
    "fox-geese-corn" => "fox_geese_corn",
    "train-scheduling" => "train_scheduling",
    "hoist-benchmark" => "hoist_benchmark",
    "portal" => "portal",
    "graph-clear" => "graph_clear",
    "cable-tree-wiring" => "cable_tree_wiring",
    "yumi-dynamic" => "yumi_dynamic"
  }

  def generate_all do
    IO.puts("Generating HDDL fixtures from MiniZinc problems...\n")

    File.mkdir_p!("test/fixtures/hddl/domains")

    Enum.each(@problem_mappings, fn {minizinc_name, hddl_domain} ->
      process_problem_type(minizinc_name, hddl_domain)
    end)

    IO.puts("\n✅ Generation complete!")
  end

  defp process_problem_type(minizinc_name, hddl_domain) do
    domain_dir = "thirdparty/mznc2024_probs/#{minizinc_name}"

    if File.exists?(domain_dir) do
      IO.puts("Processing: #{minizinc_name} -> #{hddl_domain}")

      # Find all .dzn files
      dzn_files = Path.wildcard("#{domain_dir}/*.dzn")

      if length(dzn_files) > 0 do
        # Create domain file if it doesn't exist
        domain_file = "test/fixtures/hddl/domains/#{hddl_domain}.hddl"
        unless File.exists?(domain_file) do
          create_domain_file(hddl_domain, domain_file)
        end

        # Create problem files
        Enum.each(dzn_files, fn dzn_file ->
          create_problem_file(hddl_domain, dzn_file)
        end)

        IO.puts("  ✅ Created #{length(dzn_files)} problem files")
      else
        IO.puts("  ⚠️  No .dzn files found")
      end
    else
      IO.puts("  ⚠️  Directory not found: #{domain_dir}")
    end
  end

  defp create_domain_file(domain_name, domain_file) do
    domain_content = """
(define (domain #{domain_name})
  (:requirements :strips :typing :temporal :hierarchical)

  (:aria-domain-metadata
    :id "#{UUIDv7.generate()}"
    :name "#{String.replace(domain_name, "_", " ") |> String.split() |> Enum.map(&String.capitalize/1) |> Enum.join(" ")}"
    :description "HDDL domain for #{domain_name} problem"
    :domain-type navigation
    :version 1
    :state active
  )

  ; TODO: Add predicates, actions, methods, commands based on MiniZinc model
  ; This is a stub domain - implement planning logic as needed

  (:predicates
    (problem_initialized)
  )

  (:task solve_problem
    :parameters ()
  )

  (:method solve
    :task (solve_problem)
    :precondition ()
    :subtasks ()
  )
)
"""

    File.write!(domain_file, domain_content)
  end

  defp create_problem_file(domain_name, dzn_file) do
    problem_name = Path.basename(dzn_file, ".dzn")
      |> String.replace(~r/[^a-z0-9_]/i, "_")
      |> String.downcase()

    problem_file = "test/fixtures/hddl/#{domain_name}_problem_#{problem_name}.hddl"

    # Read .dzn file and extract key parameters as facts
    facts = case File.read(dzn_file) do
      {:ok, content} ->
        extract_facts(content)
      {:error, _} ->
        "      (:fact file_read_error state :value true)"
    end

    problem_content = """
(define (problem #{domain_name}_problem_#{problem_name})
  (:domain #{domain_name})

  (:aria-plan
    :id "#{UUIDv7.generate()}"
    :name "#{String.replace(problem_name, "_", " ") |> String.capitalize()} Plan"
    :persona-id "persona_123"
    :domain-type navigation
    :objectives (
      (solve_problem)
    )
    :execution-status planned
  )

  (:aria-initial-state
    :current-time "2025-01-01T10:00:00Z"
    :timeline (
      (:event start :time "2025-01-01T10:00:00Z")
    )
    :entity-capabilities (
      (:entity agent_1 :capabilities (:navigation :computation))
    )
    :facts (
#{facts}
    )
  )

  (:aria-blacklist
    :blacklisted-commands ()
    :blacklisted-methods ()
  )
)
"""

    File.write!(problem_file, problem_content)
  end

  defp extract_facts(content) do
    content
    |> String.split("\n")
    |> Enum.reject(&(&1 =~ ~r/^%|^$/))
    |> Enum.map(&parse_line_to_fact/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp parse_line_to_fact(line) do
    line = String.trim(line)

    cond do
      # Simple assignment: var = value;
      match = Regex.run(~r/^(\w+)\s*=\s*([^;]+);/, line) ->
        [_, var, value] = match
        clean_value = String.trim(value)
        # Convert MiniZinc syntax to HDDL-friendly format
        hddl_value = convert_minizinc_value(clean_value)
        "      (:fact #{var} state :value \"#{hddl_value}\")"

      # Array assignment: array = [| ... |];
      match = Regex.run(~r/^(\w+)\s*=\s*\[/, line) ->
        var = List.last(match)
        # Extract array content (simplified)
        array_content = String.slice(line, 0, 100)
        "      (:fact #{var}_array state :value \"#{array_content}...\")"

      true ->
        nil
    end
  end

  defp convert_minizinc_value(value) do
    value
    |> String.replace("\"", "\\\"")  # Escape quotes
    |> String.trim()
  end
end

MinizincHDDLGenerator.generate_all()
