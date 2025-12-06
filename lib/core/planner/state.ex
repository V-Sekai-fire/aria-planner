# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.State do
  @moduledoc """
  Represents the planner's state, including current time, timeline, and entity capabilities.
  """
  defstruct [:current_time, :timeline, :entity_capabilities, :facts]

  @type t :: %__MODULE__{
          current_time: DateTime.t(),
          # Represents temporal events/intervals
          timeline: map(),
          # Capabilities of entities in the domain
          entity_capabilities: map(),
          # subject_id => %{predicate_table => fact_value}
          facts: %{String.t() => %{atom() => term()}}
        }

  @spec new(DateTime.t(), map(), map(), map()) :: t()
  def new(current_time, timeline, entity_capabilities, facts),
    do: %__MODULE__{
      current_time: current_time,
      timeline: timeline,
      entity_capabilities: entity_capabilities,
      facts: facts
    }

  @spec copy(t()) :: t()
  def copy(state) do
    %{state | facts: deep_copy_map(state.facts)}
  end

  defp deep_copy_map(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      Map.put(acc, key, deep_copy_map(value))
    end)
  end

  defp deep_copy_map(list) when is_list(list) do
    Enum.map(list, &deep_copy_map/1)
  end

  defp deep_copy_map(other), do: other

  @spec update(t(), t()) :: t()
  def update(state, new_state) do
    Map.merge(state, new_state, fn
      :facts, old_facts, new_facts -> Map.merge(old_facts, new_facts, &recursive_map_merge/3)
      _key, _old_value, new_value -> new_value
    end)
  end

  defp recursive_map_merge(_key, old_value, new_value) when is_map(old_value) and is_map(new_value) do
    Map.merge(old_value, new_value, &recursive_map_merge/3)
  end

  defp recursive_map_merge(_key, _old_value, new_value), do: new_value

  @doc """
  Updates a specific fact in the state.
  """
  @spec update_fact(t(), String.t(), atom(), term()) :: t()
  def update_fact(state, subject_id, predicate_table, fact_value) do
    %{
      state
      | facts:
          Map.update(
            state.facts,
            subject_id,
            %{predicate_table => fact_value},
            fn existing_facts ->
              Map.put(existing_facts, predicate_table, fact_value)
            end
          )
    }
  end

  @doc """
  Retrieves a specific fact from the state.
  """
  @spec get_fact(t(), String.t(), atom()) :: term() | nil
  def get_fact(state, subject_id, predicate_table) do
    state.facts
    # Return an empty map if subject_id is not found
    |> Map.get(subject_id, %{})
    |> Map.get(predicate_table)
  end

  @doc """
  Retrieves a fact using predicate_table -> subject_id structure.
  This matches how facts are stored in domains like aircraft_disassembly
  where facts are organized as facts[predicate_table][subject_id] = value.

  ## Examples

      # For goal format: {"activity_status", ["activity_1", "completed"]}
      get_fact_by_predicate(state, "activity_status", "activity_1")
      # => "completed"
  """
  @spec get_fact_by_predicate(t(), String.t(), String.t()) :: term() | nil
  def get_fact_by_predicate(state, predicate_table, subject_id) do
    state.facts
    # Return an empty map if predicate_table is not found
    |> Map.get(predicate_table, %{})
    |> Map.get(subject_id)
  end
end
