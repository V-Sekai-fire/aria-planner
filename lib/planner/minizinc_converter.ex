# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.MiniZincConverter do
  @moduledoc """
  Converts planner elements (actions, tasks, commands, multigoals) to MiniZinc format
  using Sourceror to parse and transform Elixir AST.

  ## Overview

  This module uses Sourceror to parse Elixir code from planner elements and convert
  them into MiniZinc constraint programming models. It extracts:

  - **Preconditions**: Converted to MiniZinc constraints
  - **Effects**: Converted to MiniZinc variable assignments
  - **Predicates**: Converted to MiniZinc decision variables
  - **Logic**: Converted to MiniZinc constraint expressions

  ## Usage

      # Convert a command module to MiniZinc
      {:ok, minizinc_code} = MiniZincConverter.convert_command(
        AriaPlanner.Domains.TinyCvrp.Commands.VisitCustomer
      )

      # Convert a task module to MiniZinc
      {:ok, minizinc_code} = MiniZincConverter.convert_task(
        AriaPlanner.Domains.TinyCvrp.Tasks.RouteVehicles
      )

      # Convert a multigoal module to MiniZinc
      {:ok, minizinc_code} = MiniZincConverter.convert_multigoal(
        AriaPlanner.Domains.TinyCvrp.Multigoals.RouteVehicles
      )

      # Convert a planning domain to MiniZinc
      {:ok, minizinc_code} = MiniZincConverter.convert_domain(domain)
  """

  alias AriaCore.PlanningDomain

  @doc """
  Converts a command module to MiniZinc format.

  Extracts preconditions, effects, and logic from the command's Elixir code
  and converts them to MiniZinc constraints and variable declarations.
  """
  @spec convert_command(module() | String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def convert_command(module) when is_atom(module) do
    case get_module_source(module) do
      {:ok, source} ->
        convert_command_source(source, module)

      error ->
        error
    end
  end

  def convert_command(module_string) when is_binary(module_string) do
    case Code.string_to_quoted(module_string) do
      {:ok, ast} ->
        convert_command_ast(ast)

      error ->
        {:error, "Failed to parse module: #{inspect(error)}"}
    end
  end

  @doc """
  Converts a task module to MiniZinc format.

  Extracts task decomposition logic and converts it to MiniZinc constraints.
  """
  @spec convert_task(module() | String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def convert_task(module) when is_atom(module) do
    case get_module_source(module) do
      {:ok, source} ->
        convert_task_source(source, module)

      error ->
        error
    end
  end

  def convert_task(module_string) when is_binary(module_string) do
    case Code.string_to_quoted(module_string) do
      {:ok, ast} ->
        convert_task_ast(ast)

      error ->
        {:error, "Failed to parse module: #{inspect(error)}"}
    end
  end

  @doc """
  Converts a multigoal module to MiniZinc format.

  Extracts goal generation logic and converts it to MiniZinc constraints.
  """
  @spec convert_multigoal(module() | String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def convert_multigoal(module) when is_atom(module) do
    case get_module_source(module) do
      {:ok, source} ->
        convert_multigoal_source(source, module)

      error ->
        error
    end
  end

  def convert_multigoal(module_string) when is_binary(module_string) do
    case Code.string_to_quoted(module_string) do
      {:ok, ast} ->
        convert_multigoal_ast(ast)

      error ->
        {:error, "Failed to parse module: #{inspect(error)}"}
    end
  end

  @doc """
  Converts an entire planning domain to MiniZinc format.

  Combines all domain elements (commands, tasks, multigoals) into a single
  MiniZinc model.
  """
  @spec convert_domain(PlanningDomain.t() | map()) :: {:ok, String.t()} | {:error, String.t()}
  def convert_domain(%PlanningDomain{} = domain) do
    convert_domain_from_maps(domain)
  end

  def convert_domain(domain_map) when is_map(domain_map) do
    convert_domain_from_maps(domain_map)
  end

  # Private helper functions

  defp get_module_source(module) do
    try do
      # Try to get the source file path
      source_file = module.__info__(:compile)[:source]

      if source_file do
        case File.read(source_file) do
          {:ok, source} -> {:ok, source}
          error -> {:error, "Failed to read source file: #{inspect(error)}"}
        end
      else
        {:error, "Could not find source file for module #{inspect(module)}"}
      end
    rescue
      _ -> {:error, "Module #{inspect(module)} does not exist or is not compiled"}
    end
  end

  defp convert_command_source(source, module) do
    try do
      ast = Sourceror.parse_string!(source)
      convert_command_ast(ast)
    rescue
      error ->
        {:error, "Failed to parse source for #{inspect(module)}: #{inspect(error)}"}
    end
  end

  defp convert_command_ast(ast) do
    # Extract command function (c_*)
    command_func = find_command_function(ast)
    preconditions = extract_preconditions(ast)
    effects = extract_effects(ast)
    predicates = extract_predicates(ast)

    minizinc = generate_minizinc_model(
      command_func,
      preconditions,
      effects,
      predicates
    )

    {:ok, minizinc}
  end

  defp convert_task_source(source, module) do
    try do
      ast = Sourceror.parse_string!(source)
      convert_task_ast(ast)
    rescue
      error ->
        {:error, "Failed to parse source for #{inspect(module)}: #{inspect(error)}"}
    end
  end

  defp convert_task_ast(ast) do
    # Extract task function (t_*)
    task_func = find_task_function(ast)
    decomposition = extract_decomposition(ast)
    predicates = extract_predicates(ast)

    minizinc = generate_task_minizinc(
      task_func,
      decomposition,
      predicates
    )

    {:ok, minizinc}
  end

  defp convert_multigoal_source(source, module) do
    try do
      ast = Sourceror.parse_string!(source)
      convert_multigoal_ast(ast)
    rescue
      error ->
        {:error, "Failed to parse source for #{inspect(module)}: #{inspect(error)}"}
    end
  end

  defp convert_multigoal_ast(ast) do
    # Extract multigoal function (m_*)
    multigoal_func = find_multigoal_function(ast)
    goals = extract_goals(ast)
    predicates = extract_predicates(ast)

    minizinc = generate_multigoal_minizinc(
      multigoal_func,
      goals,
      predicates
    )

    {:ok, minizinc}
  end

  defp convert_domain_from_maps(domain) do
    commands = Map.get(domain, :commands, []) || []
    tasks = Map.get(domain, :tasks, []) || []
    multigoals = Map.get(domain, :multigoals, []) || []

    domain_name = Map.get(domain, :name, "domain") || Map.get(domain, :domain_type, "domain")

    # Convert each element
    command_models =
      Enum.map(commands, fn cmd ->
        case convert_command_element(cmd) do
          {:ok, model} -> model
          _ -> ""
        end
      end)
      |> Enum.filter(&(&1 != ""))

    task_models =
      Enum.map(tasks, fn task ->
        case convert_task_element(task) do
          {:ok, model} -> model
          _ -> ""
        end
      end)
      |> Enum.filter(&(&1 != ""))

    multigoal_models =
      Enum.map(multigoals, fn mg ->
        case convert_multigoal_element(mg) do
          {:ok, model} -> model
          _ -> ""
        end
      end)
      |> Enum.filter(&(&1 != ""))

    # Combine into single MiniZinc model
    minizinc = """
    % MiniZinc model for domain: #{domain_name}
    % Generated from planner elements

    % Commands
    #{Enum.join(command_models, "\n\n")}

    % Tasks
    #{Enum.join(task_models, "\n\n")}

    % Multigoals
    #{Enum.join(multigoal_models, "\n\n")}

    solve satisfy;
    """

    {:ok, minizinc}
  end

  defp convert_command_element(cmd) when is_map(cmd) do
    name = Map.get(cmd, "name") || Map.get(cmd, :name)
    preconditions = Map.get(cmd, "preconditions", []) || Map.get(cmd, :preconditions, [])
    effects = Map.get(cmd, "effects", []) || Map.get(cmd, :effects, [])

    if name do
      minizinc = generate_command_minizinc_from_map(name, preconditions, effects)
      {:ok, minizinc}
    else
      {:error, "Command missing name"}
    end
  end

  defp convert_task_element(task) when is_map(task) do
    name = Map.get(task, "name") || Map.get(task, :name)
    decomposition = Map.get(task, "decomposition") || Map.get(task, :decomposition)

    if name do
      minizinc = generate_task_minizinc_from_map(name, decomposition)
      {:ok, minizinc}
    else
      {:error, "Task missing name"}
    end
  end

  defp convert_multigoal_element(mg) when is_map(mg) do
    name = Map.get(mg, "name") || Map.get(mg, :name)
    predicate = Map.get(mg, "predicate") || Map.get(mg, :predicate)

    if name do
      minizinc = generate_multigoal_minizinc_from_map(name, predicate)
      {:ok, minizinc}
    else
      {:error, "Multigoal missing name"}
    end
  end

  # AST traversal functions using Macro.postwalk

  defp find_command_function(ast) do
    # Find function definition starting with c_
    {_, result} = Macro.postwalk(ast, nil, fn
      {:def, _, [{name, _, _}, _, _], _} = node, acc ->
        func_name_str = if is_atom(name), do: Atom.to_string(name), else: to_string(name)
        if String.starts_with?(func_name_str, "c_") do
          {node, name}
        else
          {node, acc}
        end

      node, acc ->
        {node, acc}
    end)

    result
  end

  defp find_task_function(ast) do
    # Find function definition starting with t_
    {_, result} = Macro.postwalk(ast, nil, fn
      {:def, _, [{name, _, _}, _, _], _} = node, acc ->
        func_name_str = if is_atom(name), do: Atom.to_string(name), else: to_string(name)
        if String.starts_with?(func_name_str, "t_") do
          {node, name}
        else
          {node, acc}
        end

      node, acc ->
        {node, acc}
    end)

    result
  end

  defp find_multigoal_function(ast) do
    # Find function definition starting with m_
    {_, result} = Macro.postwalk(ast, nil, fn
      {:def, _, [{name, _, _}, _, _], _} = node, acc ->
        func_name_str = if is_atom(name), do: Atom.to_string(name), else: to_string(name)
        if String.starts_with?(func_name_str, "m_") do
          {node, name}
        else
          {node, acc}
        end

      node, acc ->
        {node, acc}
    end)

    result
  end

  defp extract_preconditions(ast) do
    # Extract preconditions from with/2 clauses or guard patterns
    preconditions = []

    {_, preconditions} = Macro.postwalk(ast, preconditions, fn
      {:with, _, [clauses, _]} = node, acc ->
        # Extract conditions from with clauses
        conditions = extract_with_conditions(clauses)
        {node, acc ++ conditions}

      {:if, _, [condition, _]} = node, acc ->
        # Extract if conditions
        {node, acc ++ [condition]}

      node, acc ->
        {node, acc}
    end)

    preconditions
  end

  defp extract_effects(ast) do
    # Extract effects from assignments and predicate updates
    effects = []

    {_, effects} = Macro.postwalk(ast, effects, fn
      {:=, _, [left, right]} = node, acc ->
        # Assignment
        {node, acc ++ [{left, right}]}

      {:|>, _, [arg, {:., _, [{:__aliases__, _, path}, :set]}]} = node, acc ->
        # Predicate set operation
        predicate_name = path |> Enum.map(&to_string/1) |> Enum.join(".")
        {node, acc ++ [{:predicate_set, predicate_name, arg}]}

      node, acc ->
        {node, acc}
    end)

    effects
  end

  defp extract_predicates(ast) do
    # Extract predicate references from module aliases
    predicates = []

    {_, predicates} = Macro.postwalk(ast, predicates, fn
      {:alias, _, [{:__aliases__, _, path}]} = node, acc ->
        # Check if it's a Predicate module
        path_str = path |> Enum.map(&to_string/1) |> Enum.join(".")
        if String.contains?(path_str, "Predicate") do
          {node, acc ++ [path_str]}
        else
          {node, acc}
        end

      node, acc ->
        {node, acc}
    end)

    predicates
  end

  defp extract_decomposition(ast) do
    # Extract task decomposition (list of subtasks)
    decomposition = []

    {_, decomposition} = Macro.postwalk(ast, decomposition, fn
      {:list, _, elements} = node, acc ->
        # List of subtasks
        {node, acc ++ elements}

      node, acc ->
        {node, acc}
    end)

    decomposition
  end

  defp extract_goals(ast) do
    # Extract goals from comprehension or list
    goals = []

    {_, goals} = Macro.postwalk(ast, goals, fn
      {:for, _, generators} = node, acc ->
        # List comprehension generating goals
        {node, acc ++ generators}

      {:list, _, elements} = node, acc ->
        # List of goals
        {node, acc ++ elements}

      node, acc ->
        {node, acc}
    end)

    goals
  end

  defp extract_with_conditions(clauses) do
    # Extract conditions from with clauses
    case clauses do
      [{:<-, _, [_, condition]}] -> [condition]
      [{:<-, _, [_, condition]} | rest] -> [condition | extract_with_conditions(rest)]
      _ -> []
    end
  end

  # MiniZinc generation functions

  defp generate_minizinc_model(command_func, preconditions, effects, predicates) do
    func_name = format_function_name(command_func)

    """
    % Command: #{func_name}
    % Preconditions:
    #{format_preconditions(preconditions)}
    % Effects:
    #{format_effects(effects)}
    % Predicates:
    #{format_predicates(predicates)}
    """
  end

  defp generate_task_minizinc(task_func, decomposition, predicates) do
    func_name = format_function_name(task_func)

    """
    % Task: #{func_name}
    % Decomposition:
    #{format_decomposition(decomposition)}
    % Predicates:
    #{format_predicates(predicates)}
    """
  end

  defp generate_multigoal_minizinc(multigoal_func, goals, predicates) do
    func_name = format_function_name(multigoal_func)

    """
    % Multigoal: #{func_name}
    % Goals:
    #{format_goals(goals)}
    % Predicates:
    #{format_predicates(predicates)}
    """
  end

  defp generate_command_minizinc_from_map(name, preconditions, effects) do
    """
    % Command: #{name}
    % Preconditions:
    #{format_preconditions_from_strings(preconditions)}
    % Effects:
    #{format_effects_from_strings(effects)}
    """
  end

  defp generate_task_minizinc_from_map(name, decomposition) do
    """
    % Task: #{name}
    % Decomposition: #{decomposition || "N/A"}
    """
  end

  defp generate_multigoal_minizinc_from_map(name, predicate) do
    """
    % Multigoal: #{name}
    % Predicate: #{predicate || "N/A"}
    """
  end

  # Formatting functions

  defp format_function_name(nil), do: "unknown"
  defp format_function_name({name, _, _}) when is_atom(name), do: Atom.to_string(name)
  defp format_function_name(name) when is_atom(name), do: Atom.to_string(name)
  defp format_function_name(name) when is_binary(name), do: name
  defp format_function_name(other), do: inspect(other)

  defp format_preconditions([]), do: "% (none)"
  defp format_preconditions(preconditions), do: Enum.map_join(preconditions, "\n", &format_constraint/1)

  defp format_effects([]), do: "% (none)"
  defp format_effects(effects), do: Enum.map_join(effects, "\n", &format_effect/1)

  defp format_predicates([]), do: "% (none)"
  defp format_predicates(predicates), do: Enum.map_join(predicates, "\n", &format_predicate/1)

  defp format_decomposition([]), do: "% (none)"
  defp format_decomposition(decomposition), do: inspect(decomposition)

  defp format_goals([]), do: "% (none)"
  defp format_goals(goals), do: inspect(goals)

  defp format_preconditions_from_strings([]), do: "% (none)"
  defp format_preconditions_from_strings(preconditions) when is_list(preconditions) do
    Enum.map_join(preconditions, "\n", fn prec ->
      "%   - #{prec}"
    end)
  end
  defp format_preconditions_from_strings(_), do: "% (none)"

  defp format_effects_from_strings([]), do: "% (none)"
  defp format_effects_from_strings(effects) when is_list(effects) do
    Enum.map_join(effects, "\n", fn effect ->
      "%   - #{effect}"
    end)
  end
  defp format_effects_from_strings(_), do: "% (none)"

  defp format_constraint(constraint) do
    "%   constraint: #{inspect(constraint)}"
  end

  defp format_effect(effect) do
    "%   effect: #{inspect(effect)}"
  end

  defp format_predicate(predicate) do
    "%   predicate: #{inspect(predicate)}"
  end
end

