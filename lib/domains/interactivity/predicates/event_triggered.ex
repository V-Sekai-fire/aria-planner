# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.EventTriggered do
  @moduledoc """
  Event triggered predicate for interactivity domain.

  Represents custom events that can trigger graph execution.
  Events are application-specific and can be used for external interactions.
  """

  @doc """
  Checks if an event has been triggered in state.
  """
  @spec triggered?(state :: map(), event_name :: String.t()) :: boolean()
  def triggered?(state, event_name) do
    key = {:event_triggered, event_name}
    Map.get(state, key, false)
  end

  @doc """
  Sets an event as triggered in state.
  """
  @spec trigger(state :: map(), event_name :: String.t()) :: map()
  def trigger(state, event_name) do
    key = {:event_triggered, event_name}
    Map.put(state, key, true)
  end

  @doc """
  Clears an event trigger in state.
  """
  @spec clear(state :: map(), event_name :: String.t()) :: map()
  def clear(state, event_name) do
    key = {:event_triggered, event_name}
    Map.delete(state, key)
  end

  @doc """
  Sets an event with custom metadata in state.
  """
  @spec set(state :: map(), event_name :: String.t(), metadata :: any(), triggered :: boolean()) :: map()
  def set(state, event_name, _metadata, triggered) do
    key = {:event_triggered, event_name}
    Map.put(state, key, triggered)
  end
end
