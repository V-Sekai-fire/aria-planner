# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Predicates.Atom do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive {Jason.Encoder, only: [:name]}
  schema "atoms" do
    field :name, :string, primary_key: true
  end

  @doc false
  def changeset(atom, attrs) do
    atom
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  @doc false
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> AriaPlanner.Repo.insert()
  end
end
