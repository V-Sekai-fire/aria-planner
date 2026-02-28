# SPDX-License-Identifier: MIT
# Compile the LFE project under lfe/ using rebar3.

defmodule Mix.Tasks.Lfe.Compile do
  @shortdoc "Compile the LFE project (lfe/); requires rebar3"
  @moduledoc """
  Runs `rebar3 compile` in the `lfe/` directory so the LFE planner and
  interactivity modules are built.

  ## Prerequisites

  Install rebar3 and make it available to Mix:

      mix lfe.install

  or:

      mix local.rebar

  This downloads rebar3 from Hex and stores it in MIX_HOME. The same rebar3
  is then used when you run `mix lfe.compile` (if rebar3 is not on your PATH).

  If you already have rebar3 on your PATH, you can use it directly.

  ## Examples

      mix lfe.compile
  """

  use Mix.Task

  @impl true
  def run(_args) do
    lfe_dir = Path.join(File.cwd!(), "lfe")
    unless File.dir?(lfe_dir) do
      Mix.raise("LFE directory not found: #{lfe_dir}")
    end

    rebar3 = find_rebar3()
    Mix.shell().info("Using rebar3: #{rebar3}")
    Mix.shell().info("Compiling LFE project in #{lfe_dir}")

    case System.cmd(rebar3, ["compile"], cd: lfe_dir, into: IO.stream(:stdio, :line)) do
      {_, 0} ->
        Mix.shell().info("LFE compile finished.")
        :ok

      {_, code} ->
        Mix.raise("rebar3 compile failed with exit code #{code}")
    end
  end

  defp find_rebar3 do
    case System.find_executable("rebar3") do
      path when is_binary(path) ->
        path

      nil ->
        mix_home = Path.expand(Mix.Utils.mix_home())
        candidate = Path.join(mix_home, "rebar3")

        if File.exists?(candidate) do
          candidate
        else
          Mix.raise("""
          rebar3 not found. Install it with:

              mix lfe.install

          or:

              mix local.rebar

          Then run this task again. Alternatively, install rebar3 from
          https://rebar3.org and ensure it is on your PATH.
          """)
        end
    end
  end
end
