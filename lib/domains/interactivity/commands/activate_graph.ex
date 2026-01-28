# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.ActivateGraph do
  @moduledoc """
<<<<<<< HEAD
  Command: c_activate_graph(graph_id)
=======
  Command: c_activate_graph(graph_id, opts \\ [])
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)

  Activates a behavior graph.

  Preconditions:
  - None (graph can always be activated)

  Effects:
  - Graph is marked as active
<<<<<<< HEAD
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.GraphActive

  @spec c_activate_graph(state :: map(), graph_id :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_activate_graph(state, graph_id) do
=======
  - glTF asset is stored if provided in opts

  Options:
  - `:gltf_asset` - Optional glTF asset map to store for pointer resolution
  """

  alias AriaPlanner.Domains.Interactivity.FeatureFlags
  alias AriaPlanner.Domains.Interactivity.Predicates.GltfAsset
  alias AriaPlanner.Domains.Interactivity.Predicates.GraphActive

  @spec c_activate_graph(state :: map(), graph_id :: String.t(), opts :: keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def c_activate_graph(state, graph_id, opts \\ []) do
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
    # Activate the graph
    state = GraphActive.activate(state)

    # Store graph_id for reference
    state = Map.put(state, {:active_graph, graph_id}, true)

<<<<<<< HEAD
=======
    # Store glTF asset if provided and feature flag is enabled
    state =
      if FeatureFlags.gltf_asset_enabled?() do
        case Keyword.get(opts, :gltf_asset) do
          nil -> state
          asset when is_map(asset) -> GltfAsset.set(state, graph_id, asset)
          _ -> state
        end
      else
        state
      end

>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
    {:ok, state}
  end
end
