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
  alias AriaCore.PredicateSchema
  alias AriaPlanner.Planner.EntityRequirement
  alias AriaPlanner.Planner.PlannerMetadata
  alias AriaPlanner.Planner.State

  @doc """
  Imports an HDDL domain AST into a PlanningDomain struct.

  ## Examples

      iex> ast = {:domain, :test, [{:requirements, [:strips]}]}
      iex> AriaPlanner.HDDL.Importer.import_domain(ast)
      {:ok, %AriaCore.PlanningDomain{...}}

  """
  @spec import_domain(term()) :: {:ok, PlanningDomain.t()} | {:error, String.t()}
  def import_domain({:domain, name, elements}) do
    attrs = %{
      id: UUIDv7.generate(),
      domain_type: extract_domain_type(elements),
      name: Atom.to_string(name),
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
    # Extract domain reference
    domain_ref = extract_domain_reference(elements)

    # Extract plan metadata
    plan_attrs = extract_aria_plan(elements)

    attrs = %{
      id: UUIDv7.generate(),
      name: Atom.to_string(name),
      persona_id: Map.get(plan_attrs, :persona_id, UUIDv7.generate()),
      domain_type: Map.get(plan_attrs, :domain_type, "custom"),
      objectives: Map.get(plan_attrs, :objectives, []),
      constraints: Map.get(plan_attrs, :constraints, %{}),
      temporal_constraints: Map.get(plan_attrs, :temporal_constraints, %{}),
      entity_capabilities: Map.get(plan_attrs, :entity_capabilities, %{}),
      solution_graph_data: %{},
      solution_plan: "",
      execution_status: Map.get(plan_attrs, :execution_status, "planned"),
      success_probability: Map.get(plan_attrs, :success_probability, 1.0),
      risk_assessment: Map.get(plan_attrs, :risk_assessment, %{}),
      performance_metrics: Map.get(plan_attrs, :performance_metrics, %{})
    }

    Plan.create(attrs)
  end

  def import_problem(_), do: {:error, "Invalid problem AST"}

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
  def import_temporal_metadata({:aria_temporal_metadata, elements}) do
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

  # Helper functions to extract values from AST elements

  defp extract_domain_type(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        case Map.get(metadata, :domain_type) do
          nil -> "custom"
          type when is_atom(type) -> Atom.to_string(type)
          type when is_binary(type) -> type
          _ -> "custom"
        end

      _ ->
        "custom"
    end
  end

  defp extract_description(elements) do
    case find_element(elements, :aria_domain_metadata) do
      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        case Map.get(metadata, :description) do
          nil -> ""
          desc when is_binary(desc) -> desc
          _ -> ""
        end

      _ ->
        ""
    end
  end

  defp extract_entities(elements) do
    case find_element(elements, :entities) do
      {:entities, entity_list} when is_list(entity_list) ->
        Enum.map(entity_list, &import_entity/1)

      _ ->
        []
    end
  end

  defp import_entity({:entity_declaration, type, entity_elements}) do
    %{
      id: UUIDv7.generate(),
      type: Atom.to_string(type),
      capabilities: extract_entity_capabilities_from_elements(entity_elements),
      metadata: extract_entity_metadata_from_elements(entity_elements)
    }
  end

  defp import_entity(_), do: %{}

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

  defp extract_tasks(elements) do
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
      {:aria_domain_metadata, metadata} when is_map(metadata) ->
        case Map.get(metadata, :version) do
          nil -> 1
          v when is_integer(v) -> v
          _ -> 1
        end

      _ ->
        1
    end
  end

  defp extract_domain_metadata(elements) do
    case find_element(elements, :aria_domain_metadata) do
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

  defp extract_condition(elements) do
    case find_element(elements, :condition) do
      {:condition, cond} -> cond
      _ -> nil
    end
  end

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

  defp extract_command_metadata(elements) do
    case find_element(elements, :aria_command_metadata) do
      {:aria_command_metadata, metadata} when is_map(metadata) -> metadata
      _ -> %{}
    end
  end

  defp extract_domain_reference(elements) do
    case find_element(elements, :domain) do
      {:domain, domain} when is_atom(domain) -> Atom.to_string(domain)
      _ -> nil
    end
  end

  defp extract_aria_plan(elements) do
    case find_element(elements, :aria_plan) do
      {:aria_plan, plan} when is_map(plan) ->
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
