# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.OperationMapping do
  @moduledoc """
  Maps spec operation names to internal command function names.

  The glTF Interactivity Extension spec uses mixed-case operation names
  (e.g., `math/E`, `math/Pi`, `math/Inf`, `math/NaN`) while Elixir
  function names must be lowercase. This module provides the mapping
  between spec operation IDs and internal command names.
  """

  @doc """
  Maps a spec operation name to an internal command function name.

  ## Examples

      iex> spec_to_command("math/E")
      "c_math_e"

      iex> spec_to_command("math/Pi")
      "c_math_pi"

      iex> spec_to_command("math/add")
      "c_math_add"

      iex> spec_to_command("variable/get")
      "c_variable_get"
  """
  @spec spec_to_command(String.t()) :: String.t()
  def spec_to_command(operation) when is_binary(operation) do
    # Split operation into domain and op name (e.g., "math/E" -> ["math", "E"])
    case String.split(operation, "/", parts: 2) do
      [domain, op_name] ->
        # Convert op_name to lowercase and build command name
        op_lower = String.downcase(op_name)
        "c_#{domain}_#{op_lower}"

      [op_name] ->
        # No domain prefix, just convert to lowercase
        op_lower = String.downcase(op_name)
        "c_#{op_lower}"

      _ ->
        # Invalid format, return as-is (will likely fail later)
        operation
    end
  end

  @doc """
  Maps an internal command function name back to a spec operation name.

  This is the inverse of `spec_to_command/1`, but note that some information
  may be lost (e.g., "c_math_e" -> "math/e" not "math/E").

  ## Examples

      iex> command_to_spec("c_math_e")
      "math/e"

      iex> command_to_spec("c_math_add")
      "math/add"
  """
  @spec command_to_spec(String.t()) :: String.t()
  def command_to_spec(command) when is_binary(command) do
    # Remove "c_" prefix and split
    case String.replace_prefix(command, "c_", "") do
      ^command ->
        # No prefix, return as-is
        command

      rest ->
        # Split into domain and operation
        case String.split(rest, "_", parts: 2) do
          [domain, op_name] ->
            "#{domain}/#{op_name}"

          [op_name] ->
            op_name

          _ ->
            command
        end
    end
  end

  @doc """
  Checks if an operation name matches the spec format (domain/operation).

  ## Examples

      iex> is_spec_format?("math/E")
      true

      iex> is_spec_format?("c_math_e")
      false

      iex> is_spec_format?("math/add")
      true
  """
  @spec is_spec_format?(String.t()) :: boolean()
  def is_spec_format?(operation) when is_binary(operation) do
    String.contains?(operation, "/") and not String.starts_with?(operation, "c_")
  end

  @doc """
  Gets the domain from a spec operation name.

  ## Examples

      iex> get_domain("math/E")
      "math"

      iex> get_domain("variable/get")
      "variable"
  """
  @spec get_domain(String.t()) :: String.t() | nil
  def get_domain(operation) when is_binary(operation) do
    case String.split(operation, "/", parts: 2) do
      [domain, _op_name] -> domain
      _ -> nil
    end
  end

  @doc """
  Gets the operation name from a spec operation name.

  ## Examples

      iex> get_operation("math/E")
      "E"

      iex> get_operation("variable/get")
      "get"
  """
  @spec get_operation(String.t()) :: String.t() | nil
  def get_operation(operation) when is_binary(operation) do
    case String.split(operation, "/", parts: 2) do
      [_domain, op_name] -> op_name
      _ -> nil
    end
  end
end
