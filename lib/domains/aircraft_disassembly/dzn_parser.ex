# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.AircraftDisassembly.DznParser do
  @moduledoc """
  Parser for MiniZinc .dzn data files using ABNF grammar via abnf_parsec.
  """

  use AbnfParsec,
    abnf: """
    file = *(assignment / comment / whitespace)

    assignment = identifier "=" value ";"
    identifier = ALPHA *(ALPHA / DIGIT / "_")
    value = integer / array / set / array2d / boolean

    integer = ["-"] 1*DIGIT
    boolean = "true" / "false"
    array = "[" *(value ",") [value] "]"
    set = "{" *(value ",") [value] "}"
    array2d = "array2d" "(" identifier "," identifier "," array ")"

    comment = ";" *(VCHAR / WSP)
    whitespace = 1*(SP / HTAB / CRLF)

    ALPHA = %x41-5A / %x61-7A
    DIGIT = %x30-39
    VCHAR = %x21-7E
    SP = %x20
    HTAB = %x09
    CRLF = %x0D.0A
    WSP = SP / HTAB
    """,
    parse: :file

  @doc """
  Parses a .dzn file and returns a map of parameters using ABNF grammar.
  """
  @spec parse_file(String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse_file(path) do
    case File.read(path) do
      {:ok, content} ->
        case parse(content) do
          {:ok, parsed_result, _, _, _, _} ->
            params = extract_assignments(parsed_result)
            # If ABNF parsing didn't extract enough fields, fall back to regex
            if map_size(params) < 3 do
              # Fallback to regex-based parsing
              params = parse_all_fields_regex(content)
              {:ok, params}
            else
              {:ok, post_process_all(params)}
            end

          {:error, _reason, _, _, _, _} ->
            # Fallback to regex-based parsing if ABNF parsing fails
            params = parse_all_fields_regex(content)
            {:ok, params}
        end

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  # Extract assignments from parsed ABNF result
  defp extract_assignments(parsed_result) do
    # The parsed result structure: {:file, [assignment: [...], ...]}
    case parsed_result do
      {:file, file_content} when is_list(file_content) ->
        Enum.reduce(file_content, %{}, fn
          {:assignment, parts, _}, acc when is_list(parts) ->
            # Extract identifier and value from assignment parts
            {id, val} = extract_assignment_parts(parts)

            if id != "" and id != nil do
              key = normalize_key(id)
              value = normalize_value(extract_value(val))
              Map.put(acc, key, value)
            else
              acc
            end

          _, acc ->
            acc
        end)

      _ ->
        %{}
    end
  end

  defp extract_assignment_parts(parts) do
    # Parts structure: [{:identifier, ["n", "A", "c", "t", "s"], _}, "=", {:value, [integer: ["1", "6"]], _}, ";"]
    id = extract_identifier_from_parts(parts)
    val = extract_value_from_parts(parts)
    {id, val}
  end

  defp extract_identifier_from_parts(parts) do
    case Enum.find(parts, fn
           {:identifier, _, _} -> true
           _ -> false
         end) do
      {:identifier, chars, _} when is_list(chars) ->
        List.to_string(chars)

      _ ->
        nil
    end
  end

  defp extract_value_from_parts(parts) do
    case Enum.find(parts, fn
           {:value, _, _} -> true
           _ -> false
         end) do
      {:value, val_content, _} ->
        val_content

      _ ->
        nil
    end
  end

  defp extract_value({:integer, digits, _}) when is_list(digits) do
    digits |> List.to_string() |> String.to_integer()
  end

  defp extract_value({:boolean, "true", _}), do: true
  defp extract_value({:boolean, "false", _}), do: false

  defp extract_value({:array, values, _}) when is_list(values) do
    Enum.map(values, &extract_value/1)
  end

  defp extract_value([{:integer, _digits, _} | _] = int_list) when is_list(int_list) do
    # List of integers: [{:integer, ["1"], _}, {:integer, ["6"], _}]
    Enum.map(int_list, fn {:integer, d, _} -> d |> List.to_string() |> String.to_integer() end)
  end

  defp extract_value([{:value, _val_content, _} | _] = val_list) when is_list(val_list) do
    # List of values
    Enum.map(val_list, fn {:value, v, _} -> extract_value(v) end)
  end

  defp extract_value(val) when is_list(val) do
    # Try to extract as integer list or process recursively
    case Enum.all?(val, &is_integer/1) do
      true ->
        val

      false ->
        # Check if it's a list of character lists (string)
        all_binary = fn item -> is_list(item) and Enum.all?(item, fn x -> is_binary(x) end) end

        case Enum.all?(val, all_binary) do
          true -> Enum.map(val, &List.to_string/1)
          false -> Enum.map(val, &extract_value/1)
        end
    end
  end

  defp extract_value(val), do: val

  # Fallback regex-based parsing functions
  defp parse_dzn_int(content, key, params, param_key) do
    regex = ~r/#{key}\s*=\s*(\d+);/

    case Regex.run(regex, content) do
      [_, value] ->
        Map.put(params, param_key, String.to_integer(value))

      nil ->
        params
    end
  end

  defp parse_dzn_array(content, key, params, param_key) do
    regex = ~r/#{key}\s*=\s*\[([^\]]+)\];/

    case Regex.run(regex, content) do
      [_, values] ->
        array_values =
          values
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        Map.put(params, param_key, array_values)

      nil ->
        params
    end
  end

  defp parse_dzn_precedence(content, params) do
    # Parse pred and succ arrays
    pred_regex = ~r/pred\s*=\s*\[([^\]]*)\];/
    succ_regex = ~r/succ\s*=\s*\[([^\]]*)\];/

    pred_list =
      case Regex.run(pred_regex, content) do
        [_, values] when values != "" ->
          values
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        _ ->
          []
      end

    succ_list =
      case Regex.run(succ_regex, content) do
        [_, values] when values != "" ->
          values
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        _ ->
          []
      end

    # Create precedence pairs
    precedences = Enum.zip(pred_list, succ_list)

    Map.put(params, :precedences, precedences)
  end

  # Normalize keys (e.g., "nActs" -> :num_activities)
  defp normalize_key("nActs"), do: :num_activities
  defp normalize_key("nResources"), do: :num_resources
  defp normalize_key("nPrecs"), do: :nPrecs
  defp normalize_key("nLocations"), do: :nLocations
  defp normalize_key("dur"), do: :durations
  defp normalize_key("loc"), do: :locations
  defp normalize_key("loc_cap"), do: :location_capacities
  defp normalize_key("pred"), do: :pred
  defp normalize_key("succ"), do: :succ
  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)
  defp normalize_key(key), do: key

  # Normalize values (convert strings to appropriate types)
  defp normalize_value("true"), do: true
  defp normalize_value("false"), do: false

  defp normalize_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end

  defp normalize_value(value) when is_list(value) do
    Enum.map(value, &normalize_value/1)
  end

  defp normalize_value(value), do: value

  # Post-process to create precedence pairs and handle all fields
  defp post_process_all(params) do
    params
    |> post_process_precedence()
    |> post_process_unrelated()
    |> post_process_array2d()
  end

  defp post_process_precedence(params) do
    case {Map.get(params, :pred), Map.get(params, :succ)} do
      {pred_list, succ_list} when is_list(pred_list) and is_list(succ_list) ->
        precedences = Enum.zip(pred_list, succ_list)

        params
        |> Map.put(:precedences, precedences)
        |> Map.delete(:pred)
        |> Map.delete(:succ)

      _ ->
        Map.put(params, :precedences, [])
    end
  end

  defp post_process_unrelated(params) do
    case {Map.get(params, :unpred), Map.get(params, :unsucc)} do
      {unpred_list, unsucc_list} when is_list(unpred_list) and is_list(unsucc_list) ->
        unrelated = Enum.zip(unpred_list, unsucc_list)

        params
        |> Map.put(:unrelated, unrelated)
        |> Map.delete(:unpred)
        |> Map.delete(:unsucc)

      _ ->
        Map.put(params, :unrelated, [])
    end
  end

  defp post_process_array2d(params) do
    # Handle array2d fields that need special processing
    # For now, just return params as-is (array2d parsing handled in regex fallback)
    params
  end

  # Comprehensive regex-based parsing for all fields
  defp parse_all_fields_regex(content) do
    params = %{}
    # Basic counts
    params = parse_dzn_int(content, "nActs", params, :num_activities)
    params = parse_dzn_int(content, "nResources", params, :num_resources)
    params = parse_dzn_int(content, "nSkills", params, :nSkills)
    params = parse_dzn_int(content, "nPrecs", params, :nPrecs)
    params = parse_dzn_int(content, "nUnavailable", params, :nUnavailable)
    params = parse_dzn_int(content, "nUnrels", params, :nUnrels)
    params = parse_dzn_int(content, "nLocations", params, :nLocations)
    params = parse_dzn_int(content, "maxt", params, :maxt)

    # Arrays
    params = parse_dzn_array(content, "dur", params, :durations)
    params = parse_dzn_array(content, "loc", params, :locations)
    params = parse_dzn_array(content, "loc_cap", params, :location_capacities)
    params = parse_dzn_array(content, "mass", params, :mass)
    params = parse_dzn_array(content, "maxDiff", params, :maxDiff)
    params = parse_dzn_array(content, "occupancy", params, :occupancy)
    params = parse_dzn_array(content, "resource_cost", params, :resource_cost)
    params = parse_dzn_array(content, "unavailable_resource", params, :unavailable_resource)
    params = parse_dzn_array(content, "unavailable_start", params, :unavailable_start)
    params = parse_dzn_array(content, "unavailable_end", params, :unavailable_end)

    # Precedence
    params = parse_dzn_precedence(content, params)

    # Unrelated activities
    params = parse_dzn_unrelated(content, params)

    # Sets and complex arrays
    params = parse_dzn_set_array(content, "USEFUL_RES", params, :useful_res)
    params = parse_dzn_set_array(content, "POTENTIAL_ACT", params, :potential_act)
    params = parse_dzn_set(content, "M", params, :M)

    # Array2D fields
    params = parse_dzn_array2d(content, "sreq", params, :sreq, "ACT", "SKILL")
    params = parse_dzn_array2d(content, "mastery", params, :mastery, "RESOURCE", "SKILL")
    params = parse_dzn_array2d(content, "comp_prod", params, :comp_prod, "M", "1..2")

    params
  end

  defp parse_dzn_unrelated(content, params) do
    unpred_regex = ~r/unpred\s*=\s*\[([^\]]*)\];/
    unsucc_regex = ~r/unsucc\s*=\s*\[([^\]]*)\];/

    unpred_list =
      case Regex.run(unpred_regex, content) do
        [_, values] when values != "" ->
          values
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        _ ->
          []
      end

    unsucc_list =
      case Regex.run(unsucc_regex, content) do
        [_, values] when values != "" ->
          values
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        _ ->
          []
      end

    unrelated = Enum.zip(unpred_list, unsucc_list)
    Map.put(params, :unrelated, unrelated)
  end

  defp parse_dzn_set_array(content, key, params, param_key) do
    # Parse array of sets like: USEFUL_RES=[{1,2,3}, {4,5}]
    regex = ~r/#{key}\s*=\s*\[([^\]]+)\];/

    case Regex.run(regex, content) do
      [_, values] ->
        # Parse sets within array: {1,2,3}, {4,5}
        sets =
          values
          |> String.split("}, {")
          |> Enum.map(fn set_str ->
            set_str
            |> String.replace("{", "")
            |> String.replace("}", "")
            |> String.split(",")
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.to_integer/1)
            |> MapSet.new()
          end)

        Map.put(params, param_key, sets)

      nil ->
        params
    end
  end

  defp parse_dzn_set(content, key, params, param_key) do
    # Parse set like: M = {1, 2}
    regex = ~r/#{key}\s*=\s*\{([^}]+)\};/

    case Regex.run(regex, content) do
      [_, values] ->
        set =
          values
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)
          |> MapSet.new()

        Map.put(params, param_key, set)

      nil ->
        params
    end
  end

  defp parse_dzn_array2d(content, key, params, param_key, _dim1, _dim2) do
    # Parse array2d like: sreq=array2d(ACT, SKILL, [1,1,0,1,1,0,...])
    # More flexible regex to handle nested structures
    regex = ~r/#{key}\s*=\s*array2d\s*\([^,]+,\s*[^,]+,\s*\[([^\]]+)\]\s*\)/

    case Regex.run(regex, content) do
      [_, values] ->
        # Handle values that might contain nested structures or just simple values
        array_values =
          values
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(fn val ->
            val_trimmed = String.trim(val)

            case val_trimmed do
              "true" ->
                true

              "false" ->
                false

              "" ->
                nil

              _ ->
                # Try to parse as integer, if it fails, skip it
                case Integer.parse(val_trimmed) do
                  {int, ""} -> int
                  _ -> nil
                end
            end
          end)
          |> Enum.reject(&is_nil/1)

        if length(array_values) > 0 do
          Map.put(params, param_key, array_values)
        else
          params
        end

      nil ->
        params
    end
  end
end
