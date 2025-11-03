# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Tasks.FindIf do
  @moduledoc """
  Task: t_find_if(condition, sequence)

  Return the first element in sequence that satisfies the condition,
  or nil if no element satisfies it.
  """

  @spec t_find_if((term() -> boolean()), [term()]) :: term() | nil
  def t_find_if(condition, sequence) do
    Enum.find(sequence, condition)
  end
end
