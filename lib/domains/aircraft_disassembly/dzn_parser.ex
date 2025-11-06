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
              params = %{}
              params = parse_dzn_int(content, "nActs", params, :num_activities)
              params = parse_dzn_int(content, "nResources", params, :num_resources)
              params = parse_dzn_int(content, "nPrecs", params, :nPrecs)
              params = parse_dzn_int(content, "nLocations", params, :nLocations)
              params = parse_dzn_array(content, "dur", params, :durations)
              params = parse_dzn_array(content, "loc", params, :locations)
              params = parse_dzn_array(content, "loc_cap", params, :location_capacities)
              params = parse_dzn_precedence(content, params)
              {:ok, params}
            else
              {:ok, post_process(params)}
            end
          
          {:error, _reason, _, _, _, _} ->
            # Fallback to regex-based parsing if ABNF parsing fails
            params = %{}
            params = parse_dzn_int(content, "nActs", params, :num_activities)
            params = parse_dzn_int(content, "nResources", params, :num_resources)
            params = parse_dzn_int(content, "nPrecs", params, :nPrecs)
            params = parse_dzn_int(content, "nLocations", params, :nLocations)
            params = parse_dzn_array(content, "dur", params, :durations)
            params = parse_dzn_array(content, "loc", params, :locations)
            params = parse_dzn_array(content, "loc_cap", params, :location_capacities)
            params = parse_dzn_precedence(content, params)
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
      true -> val
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
        array_values = values
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
    
    pred_list = case Regex.run(pred_regex, content) do
      [_, values] when values != "" ->
        values
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.to_integer/1)
      _ -> []
    end
    
    succ_list = case Regex.run(succ_regex, content) do
      [_, values] when values != "" ->
        values
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.to_integer/1)
      _ -> []
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

  # Post-process to create precedence pairs
  defp post_process(params) do
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
end

