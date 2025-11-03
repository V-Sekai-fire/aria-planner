# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Predicates.Holding do
  @moduledoc """
  Holding predicate for blocks world domain.

  Represents what the hand is holding.
  - block_id - the hand is holding this block
  - "false" - the hand is empty
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:entity_id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "blocks_world_holding" do
    field(:value, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating and updating holding facts.
  """
  @spec changeset(holding :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(holding \\ %__MODULE__{}, attrs) do
    holding
    |> cast(attrs, [:entity_id, :value])
    |> validate_required([:entity_id])
  end

  @doc """
  Creates a new holding fact.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates an existing holding fact.
  """
  @spec update(holding :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(holding, attrs) do
    holding
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
