# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Importer do
  @moduledoc """
  Imports HDDL AST into aria_planner structs.

  Converts parsed HDDL domain and problem definitions into:
  - `AriaCore.PlanningDomain` structs
  - `AriaCore.Plan` structs
  - `AriaPlanner.Planner.PlannerMetadata` structs
  - `AriaPlanner.Planner.EntityRequirement` structs
  - `AriaCore.PlanningDomain.PredicateSchema` structs
  - Other aria_planner structures
  """

  alias AriaCore.Plan
  alias AriaCore.Planner.MultiGoal
  alias AriaCore.PlanningDomain
  alias AriaPlanner.Planner.EntityRequirement
  alias AriaPlanner.Planner.PlannerMetadata

  @doc """
  Imports an HDDL domain AST into a PlanningDomain struct.

  ## Examples

      iex> ast = {:domain, :test, [{:requirements, [:strips]}]}
      iex> AriaPlanner.HDDL.Importer.import_domain(ast)
      {:ok, %AriaCore.PlanningDomain{...}}

  """
  @spec import_domain(term()) :: {:ok, PlanningDomain.t()} | {:error, String.t()}
  def import_domain({:domain, name, elements}) do
    # Extract name from aria-domain-metadata if present, otherwise use domain name
    domain_name = extract_domain_name(elements) || Atom.to_string(name)

    attrs = %{
      id: extract_domain_id(elements) || UUIDv7.generate(),
      domain_type: extract_domain_type(elements),
      name: domain_name,
      description: extract_description(elements),
      entities: extract_entities(elements),
      tasks: extract_tasks(elements),
      actions: extract_actions(elements),
      commands: extract_commands(elements),
      multigoals: extract_multigoals(elements),
      state: extract_state(elements),
      version: extract_version(elements),
      metadata: extract_domain_metadata(elements)
    }

    PlanningDomain.create(attrs)
  end

  def import_domain(_), do: {:error, "Invalid domain AST"}

  @doc """
  Imports an HDDL problem AST into a Plan struct.
  """
  @spec import_problem(term()) :: {:ok, Plan.t()} | {:error, String.t()}
  def import_problem({:problem, name, elements}) do
    plan_attrs = extract_aria_plan(elements)

    attrs = %{
      id: get_plan_attr(plan_attrs, :id, UUIDv7.generate()),
      name: get_plan_attr(plan_attrs, :name, Atom.to_string(name)),
      persona_id: get_plan_attr(plan_attrs, :persona_id, UUIDv7.generate()),
      domain_type: get_plan_domain_type(plan_attrs),
      objectives: get_plan_attr(plan_attrs, :objectives, []),
      constraints: get_plan_attr(plan_attrs, :constraints, %{}),
      temporal_constraints: get_plan_attr(plan_attrs, :temporal_constraints, %{}),
      entity_capabilities: get_plan_attr(plan_attrs, :entity_capabilities, %{}),
      solution_graph_data: %{},
      solution_plan: "",
      execution_status: get_plan_attr(plan_attrs, :execution_status, "planned"),
      success_probability: get_plan_attr(plan_attrs, :success_probability, 1.0),
      risk_assessment: get_plan_attr(plan_attrs, :risk_assessment, %{}),
      performance_metrics: get_plan_attr(plan_attrs, :performance_metrics, %{})
    }

    Plan.create(attrs)
  end

  def import_problem(_), do: {:error, "Invalid problem AST"}

  defp get_plan_attr(plan_attrs, key, default) do
    Map.get(plan_attrs, to_string(key)) || Map.get(plan_attrs, key, default)
  end

  defp get_plan_domain_type(plan_attrs) do
    domain_type =
      Map.get(plan_attrs, "domain_type") ||
        Map.get(plan_attrs, :domain_type) ||
        "blocks_world"

    normalize_domain_type(domain_type)
  end

  defp normalize_domain_type(type) when is_atom(type), do: Atom.to_string(type)
  defp normalize_domain_type(type) when is_binary(type), do: type
  defp normalize_domain_type(_), do: "custom"

  @doc """
  Converts HDDL action AST to action map.
  """
  @spec import_action(term()) :: map()
  def import_action({:action, name, elements}) do
    %{
      id: UUIDv7.generate(),
      name: Atom.to_string(name),
      parameters: extract_parameters(elements),
      precondition: extract_precondition(elements),
      effect: extract_effect(elements),
      temporal_metadata: extract_temporal_metadata(elements)
    }
  end

  def import_action(_), do: %{}

  @doc """
  Converts HDDL command AST to command map.
  """
  @spec import_command(term()) :: map()
  def import_command({:command, name, elements}) do
    %{
      id: UUIDv7.generate(),
      name: Atom.to_string(name),
      parameters: extract_parameters(elements),
      precondition: extract_precondition(elements),
      effect: extract_effect(elements),
      temporal_metadata: extract_temporal_metadata(elements),
      command_metadata: extract_command_metadata(elements)
    }
  end

  def import_command(_), do: %{}

  @doc """
  Converts HDDL method AST to method registration map.
  """
  @spec import_method(term()) :: map()
  def import_method({:method, name, elements}) do
    %{
      id: UUIDv7.generate(),
      name: Atom.to_string(name),
      parameters: extract_parameters(elements),
      task: extract_task(elements),
      subtasks: extract_subtasks(elements),
      temporal_metadata: extract_temporal_metadata(elements)
    }
  end

  def import_method({:durative_method, name, elements}) do
    %{
      id: UUIDv7.generate(),
      name: Atom.to_string(name),
      parameters: extract_parameters(elements),
      task: extract_task(elements),
      duration: extract_duration(elements),
      subtasks: extract_subtasks(elements),
      temporal_metadata: extract_temporal_metadata(elements)
    }
  end

  def import_method({:goal_method, name, elements}) do
    %{
      id: UUIDv7.generate(),
      name: Atom.to_string(name),
      parameters: extract_parameters(elements),
      goal: extract_goal(elements),
      subtasks: extract_subtasks(elements),
      temporal_metadata: extract_temporal_metadata(elements)
    }
  end

  def import_method(_), do: %{}

  @doc """
  Converts HDDL multigoal AST to MultiGoal struct.
  """
  @spec import_multigoal(term()) :: MultiGoal.t()
  def import_multigoal({:multigoal, name, elements}) do
    goal_tag = extract_goal_tag(elements) || name
    goals = extract_goals(elements)

    MultiGoal.new(goal_tag, goals)
  end

  def import_multigoal(_), do: MultiGoal.new(:unknown, [])

  @doc """
  Converts HDDL temporal metadata to PlannerMetadata struct.
  """
  @spec import_temporal_metadata(term()) :: {:ok, PlannerMetadata.t()} | {:error, atom()}
  def import_temporal_metadata({:aria_temporal_metadata, elements}) when is_list(elements) do
    # elements is a keyword list from the parser
    duration = extract_duration_iso8601_from_keyword_list(elements)
    start_time = extract_start_time_iso8601_from_keyword_list(elements)
    end_time = extract_end_time_iso8601_from_keyword_list(elements)
    requires_entities = extract_requires_entities_from_keyword_list(elements)

    PlannerMetadata.new(duration, requires_entities, start_time: start_time, end_time: end_time)
  end

  def import_temporal_metadata({:aria_temporal_metadata, elements}) when is_map(elements) do
    # Legacy format
    duration = extract_duration_iso8601(elements)
    start_time = extract_start_time_iso8601(elements)
    end_time = extract_end_time_iso8601(elements)
    requires_entities = extract_requires_entities(elements)

    PlannerMetadata.new(duration, requires_entities, start_time: start_time, end_time: end_time)
  end

  def import_temporal_metadata(_), do: {:error, :no_temporal_metadata}

  @doc """
  Converts HDDL entity requirements to EntityRequirement structs.
  """
  @spec import_entity_requirements(term()) :: [EntityRequirement.t()]
  def import_entity_requirements({:requires_entities, entity_list}) when is_list(entity_list) do
    Enum.map(entity_list, fn entity_ast ->
      import_entity_requirement(entity_ast)
    end)
    |> Enum.filter(fn
      {:ok, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {:ok, req} -> req end)
  end

  def import_entity_requirements(_), do: []

  defp import_entity_requirement({:entity_requirement, type, elements}) do
    capabilities = extract_entity_capabilities_from_elements(elements)
    EntityRequirement.new(Atom.to_string(type), capabilities)
  end

  defp import_entity_requirement(_), do: {:error, :invalid_entity_requirement}

  defp import_entity_requirement_from_map(entity_map) when is_map(entity_map) do
    # New format: %{type: :entity, entity_type: :agent, capabilities: [:navigation, :transport]}
    entity_type = entity_map |> Map.get(:entity_type) |> normalize_entity_type()
    capabilities = entity_map |> Map.get(:capabilities, []) |> normalize_capabilities()
    {:ok, EntityRequirement.new(entity_type, capabilities)}
  end

  defp import_entity_requirement_from_map(_), do: {:error, :invalid_entity_requirement}

  # Helper functions to extract values from AST elements

  defp extract_domain_type(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_list(metadata) ->
        normalize_domain_type_value(Keyword.get(metadata, :domain_type))

      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        normalize_domain_type_value(Map.get(metadata, :domain_type))

      _ ->
        "custom"
    end
  end

  defp normalize_domain_type_value(nil), do: "custom"
  defp normalize_domain_type_value(type) when is_atom(type), do: Atom.to_string(type)
  defp normalize_domain_type_value(type) when is_binary(type), do: type
  defp normalize_domain_type_value(_), do: "custom"

  defp extract_domain_name(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_list(metadata) ->
        normalize_name_value(Keyword.get(metadata, :name))

      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        normalize_name_value(Map.get(metadata, :name))

      _ ->
        nil
    end
  end

  defp normalize_name_value(nil), do: nil
  defp normalize_name_value(name) when is_binary(name), do: name
  defp normalize_name_value(name) when is_atom(name), do: Atom.to_string(name)
  defp normalize_name_value(_), do: nil

  defp extract_domain_id(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_list(metadata) ->
        Keyword.get(metadata, :id)

      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        Map.get(metadata, :id)

      _ ->
        nil
    end
  end

  defp extract_description(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_list(metadata) ->
        normalize_description_value(Keyword.get(metadata, :description))

      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        normalize_description_value(Map.get(metadata, :description))

      _ ->
        ""
    end
  end

  defp normalize_description_value(nil), do: ""
  defp normalize_description_value(desc) when is_binary(desc), do: desc
  defp normalize_description_value(_), do: ""

  defp extract_entities(elements) do
    case find_element(elements, :entities) do
      {:entities, entity_list} when is_list(entity_list) ->
        Enum.map(entity_list, &import_entity/1)

      _ ->
        []
    end
  end

  defp import_entity(entity_map) when is_map(entity_map) do
    # New format from RecursiveDescent parser:
    # %{type: :entity, name: ..., entity_type: ..., capabilities: ..., metadata: ...}
    %{
      id: UUIDv7.generate(),
      type: entity_map |> Map.get(:entity_type) |> normalize_entity_type(),
      capabilities: entity_map |> Map.get(:capabilities, []) |> normalize_capabilities(),
      metadata: entity_map |> Map.get(:metadata, %{})
    }
  end

  defp import_entity({:entity_declaration, type, entity_elements}) do
    # Legacy format
    %{
      id: UUIDv7.generate(),
      type: Atom.to_string(type),
      capabilities: extract_entity_capabilities_from_elements(entity_elements),
      metadata: extract_entity_metadata_from_elements(entity_elements)
    }
  end

  defp import_entity(_), do: %{}

  defp normalize_entity_type(nil), do: "agent"
  defp normalize_entity_type(type) when is_atom(type), do: Atom.to_string(type)
  defp normalize_entity_type(type) when is_binary(type), do: type
  defp normalize_entity_type(_), do: "agent"

  defp normalize_capabilities(caps) when is_list(caps) do
    Enum.map(caps, fn
      cap when is_atom(cap) -> cap
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_capabilities(_), do: []

  defp extract_entity_capabilities_from_elements(elements) do
    case find_element(elements, :capabilities) do
      {:capabilities, caps} when is_list(caps) ->
        Enum.map(caps, fn
          cap when is_atom(cap) -> cap
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  defp extract_entity_metadata_from_elements(elements) do
    case find_element(elements, :metadata) do
      {:metadata, metadata} when is_map(metadata) -> metadata
      {:metadata, metadata} when is_list(metadata) -> List.to_tuple(metadata) |> normalize_metadata()
      _ -> %{}
    end
  end

  defp normalize_metadata(metadata) when is_map(metadata), do: metadata

  defp normalize_metadata(metadata) when is_tuple(metadata) do
    metadata
    |> Tuple.to_list()
    |> Enum.reduce(%{}, fn
      {key, value} when is_atom(key) -> Map.put(%{}, key, value)
      _ -> %{}
    end)
  end

  defp normalize_metadata(_), do: %{}

  defp extract_tasks(_elements) do
    # Tasks are typically defined implicitly through methods
    # For now, return empty list - tasks will be extracted from methods
    []
  end

  defp extract_actions(elements) do
    elements
    |> Enum.filter(fn
      {:action, _, _} -> true
      {:durative_action, _, _} -> true
      _ -> false
    end)
    |> Enum.map(&import_action/1)
  end

  defp extract_commands(elements) do
    elements
    |> Enum.filter(fn
      {:command, _, _} -> true
      _ -> false
    end)
    |> Enum.map(&import_command/1)
  end

  defp extract_multigoals(elements) do
    elements
    |> Enum.filter(fn
      {:multigoal, _, _} -> true
      _ -> false
    end)
    |> Enum.map(&import_multigoal/1)
    |> Enum.map(fn %MultiGoal{} = mg -> Map.from_struct(mg) end)
  end

  defp extract_state(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_list(metadata) ->
        normalize_state(Keyword.get(metadata, :state))

      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        normalize_state(Map.get(metadata, :state))

      _ ->
        :active
    end
  end

  defp normalize_state(:active), do: :active
  defp normalize_state(:archived), do: :archived
  defp normalize_state(:deprecated), do: :deprecated
  defp normalize_state("active"), do: :active
  defp normalize_state("archived"), do: :archived
  defp normalize_state("deprecated"), do: :deprecated
  defp normalize_state(_), do: :active

  defp extract_version(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_list(metadata) ->
        normalize_version_value(Keyword.get(metadata, :version))

      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        normalize_version_value(Map.get(metadata, :version))

      _ ->
        1
    end
  end

  defp normalize_version_value(nil), do: 1
  defp normalize_version_value(v) when is_integer(v), do: v
  defp normalize_version_value(_), do: 1

  defp extract_domain_metadata(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_list(metadata) ->
        metadata
        |> Keyword.drop([:domain_type, :description, :state, :version])
        |> Enum.map(fn
          {k, v} when is_atom(k) -> {Atom.to_string(k), v}
          {k, v} -> {k, v}
        end)
        |> Map.new()

      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        metadata
        |> Map.drop([:domain_type, :description, :state, :version])
        |> Enum.map(fn
          {k, v} when is_atom(k) -> {Atom.to_string(k), v}
          {k, v} -> {k, v}
        end)
        |> Map.new()

      _ ->
        %{}
    end
  end

  defp extract_parameters(elements) do
    case find_element(elements, :parameters) do
      {:parameters, params} when is_list(params) ->
        Enum.map(params, fn
          {:variable, var} -> var
          var when is_binary(var) -> var
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  defp extract_precondition(elements) do
    case find_element(elements, :precondition) do
      {:precondition, prec} -> prec
      _ -> nil
    end
  end

  # Unused function - kept for potential future use
  # defp extract_condition(elements) do
  #   case find_element(elements, :condition) do
  #     {:condition, cond} -> cond
  #     _ -> nil
  #   end
  # end

  defp extract_effect(elements) do
    case find_element(elements, :effect) do
      {:effect, eff} -> eff
      _ -> nil
    end
  end

  defp extract_duration(elements) do
    case find_element(elements, :duration) do
      {:duration, dur} -> dur
      _ -> nil
    end
  end

  defp extract_task(elements) do
    case find_element(elements, :task) do
      {:task, task} -> task
      _ -> nil
    end
  end

  defp extract_goal(elements) do
    case find_element(elements, :goal) do
      {:goal, goal} -> goal
      _ -> nil
    end
  end

  defp extract_goal_tag(elements) do
    case find_element(elements, :goal_tag) do
      {:goal_tag, tag} when is_atom(tag) -> tag
      _ -> nil
    end
  end

  defp extract_goals(elements) do
    case find_element(elements, :goals) do
      {:goals, goals} when is_list(goals) -> goals
      _ -> []
    end
  end

  defp extract_subtasks(elements) do
    case find_element(elements, :subtasks) do
      {:subtasks, subtasks} when is_list(subtasks) -> subtasks
      _ -> []
    end
  end

  defp extract_duration_iso8601(elements) do
    case find_element(elements, :duration) do
      {:duration, dur} when is_binary(dur) -> dur
      _ -> "PT0S"
    end
  end

  defp extract_start_time_iso8601(elements) do
    case find_element(elements, :start_time) do
      {:start_time, time} when is_binary(time) -> time
      _ -> nil
    end
  end

  defp extract_end_time_iso8601(elements) do
    case find_element(elements, :end_time) do
      {:end_time, time} when is_binary(time) -> time
      _ -> nil
    end
  end

  defp extract_requires_entities(elements) do
    case find_element(elements, :requires_entities) do
      {:requires_entities, entities} ->
        import_entity_requirements({:requires_entities, entities})

      _ ->
        []
    end
  end

  # New helper functions for keyword list format
  # Handle both keyword lists and flat lists (from parser)
  defp extract_duration_iso8601_from_keyword_list(elements) when is_list(elements) do
    # Try keyword list first
    case Keyword.get(elements, :duration) do
      dur when is_binary(dur) ->
        dur

      _ ->
        # Try flat list format: [:duration, "PT5M", ...]
        case find_in_flat_list(elements, :duration) do
          dur when is_binary(dur) -> dur
          _ -> "PT0S"
        end
    end
  end

  defp extract_start_time_iso8601_from_keyword_list(elements) when is_list(elements) do
    # Try keyword list first
    case Keyword.get(elements, :start_time) do
      time when is_binary(time) ->
        time

      _ ->
        # Try flat list format
        find_in_flat_list(elements, :start_time)
    end
  end

  defp extract_end_time_iso8601_from_keyword_list(elements) when is_list(elements) do
    # Try keyword list first
    case Keyword.get(elements, :end_time) do
      time when is_binary(time) ->
        time

      _ ->
        # Try flat list format
        find_in_flat_list(elements, :end_time)
    end
  end

  defp extract_requires_entities_from_keyword_list(elements) when is_list(elements) do
    entities = get_entities_from_elements(elements)

    if is_list(entities) do
      Enum.flat_map(entities, &transform_entity_item/1)
    else
      []
    end
  end

  defp get_entities_from_elements(elements) do
    case Keyword.get(elements, :requires_entities) do
      entities_list when is_list(entities_list) ->
        entities_list

      _ ->
        find_in_flat_list(elements, :requires_entities) || []
    end
  end

  defp transform_entity_item(entity_map) when is_map(entity_map) do
    case import_entity_requirement_from_map(entity_map) do
      {:ok, req} -> [req]
      _ -> []
    end
  end

  defp transform_entity_item(entity_list) when is_list(entity_list) do
    case transform_entity_requirement_from_tokens(entity_list) do
      {:ok, req} -> [req]
      _ -> []
    end
  end

  defp transform_entity_item(_), do: []

  # Transform entity requirement from raw token list: [{:keyword, :entity}, {:identifier, :agent}, ...]
  defp transform_entity_requirement_from_tokens([{:keyword, :entity} | rest]) do
    # Extract entity type (should be first identifier after :entity)
    entity_type =
      case rest do
        [{:identifier, type} | _] -> type
        _ -> :agent
      end

    # Extract capabilities from the rest
    capabilities = extract_capabilities_from_tokens(rest)

    case EntityRequirement.new(Atom.to_string(entity_type), capabilities) do
      {:ok, req} -> {:ok, req}
      error -> error
    end
  end

  defp transform_entity_requirement_from_tokens([{:identifier, :entity} | rest]) do
    # Same as above but with identifier instead of keyword
    entity_type =
      case rest do
        [{:identifier, type} | _] -> type
        _ -> :agent
      end

    capabilities = extract_capabilities_from_tokens(rest)

    case EntityRequirement.new(Atom.to_string(entity_type), capabilities) do
      {:ok, req} -> {:ok, req}
      error -> error
    end
  end

  defp transform_entity_requirement_from_tokens(_), do: {:error, :invalid_format}

  # Extract capabilities from token list: [{:identifier, :agent}, {:keyword, :capabilities}, [keyword: :navigation]]
  # Also handles nested token structure: [[{:keyword, :entity}, {:identifier, :agent}, {:keyword, :capabilities}, [keyword: :navigation]]]
  defp extract_capabilities_from_tokens(tokens) do
    # Find :capabilities keyword and get the list after it
    case find_capabilities_list(tokens) do
      caps_list when is_list(caps_list) ->
        Enum.flat_map(caps_list, fn
          {:keyword, cap} ->
            [cap]

          {:identifier, cap} ->
            [cap]

          cap when is_atom(cap) ->
            [cap]

          # Handle nested lists like [keyword: :navigation]
          list when is_list(list) ->
            Enum.flat_map(list, fn
              {:keyword, cap} -> [cap]
              cap when is_atom(cap) -> [cap]
              _ -> []
            end)

          _ ->
            []
        end)

      _ ->
        []
    end
  end

  defp find_capabilities_list([{:keyword, :capabilities}, caps_list | _]) when is_list(caps_list), do: caps_list
  defp find_capabilities_list([{:identifier, :capabilities}, caps_list | _]) when is_list(caps_list), do: caps_list
  defp find_capabilities_list([_ | rest]), do: find_capabilities_list(rest)
  defp find_capabilities_list([]), do: nil

  # Helper to find value after key in flat list format: [key, value, ...]
  defp find_in_flat_list([key, value | _rest], search_key) when key == search_key, do: value
  defp find_in_flat_list([_ | rest], search_key), do: find_in_flat_list(rest, search_key)
  defp find_in_flat_list([], _), do: nil

  defp extract_command_metadata(elements) do
    case find_element(elements, :aria_command_metadata) do
      {:aria_command_metadata, metadata} when is_map(metadata) -> metadata
      _ -> %{}
    end
  end

  defp extract_temporal_metadata(elements) do
    case find_element(elements, :aria_temporal_metadata) do
      {:aria_temporal_metadata, _} = temporal_ast ->
        case import_temporal_metadata(temporal_ast) do
          {:ok, metadata} -> metadata
          _ -> nil
        end

      # Also check for tuple format
      {_, {:aria_temporal_metadata, _} = temporal_ast} ->
        case import_temporal_metadata(temporal_ast) do
          {:ok, metadata} -> metadata
          _ -> nil
        end

      _ ->
        nil
    end
  end

  # Unused function - kept for potential future use
  # defp extract_domain_reference(elements) do
  #   case find_element(elements, :domain) do
  #     {:domain, domain} when is_atom(domain) -> Atom.to_string(domain)
  #     _ -> nil
  #   end
  # end

  defp extract_aria_plan(elements) do
    case find_element(elements, :aria_plan) do
      {:aria_plan, plan} when is_list(plan) ->
        # Keyword list format from parser
        plan
        |> Enum.map(fn
          {k, v} when is_atom(k) -> {Atom.to_string(k), v}
          {k, v} -> {k, v}
        end)
        |> Map.new()

      {:aria_plan, plan} when is_map(plan) ->
        # Legacy map format
        plan
        |> Enum.map(fn
          {k, v} when is_atom(k) -> {Atom.to_string(k), v}
          {k, v} -> {k, v}
        end)
        |> Map.new()

      _ ->
        %{}
    end
  end

  defp find_element(elements, tag) when is_list(elements) do
    Enum.find(elements, fn
      {t, _} when t == tag -> true
      {t, _, _} when t == tag -> true
      _ -> false
    end)
  end

  defp find_element(_, _), do: nil
end
