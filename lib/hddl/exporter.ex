# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Exporter do
  @moduledoc """
  Exports aria_planner structs to HDDL format.

  Converts aria_planner structures to HDDL syntax:
  - `AriaCore.PlanningDomain` → HDDL domain definition
  - `AriaCore.Plan` → HDDL problem definition
  - `AriaPlanner.Planner.PlannerMetadata` → `:aria-temporal-metadata` blocks
  - Other structures → HDDL syntax
  """

  alias AriaCore.Plan
  alias AriaCore.PlanningDomain
  alias AriaPlanner.Planner.EntityRequirement
  alias AriaPlanner.Planner.PlannerMetadata

  @doc """
  Exports a PlanningDomain to HDDL domain string.
  """
  @spec export_domain(PlanningDomain.t()) :: String.t()
  def export_domain(%PlanningDomain{} = domain) do
    domain_name = String.to_atom(domain.name || "domain")

    elements =
      [
        export_requirements(domain),
        export_predicates(domain),
        export_entities(domain),
        export_actions(domain),
        export_commands(domain),
        export_methods(domain),
        export_multigoals(domain),
        export_aria_domain_metadata(domain),
        export_aria_predicate_schemas(domain)
      ]
      |> Enum.reject(&is_nil/1)

    format_domain(domain_name, elements)
  end

  @doc """
  Exports a Plan to HDDL problem string.
  """
  @spec export_problem(Plan.t()) :: String.t()
  def export_problem(%Plan{} = plan) do
    problem_name = String.to_atom(plan.name || "problem")

    elements =
      [
        export_domain_reference(plan),
        export_aria_plan(plan),
        export_aria_initial_state(plan),
        export_aria_blacklist(plan)
      ]
      |> Enum.reject(&is_nil/1)

    format_problem(problem_name, elements)
  end

  @doc """
  Exports temporal metadata to HDDL `:aria-temporal-metadata` block.
  """
  @spec export_temporal_metadata(PlannerMetadata.t() | nil) :: String.t()
  def export_temporal_metadata(nil), do: ""

  def export_temporal_metadata(%PlannerMetadata{} = metadata) do
    parts =
      [
        ":duration \"#{metadata.duration}\"",
        if(metadata.start_time, do: ":start-time \"#{metadata.start_time}\"", else: nil),
        if(metadata.end_time, do: ":end-time \"#{metadata.end_time}\"", else: nil),
        export_requires_entities(metadata.requires_entities)
      ]
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(parts) do
      ""
    else
      "(:aria-temporal-metadata\n" <>
        Enum.map_join(parts, "\n", fn part -> "    " <> part end) <> "\n  )"
    end
  end

  # Private helper functions

  defp export_requirements(%PlanningDomain{} = _domain) do
    # Requirements are typically standard HDDL - return basic set
    "(:requirements :strips :typing :temporal :hierarchical)"
  end

  defp export_predicates(%PlanningDomain{} = _domain) do
    # Extract predicates from domain - for now return empty
    # Predicates would need to be extracted from domain structure
    nil
  end

  defp export_entities(%PlanningDomain{} = domain) do
    if Enum.empty?(domain.entities) do
      nil
    else
      entity_strings =
        Enum.map(domain.entities, fn entity ->
          export_entity(entity)
        end)

      "(:entities\n" <>
        Enum.map_join(entity_strings, "\n", fn e -> "    " <> e end) <> "\n  )"
    end
  end

  defp export_entity(entity) when is_map(entity) do
    type = Map.get(entity, :type, "entity")
    capabilities = Map.get(entity, :capabilities, [])
    metadata = normalize_metadata_for_export(Map.get(entity, :metadata, %{}))

    cap_string =
      if Enum.empty?(capabilities) do
        ""
      else
        " :capabilities (" <> Enum.map_join(capabilities, " ", &Atom.to_string/1) <> ")"
      end

    meta_string =
      if map_size(metadata) > 0 do
        " :metadata (" <> format_metadata(metadata) <> ")"
      else
        ""
      end

    "(:entity #{type}#{cap_string}#{meta_string})"
  end

  # Normalize metadata from keyword list to map format
  defp normalize_metadata_for_export(metadata) when is_map(metadata), do: metadata

  defp normalize_metadata_for_export(metadata) when is_list(metadata) do
    # Convert keyword list or flat list to map
    # Handle both formats: [{:key, value}, ...] and [:key, value, ...]
    case metadata do
      # Proper keyword list: [{:key, value}, ...]
      [{key, _value} | _] when is_atom(key) ->
        Enum.reduce(metadata, %{}, fn
          {k, v} when is_atom(k) -> Map.put(%{}, k, v)
          _ -> %{}
        end)

      # Flat list: [:key, value, ...]
      [key | _rest] when is_atom(key) ->
        normalize_flat_list_to_map(metadata, %{})

      _ ->
        %{}
    end
  end

  defp normalize_metadata_for_export(_), do: %{}

  # Convert flat list [:key1, value1, :key2, value2, ...] to map
  defp normalize_flat_list_to_map([], acc), do: acc

  defp normalize_flat_list_to_map([key, value | rest], acc) when is_atom(key) do
    normalize_flat_list_to_map(rest, Map.put(acc, key, value))
  end

  defp normalize_flat_list_to_map([_ | rest], acc), do: normalize_flat_list_to_map(rest, acc)

  defp format_metadata(metadata) when is_map(metadata) do
    Enum.map_join(metadata, " ", fn
      {k, v} when is_atom(k) -> ":#{k} #{format_value(v)}"
      {k, v} -> ":#{k} #{format_value(v)}"
    end)
  end

  defp format_value(v) when is_binary(v), do: "\"#{v}\""
  defp format_value(v) when is_atom(v), do: ":#{v}"
  defp format_value(v) when is_integer(v), do: Integer.to_string(v)
  defp format_value(v) when is_boolean(v), do: if(v, do: "true", else: "false")

  defp format_value(v) when is_list(v) do
    # Format lists as HDDL S-expressions, not Elixir syntax
    "(" <> Enum.map_join(v, " ", &format_value/1) <> ")"
  end

  defp format_value(v) when is_map(v) do
    # Format maps as HDDL keyword list syntax
    "(" <> Enum.map_join(v, " ", fn {k, v} -> ":#{k} #{format_value(v)}" end) <> ")"
  end

  defp format_value(v) when is_tuple(v) do
    # Format tuples as HDDL S-expressions
    "(" <> Enum.map_join(Tuple.to_list(v), " ", &format_value/1) <> ")"
  end

  # For any other type, convert to string representation (avoid inspect which uses Elixir syntax)
  defp format_value(v) when is_float(v), do: Float.to_string(v)
  defp format_value(v) when is_nil(v), do: "nil"
  defp format_value(v), do: to_string(v)

  defp export_actions(%PlanningDomain{} = domain) do
    if Enum.empty?(domain.actions) do
      nil
    else
      action_strings =
        Enum.map(domain.actions, fn action ->
          export_action(action)
        end)

      Enum.map_join(action_strings, "\n\n", fn a -> "  " <> a end)
    end
  end

  defp export_action(action) when is_map(action) do
    name = Map.get(action, :name, "action")
    parameters = Map.get(action, :parameters, [])
    precondition = Map.get(action, :precondition)
    effect = Map.get(action, :effect)
    temporal_metadata = Map.get(action, :temporal_metadata)

    parts =
      [
        if(Enum.empty?(parameters), do: nil, else: ":parameters (" <> format_parameters(parameters) <> ")"),
        if(precondition, do: ":precondition " <> format_sexp(precondition), else: nil),
        if(effect, do: ":effect " <> format_sexp(effect), else: nil),
        if(temporal_metadata, do: export_temporal_metadata_from_map(temporal_metadata), else: nil)
      ]
      |> Enum.reject(&is_nil/1)

    "(:action #{name}\n" <>
      Enum.map_join(parts, "\n", fn p -> "    " <> p end) <> "\n  )"
  end

  defp export_commands(%PlanningDomain{} = domain) do
    if Enum.empty?(domain.commands) do
      nil
    else
      command_strings =
        Enum.map(domain.commands, fn command ->
          export_command(command)
        end)

      Enum.map_join(command_strings, "\n\n", fn c -> "  " <> c end)
    end
  end

  defp export_command(command) when is_map(command) do
    name = Map.get(command, :name, "command")
    parameters = Map.get(command, :parameters, [])
    precondition = Map.get(command, :precondition)
    effect = Map.get(command, :effect)
    temporal_metadata = Map.get(command, :temporal_metadata)
    command_metadata = Map.get(command, :command_metadata, %{})

    parts =
      [
        if(Enum.empty?(parameters), do: nil, else: ":parameters (" <> format_parameters(parameters) <> ")"),
        if(precondition, do: ":precondition " <> format_sexp(precondition), else: nil),
        if(effect, do: ":effect " <> format_sexp(effect), else: nil),
        if(temporal_metadata, do: export_temporal_metadata_from_map(temporal_metadata), else: nil),
        if(map_size(command_metadata) > 0,
          do:
            "(:aria-command-metadata\n" <>
              format_metadata_block(command_metadata) <> "\n    )",
          else: nil
        )
      ]
      |> Enum.reject(&is_nil/1)

    "(:command #{name}\n" <>
      Enum.map_join(parts, "\n", fn p -> "    " <> p end) <> "\n  )"
  end

  defp export_methods(%PlanningDomain{} = _domain) do
    # Methods are registered separately in aria_planner
    # For now, return nil - methods would need to be extracted from method registry
    nil
  end

  defp export_multigoals(%PlanningDomain{} = domain) do
    if Enum.empty?(domain.multigoals) do
      nil
    else
      multigoal_strings =
        Enum.map(domain.multigoals, fn multigoal ->
          export_multigoal(multigoal)
        end)

      Enum.map_join(multigoal_strings, "\n\n", fn m -> "  " <> m end)
    end
  end

  defp export_multigoal(multigoal) when is_map(multigoal) do
    name = Map.get(multigoal, :name, "multigoal")
    goal_tag = Map.get(multigoal, :goal_tag) || Map.get(multigoal, "goal_tag")
    goals = Map.get(multigoal, :goals) || Map.get(multigoal, "goals", [])

    parts =
      [
        if(goal_tag, do: ":goal-tag #{format_atom(goal_tag)}", else: nil),
        if(Enum.empty?(goals), do: nil, else: ":goals (" <> format_goals(goals) <> ")")
      ]
      |> Enum.reject(&is_nil/1)

    "(:multigoal #{name}\n" <>
      Enum.map_join(parts, "\n", fn p -> "    " <> p end) <> "\n  )"
  end

  defp export_aria_domain_metadata(%PlanningDomain{} = domain) do
    parts =
      [
        if(domain.id, do: ":id \"#{domain.id}\"", else: nil),
        if(domain.name, do: ":name \"#{domain.name}\"", else: nil),
        if(domain.description, do: ":description \"#{domain.description}\"", else: nil),
        if(domain.domain_type, do: ":domain-type #{format_atom(domain.domain_type)}", else: nil),
        if(domain.version, do: ":version #{domain.version}", else: nil),
        if(domain.state, do: ":state #{format_atom(domain.state)}", else: nil),
        if(map_size(domain.metadata) > 0,
          do: ":metadata (" <> format_metadata(domain.metadata) <> ")",
          else: nil
        )
      ]
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(parts) do
      nil
    else
      "(:aria-domain-metadata\n" <>
        Enum.map_join(parts, "\n", fn p -> "    " <> p end) <> "\n  )"
    end
  end

  defp export_aria_predicate_schemas(%PlanningDomain{} = _domain) do
    # Predicate schemas would need to be extracted from domain
    nil
  end

  defp export_domain_reference(%Plan{} = plan) do
    domain_type = plan.domain_type || "custom"
    "(:domain #{format_atom(domain_type)})"
  end

  defp export_aria_plan(%Plan{} = plan) do
    parts =
      [
        if(plan.id, do: ":id \"#{plan.id}\"", else: nil),
        if(plan.name, do: ":name \"#{plan.name}\"", else: nil),
        if(plan.persona_id, do: ":persona-id \"#{plan.persona_id}\"", else: nil),
        if(plan.domain_type, do: ":domain-type #{format_atom(plan.domain_type)}", else: nil),
        if(plan.execution_status, do: ":execution-status #{format_atom(plan.execution_status)}", else: nil),
        if(plan.success_probability, do: ":success-probability #{plan.success_probability}", else: nil)
      ]
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(parts) do
      nil
    else
      "(:aria-plan\n" <>
        Enum.map_join(parts, "\n", fn p -> "    " <> p end) <> "\n  )"
    end
  end

  defp export_aria_initial_state(%Plan{} = _plan) do
    # Initial state would need to be extracted from plan
    nil
  end

  defp export_aria_blacklist(%Plan{} = _plan) do
    # Blacklist would need to be extracted from plan
    nil
  end

  defp export_requires_entities(entities) when is_list(entities) do
    if Enum.empty?(entities) do
      nil
    else
      entity_strings =
        Enum.map(entities, fn
          %EntityRequirement{} = req ->
            export_entity_requirement(req)

          req when is_map(req) ->
            export_entity_requirement_from_map(req)
        end)

      ":requires-entities (\n" <>
        Enum.map_join(entity_strings, "\n", fn e -> "      " <> e end) <> "\n    )"
    end
  end

  defp export_requires_entities(_), do: nil

  defp export_entity_requirement(%EntityRequirement{} = req) do
    caps_string =
      if Enum.empty?(req.capabilities) do
        ""
      else
        " :capabilities (" <> Enum.map_join(req.capabilities, " ", &format_atom/1) <> ")"
      end

    "(:entity #{req.type}#{caps_string})"
  end

  defp export_entity_requirement_from_map(req) when is_map(req) do
    type = Map.get(req, :type) || Map.get(req, "type", "entity")
    capabilities = Map.get(req, :capabilities) || Map.get(req, "capabilities", [])

    caps_string =
      if Enum.empty?(capabilities) do
        ""
      else
        " :capabilities (" <> Enum.map_join(capabilities, " ", &format_atom/1) <> ")"
      end

    "(:entity #{type}#{caps_string})"
  end

  defp export_temporal_metadata_from_map(metadata) when is_map(metadata) do
    duration = Map.get(metadata, :duration) || Map.get(metadata, "duration", "PT0S")
    start_time = Map.get(metadata, :start_time) || Map.get(metadata, "start_time")
    end_time = Map.get(metadata, :end_time) || Map.get(metadata, "end_time")
    requires_entities = Map.get(metadata, :requires_entities) || Map.get(metadata, "requires_entities", [])

    parts =
      [
        ":duration \"#{duration}\"",
        if(start_time, do: ":start-time \"#{start_time}\"", else: nil),
        if(end_time, do: ":end-time \"#{end_time}\"", else: nil),
        export_requires_entities(requires_entities)
      ]
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(parts) do
      ""
    else
      "(:aria-temporal-metadata\n" <>
        Enum.map_join(parts, "\n", fn part -> "      " <> part end) <> "\n    )"
    end
  end

  defp format_parameters(params) when is_list(params) do
    Enum.map_join(params, " ", fn
      "?" <> _ = var -> var
      var when is_binary(var) -> "?#{var}"
      _ -> ""
    end)
  end

  defp format_parameters(_), do: ""

  defp format_goals(goals) when is_list(goals) do
    Enum.map_join(goals, " ", fn
      goal when is_list(goal) -> "(" <> Enum.map_join(goal, " ", &format_value/1) <> ")"
      goal -> format_value(goal)
    end)
  end

  defp format_goals(_), do: ""

  defp format_sexp(sexp) when is_list(sexp) do
    "(" <> Enum.map_join(sexp, " ", &format_value/1) <> ")"
  end

  defp format_sexp(sexp), do: format_value(sexp)

  defp format_atom(atom) when is_atom(atom), do: ":#{atom}"
  defp format_atom(str) when is_binary(str), do: ":#{str}"

  defp format_metadata_block(metadata) when is_map(metadata) do
    Enum.map_join(metadata, "\n", fn
      {k, v} when is_atom(k) -> "      :#{k} #{format_value(v)}"
      {k, v} -> "      :#{k} #{format_value(v)}"
    end)
  end

  defp format_domain(name, elements) do
    "(define (domain #{name})\n" <>
      Enum.map_join(elements, "\n\n", fn e -> "  " <> e end) <> "\n)"
  end

  defp format_problem(name, elements) do
    "(define (problem #{name})\n" <>
      Enum.map_join(elements, "\n\n", fn e -> "  " <> e end) <> "\n)"
  end
end
