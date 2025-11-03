# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.PlanningDomains do
  @moduledoc """
  Generic planning domain utilities for AI planning systems.

  This module provides reusable components for building domain states,
  executing plans, and extracting results from planning operations.

  Designed to be timeless and domain-independent, usable across
  various applications (battle simulations, logistics, manufacturing, etc.).

  ## Key Features

  - **State Construction**: Build planning states from entity data
  - **Action Templates**: Reusable action patterns for common operations
  - **Method Templates**: HTN planning method decomposition patterns
  - **Distance Calculations**: Spatial reasoning utilities
  - **Entity Management**: Standardized entity property handling

  ## Usage Patterns

  ### State Construction
  ```elixir
  entities = [%{id: 1, name: "Worker1", position: {10, 20, 0}, health: 100}]
  state = PlanningDomains.create_state_from_entities(entities)
  ```

  ### Action Templates
  ```elixir
  move_action = PlanningDomains.create_action_template(:move, :entities)
  result = move_action.(state, [entity: :worker1, position: {15, 25, 0}])
  ```

  ### Method Templates
  ```elixir
  sequence_method = PlanningDomains.create_method_template(:sequence, decomposition_fn)
  result = sequence_method.(state, args)
  ```
  """

  @doc """
  Creates a generic domain state from entity data.

  Converts a list of entities with positions, health, skills, etc. into
  the planning state format expected by TensorWorkflowPlanner.

  ## Parameters:
  - `entities`: List of entity maps with standard properties (id, name, position, etc.)
  - `entity_key`: Key path to access entity data (default: :entities)
  - `metadata`: Additional state information (phases, environments, etc.)

  ## Returns:
  Planning state map ready for planning operations

  ## Example:
  ```elixir
  entities = [%{id: 1, name: "Worker1", position: {10, 20, 0}, health: 100}]
  state = PlanningDomains.create_state_from_entities(entities)
  ```
  """
  @spec create_state_from_entities([map()], atom(), map()) :: map()
  def create_state_from_entities(entities, entity_key \\ :entities, metadata \\ %{}) do
    entity_map =
      entities
      |> Enum.reduce(%{}, fn entity, acc ->
        entity_data = %{
          id: Map.get(entity, :id, Map.get(entity, :entity_id, nil)),
          name: Map.get(entity, :name, Map.get(entity, :entity_name, "")),
          position: Map.get(entity, :position, {0.0, 0.0, 0.0}),
          health: Map.get(entity, :health, 100),
          skills: Map.get(entity, :skills, %{}),
          capabilities: Map.get(entity, :capabilities, []),
          status: Map.get(entity, :status, :active)
        }

        Map.put(acc, String.to_atom(entity_data.name), entity_data)
      end)

    Map.merge(metadata, %{entity_key => entity_map})
  end

  @doc """
  Creates a generic action template for entity manipulation.

  Generates reusable action functions for moving, modifying, or interacting
  with entities in planning domains.

  ## Parameters:
  - `action_type`: :move, :modify, :interact
  - `entity_key`: State path key for entities (default: :entities)
  - `calculator`: Optional custom calculation function

  ## Returns:
  Action function ready to be included in domain
  """
  @spec create_action_template(atom(), atom(), (map(), keyword() -> any())) :: function()
  def create_action_template(action_type, entity_key \\ :entities, calculator \\ nil) do
    case action_type do
      :move ->
        fn state, [entity: entity_id, position: new_pos] = _args ->
          entities = Map.get(state, entity_key, %{})
          entity = Map.get(entities, entity_id, %{})
          current_pos = Map.get(entity, :position, {0.0, 0.0, 0.0})
          distance = calculate_distance(current_pos, new_pos)

          updated_state = put_in(state, [entity_key, entity_id, :position], new_pos)

          metadata = %{
            action: :move,
            entity: entity_id,
            from: current_pos,
            to: new_pos,
            distance: Float.round(distance, 2)
          }

          {:ok, updated_state, metadata}
        end

      :modify ->
        fn state, [entity: entity_id, attribute: attr, value: val] = args ->
          entities = Map.get(state, entity_key, %{})
          entity = Map.get(entities, entity_id, %{})
          current_value = Map.get(entity, attr, 0)
          change = if is_number(val), do: val, else: val
          new_value = if is_function(calculator), do: calculator.(current_value, args), else: change

          updated_state = put_in(state, [entity_key, entity_id, attr], new_value)

          metadata = %{
            action: :modify,
            entity: entity_id,
            attribute: attr,
            from: current_value,
            to: new_value,
            change: change
          }

          {:ok, updated_state, metadata}
        end

      :interact ->
        fn state, [initiator: init_id, target: targ_id] = args ->
          entities = Map.get(state, entity_key, %{})
          initiator = Map.get(entities, init_id, %{})
          target = Map.get(entities, targ_id, %{})
          initiator_pos = Map.get(initiator, :position, {0.0, 0.0, 0.0})
          target_pos = Map.get(target, :position, {0.0, 0.0, 0.0})
          distance = calculate_distance(initiator_pos, target_pos)

          # Generic interaction calculation
          skills = Map.get(initiator, :skills, %{})
          strength = Map.get(skills, :strength, 1)
          interaction_result = if is_function(calculator), do: calculator.(strength, args, distance), else: strength

          # Optional effect application
          updated_state =
            case args[:effect] do
              nil -> state
              effect -> apply_interaction_effect(state, entity_key, targ_id, effect, interaction_result)
            end

          metadata = %{
            action: :interact,
            initiator: init_id,
            target: targ_id,
            distance: Float.round(distance, 1),
            strength: strength,
            result: interaction_result
          }

          {:ok, updated_state, metadata}
        end

      _ ->
        raise "Unknown action type: #{action_type}. Use :move, :modify, or :interact."
    end
  end

  @doc """
  Creates a generic method template for HTN planning.

  Generates reusable method functions that decompose complex tasks
  into primitive actions.

  ## Parameters:
  - `method_type`: :sequence, :parallel, :conditional
  - `decomposition`: Function that returns list of subtasks
  - `conditions`: Optional precondition function

  ## Returns:
  Method function ready to be included in domain
  """
  @spec create_method_template(atom(), (map(), keyword() -> [tuple()]), (map(), keyword() -> boolean())) :: function()
  def create_method_template(method_type, decomposition, conditions \\ nil) do
    fn state, args ->
      # Check preconditions if provided
      if conditions && !conditions.(state, args) do
        raise "Method preconditions not met for #{method_type}"
      end

      subtasks = decomposition.(state, args)

      case method_type do
        :sequence ->
          # Execute subtasks in sequence
          subtasks

        :parallel ->
          # Mark as parallel execution (implementation dependent)
          subtasks
          |> Enum.map(fn {action, params} ->
            {action, Keyword.put(params, :parallel, true)}
          end)

        :conditional ->
          # Select appropriate subtasks based on conditions
          subtasks |> select_conditional_subtasks(state, args)

        _ ->
          raise "Unknown method type: #{method_type}. Use :sequence, :parallel, or :conditional."
      end
    end
  end

  # Private helper functions

  @doc false
  @spec calculate_distance({number(), number(), number()}, {number(), number(), number()}) :: float()
  def calculate_distance({x1, y1, z1}, {x2, y2, z2}) do
    dx = x2 - x1
    dy = y2 - y1
    dz = z2 - z1
    :math.sqrt(dx * dx + dy * dy + dz * dz)
  end

  @doc false
  defp apply_interaction_effect(state, entity_key, target_id, effect, result) do
    case effect do
      :damage -> update_in(state, [entity_key, target_id, :health], &max(&1 - result, 0))
      :heal -> update_in(state, [entity_key, target_id, :health], &min(&1 + result, 100.0))
      :buff -> put_in(state, [entity_key, target_id, :buff], result)
      :status_change -> put_in(state, [entity_key, target_id, :status], result)
      # No effect applied
      _ -> state
    end
  end

  @doc false
  defp select_conditional_subtasks(subtasks, state, _args) do
    # Select subtasks based on state conditions
    # This is a simplified implementation - extend as needed
    entities = Map.get(state, :entities, %{})
    mika = Map.get(entities, :mika, %{})
    health = Map.get(mika, :health, 100.0)

    cond do
      # Full plan
      health > 70 -> subtasks
      # Partial plan
      health > 30 -> Enum.take(subtasks, div(length(subtasks), 2))
      # Minimal plan
      true -> Enum.take(subtasks, 1)
    end
  end
end
