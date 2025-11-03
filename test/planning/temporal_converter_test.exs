# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.TemporalConverterTest do
  use ExUnit.Case, async: true

  alias AriaPlanner.Planner.TemporalConverter

  describe "convert_durative_action/1" do
    test "converts basic durative action" do
      durative_action = %{
        name: :cook_meal,
        duration: "PT1H",
        conditions: %{},
        effects: %{}
      }

      {simple_action, method_fn} = TemporalConverter.convert_durative_action(durative_action)

      assert simple_action.name == :cook_meal
      assert simple_action.duration == "PT1H"
      assert is_function(method_fn)
    end

    test "handles different duration formats" do
      # Fixed duration in seconds
      durative_action = %{
        name: :test_action,
        duration: {:fixed, 3600},
        conditions: %{},
        effects: %{}
      }

      {simple_action, _} = TemporalConverter.convert_durative_action(durative_action)
      assert simple_action.duration == "PT1H"

      # Controllable duration
      durative_action = Map.put(durative_action, :duration, {:controllable, 1800})
      {simple_action, _} = TemporalConverter.convert_durative_action(durative_action)
      assert simple_action.duration == "PT30M"
    end

    test "defaults to PT1S for invalid duration" do
      durative_action = %{
        name: :test_action,
        duration: "invalid",
        conditions: %{},
        effects: %{}
      }

      {simple_action, _} = TemporalConverter.convert_durative_action(durative_action)
      assert simple_action.duration == "PT1S"
    end

    test "defaults to PT1S for nil duration" do
      durative_action = %{
        name: :test_action,
        duration: nil,
        conditions: %{},
        effects: %{}
      }

      {simple_action, _} = TemporalConverter.convert_durative_action(durative_action)
      assert simple_action.duration == "PT1S"
    end
  end

  describe "extract_simple_action/1" do
    test "extracts basic properties" do
      durative_action = %{
        name: :test_action,
        duration: "PT30M",
        conditions: %{at_start: [{"oven", "temperature", {:>=, 350}}]},
        effects: %{at_end: [{"meal", "quality", {:>=, 8}}]}
      }

      simple_action = TemporalConverter.extract_simple_action(durative_action)

      assert simple_action.name == :test_action
      assert simple_action.duration == "PT30M"
    end

    test "removes complex temporal conditions and effects" do
      durative_action = %{
        name: :complex_action,
        duration: "PT1H",
        conditions: %{
          at_start: [{"oven", "temperature", {:>=, 350}}],
          over_all: [{"oven", "power", {:==, "on"}}],
          at_end: [{"meal", "cooked", true}]
        },
        effects: %{
          at_start: [{"oven", "in_use", true}],
          at_end: [{"meal", "quality", 8}]
        }
      }

      simple_action = TemporalConverter.extract_simple_action(durative_action)

      # Should only have name and duration
      assert Map.keys(simple_action) == [:name, :duration]
      assert simple_action.name == :complex_action
      assert simple_action.duration == "PT1H"
    end
  end

  describe "build_method_decomposition/1" do
    test "returns a function that generates method decomposition" do
      durative_action = %{
        name: :cook_meal,
        duration: "PT1H",
        conditions: %{},
        effects: %{}
      }

      method_fn = TemporalConverter.build_method_decomposition(durative_action)

      assert is_function(method_fn)

      # Test calling the method function
      {:ok, todo_items, metadata} = method_fn.(%{}, [])

      assert is_list(todo_items)
      assert is_map(metadata)
    end

    test "includes main action in todo items" do
      durative_action = %{
        name: :cook_meal,
        duration: "PT1H",
        conditions: %{},
        effects: %{}
      }

      method_fn = TemporalConverter.build_method_decomposition(durative_action)
      {:ok, todo_items, _metadata} = method_fn.(%{}, [])

      # Should include the main action
      assert {:action, :cook_meal, []} in todo_items
    end

    test "converts at_start conditions to prerequisite unigoals" do
      durative_action = %{
        name: :cook_meal,
        duration: "PT1H",
        conditions: %{
          at_start: [{"oven", "temperature", {:>=, 350}}]
        },
        effects: %{}
      }

      method_fn = TemporalConverter.build_method_decomposition(durative_action)
      {:ok, todo_items, _metadata} = method_fn.(%{}, [])

      assert {:unigoal, "oven", ["temperature", {:>=, 350}]} in todo_items
    end

    test "converts over_all conditions to monitoring unigoals" do
      durative_action = %{
        name: :cook_meal,
        duration: "PT1H",
        conditions: %{
          over_all: [{"oven", "power", {:==, "on"}}]
        },
        effects: %{}
      }

      method_fn = TemporalConverter.build_method_decomposition(durative_action)
      {:ok, todo_items, _metadata} = method_fn.(%{}, [])

      assert {:unigoal, "oven", ["power", {:==, "on"}]} in todo_items
    end

    test "converts at_end conditions to verification unigoals" do
      durative_action = %{
        name: :cook_meal,
        duration: "PT1H",
        conditions: %{
          at_end: [{"meal", "cooked", true}]
        },
        effects: %{}
      }

      method_fn = TemporalConverter.build_method_decomposition(durative_action)
      {:ok, todo_items, _metadata} = method_fn.(%{}, [])

      assert {:unigoal, "meal", ["cooked", true]} in todo_items
    end

    test "converts at_end effects to cleanup unigoals" do
      durative_action = %{
        name: :cook_meal,
        duration: "PT1H",
        conditions: %{},
        effects: %{
          at_end: [{"meal", "quality", 8}]
        }
      }

      method_fn = TemporalConverter.build_method_decomposition(durative_action)
      {:ok, todo_items, _metadata} = method_fn.(%{}, [])

      assert {:unigoal, "meal", ["quality", 8]} in todo_items
    end
  end

  describe "validate_conversion/2" do
    test "validates correct conversion" do
      original = %{
        name: :cook_meal,
        duration: "PT1H",
        conditions: %{},
        effects: %{}
      }

      {simple_action, method_fn} = TemporalConverter.convert_durative_action(original)

      assert TemporalConverter.validate_conversion(original, {simple_action, method_fn})
    end

    test "rejects conversion with wrong name" do
      original = %{name: :cook_meal}
      simple_action = %{name: :wrong_name}
      method_fn = fn _, _ -> {:ok, [], %{}} end

      refute TemporalConverter.validate_conversion(original, {simple_action, method_fn})
    end

    test "rejects invalid method function" do
      original = %{name: :cook_meal}
      simple_action = %{name: :cook_meal}
      method_fn = "not a function"

      refute TemporalConverter.validate_conversion(original, {simple_action, method_fn})
    end

    test "rejects method function with wrong return format" do
      original = %{name: :cook_meal}
      simple_action = %{name: :cook_meal}
      method_fn = fn _, _ -> :invalid_return end

      refute TemporalConverter.validate_conversion(original, {simple_action, method_fn})
    end
  end

  describe "convert_batch/1" do
    test "converts multiple durative actions" do
      actions = [
        %{name: :action1, duration: "PT1H", conditions: %{}, effects: %{}},
        %{name: :action2, duration: "PT30M", conditions: %{}, effects: %{}}
      ]

      {:ok, conversions} = TemporalConverter.convert_batch(actions)

      assert length(conversions) == 2

      Enum.each(conversions, fn {simple_action, method_fn} ->
        assert is_map(simple_action)
        assert is_function(method_fn)
      end)
    end

    test "returns empty list for empty input" do
      {:ok, conversions} = TemporalConverter.convert_batch([])
      assert conversions == []
    end
  end
end
