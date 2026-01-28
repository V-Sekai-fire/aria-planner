# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Predicates.VariableValueSchema do
  @moduledoc """
  Ecto schema for variable_value predicate persistence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interactivity_variable_value" do
    field(:variable_name, :string)
    field(:value, :map)
    field(:value_type, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(variable_value, attrs) do
    variable_value
    |> cast(attrs, [:variable_name, :value, :value_type])
    |> validate_required([:variable_name])
    |> unique_constraint(:variable_name, name: :interactivity_variable_value_variable_name_index)
  end
end
