# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.BlocksWorldProblems do
  @moduledoc """
  Test fixtures for Blocks World initial states and goals, translated from Python examples.
  """

  def init_state_1 do
    %{
      pos: %{"a" => "b", "b" => "table", "c" => "table"},
      clear: %{"c" => true, "b" => false, "a" => true},
      holding: %{"hand" => "false"}
    }
  end

  def goal1a do
    %{
      pos: %{"c" => "b", "b" => "a", "a" => "table"},
      clear: %{"c" => true, "b" => false, "a" => false},
      holding: %{"hand" => "false"}
    }
  end

  def goal1b do
    %{
      pos: %{"c" => "b", "b" => "a"}
    }
  end

  def init_state_2 do
    %{
      pos: %{"a" => "c", "b" => "d", "c" => "table", "d" => "table"},
      clear: %{"a" => true, "c" => false, "b" => true, "d" => false},
      holding: %{"hand" => "false"}
    }
  end

  def goal2a do
    %{
      pos: %{"b" => "c", "a" => "d", "c" => "table", "d" => "table"},
      clear: %{"a" => true, "c" => false, "b" => true, "d" => false},
      holding: %{"hand" => "false"}
    }
  end

  def goal2b do
    %{
      pos: %{"b" => "c", "a" => "d"}
    }
  end

  def init_state_3 do
    %{
      pos: %{
        "1" => "12", "12" => "13", "13" => "table",
        "11" => "10", "10" => "5", "5" => "4", "4" => "14", "14" => "15", "15" => "table",
        "9" => "8", "8" => "7", "7" => "6", "6" => "table",
        "19" => "18", "18" => "17", "17" => "16", "16" => "3", "3" => "2", "2" => "table"
      },
      clear: %{
        "1" => true, "2" => false, "3" => false, "4" => false, "5" => false,
        "6" => false, "7" => false, "8" => false, "9" => true, "10" => false,
        "11" => true, "12" => false, "13" => false, "14" => false, "15" => false,
        "16" => false, "17" => false, "18" => false, "19" => true
      },
      holding: %{"hand" => "false"}
    }
  end

  def goal3 do
    %{
      pos: %{
        "15" => "13", "13" => "8", "8" => "9", "9" => "4", "4" => "table",
        "12" => "2", "2" => "3", "3" => "16", "16" => "11", "11" => "7", "7" => "6", "6" => "table"
      },
      clear: %{"17" => true, "15" => true, "12" => true}
    }
  end
end
