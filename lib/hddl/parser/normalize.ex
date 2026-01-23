# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Parser.Normalize do
  @moduledoc """
  AST normalization functions for HDDL parser.
  Converts raw parser output into cleaner, more structured AST format.
  """
  @doc """
  Normalizes the top-level AST structure.
  ## Examples
      iex> AriaPlanner.HDDL.Parser.Normalize.normalize_ast({:domain, :test, []})
      {:domain, :test, []}
  @spec normalize_ast({:domain, atom(), list()} | {:problem, atom(), list()} | term()) ::
          {:domain, atom(), list()} | {:problem, atom(), list()} | term()
  def normalize_ast(ast) do
    case ast do
      {:domain, name, elements} ->
        normalized_elements = Enum.map(elements, &normalize_element/1)
        {:domain, name, normalized_elements}
      {:problem, name, elements} ->
        {:problem, name, normalized_elements}
      other ->
        normalize_element(other)
    end
  end
  @spec normalize_element(term()) :: term()
  defp normalize_element({:keyword_list, pairs}) do
    Enum.reduce(pairs, %{}, fn
      {:pair, [key, value]} ->
        Map.put(%{}, key, normalize_value(value))
      {:keyword, key} when is_atom(key) ->
        Map.put(%{}, key, true)
      _other ->
        %{}
    end)
  defp normalize_element({:list, items}) do
    Enum.map(items, &normalize_value/1)
  defp normalize_element({tag, value}) when is_atom(tag) do
    {tag, normalize_value(value)}
  defp normalize_element({tag, name, elements}) when is_atom(tag) do
    normalized_elements = Enum.map(elements, &normalize_element/1)
    {tag, name, normalized_elements}
  defp normalize_element(other) do
    normalize_value(other)
  @spec normalize_value(term()) :: term()
  defp normalize_value({:keyword_list, pairs}) do
  defp normalize_value({:list, items}) do
  defp normalize_value({tag, value}) when is_atom(tag) do
  defp normalize_value(value) when is_atom(value) or is_binary(value) or is_integer(value) do
    value
  defp normalize_value(other) do
    other
end
