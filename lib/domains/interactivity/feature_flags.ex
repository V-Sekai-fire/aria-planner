# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.FeatureFlags do
  @moduledoc """
  Feature flags for interactivity domain.

  New and untested features are gated behind feature flags to allow
  gradual rollout and easy rollback if issues are discovered.
  """

  @doc """
  Checks if glTF asset support is enabled.

  This flag gates the new glTF asset loading and JSON pointer resolution
  functionality. When disabled, pointer operations fall back to VariableValue.
  """
  @spec gltf_asset_enabled?() :: boolean()
  def gltf_asset_enabled? do
    FunWithFlags.enabled?(:gltf_asset_support)
  end

  @doc """
  Checks if JSON pointer template parsing is enabled.

  This flag gates the new JSON pointer template parsing functionality
  that supports parameterized pointers like "/nodes/{nodeId}/scale".
  """
  @spec pointer_template_enabled?() :: boolean()
  def pointer_template_enabled? do
    FunWithFlags.enabled?(:pointer_template_support)
  end

  @doc """
  Checks if glTF loader functionality is enabled.

  This flag gates the glTF file loading and behavior graph extraction
  functionality.
  """
  @spec gltf_loader_enabled?() :: boolean()
  def gltf_loader_enabled? do
    FunWithFlags.enabled?(:gltf_loader_support)
  end
end
