# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias AriaPlanner.Planner.DomainRegistry

  @impl true
  @spec start(Application.start_type(), term()) :: {:ok, pid()} | {:ok, pid(), term()} | {:error, term()}
  def start(_type, _args) do
    # Initialize ETS storage
    AriaPlanner.Storage.EtsStorage.start_link()

    children = [
      # Domain Registry for dynamic domain discovery
      DomainRegistry
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaPlanner.Planner.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
