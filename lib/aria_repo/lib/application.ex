# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaRepo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Code.ensure_loaded?(AriaRepo.Repo) and function_exported?(AriaRepo.Repo, :start_link, 1) do
        [AriaRepo.Repo]
      else
        []
      end

    opts = [strategy: :one_for_one, name: AriaRepo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
