# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Solvers.AriaChuffedSolver do
  @compile {:no_warn_undefined, [parse_chuffed_output: 1, parse_flatzinc_output: 1, parse_value: 1, parse_array: 1]}
  @moduledoc """
  High-level Chuffed solver interface for AriaPlanner.

  This module provides a convenient Elixir interface to the Chuffed constraint solver,
  integrating with the planner's constraint solving infrastructure.

  ## Features

  - Solves constraint programming problems using Chuffed
  - Works directly with FlatZinc (.fzn) files (no MiniZinc)
  - Integrates with planning domains
  - Returns structured solutions

  Note: MiniZinc dependencies have been removed. This solver requires direct Chuffed executable.

  ## Usage

      # Solve a FlatZinc problem
      {:ok, solution} = AriaChuffedSolver.solve_flatzinc(flatzinc_content)
      
      # Or solve from a file
      {:ok, solution} = AriaChuffedSolver.solve_flatzinc_file("problem.fzn")
  """

  alias AriaPlanner.Solvers.FlatZincGenerator
  # alias AriaPlanner.Planner.State  # Unused - removed to fix compilation warning

  @doc """
  Checks if Chuffed solver is available.

  Note: MiniZinc is not used. This checks for direct Chuffed availability.
  """
  @spec available?() :: boolean()
  def available? do
    # Check for direct fzn-chuffed executable
    case System.cmd("which", ["fzn-chuffed"], stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  @doc """
  Solves constraints using Chuffed solver directly with FlatZinc format.

  Chuffed is a FlatZinc solver and works directly with FlatZinc format.
  This solver only supports FlatZinc (.fzn) files - no MiniZinc support.

  ## Parameters

  - `constraints`: Map or list of constraints to solve
  - `opts`: Options keyword list
    - `:domain_type` - Domain type (e.g., "aircraft_disassembly")
    - `:flatzinc_path` - Path to FlatZinc file
    - `:timeout` - Timeout in milliseconds (default: 60000)
    - `:options` - Additional solver options as JSON string

  ## Returns

  - `{:ok, solution}` - Solution map with variables and values
  - `{:error, reason}` - Error reason

  ## Example

      # Solve FlatZinc file directly
      {:ok, solution} = AriaChuffedSolver.solve(
        %{flatzinc_path: "problem.fzn"},
        domain_type: "aircraft_disassembly"
      )
  """
  @spec solve(map() | list(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def solve(constraints, opts \\ []) do
    domain_type = Keyword.get(opts, :domain_type, "default")
    flatzinc_path = Keyword.get(opts, :flatzinc_path)
    timeout = Keyword.get(opts, :timeout, 60_000)
    solver_options = Keyword.get(opts, :options, "{}")

    cond do
      flatzinc_path && File.exists?(flatzinc_path) ->
        # Direct FlatZinc solving
        solve_flatzinc_file(flatzinc_path, solver_options, timeout)

      domain_type != "default" ->
        solve_from_domain(domain_type, constraints, opts)

      true ->
        solve_from_constraints(constraints, solver_options, timeout)
    end
  end

  @doc """
  Solves a FlatZinc file using Chuffed directly (no MiniZinc).

  Note: MiniZinc is not used. This requires direct fzn-chuffed executable.

  ## Parameters

  - `flatzinc_path`: Path to .fzn FlatZinc file
  - `opts`: Options keyword list

  ## Returns

  - `{:ok, solution}` - Parsed solution
  - `{:error, reason}` - Error reason
  """
  @spec solve_flatzinc_file(String.t(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def solve_flatzinc_file(_flatzinc_path, _opts \\ []) do
    {:error, "Direct Chuffed solver not yet implemented. MiniZinc dependencies have been removed."}
  end

  @doc """
  Solves a FlatZinc problem using Chuffed directly (no MiniZinc).

  Writes the FlatZinc content to a temporary file and solves it.

  ## Parameters

  - `flatzinc_content`: FlatZinc problem as string
  - `opts`: Options keyword list

  ## Returns

  - `{:ok, solution}` - Parsed solution
  - `{:error, reason}` - Error reason
  """
  @spec solve_flatzinc(String.t(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def solve_flatzinc(flatzinc_content, opts \\ []) do
    # Write to temporary file
    tmp_file = System.tmp_dir!() |> Path.join("chuffed_#{:rand.uniform(1_000_000)}.fzn")

    try do
      File.write!(tmp_file, flatzinc_content)
      solve_flatzinc_file(tmp_file, opts)
    after
      File.rm(tmp_file)
    end
  end

  # Private helper functions

  defp solve_flatzinc_file(flatzinc_path, solver_options, timeout) do
    solve_flatzinc_file(flatzinc_path, timeout: timeout, solver_options: solver_options)
  end

  defp solve_from_domain(domain_type, _constraints, opts) do
    # Find domain-specific FlatZinc file
    flatzinc_path = find_domain_flatzinc(domain_type)

    if flatzinc_path do
      solve_flatzinc_file(flatzinc_path, Keyword.get(opts, :options, "{}"), Keyword.get(opts, :timeout, 60_000))
    else
      {:error, "No FlatZinc file found for domain: #{domain_type}. Provide :flatzinc_path option."}
    end
  end

  defp solve_from_constraints(constraints, solver_options, timeout) do
    # Convert constraints to FlatZinc format using EEx template
    flatzinc = FlatZincGenerator.generate(constraints)
    solve_flatzinc(flatzinc, timeout: timeout, solver_options: solver_options)
  end

  defp find_domain_flatzinc(domain_type) do
    # Look for FlatZinc files in thirdparty directories
    # Note: FlatZinc files are typically generated from MiniZinc models
    # Users should provide FlatZinc files directly or generate them separately
    possible_paths = [
      "thirdparty/mznc2024_probs/#{domain_type}/#{domain_type}.fzn",
      "thirdparty/mznc2024_probs/#{String.replace(domain_type, "_", "-")}/#{String.replace(domain_type, "_", "-")}.fzn",
      "thirdparty/mznc2025_probs/#{domain_type}/#{domain_type}.fzn",
      "thirdparty/mznc2025_probs/#{String.replace(domain_type, "_", "-")}/#{String.replace(domain_type, "_", "-")}.fzn"
    ]

    Enum.find(possible_paths, &File.exists?/1)
  end

  # Note: MiniZinc dependencies have been removed from the solver
end
