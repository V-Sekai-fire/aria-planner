# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.PointerGet do
  @moduledoc """
  Command: c_pointer_get(node_id, ...)

<<<<<<< HEAD
  Executes pointer/get operation.

  Preconditions:
  - Graph must be active
=======
  Executes pointer/get operation per glTF Interactivity Extension specification.

  Configuration (stored in state):
  - `pointer`: JSON Pointer Template string (e.g., "/nodes/{nodeId}/scale")
  - `type`: Type index from types array

  Input value sockets:
  - Template parameters extracted from pointer template (e.g., `{nodeId}`)

  Output value sockets:
  - `value`: The resolved property value
  - `isValid`: Boolean indicating if property could be resolved

  Preconditions:
  - Graph must be active
  - glTF asset must be available in state
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
<<<<<<< HEAD
=======
    GltfAsset,
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
    NodeExecuted,
    SocketValue
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers
<<<<<<< HEAD

  @spec c_pointer_get(state :: map(), node_id :: String.t(), a_socket :: String.t(), value_socket :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_pointer_get(state, node_id, a_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        case MathHelpers.get_socket_value(state, node_id, a_socket) do
          {:ok, pointer_path} ->
            # Pointer access reads from nested structure (simplified: treat as variable)
            alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue
            value = VariableValue.get(state, pointer_path)

            if value != nil do
              state = SocketValue.set(state, node_id, value_socket, value)
              state = NodeExecuted.set(state, node_id, true)
              {:ok, state}
            else
              {:error, "Pointer #{pointer_path} not found"}
            end

          error ->
            error
=======
  alias AriaPlanner.Domains.Interactivity.FeatureFlags
  alias AriaPlanner.Domains.Interactivity.PointerResolver
  alias AriaPlanner.Domains.Interactivity.Types

  @spec c_pointer_get(
          state :: map(),
          node_id :: String.t(),
          pointer_template_socket :: String.t(),
          value_socket :: String.t(),
          opts :: keyword()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_pointer_get(state, node_id, pointer_template_socket, value_socket, opts \\ []) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        # Get graph ID (for glTF asset lookup)
        graph_id = get_graph_id(state, node_id)

        # Check if glTF asset support is enabled
        if FeatureFlags.gltf_asset_enabled?() do
          # Get glTF asset
          asset = GltfAsset.get(state, graph_id)

          if asset == nil do
            # Fallback to VariableValue for backward compatibility
            fallback_to_variable(state, node_id, pointer_template_socket, value_socket)
          else
            # Get pointer template from socket or config
            pointer_template = get_pointer_template(state, node_id, pointer_template_socket, opts)

            # Get type index from config
            type_index = get_type_index(state, node_id, opts)

            perform_get_operation(state, node_id, pointer_template, type_index, value_socket, asset)
          end
        else
          # Feature flag disabled - use fallback
          fallback_to_variable(state, node_id, pointer_template_socket, value_socket)
        end

      error ->
        error
    end
  end

  defp get_graph_id(state, _node_id) do
    # Try to get graph ID from state
    Map.get(state, {:active_graph, :id}) ||
      Map.get(state, :active_graph_id) ||
      "default"
  end

  defp get_pointer_template(state, node_id, socket, opts) do
    # Try config first, then socket value, then opts
    cond do
      config = Map.get(state, {:node_config, node_id}) ->
        Map.get(config, "pointer") || Map.get(config, :pointer)

      template = Keyword.get(opts, :pointer) ->
        template

      true ->
        # Fallback: treat socket value as simple pointer path
        case MathHelpers.get_socket_value(state, node_id, socket) do
          {:ok, path} -> path
          _ -> "/"
        end
    end
  end

  defp get_type_index(state, node_id, opts) do
    cond do
      config = Map.get(state, {:node_config, node_id}) ->
        Map.get(config, "type") || Map.get(config, :type) || 2

      index = Keyword.get(opts, :type) ->
        index

      true ->
        2
    end
  end

  defp get_parameter_values(state, node_id, param_list) do
    # Get values for each parameter from input sockets
    param_values =
      Enum.reduce_while(param_list, %{}, fn {socket_id, _start, _end}, acc ->
        case MathHelpers.get_socket_value(state, node_id, socket_id) do
          {:ok, value} ->
            {:cont, Map.put(acc, socket_id, value)}

          {:error, _reason} ->
            {:halt, {:error, "Missing parameter socket: #{socket_id}"}}
        end
      end)

    if is_map(param_values) do
      {:ok, param_values}
    else
      param_values
    end
  end

  defp set_outputs(state, node_id, value_socket, value, is_valid) do
    # Set value socket
    state = SocketValue.set(state, node_id, value_socket, {value, is_valid})

    # Mark node as executed
    state = NodeExecuted.set(state, node_id, true)

    {:ok, state}
  end

  # Helper function to reduce nesting depth
  defp perform_get_operation(state, node_id, pointer_template, type_index, value_socket, asset) do
    # Parse template and get parameters
    case PointerResolver.parse_template(pointer_template) do
      {:ok, param_list} ->
        # Get parameter values from input sockets
        case get_parameter_values(state, node_id, param_list) do
          {:ok, param_values} ->
            # Check for negative values (per spec step 2)
            if Enum.any?(Map.values(param_values), fn val -> is_integer(val) and val < 0 end) do
              # Set isValid=false and default value
              type_name = Types.type_name(type_index) || "float"
              default_value = Types.default_value(type_name)
              set_outputs(state, node_id, value_socket, default_value, false)
            else
              # Check if pointer template support is enabled
              if FeatureFlags.pointer_template_enabled?() do
                # Resolve template with parameters
                case PointerResolver.resolve_template(pointer_template, param_values) do
                  {:ok, effective_pointer} ->
                    # Get property from glTF asset
                    type_name = Types.type_name(type_index) || "float"
                    {value, is_valid} = PointerResolver.get_property(asset, effective_pointer, type_name)
                    set_outputs(state, node_id, value_socket, value, is_valid)

                  {:error, _reason} ->
                    type_name = Types.type_name(type_index) || "float"
                    default_value = Types.default_value(type_name)
                    set_outputs(state, node_id, value_socket, default_value, false)
                end
              else
                # Template parsing disabled - treat as simple pointer
                type_name = Types.type_name(type_index) || "float"
                {value, is_valid} = PointerResolver.get_property(asset, pointer_template, type_name)
                set_outputs(state, node_id, value_socket, value, is_valid)
              end
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, "Invalid pointer template: #{reason}"}
    end
  end

  # Fallback to VariableValue for backward compatibility
  defp fallback_to_variable(state, node_id, pointer_template_socket, value_socket) do
    case MathHelpers.get_socket_value(state, node_id, pointer_template_socket) do
      {:ok, pointer_path} ->
        alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue
        value = VariableValue.get(state, pointer_path)

        if value != nil do
          state = SocketValue.set(state, node_id, value_socket, {value, true})
          state = NodeExecuted.set(state, node_id, true)
          {:ok, state}
        else
          # Return default with isValid=false
          state = SocketValue.set(state, node_id, value_socket, {nil, false})
          state = NodeExecuted.set(state, node_id, true)
          {:ok, state}
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
        end

      error ->
        error
    end
  end
end
