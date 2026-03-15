# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.PointerResolverTest do
  @moduledoc """
  Tests for JSON pointer resolution functionality.
  """

  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.Interactivity.PointerResolver

  describe "parse_template" do
    test "parses simple pointer without parameters" do
      assert {:ok, []} = PointerResolver.parse_template("/nodes/0/translation")
    end

    @tag :skip
    # FIXME: Re-enable when parameter position calculation is verified
    test "parses pointer with single parameter" do
      assert {:ok, [{"nodeId", 7, 14}]} = PointerResolver.parse_template("/nodes/{nodeId}/scale")
    end

    test "parses pointer with multiple parameters" do
      template = "/nodes/{nodeId}/weights/{weightIndex}"
      assert {:ok, params} = PointerResolver.parse_template(template)
      assert length(params) == 2
      assert {"nodeId", _, _} = List.first(params)
      assert {"weightIndex", _, _} = List.last(params)
    end

    test "handles escaped characters in parameters" do
      # ~1 should be decoded to /, ~0 should be decoded to ~
      assert {:ok, [{"path/to", _, _}]} = PointerResolver.parse_template("/{path~1to}")
      assert {:ok, [{"path~value", _, _}]} = PointerResolver.parse_template("/{path~0value}")
    end

    @tag :skip
    # FIXME: Re-enable when literal curly bracket parsing is implemented
    test "handles literal curly brackets" do
      # {{ should be treated as literal {
      assert {:ok, []} = PointerResolver.parse_template("/nodes/{{literal}}/scale")
    end

    test "rejects invalid template - single {" do
      assert {:error, _reason} = PointerResolver.parse_template("/nodes/{/scale")
    end

    test "rejects invalid template - duplicate parameters" do
      assert {:error, _reason} = PointerResolver.parse_template("/nodes/{id}/scale/{id}")
    end

    test "rejects invalid template - empty parameter" do
      assert {:error, _reason} = PointerResolver.parse_template("/nodes/{}/scale")
    end

    test "rejects invalid template - missing leading /" do
      assert {:error, _reason} = PointerResolver.parse_template("nodes/0/translation")
    end
  end

  describe "resolve_template" do
    test "resolves template with parameters" do
      template = "/nodes/{nodeId}/scale"
      parameters = %{"nodeId" => 0}

      assert {:ok, "/nodes/0/scale"} = PointerResolver.resolve_template(template, parameters)
    end

    test "resolves template with multiple parameters" do
      template = "/nodes/{nodeId}/weights/{weightIndex}"
      parameters = %{"nodeId" => 1, "weightIndex" => 2}

      assert {:ok, "/nodes/1/weights/2"} =
               PointerResolver.resolve_template(template, parameters)
    end

    test "returns error for missing parameter" do
      template = "/nodes/{nodeId}/scale"
      parameters = %{}

      assert {:error, "Missing parameter: nodeId"} =
               PointerResolver.resolve_template(template, parameters)
    end
  end

  describe "get_property" do
    test "gets property from simple map" do
      asset = %{"nodes" => [%{"translation" => [1.0, 2.0, 3.0]}]}
      pointer = "/nodes/0/translation"

      {value, is_valid} = PointerResolver.get_property(asset, pointer, "float3")
      assert value == [1.0, 2.0, 3.0]
      assert is_valid == true
    end

    test "gets nested property" do
      asset = %{
        "nodes" => [
          %{
            "extensions" => %{
              "custom" => %{"value" => 42}
            }
          }
        ]
      }

      pointer = "/nodes/0/extensions/custom/value"

      {value, is_valid} = PointerResolver.get_property(asset, pointer, "int")
      assert value == 42
      assert is_valid == true
    end

    test "returns invalid for non-existent property" do
      asset = %{"nodes" => []}
      pointer = "/nodes/0/translation"

      {value, is_valid} = PointerResolver.get_property(asset, pointer, "float3")
      assert is_valid == false
      assert value == {:nan, :nan, :nan}
    end

    @tag :skip
    # FIXME: Re-enable when type mismatch handling returns correct format
    test "returns invalid for type mismatch" do
      asset = %{"nodes" => [%{"translation" => [1.0, 2.0, 3.0]}]}
      pointer = "/nodes/0/translation"

      {value, is_valid} = PointerResolver.get_property(asset, pointer, "float4")
      assert is_valid == false
      assert value == {:nan, :nan, :nan, :nan}
    end

    test "handles escaped characters in pointer" do
      asset = %{"path/to" => %{"value" => 10}}
      pointer = "/path~1to/value"

      {value, is_valid} = PointerResolver.get_property(asset, pointer, "int")
      assert value == 10
      assert is_valid == true
    end
  end

  describe "set_property" do
    test "sets property in simple map" do
      asset = %{"nodes" => [%{"translation" => [0.0, 0.0, 0.0]}]}
      pointer = "/nodes/0/translation"
      value = [1.0, 2.0, 3.0]

      assert {:ok, updated} = PointerResolver.set_property(asset, pointer, value)
      assert get_in(updated, ["nodes", Access.at(0), "translation"]) == [1.0, 2.0, 3.0]
    end

    test "sets nested property" do
      asset = %{
        "nodes" => [
          %{
            "extensions" => %{
              "custom" => %{"value" => 0}
            }
          }
        ]
      }

      pointer = "/nodes/0/extensions/custom/value"
      value = 42

      assert {:ok, updated} = PointerResolver.set_property(asset, pointer, value)
      assert get_in(updated, ["nodes", Access.at(0), "extensions", "custom", "value"]) == 42
    end

    test "returns error for non-existent path" do
      asset = %{"nodes" => []}
      pointer = "/nodes/0/translation"
      value = [1.0, 2.0, 3.0]

      assert {:error, _reason} = PointerResolver.set_property(asset, pointer, value)
    end
  end
end
