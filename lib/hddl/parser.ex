# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Parser do
  @moduledoc """
  Parser for HDDL 2.1 + aria_planner extensions.

  Parses HDDL (Hierarchical Domain Definition Language) syntax into structured AST.
  Supports full HDDL 2.1 syntax and aria_planner-specific extensions.

  HDDL uses Lisp-like S-expression syntax. This parser handles:
  - Domain definitions: `(define (domain <name>) ...)`
  - Problem definitions: `(define (problem <name>) ...)`
  - Actions, durative actions, methods, commands
  - aria_planner extensions: `:aria-*` blocks

  ## Migration to SourcerorStyle

  This module now delegates all parsing to `AriaPlanner.HDDL.Parser.SourcerorStyle`
  which uses recursive descent parsing with pattern matching instead of NimbleParsec.
  """

  # NOTE: All NimbleParsec parser definitions have been removed.
  # The main parse/1 function delegates to AriaPlanner.HDDL.Parser.SourcerorStyle.parse/1
  # which handles all parsing using recursive descent with pattern matching.

  # Public API - delegates to SourcerorStyle parser
  @doc """
  Parses an HDDL string and returns an AST using Sourceror-style parsing.

  ## Examples

      iex> AriaPlanner.HDDL.Parser.parse("(define (domain test) (:requirements :strips))")
      {:ok, {:domain, :test, [{:requirements, [:strips]}]}, "", ...}

  """
  @spec parse(String.t()) :: {:ok, term(), String.t(), integer(), integer(), integer()} | {:error, String.t()}
  def parse(hddl_string) when is_binary(hddl_string) do
    case AriaPlanner.HDDL.Parser.SourcerorStyle.parse(hddl_string) do
      {:ok, ast} ->
        normalized_ast = normalize_ast(ast)
        {:ok, normalized_ast, "", 0, 0, 0}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parses an HDDL file and returns an AST.
  """
  @spec parse_file(String.t()) :: {:ok, term()} | {:error, String.t()}
  def parse_file(path) do
    case File.read(path) do
      {:ok, content} ->
        case parse(content) do
          {:ok, ast, _, _, _, _} -> {:ok, ast}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  # Normalize AST to cleaner structure
  defp normalize_ast(ast) do
    case ast do
      {:domain, name, elements} ->
        normalized_elements = Enum.map(elements, &normalize_element/1)
        {:domain, name, normalized_elements}

      {:problem, name, elements} ->
        normalized_elements = Enum.map(elements, &normalize_element/1)
        {:problem, name, normalized_elements}

      other ->
        normalize_element(other)
    end
  end

  defp normalize_element({:keyword_list, pairs}) do
    Enum.reduce(pairs, %{}, fn
      {:pair, [key, value]} ->
        Map.put(%{}, key, normalize_value(value))

      {:keyword, key} when is_atom(key) ->
        Map.put(%{}, key, true)

      _other ->
        %{}
    end)
  end

  defp normalize_element({:list, items}) do
    Enum.map(items, &normalize_value/1)
  end

  defp normalize_element({tag, value}) when is_atom(tag) do
    {tag, normalize_value(value)}
  end

  defp normalize_element({tag, name, elements}) when is_atom(tag) do
    normalized_elements = Enum.map(elements, &normalize_element/1)
    {tag, name, normalized_elements}
  end

  defp normalize_element(other) do
    normalize_value(other)
  end

  defp normalize_value({:keyword_list, pairs}) do
    Enum.reduce(pairs, %{}, fn
      {:pair, [key, value]} ->
        Map.put(%{}, key, normalize_value(value))

      {:keyword, key} when is_atom(key) ->
        Map.put(%{}, key, true)

      _other ->
        %{}
    end)
  end

  defp normalize_value({:list, items}) do
    Enum.map(items, &normalize_value/1)
  end

  defp normalize_value({tag, value}) when is_atom(tag) do
    {tag, normalize_value(value)}
  end

  defp normalize_value(value) when is_atom(value) or is_binary(value) or is_integer(value) do
    value
  end

  defp normalize_value(other) do
    other
  end
end
