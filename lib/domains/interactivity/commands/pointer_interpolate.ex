# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.PointerInterpolate do
  @moduledoc """
  Command: c_pointer_interpolate(node_id, ...)

<<<<<<< HEAD
  Executes pointer/interpolate operation.

  Preconditions:
  - Graph must be active
  - Required input sockets must have values

  Effects:
  - Output socket values are computed
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    NodeExecuted
  }

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers
=======
  Executes pointer/interpolate operation per glTF Interactivity Extension specification.

  Configuration (stored in state):
  - `pointer`: JSON Pointer Template string (e.g., "/nodes/{nodeId}/scale")
  - `type`: Type index from types array

  Input value sockets:
  - Template parameters extracted from pointer template (e.g., `{nodeId}`)
  - `a`: Start value for interpolation
  - `b`: End value for interpolation
  - `t`: Interpolation factor (0.0 to 1.0)

  Preconditions:
  - Graph must be active
  - glTF asset must be available in state
  - Required input sockets must have values

  Effects:
  - glTF property value is set to interpolated value
  - Node is marked as executed
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{GltfAsset, NodeExecuted}

  alias AriaPlanner.Domains.Interactivity.Commands.MathHelpers
  alias AriaPlanner.Domains.Interactivity.FeatureFlags
  alias AriaPlanner.Domains.Interactivity.PointerResolver
  alias AriaPlanner.Domains.Interactivity.Types
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)

  @spec c_pointer_interpolate(
          state :: map(),
          node_id :: String.t(),
<<<<<<< HEAD
          a_socket :: String.t(),
          b_socket :: String.t(),
          c_socket :: String.t(),
          value_socket :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_pointer_interpolate(state, node_id, a_socket, b_socket, c_socket, value_socket) do
    case MathHelpers.check_graph_active(state) do
      :ok ->
        with {:ok, pointer_path} <- MathHelpers.get_socket_value(state, node_id, a_socket),
             {:ok, a} <- MathHelpers.get_socket_value(state, node_id, b_socket),
             {:ok, b} <- MathHelpers.get_socket_value(state, node_id, c_socket),
             {:ok, t} <- MathHelpers.get_socket_value(state, node_id, value_socket) do
          alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue

          result =
            if is_number(a) and is_number(b),
              do: (1.0 - t) * a + t * b,
              else: {:error, "Cannot interpolate non-numeric values"}

          case result do
            {:error, reason} ->
              {:error, reason}

            _ ->
              state = VariableValue.set(state, pointer_path, result)
              state = NodeExecuted.set(state, node_id, true)
              {:ok, state}
          end
        else
          error -> error
=======
          pointer_template_socket :: String.t(),
          a_socket :: String.t(),
          b_socket :: String.t(),
          t_socket :: String.t(),
          opts :: keyword()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def c_pointer_interpolate(
        state,
        node_id,
        pointer_template_socket,
        a_socket,
        b_socket,
        t_socket,
        opts \\ []
      ) do
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
            fallback_to_variable(state, node_id, pointer_template_socket, a_socket, b_socket, t_socket)
          else
            # Get pointer template from socket or config
            pointer_template = get_pointer_template(state, node_id, pointer_template_socket, opts)

            # Get type index from config
            type_index = get_type_index(state, node_id, opts)

            # Get interpolation values
            with {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
                 {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket),
                 {:ok, t} <- MathHelpers.get_socket_value(state, node_id, t_socket) do
              # Perform interpolation
              interpolated_value = interpolate_values(a, b, t)

              perform_interpolation_operation(
                state,
                node_id,
                pointer_template,
                type_index,
                interpolated_value,
                asset,
                graph_id
              )
            else
              error -> error
            end
          end
        else
          # Feature flag disabled - use fallback
          fallback_to_variable(state, node_id, pointer_template_socket, a_socket, b_socket, t_socket)
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
        end

      error ->
        error
    end
  end
<<<<<<< HEAD
=======

  # Helper function to reduce nesting depth
  defp perform_interpolation_operation(
         state,
         node_id,
         pointer_template,
         type_index,
         interpolated_value,
         asset,
         graph_id
       ) do
    # Parse template and get parameters
    case PointerResolver.parse_template(pointer_template) do
      {:ok, param_list} ->
        # Get parameter values from input sockets
        case get_parameter_values(state, node_id, param_list) do
          {:ok, param_values} ->
            # Check for negative values (per spec)
            if Enum.any?(Map.values(param_values), fn val -> is_integer(val) and val < 0 end) do
              # Invalid: negative index
              state = NodeExecuted.set(state, node_id, true)
              {:ok, state}
            else
              # Check if pointer template support is enabled
              if FeatureFlags.pointer_template_enabled?() do
                # Resolve template with parameters
                case PointerResolver.resolve_template(pointer_template, param_values) do
                  {:ok, effective_pointer} ->
                    set_interpolated_property(
                      state,
                      node_id,
                      effective_pointer,
                      type_index,
                      interpolated_value,
                      asset,
                      graph_id
                    )

                  {:error, reason} ->
                    {:error, "Failed to resolve pointer: #{reason}"}
                end
              else
                # Template parsing disabled - treat as simple pointer
                set_interpolated_property(
                  state,
                  node_id,
                  pointer_template,
                  type_index,
                  interpolated_value,
                  asset,
                  graph_id
                )
              end
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, "Invalid pointer template: #{reason}"}
    end
  end

  # Helper function to set interpolated property
  defp set_interpolated_property(state, node_id, pointer, type_index, interpolated_value, asset, graph_id) do
    type_name = Types.type_name(type_index) || "float"

    if Types.validate_type(interpolated_value, type_name) do
      case PointerResolver.set_property(asset, pointer, interpolated_value) do
        {:ok, updated_asset} ->
          # Update asset in state
          state = GltfAsset.set(state, graph_id, updated_asset)
          state = NodeExecuted.set(state, node_id, true)
          {:ok, state}

        {:error, reason} ->
          {:error, "Failed to set property: #{reason}"}
      end
    else
      # Type mismatch - per spec, this is not an error
      state = NodeExecuted.set(state, node_id, true)
      {:ok, state}
    end
  end

  defp interpolate_values(a, b, t) when is_number(a) and is_number(b) and is_number(t) do
    (1.0 - t) * a + t * b
  end

  defp interpolate_values({a1, a2}, {b1, b2}, t) when is_number(t) do
    {(1.0 - t) * a1 + t * b1, (1.0 - t) * a2 + t * b2}
  end

  defp interpolate_values({a1, a2, a3}, {b1, b2, b3}, t) when is_number(t) do
    {(1.0 - t) * a1 + t * b1, (1.0 - t) * a2 + t * b2, (1.0 - t) * a3 + t * b3}
  end

  defp interpolate_values({a1, a2, a3, a4}, {b1, b2, b3, b4}, t) when is_number(t) do
    {(1.0 - t) * a1 + t * b1, (1.0 - t) * a2 + t * b2, (1.0 - t) * a3 + t * b3, (1.0 - t) * a4 + t * b4}
  end

  defp interpolate_values(a, b, t) when is_tuple(a) and is_tuple(b) and tuple_size(a) == tuple_size(b) do
    a
    |> Tuple.to_list()
    |> Enum.zip_with(Tuple.to_list(b), fn x, y -> (1.0 - t) * x + t * y end)
    |> List.to_tuple()
  end

  defp interpolate_values(_a, _b, _t), do: {:error, "Cannot interpolate incompatible types"}

  defp get_graph_id(state, _node_id) do
    Map.get(state, {:active_graph, :id}) ||
      Map.get(state, :active_graph_id) ||
      "default"
  end

  defp get_pointer_template(state, node_id, socket, opts) do
    cond do
      config = Map.get(state, {:node_config, node_id}) ->
        Map.get(config, "pointer") || Map.get(config, :pointer)

      template = Keyword.get(opts, :pointer) ->
        template

      true ->
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
    param_values =
      Enum.reduce_while(param_list, %{}, fn {socket_id, _start, _end}, acc ->
        case MathHelpers.get_socket_value(state, node_id, socket_id) do
          {:ok, value} ->
            {:cont, Map.put(acc, socket_id, value)}

          {:error, _} ->
            {:halt, {:error, "Missing parameter socket: #{socket_id}"}}
        end
      end)

    if is_map(param_values) do
      {:ok, param_values}
    else
      param_values
    end
  end

  # Fallback to VariableValue for backward compatibility
  defp fallback_to_variable(state, node_id, pointer_template_socket, a_socket, b_socket, t_socket) do
    with {:ok, pointer_path} <- MathHelpers.get_socket_value(state, node_id, pointer_template_socket),
         {:ok, a} <- MathHelpers.get_socket_value(state, node_id, a_socket),
         {:ok, b} <- MathHelpers.get_socket_value(state, node_id, b_socket),
         {:ok, t} <- MathHelpers.get_socket_value(state, node_id, t_socket) do
      alias AriaPlanner.Domains.Interactivity.Predicates.VariableValue

      result = interpolate_values(a, b, t)

      case result do
        {:error, reason} ->
          {:error, reason}

        _ ->
          state = VariableValue.set(state, pointer_path, result)
          state = NodeExecuted.set(state, node_id, true)
          {:ok, state}
      end
    else
      error -> error
    end
  end
>>>>>>> 23d7f9f (Complete interactivity domain implementation with glTF support)
end
