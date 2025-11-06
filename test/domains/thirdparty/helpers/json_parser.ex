# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Helpers.JsonParser do
  @moduledoc """
  Helper module for parsing JSON data files from MiniZinc problems.
  """

  @doc """
  Parses a JSON file and returns the decoded data.
  """
  @spec parse_json_file(path :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse_json_file(path) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, "Failed to decode JSON: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  @doc """
  Extracts a value from parsed JSON data by key path.
  """
  @spec get_value(data :: map(), key_path :: list()) :: any() | nil
  def get_value(data, key_path) when is_list(key_path) do
    Enum.reduce(key_path, data, fn
      key, nil -> nil
      key, map when is_map(map) -> Map.get(map, key)
      _key, _ -> nil
    end)
  end

  @doc """
  Extracts a value from parsed JSON data by single key.
  """
  @spec get_value(data :: map(), key :: String.t() | atom()) :: any() | nil
  def get_value(data, key) when is_map(data) do
    Map.get(data, key) || Map.get(data, to_string(key))
  end
end

