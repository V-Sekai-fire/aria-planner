# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Solvers.AriaChuffedSolver do
  @moduledoc """
  High-level Chuffed solver interface for AriaPlanner.
  
  This module provides a convenient Elixir interface to the Chuffed constraint solver,
  integrating with the planner's constraint solving infrastructure.
  
  ## Features
  
  - Solves constraint programming problems using Chuffed
  - Uses MiniZinc with Chuffed solver
  - Supports both MiniZinc (.mzn) and FlatZinc (.fzn) files
  - Integrates with planning domains
  - Returns structured solutions
  
  ## Usage
  
      # Solve a FlatZinc problem
      {:ok, solution} = AriaChuffedSolver.solve_flatzinc(flatzinc_content)
      
      # Or solve from a file
      {:ok, solution} = AriaChuffedSolver.solve_flatzinc_file("problem.fzn")
  """

  alias AriaPlanner.Solvers.MiniZincSolver
  alias AriaPlanner.Solvers.FlatZincGenerator
  alias AriaPlanner.Planner.State

  @doc """
  Checks if Chuffed solver is available via MiniZinc.

  ## Returns

  - `true` if MiniZinc with Chuffed solver is available
  - `false` if Chuffed is not available
  """
  @spec available?() :: boolean()
  def available? do
    MiniZincSolver.available?()
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
  Solves a FlatZinc file using Chuffed via MiniZinc.
  
  ## Parameters
  
  - `flatzinc_path`: Path to .fzn FlatZinc file
  - `opts`: Options keyword list
  
  ## Returns
  
  - `{:ok, solution}` - Parsed solution
  - `{:error, reason}` - Error reason
  """
  @spec solve_flatzinc_file(String.t(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def solve_flatzinc_file(flatzinc_path, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    solver = Keyword.get(opts, :solver, "chuffed")
    solver_options = Keyword.get(opts, :solver_options, [])

    case MiniZincSolver.solve(flatzinc_path, nil, solver: solver, timeout: timeout, solver_options: solver_options) do
      {:ok, solution} ->
        {:ok, solution}

      error ->
        error
    end
  end


  @doc """
  Solves a FlatZinc problem using Chuffed via MiniZinc.
  
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

  defp solve_from_domain(domain_type, constraints, opts) do
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


  defp parse_chuffed_output(output) do
    # Parse MiniZinc JSON output (newline-delimited JSON)
    # Each line is a JSON object with type: "solution", "status", "error", etc.
    
    lines = String.split(output, "\n") |> Enum.filter(&(&1 != ""))
    
    # Try to parse as JSON first
    solution = %{}
    status = nil
    error = nil
    
    {solution, status, error} =
      Enum.reduce(lines, {solution, status, error}, fn line, {sol_acc, stat_acc, err_acc} ->
        case Jason.decode(line) do
          {:ok, json} ->
            case json do
              %{"type" => "solution", "output" => output_text} ->
                # Parse the output text which contains variable assignments
                parsed = parse_flatzinc_output(output_text)
                {Map.merge(sol_acc, parsed), stat_acc, err_acc}
              
              %{"type" => "solution", "json" => json_solution} ->
                # Direct JSON solution
                {Map.merge(sol_acc, json_solution), stat_acc, err_acc}
              
              %{"type" => "status", "status" => stat} ->
                {sol_acc, stat, err_acc}
              
              %{"type" => "error", "message" => msg} ->
                {sol_acc, stat_acc, msg}
              
              _ ->
                {sol_acc, stat_acc, err_acc}
            end
          
          {:error, _} ->
            # Not JSON, try parsing as FlatZinc format
            parsed = parse_flatzinc_output(line)
            {Map.merge(sol_acc, parsed), stat_acc, err_acc}
        end
      end)
    
    # Return appropriate result
    cond do
      error ->
        {:error, error}
      
      status in ["UNSATISFIABLE", "UNSAT"] ->
        {:error, "Problem is unsatisfiable"}
      
      map_size(solution) > 0 ->
        {:ok, solution}
      
      status == "OPTIMAL_SOLUTION" or status == "SATISFIED" ->
        {:ok, %{status: status, raw_output: output}}
      
      true ->
        {:ok, %{raw_output: output}}
    end
  end

  defp parse_flatzinc_output(output) do
    # Parse FlatZinc format: variable_name = value;
    lines = String.split(output, "\n")
    
    Enum.reduce(lines, %{}, fn line, acc ->
      case Regex.run(~r/^(\w+)\s*=\s*([^;]+);/, line) do
        [_, var_name, value] ->
          parsed_value = parse_value(value)
          Map.put(acc, String.to_atom(var_name), parsed_value)
        
        _ ->
          acc
      end
    end)
  end

  defp parse_value(value) do
    value = String.trim(value)

    cond do
      value == "true" -> true
      value == "false" -> false
      Regex.match?(~r/^-?\d+$/, value) -> String.to_integer(value)
      Regex.match?(~r/^-?\d+\.\d+$/, value) -> String.to_float(value)
      Regex.match?(~r/^\[.*\]$/, value) -> parse_array(value)
      true -> value
    end
  end

  defp parse_array(array_str) do
    # Parse array like [1, 2, 3]
    array_str
    |> String.trim_leading("[")
    |> String.trim_trailing("]")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&parse_value/1)
  end
end

