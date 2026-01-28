# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.GltfAsset do
  @moduledoc """
  glTF asset predicate for interactivity domain.

  Stores parsed glTF asset structures in state for JSON pointer resolution.
  Multiple behavior graphs can reference the same glTF asset.
  """

  @doc """
  Gets the glTF asset for a graph from state.

  Returns the parsed glTF asset structure, or nil if not found.
  """
  @spec get(state :: map(), graph_id :: String.t()) :: map() | nil
  def get(state, graph_id) do
    key = {:gltf_asset, graph_id}
    Map.get(state, key)
  end

  @doc """
  Sets the glTF asset for a graph in state.

  The asset should be a parsed glTF structure (map) from aria-gltf.
  """
  @spec set(state :: map(), graph_id :: String.t(), asset :: map()) :: map()
  def set(state, graph_id, asset) do
    key = {:gltf_asset, graph_id}
    Map.put(state, key, asset)
  end

  @doc """
  Checks if a glTF asset exists for a graph.
  """
  @spec has_asset?(state :: map(), graph_id :: String.t()) :: boolean()
  def has_asset?(state, graph_id) do
    get(state, graph_id) != nil
  end
end
