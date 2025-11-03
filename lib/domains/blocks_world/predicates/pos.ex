# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Predicates.Pos do
  @moduledoc """
  Position predicate for blocks world domain.

  Represents where each block is located:
  - "table" - block is on the table
  - "hand" - block is being held
  - block_id - block is on top of another block
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:entity_id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "blocks_world_pos" do
    field(:value, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating and updating position facts.
  """
  @spec changeset(pos :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(pos \\ %__MODULE__{}, attrs) do
    pos
    |> cast(attrs, [:entity_id, :value])
    |> validate_required([:entity_id, :value])
  end

  @doc """
  Creates a new position fact.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates an existing position fact.
  """
  @spec update(pos :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(pos, attrs) do
    pos
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
