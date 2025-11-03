# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Predicate do
  @moduledoc """
  Simple predicate for planning system relationships.

  Uses plain maps for scrappy operation without database dependencies.
  """

  @type t :: %{
          id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          category: String.t(),
          multi_valued: boolean(),
          metadata: map()
        }

  @doc """
  Creates a new predicate with validation.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) do
    id = Map.get_lazy(attrs, :id, fn -> :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower) end)
    name = Map.get(attrs, :name)

    if is_nil(name) or not (is_binary(name) and String.match?(name, ~r/^[a-z][a-zA-Z0-9_]*$/)) do
      {:error, "name is required and must be a valid atom name (starting with lowercase letter)"}
    else
      {:ok,
       %{
         id: id,
         name: name,
         description: Map.get(attrs, :description),
         category: Map.get(attrs, :category, "state"),
         multi_valued: Map.get(attrs, :multi_valued, false),
         metadata: Map.get(attrs, :metadata, %{})
       }}
    end
  end

  @doc """
  Creates a new predicate or raises on error.
  """
  @spec new!(map()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, predicate} -> predicate
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Validates predicate data.
  """
  @spec validate(map()) :: {:ok, t()} | {:error, keyword()}
  def validate(attrs) do
    case new(attrs) do
      {:ok, predicate} -> {:ok, predicate}
      {:error, reason} -> {:error, reason: reason}
    end
  end
end
