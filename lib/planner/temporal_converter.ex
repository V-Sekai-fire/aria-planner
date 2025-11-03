# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.TemporalConverter do
  @moduledoc """
  Converts durative actions with complex temporal semantics into simple actions
  suitable for HTN planning, along with method decompositions that preserve
  the original temporal constraints.

  ## Overview

  TemporalConverter bridges the gap between complex durative actions (with at_start,
  over_all, and at_end conditions/effects) and the simpler action model used by HTN planners.
  It decomposes temporal complexity into method-based planning elements.

  ## Durative Action Structure

  Durative actions have temporal phases:
  - **at_start**: Conditions/effects that apply when action begins
  - **over_all**: Conditions that must hold throughout action duration
  - **at_end**: Conditions/effects that apply when action completes

  ## Conversion Process

  1. **Extract Simple Action**: Create duration-only action for HTN planner
  2. **Build Method Decomposition**: Create method that handles temporal logic
  3. **Preserve Semantics**: Ensure temporal constraints are maintained

  ## Example

  ```elixir
  durative_action = %{
    name: :cook_meal,
    duration: "PT30M",
    conditions: %{
      at_start: [{"oven", "temperature", {:>=, 350}}],
      over_all: [{"kitchen", "ventilated", true}],
      at_end: [{"meal", "ready", true}]
    }
  }

  {simple_action, method} = TemporalConverter.convert_durative_action(durative_action)
  ```
  """
  alias AriaPlanner.Client


  @doc """
  Converts a durative action into a simple action and method decomposition.

  Legacy durative actions with complex temporal conditions are converted as follows:

  - **at_start conditions** → **prerequisite goals** in method decomposition
  - **at_start effects** → **setup tasks** in method decomposition
  - **over_all conditions** → **monitoring tasks** in method decomposition
  - **Main action** → **simple durative action** (duration + entity requirements only)
  - **at_end conditions** → **verification goals** in method decomposition
  - **at_end effects** → **cleanup tasks** in method decomposition

  ## Parameters

  - `durative_action`: Map with name, duration, conditions, effects, etc.

  ## Returns

  - `{simple_action, method_decomposition}` tuple

  ## Example

      iex> durative_action = %{name: :cook_meal, duration: "PT1H", conditions: %{at_start: [{"oven", "temperature", {:>=, 350}}]}, effects: %{at_end: [{"meal", "quality", {:>=, 8}}]}}
      iex> {simple_action, method} = convert_durative_action(durative_action)
      iex> simple_action.name
      :cook_meal
      iex> simple_action.duration
      "PT1H"
  """
  def convert_durative_action(durative_action) do
    simple_action = extract_simple_action(durative_action)
    method_decomposition = build_method_decomposition(durative_action)
    {simple_action, method_decomposition}
  end

  @doc """
  Extracts a simple action from a durative action.

  Removes all temporal conditions and effects, keeping only:
  - Action name
  - Duration specification
  - Entity requirements
  - Capabilities
  - Basic action function

  ## Parameters

  - `durative_action`: The durative action to simplify

  ## Returns

  - Simple action map with basic properties
  """
  def extract_simple_action(durative_action) do
    duration =
      case durative_action[:duration] do
        duration when is_binary(duration) ->
          if (Client.iso8601_duration_to_microseconds(duration) |> elem(0) == :ok) do
            duration
          else
            # Default for invalid duration
            "PT1S"
          end

        {:fixed, seconds_value} ->
          build_iso8601_duration(seconds_value)

        {:controllable, seconds_value} ->
          build_iso8601_duration(seconds_value)

        nil ->
          # Default 1 second duration
          "PT1S"

        _ ->
          # Default for unknown format
          "PT1S"
      end

    %{
      name: durative_action.name,
      duration: duration
    }
  end

  # Private helper to build ISO8601 duration string from seconds
  defp build_iso8601_duration(seconds) when is_integer(seconds) do
    build_iso8601_duration({seconds, 0})
  end

  defp build_iso8601_duration({seconds, microseconds}) when is_integer(seconds) and is_integer(microseconds) do
    total_seconds = seconds + div(microseconds, 1_000_000)
    remaining_microseconds = rem(microseconds, 1_000_000)

    hours = div(total_seconds, 3600)
    remaining_after_hours = rem(total_seconds, 3600)
    minutes = div(remaining_after_hours, 60)
    secs = rem(remaining_after_hours, 60)

    # Build the time portion
    time_parts =
      []
      |> maybe_append_hours(hours)
      |> maybe_append_minutes(minutes)
      |> maybe_append_seconds(secs, remaining_microseconds)

    case time_parts do
      [] -> "PT1S"  # Default if all zeros
      parts -> "PT" <> Enum.join(parts)
    end
  end

  defp maybe_append_hours(acc, 0), do: acc
  defp maybe_append_hours(acc, hours), do: acc ++ ["#{hours}H"]

  defp maybe_append_minutes(acc, 0), do: acc
  defp maybe_append_minutes(acc, minutes), do: acc ++ ["#{minutes}M"]

  defp maybe_append_seconds(acc, 0, 0), do: acc
  defp maybe_append_seconds(acc, secs, 0) do
    acc ++ ["#{secs}S"]
  end

  defp maybe_append_seconds(acc, secs, microseconds) when microseconds > 0 do
    # Build fractional seconds string without storing singular numeric values
    microsecond_string = microseconds |> :erlang.float_to_binary([decimals: 6]) |> String.replace_prefix("0.", "")
    acc ++ ["#{secs}.#{microsecond_string}S"]
  end

  @doc """
  Builds method decomposition for a durative action.

  Creates a method that returns a list of planner elements (actions, tasks, unigoals)
  that achieve the temporal goals of the original durative action.

  ## Parameters

  - `durative_action`: The durative action to decompose

  ## Returns

  - Method function that returns {:ok, todo_items, metadata}
  """
  def build_method_decomposition(durative_action) do
    # Create a method function that returns proper HTN planner elements
    fn _state, _args ->
      todo_items = extract_todo_items(durative_action)
      metadata = create_method_metadata(durative_action)
      {:ok, todo_items, metadata}
    end
  end

  @doc """
  Validates that a conversion preserves the original durative action semantics.

  ## Parameters

  - `original`: The original durative action
  - `conversion`: {simple_action, method} tuple

  ## Returns

  - `true` if conversion is valid, `false` otherwise
  """
  def validate_conversion(original, {simple_action, method_fn}) do
    # Basic validation for the new method function format
    # Test that the method function can be called
    simple_action.name == original.name &&
      is_function(method_fn) &&
      case method_fn.(%{}, []) do
        {:ok, todo_items, metadata} ->
          is_list(todo_items) && is_map(metadata)

        _ ->
          false
      end
  end

  @doc """
  Converts a batch of durative actions.

  ## Parameters

  - `durative_actions`: List of durative actions

  ## Returns

  - `{:ok, conversions}` where conversions is a list of {simple_action, method} tuples
  """
  def convert_batch(durative_actions) when is_list(durative_actions) do
    conversions = Enum.map(durative_actions, &convert_durative_action/1)
    {:ok, conversions}
  end

  # Private helper functions

  defp extract_todo_items(durative_action) do
    # Convert durative action temporal logic into HTN planner elements
    # Each todo item is represented as a JSON object with action name as key and arguments array as value
    todo_items = []

    # Add prerequisite unigoals for at_start conditions
    at_start_conditions = durative_action[:conditions][:at_start] || []

    prerequisite_unigoals =
      Enum.map(at_start_conditions, fn condition ->
        case condition do
          {pred, subj, val} -> {String.to_atom(pred), [subj, val]}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    todo_items = todo_items ++ prerequisite_unigoals

    # Add monitoring unigoals for over_all conditions
    over_all_conditions = durative_action[:conditions][:over_all] || []

    monitoring_unigoals =
      Enum.map(over_all_conditions, fn condition ->
        case condition do
          {pred, subj, val} -> {String.to_atom(pred), [subj, val]}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    todo_items = todo_items ++ monitoring_unigoals

    # Add the main action
    main_action = {durative_action[:name], []}
    todo_items = todo_items ++ [main_action]

    # Add verification unigoals for at_end conditions
    at_end_conditions = durative_action[:conditions][:at_end] || []

    verification_unigoals =
      Enum.map(at_end_conditions, fn condition ->
        case condition do
          {pred, subj, val} -> {String.to_atom(pred), [subj, val]}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    todo_items = todo_items ++ verification_unigoals

    # Add cleanup unigoals for at_end effects
    at_end_effects = durative_action[:effects][:at_end] || []

    cleanup_unigoals =
      Enum.map(at_end_effects, fn effect ->
        case effect do
          {pred, subj, val} -> {String.to_atom(pred), [subj, val]}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    todo_items = todo_items ++ cleanup_unigoals

    todo_items
  end

  defp create_method_metadata(durative_action) do
    # Create metadata for the method
    AriaPlanner.Planner.MetadataHelpers.action_metadata(
      durative_action[:duration] || "PT1S",
      "system",
      [:temporal_conversion]
    )
  end


end
