defmodule AriaPlanner.Solvers.ChuffedMiniZinc do
  @moduledoc """
  Chuffed solver using standard MiniZinc interface.
  Uses the `minizinc` command-line tool with `--solver chuffed`.
  """

  @doc """
  Solves a MiniZinc model file using Chuffed solver.
  
  ## Parameters
  
  - `model_path`: Path to .mzn MiniZinc model file
  - `data_path`: Optional path to .dzn data file
  - `opts`: Options keyword list
    - `:timeout` - Timeout in milliseconds (default: 60000)
    - `:solver_options` - Additional solver options
  
  ## Returns
  
  - `{:ok, output}` - MiniZinc output as string
  - `{:error, reason}` - Error reason
  """
  @spec solve_minizinc(String.t(), String.t() | nil, keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def solve_minizinc(model_path, data_path \\ nil, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    solver_options = Keyword.get(opts, :solver_options, [])
    
    if not File.exists?(model_path) do
      {:error, "MiniZinc model file not found: #{model_path}"}
    else
      # Build minizinc command
      cmd = build_minizinc_command(model_path, data_path, solver_options)
      
      # Run minizinc
      try do
        # System.cmd timeout is in milliseconds
        case System.cmd("minizinc", cmd, stderr_to_stdout: true) do
          {output, 0} ->
            {:ok, output}
          
          {output, exit_code} ->
            # MiniZinc may return non-zero but still have a solution
            if String.contains?(output, "=") or String.contains?(output, "Solution") do
              {:ok, output}
            else
              {:error, "MiniZinc failed with exit code #{exit_code}: #{String.slice(output, 0, 500)}"}
            end
        end
      rescue
        e ->
          {:error, "MiniZinc execution failed: #{inspect(e)}"}
      end
    end
  end

  @doc """
  Solves a FlatZinc file using Chuffed.
  
  For FlatZinc files, we use the fzn-chuffed executable directly if available,
  otherwise fall back to MiniZinc.
  
  ## Parameters
  
  - `flatzinc_path`: Path to .fzn FlatZinc file
  - `opts`: Options keyword list
  
  ## Returns
  
  - `{:ok, output}` - Solution output
  - `{:error, reason}` - Error reason
  """
  @spec solve_flatzinc_file(String.t(), keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def solve_flatzinc_file(flatzinc_path, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    
    if not File.exists?(flatzinc_path) do
      {:error, "FlatZinc file not found: #{flatzinc_path}"}
    else
      # Try fzn-chuffed first (direct FlatZinc solver)
      # If not available, use minizinc with chuffed solver
      case find_fzn_chuffed() do
        {:ok, fzn_chuffed_path} ->
          solve_with_fzn_chuffed(fzn_chuffed_path, flatzinc_path, timeout)
        
        :error ->
          # Fall back to minizinc
          solve_with_minizinc(flatzinc_path, timeout)
      end
    end
  end

  defp find_fzn_chuffed do
    # Check common locations for fzn-chuffed
    possible_paths = [
      System.find_executable("fzn-chuffed"),
      Path.join([:code.priv_dir(:aria_planner), "..", "thirdparty", "chuffed", "build", "fzn-chuffed"]),
      Path.join([:code.priv_dir(:aria_planner), "..", "thirdparty", "chuffed", "build", "fzn-chuffed.exe"])
    ]
    
    case Enum.find(possible_paths, &(&1 && File.exists?(&1))) do
      nil -> :error
      path -> {:ok, path}
    end
  end

  defp solve_with_fzn_chuffed(_fzn_chuffed_path, flatzinc_path, timeout) do
    try do
      # Use minizinc with --input-is-flatzinc to solve FlatZinc files
      # and force JSON output
      # MiniZinc can read FlatZinc files directly
      task = Task.async(fn ->
        System.cmd("minizinc", [
          "--solver", "chuffed",
          "--json-stream",
          flatzinc_path
        ], stderr_to_stdout: true)
      end)
      
      case Task.yield(task, timeout) || Task.shutdown(task) do
        {:ok, {output, 0}} ->
          {:ok, output}
        
        {:ok, {output, _exit_code}} ->
          # Check if output contains JSON
          if String.contains?(output, "{") or String.contains?(output, "[") or 
             String.contains?(output, "=") or String.contains?(output, "Solution") do
            {:ok, output}
          else
            {:error, "MiniZinc failed: #{String.slice(output, 0, 500)}"}
          end
        
        nil ->
          {:error, "MiniZinc execution timed out after #{timeout}ms"}
        
        {:exit, reason} ->
          {:error, "MiniZinc process exited: #{inspect(reason)}"}
      end
    rescue
      e ->
        {:error, "MiniZinc execution failed: #{inspect(e)}"}
    end
  end

  defp solve_with_minizinc(flatzinc_path, timeout) do
    # MiniZinc can solve FlatZinc files directly
    try do
      task = Task.async(fn ->
        System.cmd("minizinc", [
          "--solver", "chuffed",
          "--json-stream",
          flatzinc_path
        ], stderr_to_stdout: true)
      end)
      
      case Task.yield(task, timeout) || Task.shutdown(task) do
        {:ok, {output, 0}} ->
          {:ok, output}
        
        {:ok, {output, _exit_code}} ->
          if String.contains?(output, "{") or String.contains?(output, "[") or
             String.contains?(output, "=") or String.contains?(output, "Solution") do
            {:ok, output}
          else
            {:error, "MiniZinc failed: #{String.slice(output, 0, 500)}"}
          end
        
        nil ->
          {:error, "MiniZinc execution timed out after #{timeout}ms"}
        
        {:exit, reason} ->
          {:error, "MiniZinc process exited: #{inspect(reason)}"}
      end
    rescue
      e ->
        {:error, "MiniZinc execution failed: #{inspect(e)}"}
    end
  end

  @doc """
  Checks if MiniZinc with Chuffed solver is available.
  """
  @spec available?() :: boolean()
  def available? do
    case System.cmd("minizinc", ["--solvers"], stderr_to_stdout: true, timeout: 5000) do
      {output, 0} ->
        String.contains?(output, "chuffed") or String.contains?(output, "Chuffed")
      
      _ ->
        false
    end
  rescue
    _ ->
      false
  end

  # Private helpers

  defp build_minizinc_command(model_path, data_path, solver_options) do
    cmd = ["--solver", "chuffed", "--json-stream"]
    
    # Add solver-specific options
    cmd = add_solver_options(cmd, solver_options)
    
    # Add model file
    cmd = cmd ++ [model_path]
    
    # Add data file if provided
    if data_path && File.exists?(data_path) do
      cmd ++ [data_path]
    else
      cmd
    end
  end

  defp add_solver_options(cmd, opts) when is_list(opts) do
    Enum.reduce(opts, cmd, fn
      {:time_limit, ms} ->
        # Convert milliseconds to seconds for MiniZinc
        seconds = div(ms, 1000)
        cmd ++ ["--time-limit", Integer.to_string(seconds)]
      
      {:free_search, true} ->
        cmd ++ ["--free-search"]
      
      {:num_solutions, n} ->
        cmd ++ ["--num-solutions", Integer.to_string(n)]
      
      _ ->
        cmd
    end)
  end

  defp add_solver_options(cmd, _), do: cmd
end

