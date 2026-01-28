# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.GltfLoader do
  @moduledoc """
  glTF file loader for Interactivity Extension.

  Loads glTF files (.gltf JSON or .glb binary) and extracts behavior graphs
  from the KHR_interactivity extension.

  This module is gated behind the `:gltf_loader_support` feature flag.
  """

  alias AriaPlanner.Domains.Interactivity.FeatureFlags

  @doc """
  Loads a glTF file and extracts the behavior graph.

  Returns `{:ok, {asset, behavior_graph}}` or `{:error, reason}`.

  The asset is the parsed glTF structure, and behavior_graph is the extracted
  behavior graph from extensions.KHR_interactivity.
  """
  @spec load_from_file(file_path :: String.t()) ::
          {:ok, {map(), map()}} | {:error, String.t()}
  def load_from_file(file_path) when is_binary(file_path) do
    if FeatureFlags.gltf_loader_enabled?() do
      case File.read(file_path) do
        {:ok, content} ->
          if String.ends_with?(file_path, ".glb") do
            load_glb(content)
          else
            load_gltf_json(content)
          end

        {:error, reason} ->
          {:error, "Failed to read file: #{inspect(reason)}"}
      end
    else
      {:error, "glTF loader support is disabled (feature flag :gltf_loader_support)"}
    end
  end

  def load_from_file(_file_path), do: {:error, "File path must be a string"}

  @doc """
  Loads a glTF JSON string.

  Returns `{:ok, {asset, behavior_graph}}` or `{:error, reason}`.
  """
  @spec load_gltf_json(json_string :: String.t()) ::
          {:ok, {map(), map()}} | {:error, String.t()}
  def load_gltf_json(json_string) when is_binary(json_string) do
    if FeatureFlags.gltf_loader_enabled?() do
      case Jason.decode(json_string) do
        {:ok, asset} ->
          extract_behavior_graph(asset)

        {:error, reason} ->
          {:error, "Failed to parse JSON: #{inspect(reason)}"}
      end
    else
      {:error, "glTF loader support is disabled (feature flag :gltf_loader_support)"}
    end
  end

  def load_gltf_json(_), do: {:error, "JSON string must be a string"}

  @doc """
  Loads a glTF binary (.glb) file.

  Note: Full .glb parsing is complex. This is a placeholder that will need
  aria-gltf library integration for proper binary format support.
  """
  @spec load_glb(binary_content :: binary()) ::
          {:ok, {map(), map()}} | {:error, String.t()}
  def load_glb(binary_content) when is_binary(binary_content) do
    # TODO: Implement .glb parsing using aria-gltf library when available
    # For now, return error as .glb support is not yet implemented
    {:error, ".glb file format support is not yet implemented"}
  end

  def load_glb(_), do: {:error, "Binary content must be binary"}

  @doc """
  Extracts the behavior graph from a parsed glTF asset.

  Returns `{:ok, {asset, behavior_graph}}` or `{:error, reason}`.
  """
  @spec extract_behavior_graph(asset :: map()) ::
          {:ok, {map(), map()}} | {:error, String.t()}
  def extract_behavior_graph(asset) when is_map(asset) do
    case get_in(asset, ["extensions", "KHR_interactivity"]) do
      nil ->
        {:error, "No KHR_interactivity extension found in glTF asset"}

      behavior_graph ->
        # Validate basic structure
        case validate_graph(behavior_graph) do
          :ok ->
            {:ok, {asset, behavior_graph}}

          {:error, reason} ->
            {:error, "Invalid behavior graph: #{reason}"}
        end
    end
  end

  def extract_behavior_graph(_), do: {:error, "Asset must be a map"}

  @doc """
  Validates a behavior graph structure.

  Returns `:ok` or `{:error, reason}`.
  """
  @spec validate_graph(graph :: map()) :: :ok | {:error, String.t()}
  def validate_graph(graph) when is_map(graph) do
    # Basic validation: check for required top-level fields
    # According to spec, behavior graphs contain nodes, and MAY contain
    # custom variables and custom events

    if Map.has_key?(graph, "nodes") do
      :ok
    else
      {:error, "Behavior graph must contain 'nodes' array"}
    end
  end

  def validate_graph(_), do: {:error, "Behavior graph must be a map"}

  @doc """
  Gets the behavior graph from a glTF asset without loading from file.

  Useful when you already have a parsed glTF asset.
  """
  @spec get_behavior_graph(asset :: map()) :: map() | nil
  def get_behavior_graph(asset) when is_map(asset) do
    get_in(asset, ["extensions", "KHR_interactivity"])
  end

  def get_behavior_graph(_), do: nil
end
