# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.State do
  @moduledoc """
  In-memory state representation for the Aria Hybrid Planner.

  This module provides a structured state representation that enforces
  the required fields while maintaining map-like behavior for facts storage.
  """

  @type predicate :: String.t()
  @type subject :: String.t()
  @type fact_value :: term()
  @type fact :: {predicate(), subject(), fact_value()}

  @type t :: %__MODULE__{
          facts: %{optional(predicate()) => %{optional(subject()) => fact_value()}}
        }

  @enforce_keys [:facts]
  defstruct facts: %{}

  @doc """
  Create a new empty state.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{facts: %{}}
  end

  @doc """
  Create a state with initial facts.
  """
  @spec new(%{optional(predicate()) => %{optional(subject()) => fact_value()}}) :: t()
  def new(facts) when is_map(facts) do
    %__MODULE__{facts: facts}
  end

  @doc """
  Check if a predicate-subject-value triple matches in the state.

  ## Parameters
  - `state`: The state to check
  - `predicate`: The predicate to match
  - `subject`: The subject to match
  - `value`: The expected value

  ## Returns
  - `true` if the triple exists and matches
  - `false` otherwise
  """
  @spec matches?(t(), predicate(), subject(), fact_value()) :: boolean()
  def matches?(%__MODULE__{facts: facts}, predicate, subject, value) do
    case get_in(facts, [predicate, subject]) do
      ^value -> true
      _ -> false
    end
  end

  @doc """
  Convert state facts to a list of {predicate, subject, value} triples.

  ## Parameters
  - `state`: The state to convert

  ## Returns
  - List of {predicate, subject, value} tuples representing all facts
  """
  @spec to_triples(t()) :: [fact()]
  def to_triples(%__MODULE__{facts: facts}) do
    for {predicate, subjects} <- facts,
        {subject, value} <- subjects do
      {predicate, subject, value}
    end
  end

  @doc """
  Set a fact in the state.

  ## Parameters
  - `state`: The state to update
  - `predicate`: The predicate
  - `subject`: The subject
  - `value`: The value to set

  ## Returns
  - Updated state with the new fact
  """
  @spec set_fact(t(), predicate(), subject(), fact_value()) :: t()
  def set_fact(%__MODULE__{facts: facts} = state, predicate, subject, value) do
    updated_facts =
      update_in(facts, [predicate], fn
        nil -> %{subject => value}
        existing -> Map.put(existing, subject, value)
      end)

    %{state | facts: updated_facts}
  end

  @doc """
  Check if the state has any facts.
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{facts: facts}) do
    map_size(facts) == 0
  end

  @doc """
  Get the number of facts in the state.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{facts: facts}) do
    Enum.reduce(facts, 0, fn {_pred, subjects}, acc ->
      acc + map_size(subjects)
    end)
  end
end
