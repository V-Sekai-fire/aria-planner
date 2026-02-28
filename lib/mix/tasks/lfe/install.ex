# SPDX-License-Identifier: MIT
# Install rebar3 via Mix so LFE can be compiled.

defmodule Mix.Tasks.Lfe.Install do
  @shortdoc "Install rebar3 (mix local.rebar) for LFE compilation"
  @moduledoc """
  Installs rebar3 so you can compile the LFE project. Runs:

      mix local.rebar

  After this, run `mix lfe.compile` to build the LFE code in `lfe/`.
  """

  use Mix.Task

  @impl true
  def run(_args) do
    Mix.shell().info("Installing rebar3 (used by Mix for Erlang deps and by mix lfe.compile)...")
    Mix.Task.run("local.rebar", [])
    Mix.shell().info("Done. Run mix lfe.compile to build the LFE project.")
  end
end
