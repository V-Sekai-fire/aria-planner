# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Solvers.FlatZincGenerator do
  @moduledoc """
  Generates FlatZinc format from constraint specifications using EEx templates.
  """

  # Get template path relative to this file's directory
  @template_path Path.expand("templates/flatzinc.eex", __DIR__)

  @doc """
  Generates FlatZinc content from a constraint map.

  ## Parameters

  - `constraints`: Map with `:variables`, `:constraints`, and optional `:objective`

  ## Returns

  - FlatZinc string

  ## Example

      constraints = %{
        variables: [
          {:x, :int, 1, 10},
          {:y, :int, 1, 10}
        ],
        constraints: [
          {:int_eq, {:+, :x, :y}, 10}
        ],
        objective: {:minimize, :x}
      }
      
      flatzinc = FlatZincGenerator.generate(constraints)
  """
  @spec generate(map()) :: String.t()
  def generate(constraints) when is_map(constraints) do
    variables = Map.get(constraints, :variables, [])
    constraint_list = Map.get(constraints, :constraints, [])
    objective = Map.get(constraints, :objective)

    assigns = [
      variables: variables,
      constraints: constraint_list,
      objective: objective
    ]

    # Add format functions to assigns so template can access them
    assigns_with_functions =
      assigns ++
        [
          format_variable: &format_variable/1,
          format_constraint: &format_constraint/1,
          format_objective: &format_objective/1
        ]

    EEx.eval_file(@template_path, assigns: assigns_with_functions)
  end

  def generate(_), do: "% Empty constraints\nsolve satisfy;"

  # Format a variable declaration (public for EEx template)
  def format_variable({name, :int, min, max}) when is_atom(name) do
    "var #{min}..#{max}: #{name};"
  end

  def format_variable({name, :bool}) when is_atom(name) do
    "var bool: #{name};"
  end

  def format_variable({name, :float, min, max}) when is_atom(name) do
    "var #{min}..#{max}: #{name};"
  end

  def format_variable({name, :int, min, max}) when is_binary(name) do
    "var #{min}..#{max}: #{name};"
  end

  def format_variable({name, :bool}) when is_binary(name) do
    "var bool: #{name};"
  end

  def format_variable({name, :float, min, max}) when is_binary(name) do
    "var #{min}..#{max}: #{name};"
  end

  def format_variable(var) do
    "% Unknown variable format: #{inspect(var)}"
  end

  # Format a constraint (public for EEx template)
  def format_constraint({:all_different, vars}) do
    var_list = Enum.join(Enum.map(vars, &var_to_string/1), ", ")
    "constraint all_different([#{var_list}]);"
  end

  def format_constraint({:int_eq, left, right}) do
    "constraint #{expr_to_string(left)} = #{expr_to_string(right)};"
  end

  def format_constraint({:int_ne, left, right}) do
    "constraint #{expr_to_string(left)} != #{expr_to_string(right)};"
  end

  def format_constraint({:int_le, left, right}) do
    "constraint #{expr_to_string(left)} <= #{expr_to_string(right)};"
  end

  def format_constraint({:int_lt, left, right}) do
    "constraint #{expr_to_string(left)} < #{expr_to_string(right)};"
  end

  def format_constraint({:int_ge, left, right}) do
    "constraint #{expr_to_string(left)} >= #{expr_to_string(right)};"
  end

  def format_constraint({:int_gt, left, right}) do
    "constraint #{expr_to_string(left)} > #{expr_to_string(right)};"
  end

  def format_constraint({:bool_eq, left, right}) do
    "constraint #{expr_to_string(left)} = #{expr_to_string(right)};"
  end

  def format_constraint({:bool_and, left, right}) do
    "constraint #{expr_to_string(left)} /\\ #{expr_to_string(right)};"
  end

  def format_constraint({:bool_or, left, right}) do
    "constraint #{expr_to_string(left)} \\/ #{expr_to_string(right)};"
  end

  def format_constraint({:bool_not, expr}) do
    "constraint not #{expr_to_string(expr)};"
  end

  def format_constraint({:array_element, array, index, value}) do
    "constraint element(#{expr_to_string(index)}, #{expr_to_string(array)}, #{expr_to_string(value)});"
  end

  def format_constraint({:global_cardinality, vars, low, high}) do
    "constraint global_cardinality_low_up([#{Enum.join(Enum.map(vars, &expr_to_string/1), ", ")}], #{expr_to_string(low)}, #{expr_to_string(high)});"
  end

  def format_constraint(constraint) do
    "% Unknown constraint: #{inspect(constraint)}"
  end

  # Format an objective (public for EEx template)
  def format_objective({:minimize, var}) do
    "solve minimize #{var_to_string(var)};"
  end

  def format_objective({:maximize, var}) do
    "solve maximize #{var_to_string(var)};"
  end

  def format_objective(_), do: "solve satisfy;"

  # Convert expression to string
  defp expr_to_string({:+, left, right}) do
    "(#{expr_to_string(left)} + #{expr_to_string(right)})"
  end

  defp expr_to_string({:-, left, right}) do
    "(#{expr_to_string(left)} - #{expr_to_string(right)})"
  end

  defp expr_to_string({:*, left, right}) do
    "(#{expr_to_string(left)} * #{expr_to_string(right)})"
  end

  defp expr_to_string({:/, left, right}) do
    "(#{expr_to_string(left)} / #{expr_to_string(right)})"
  end

  defp expr_to_string({:mod, left, right}) do
    "(#{expr_to_string(left)} mod #{expr_to_string(right)})"
  end

  defp expr_to_string({:sum, vars}) do
    var_list = Enum.join(Enum.map(vars, &expr_to_string/1), " + ")
    "(#{var_list})"
  end

  defp expr_to_string({:array, elements}) do
    "[#{Enum.join(Enum.map(elements, &expr_to_string/1), ", ")}]"
  end

  defp expr_to_string(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp expr_to_string(int) when is_integer(int), do: Integer.to_string(int)
  defp expr_to_string(float) when is_float(float), do: Float.to_string(float)
  defp expr_to_string(bool) when is_boolean(bool), do: if(bool, do: "true", else: "false")
  defp expr_to_string(str) when is_binary(str), do: str
  defp expr_to_string(other), do: inspect(other)

  # Convert variable to string
  defp var_to_string(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp var_to_string(str) when is_binary(str), do: str
  defp var_to_string(other), do: inspect(other)
end
