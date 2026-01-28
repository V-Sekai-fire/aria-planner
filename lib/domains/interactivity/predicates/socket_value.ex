# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.SocketValue do
  @moduledoc """
  Socket value predicate for interactivity domain.

  Represents the value stored in a value socket (input or output).
  Value sockets have types: bool, float, float2, float3, float4, int, etc.
  """

  @doc """
  Gets the value of a socket from state.
  """
  @spec get(state :: map(), node_id :: String.t(), socket_id :: String.t()) ::
          any() | nil
  def get(state, node_id, socket_id) do
    key = {:socket_value, node_id, socket_id}
    Map.get(state, key)
  end

  @doc """
  Sets the value of a socket in state.
  """
  @spec set(state :: map(), node_id :: String.t(), socket_id :: String.t(), value :: any()) ::
          map()
  def set(state, node_id, socket_id, value) do
    key = {:socket_value, node_id, socket_id}
    Map.put(state, key, value)
  end

  @doc """
  Gets the type of a socket from state.
  """
  @spec get_type(state :: map(), node_id :: String.t(), socket_id :: String.t()) ::
          String.t() | nil
  def get_type(state, node_id, socket_id) do
    key = {:socket_type, node_id, socket_id}
    Map.get(state, key)
  end

  @doc """
  Sets the type of a socket in state.
  """
  @spec set_type(state :: map(), node_id :: String.t(), socket_id :: String.t(), type :: String.t()) :: map()
  def set_type(state, node_id, socket_id, type) do
    key = {:socket_type, node_id, socket_id}
    Map.put(state, key, type)
  end
end
