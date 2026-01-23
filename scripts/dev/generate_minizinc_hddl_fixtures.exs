#!/usr/bin/env elixir

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Script to generate HDDL domain and problem fixtures from MiniZinc problems
# Usage: mix run scripts/generate_minizinc_hddl_fixtures.exs

alias AriaPlanner.HDDL

# Base directory for MiniZinc problems
@minizinc_base "thirdparty/mznc2024_probs"
@hddl_domains_dir "test/fixtures/hddl/domains"
@hddl_problems_dir "test/fixtures/hddl"

# Problem types to process (focusing on planning-relevant ones)
@problem_types [
  "train-scheduling",
  "hoist-benchmark",
  "portal",
  "graph-clear",
  "cable-tree-wiring",
  "yumi-dynamic"
]

defmodule MinizincToHDDL do
  def generate_all do
    IO.puts("Generating HDDL fixtures from MiniZinc problems...\n")

    # Create directories
    File.mkdir_p!("test/fixtures/hddl/domains")

    # Process each problem type
    Enum.each(@problem_types, fn problem_type ->
      process_problem_type(problem_type)
    end)

    IO.puts("\n✅ Generation complete!")
  end

  defp process_problem_type(problem_type) do
    domain_dir = Path.join(@minizinc_base, problem_type)

    if File.exists?(domain_dir) do
      IO.puts("Processing: #{problem_type}")

      # Find all .dzn files
      dzn_files = domain_dir
        |> Path.join("*.dzn")
        |> Path.wildcard()

      if length(dzn_files) > 0 do
        # Create domain file (once per problem type)
        create_domain_file(problem_type)

        # Create problem file for each .dzn
        Enum.each(dzn_files, fn dzn_file ->
          create_problem_file(problem_type, dzn_file)
        end)

        IO.puts("  ✅ Created #{length(dzn_files)} problem files")
      else
        IO.puts("  ⚠️  No .dzn files found")
      end
    else
      IO.puts("  ⚠️  Directory not found: #{domain_dir}")
    end
  end

  defp create_domain_file(problem_type) do
    domain_name = String.replace(problem_type, "-", "_")
    domain_file = Path.join(@hddl_domains_dir, "#{domain_name}.hddl")

    domain_content = """
(define (domain #{domain_name})
  (:requirements :strips :typing :temporal :hierarchical)

  (:aria-domain-metadata
    :id "#{UUIDv7.generate()}"
    :name "#{String.replace(problem_type, "-", " ") |> String.capitalize()}"
    :description "HDDL domain for #{problem_type} problem"
    :domain-type navigation
    :version 1
    :state active
  )

  ; TODO: Add predicates, actions, methods, commands based on MiniZinc model
  ; This is a stub domain - implement planning logic as needed
)
"""

    File.write!(domain_file, domain_content)
  end

  defp create_problem_file(problem_type, dzn_file) do
    domain_name = String.replace(problem_type, "-", "_")
    problem_name = Path.basename(dzn_file, ".dzn")
      |> String.replace(~r/[^a-z0-9_]/i, "_")
      |> String.downcase()

    problem_file = Path.join(@hddl_problems_dir, "#{domain_name}_problem_#{problem_name}.hddl")

    # Read and parse .dzn file to extract facts
    facts = extract_facts_from_dzn(dzn_file)

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

  defp extract_facts_from_dzn(dzn_file) do
    case File.read(dzn_file) do
      {:ok, content} ->
        # Simple extraction: convert MiniZinc assignments to HDDL facts
        # This is a basic implementation - can be enhanced
        content
        |> String.split("\n")
        |> Enum.reject(&(&1 =~ ~r/^%|^$/))  # Remove comments and empty lines
        |> Enum.map(&extract_fact_from_line/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.join("\n")

      {:error, _} ->
        "      ; Failed to read #{Path.basename(dzn_file)}"
    end
  end

  defp extract_fact_from_line(line) do
    # Basic pattern matching for common MiniZinc patterns
    cond do
      # Array assignments: array_name = [| ... |];
      line =~ ~r/^(\w+)\s*=\s*\[/ ->
        var_name = Regex.run(~r/^(\w+)/, line) |> List.last()
        "      (:fact #{var_name} state :value \"#{String.trim(line)}\")"

      # Simple assignments: var = value;
      line =~ ~r/^(\w+)\s*=\s*([^;]+);/ ->
        [_, var_name, value] = Regex.run(~r/^(\w+)\s*=\s*([^;]+);/, line)
        clean_value = String.trim(value)
        "      (:fact #{var_name} state :value #{clean_value})"

      true ->
        nil
    end
  end
end

# Run the generator
MinizincToHDDL.generate_all()
