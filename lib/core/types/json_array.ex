# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Types.JsonArray do
  @moduledoc """
  Custom Ecto type for storing arrays as JSON strings in SQLite3.
  """

  use Ecto.Type

  def type, do: :string

  def cast(value) when is_list(value) do
    {:ok, value}
  end

  def cast(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, list} when is_list(list) -> {:ok, list}
      _ -> :error
    end
  end

  def cast(_), do: :error

  def load(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, list} when is_list(list) -> {:ok, list}
      _ -> {:ok, []}
    end
  end

  def load(_), do: {:ok, []}

  def dump(value) when is_list(value) do
    {:ok, Jason.encode!(value)}
  end

  def dump(_), do: :error
end
