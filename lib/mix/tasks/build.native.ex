# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Build.Native do
  @shortdoc "Build the C interactivity runner in c_src/"
  @moduledoc """
  Runs `make` in `c_src/` to build the GLB interactivity runner.

  Requires `make` and `gcc` (or CC) to be on the PATH. On Windows you may need
  MinGW or WSL. The binary is produced as `c_src/interactivity_runner`.
  """

  use Mix.Task

  @impl true
  def run(_args) do
    cwd = Path.join(File.cwd!(), "c_src")
    Mix.shell().info("Building native runner in #{cwd}")
    case System.cmd("cmake", ["-B", "build", "-S", "."], cd: cwd, stderr_to_stdout: true) do
      {_, 0} -> :ok
      {output, code} ->
        Mix.shell().error(output)
        Mix.raise("cmake configure failed with code #{code}")
    end
    case System.cmd("cmake", ["--build", "build"], cd: cwd, stderr_to_stdout: true) do
      {output, 0} ->
        Mix.shell().info(output)
        Mix.shell().info("Done. Binary: c_src/build/interactivity_runner")
      {output, code} ->
        Mix.shell().error(output)
        Mix.raise("cmake build failed with code #{code}")
    end
  end
end
