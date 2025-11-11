defmodule AriaPlanner.Solvers.ChuffedCNode do
  @moduledoc """
  Chuffed solver using C node approach.
  Communicates with a separate C++ process running Chuffed.
  """

  @cnode_path Path.join([:code.priv_dir(:aria_planner), "chuffed_cnode"])

  @doc """
  Solves a FlatZinc problem using Chuffed via C node.
  """
  @spec solve_flatzinc(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def solve_flatzinc(flatzinc_content, _options \\ "{}") do
    # Use port-based communication with C node executable
    # The C node reads from stdin and writes to stdout/stderr
    cnode_path = Path.expand(@cnode_path)
    
    if not File.exists?(cnode_path) do
      {:error, "Chuffed C node not found at #{cnode_path}. Please build with 'make -C c_src'."}
    else
      # Use port to communicate with C node
      port = Port.open({:spawn_executable, cnode_path}, [
        :binary,
        :use_stdio,
        :stderr_to_stdout,
        :exit_status
      ])

      # Send FlatZinc content and close stdin to signal EOF
      Port.command(port, flatzinc_content)
      Port.close(port)

      # Read response (port will close when process exits)
      result = collect_response(port, <<>>)

      case result do
        {:ok, data} -> parse_response(data)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp collect_response(port, acc) do
    receive do
      {^port, {:data, data}} ->
        collect_response(port, acc <> data)

      {^port, {:exit_status, status}} ->
        if status == 0 do
          {:ok, acc}
        else
          {:error, "C node exited with status #{status}. Output: #{acc}"}
        end
    after
      60_000 ->
        {:error, "Timeout waiting for Chuffed response. Partial output: #{acc}"}
    end
  end

  defp parse_response(data) do
    # Parse the response from C node
    # Format: "ok\n<solution>" or "error\n<error_message>"
    case String.split(data, "\n", parts: 2) do
      ["ok" <> rest, solution] ->
        {:ok, solution}

      ["ok" <> rest] ->
        {:ok, rest}

      ["error", error] ->
        {:error, error}

      ["error" <> rest] ->
        {:error, rest}

      _ ->
        # Try to parse as raw output (might be solution without prefix)
        if String.contains?(data, "=") or String.contains?(data, "Solution") do
          {:ok, data}
        else
          {:error, "Invalid response format: #{String.slice(inspect(data), 0, 100)}"}
        end
    end
  end

  @doc """
  Checks if Chuffed C node is available.
  """
  @spec available?() :: boolean()
  def available? do
    cnode_path = Path.expand(@cnode_path)
    File.exists?(cnode_path) && File.executable?(cnode_path)
  end
end

