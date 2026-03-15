# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.FeatureFlags do
  @moduledoc """
  Feature flags for interactivity domain.

  New and untested features are gated behind feature flags to allow
  gradual rollout and easy rollback if issues are discovered.

  FunWithFlags removed; all flags default to true. Use application config
  :aria_planner, :feature_flags, [gltf_asset: true, pointer_template: true, gltf_loader: true]
  to override.
  """

  @doc """
  Checks if glTF asset support is enabled.
  """
  @spec gltf_asset_enabled?() :: boolean()
  def gltf_asset_enabled? do
    get_flag(:gltf_asset, true)
  end

  @doc """
  Checks if JSON pointer template parsing is enabled.
  """
  @spec pointer_template_enabled?() :: boolean()
  def pointer_template_enabled? do
    get_flag(:pointer_template, true)
  end

  @doc """
  Checks if glTF loader functionality is enabled.
  """
  @spec gltf_loader_enabled?() :: boolean()
  def gltf_loader_enabled? do
    get_flag(:gltf_loader, true)
  end

  defp get_flag(key, default) do
    Application.get_env(:aria_planner, :feature_flags, [])
    |> Keyword.get(key, default)
  end
end
