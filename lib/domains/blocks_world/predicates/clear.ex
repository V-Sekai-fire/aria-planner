# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Predicates.Clear do
  @moduledoc """
  Clear predicate for blocks world domain.

  Represents whether a block is clear (nothing on top of it and hand not holding it).
  - true - block is clear
  - false - block has something on top or is being held
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:entity_id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "blocks_world_clear" do
    field(:value, :boolean)

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating and updating clear facts.
  """
  @spec changeset(clear :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(clear \\ %__MODULE__{}, attrs) do
    clear
    |> cast(attrs, [:entity_id, :value])
    |> validate_required([:entity_id, :value])
  end

  @doc """
  Creates a new clear fact.
  """
  @spec create(attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Updates an existing clear fact.
  """
  @spec update(clear :: %__MODULE__{}, attrs :: map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(clear, attrs) do
    clear
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
