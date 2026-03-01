# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.TestFixtures.Ipc2020 do
  @moduledoc """
  Paths and discovery for IPC 2020 HDDL domains (test problems).

  The repo is added as a git submodule at `thirdparty/ipc2020-domains`. We do not
  parse HDDL; these paths are used as reference test problems. Port domains to
  glTF Interactivity as needed for export/executor tests.
  """

  @ipc2020_rel "thirdparty/ipc2020-domains"

  @doc """
  Returns the absolute path to the IPC 2020 domains root, or nil if the submodule is not present.
  """
  @spec root_path() :: String.t() | nil
  def root_path do
    # Project root when running mix test / mix run
    root = File.cwd!()
    path = Path.join(root, @ipc2020_rel)
    if File.exists?(path), do: path, else: nil
  end

  @doc """
  Returns true if the IPC 2020 submodule is present (root directory exists).
  """
  @spec available?() :: boolean()
  def available? do
    root_path() != nil
  end

  @doc """
  Lists top-level domain directories under total-order or partial-order.
  Returns a list of short names (e.g. ["Blocksworld-GTOHP", "Rover"]).
  """
  @spec list_domain_names(String.t()) :: [String.t()]
  def list_domain_names(order \\ "total-order") do
    case root_path() do
      nil -> []
      root ->
        path = Path.join(root, order)
        if File.exists?(path) and File.dir?(path) do
          path
          |> File.ls!()
          |> Enum.filter(fn name ->
            full = Path.join(path, name)
            File.dir?(full)
          end)
          |> Enum.sort()
        else
          []
        end
    end
  end
end
