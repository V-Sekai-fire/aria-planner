# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.PointerResolver do
  @moduledoc """
  JSON Pointer resolution for glTF Interactivity Extension.

  Handles JSON pointer template parsing, parameter resolution, and property access
  against glTF assets according to RFC 6901 and glTF Interactivity Extension spec.
  """

  alias AriaPlanner.Domains.Interactivity.Types

  @doc """
  Parses a JSON pointer template string and extracts template parameters.

  Returns `{:ok, parameters}` where parameters is a list of `{socket_id, start, end}` tuples,
  or `{:error, reason}` if the template is invalid.

  Example:
      parse_template("/nodes/{nodeId}/scale")
      # => {:ok, [{"nodeId", 7, 14}]}
  """
  @spec parse_template(template :: String.t()) :: {:ok, list({String.t(), integer(), integer()})} | {:error, String.t()}
  def parse_template(template) when is_binary(template) do
    # Step 1: Initialize validity flag and parameter array
    validity = true
    parameters = []

    # Step 2: Basic JSON Pointer validation (must start with /)
    if String.starts_with?(template, "/") do
      # Step 3: Split at forward slashes
      segments = String.split(template, "/", trim: false)

      # Process segments
      {validity, parameters} = parse_segments(segments, template, validity, parameters, 0)

      if validity do
        {:ok, Enum.reverse(parameters)}
      else
        {:error, "Invalid JSON Pointer template syntax"}
      end
    else
      {:error, "JSON Pointer must start with '/"}
    end
  end

  def parse_template(_), do: {:error, "Template must be a string"}

  defp parse_segments([], _template, validity, parameters, _offset), do: {validity, parameters}

  defp parse_segments([segment | rest], template, validity, parameters, offset) do
    segment_start = offset + if offset == 0, do: 0, else: 1
    segment_end = segment_start + String.length(segment)

    {new_validity, new_parameters} =
      if validity do
        cond do
          # Step 4.1: Single left curly bracket
          segment == "{" ->
            {false, parameters}

          # Step 4.2: Template parameter (starts with { but not {{)
          String.starts_with?(segment, "{") and not String.starts_with?(segment, "{{") ->
            parse_template_parameter(segment, template, segment_start, segment_end, parameters)

          # Step 4.3: Literal path segment
          true ->
            # Check for odd number of consecutive curly brackets
            if has_odd_curly_brackets?(segment) do
              {false, parameters}
            else
              {validity, parameters}
            end
        end
      else
        # If validity is already false, keep it false but still validate the segment
        {false, parameters}
      end

    parse_segments(rest, template, new_validity, new_parameters, segment_end)
  end

  defp parse_template_parameter(segment, _template, start, _end, parameters) do
    # Check if segment ends with }
    if String.ends_with?(segment, "}") do
      # Check for curly brackets in the middle
      inner = String.slice(segment, 1..-2//1)

      if String.contains?(inner, "{") or String.contains?(inner, "}") do
        {false, parameters}
      else
        # Derive socket ID: strip { and }, replace ~1 with /, ~0 with ~
        socket_id =
          inner
          |> String.replace("~1", "/")
          |> String.replace("~0", "~")

        # Check for empty socket IDs (invalid)
        if socket_id == "" do
          {false, parameters}
        else
          # Check for duplicate socket IDs
          if Enum.any?(parameters, fn {id, _, _} -> id == socket_id end) do
            {false, parameters}
          else
            {true, [{socket_id, start, String.length(segment) + start} | parameters]}
          end
        end
      end
    else
      {false, parameters}
    end
  end

  defp has_odd_curly_brackets?(segment) do
    # Count consecutive { or } characters
    # Check if there are odd numbers of consecutive brackets
    left_pattern = ~r/\{+/
    right_pattern = ~r/\}+/

    left_matches = Regex.scan(left_pattern, segment) |> Enum.map(&length(List.first(&1)))
    right_matches = Regex.scan(right_pattern, segment) |> Enum.map(&length(List.first(&1)))

    left_odd = Enum.any?(left_matches, fn len -> rem(len, 2) != 0 end)
    right_odd = Enum.any?(right_matches, fn len -> rem(len, 2) != 0 end)

    left_odd or right_odd
  end

  @doc """
  Resolves a JSON pointer template with runtime parameter values.

  Takes a template string, a map of socket_id -> value, and generates the effective JSON pointer.

  Returns `{:ok, effective_pointer}` or `{:error, reason}`.
  """
  @spec resolve_template(template :: String.t(), parameters :: %{String.t() => integer()}) ::
          {:ok, String.t()} | {:error, String.t()}
  def resolve_template(template, parameters) when is_binary(template) and is_map(parameters) do
    case parse_template(template) do
      {:ok, param_list} ->
        # Replace each parameter in the template
        replace_parameters(template, param_list, parameters)

      error ->
        error
    end
  end

  defp replace_parameters(template, [], _parameters), do: {:ok, template}

  defp replace_parameters(template, param_list, parameters) do
    # Replace parameters in reverse order to preserve positions
    result =
      Enum.reduce_while(param_list, template, fn {socket_id, _start, _end}, acc ->
        param_value = Map.get(parameters, socket_id)

        if param_value == nil do
          {:halt, {:error, "Missing parameter: #{socket_id}"}}
        else
          # Replace {socket_id} with the value
          pattern = "{" <> socket_id <> "}"
          new_template = String.replace(acc, pattern, Integer.to_string(param_value), global: false)
          {:cont, new_template}
        end
      end)

    case result do
      {:error, _reason} = error -> error
      updated_template -> {:ok, updated_template}
    end
  end

  @doc """
  Gets a property value from a glTF asset using a JSON pointer.

  Returns `{value, is_valid}` tuple per specification.
  """
  @spec get_property(asset :: map(), pointer :: String.t(), expected_type :: String.t()) ::
          {term(), boolean()}
  def get_property(asset, pointer, expected_type) when is_map(asset) and is_binary(pointer) do
    case resolve_json_pointer(asset, pointer) do
      {:ok, value} ->
        # Validate type
        is_valid = Types.validate_type(value, expected_type)
        {value, is_valid}

      {:error, _reason} ->
        # Return default value with isValid=false
        default = Types.default_value(expected_type)
        {default, false}
    end
  end

  @doc """
  Sets a property value in a glTF asset using a JSON pointer.

  Returns `{:ok, updated_asset}` or `{:error, reason}`.
  """
  @spec set_property(asset :: map(), pointer :: String.t(), value :: term()) ::
          {:ok, map()} | {:error, String.t()}
  def set_property(asset, pointer, value) when is_map(asset) and is_binary(pointer) do
    case set_json_pointer(asset, pointer, value) do
      {:ok, updated} -> {:ok, updated}
      error -> error
    end
  end

  # Resolve JSON pointer against a map (RFC 6901)
  defp resolve_json_pointer(data, pointer) when is_binary(pointer) do
    if String.starts_with?(pointer, "/") do
      segments = String.split(pointer, "/", trim: true)
      resolve_segments(data, segments)
    else
      {:error, "JSON Pointer must start with '/'"}
    end
  end

  defp resolve_segments(data, []), do: {:ok, data}

  defp resolve_segments(data, [segment | rest]) when is_map(data) do
    # Decode JSON Pointer segment (replace ~1 with /, ~0 with ~)
    decoded = String.replace(segment, "~1", "/") |> String.replace("~0", "~")

    case Map.get(data, decoded) do
      nil -> {:error, "Property not found: #{decoded}"}
      value -> resolve_segments(value, rest)
    end
  end

  defp resolve_segments(data, [segment | rest]) when is_list(data) do
    # Decode segment
    decoded = String.replace(segment, "~1", "/") |> String.replace("~0", "~")

    case Integer.parse(decoded) do
      {index, ""} when index >= 0 and index < length(data) ->
        value = Enum.at(data, index)
        resolve_segments(value, rest)

      _ ->
        {:error, "Invalid array index: #{decoded}"}
    end
  end

  defp resolve_segments(_data, _segments), do: {:error, "Cannot traverse non-map/non-list value"}

  # Set JSON pointer value in a map (RFC 6901)
  defp set_json_pointer(data, pointer, value) when is_binary(pointer) do
    if String.starts_with?(pointer, "/") do
      segments = String.split(pointer, "/", trim: true)
      set_segments(data, segments, value)
    else
      {:error, "JSON Pointer must start with '/'"}
    end
  end

  defp set_segments(_data, [], value), do: {:ok, value}

  defp set_segments(data, [segment], value) when is_map(data) do
    decoded = String.replace(segment, "~1", "/") |> String.replace("~0", "~")
    updated = Map.put(data, decoded, value)
    {:ok, updated}
  end

  defp set_segments(data, [segment | rest], value) when is_map(data) do
    decoded = String.replace(segment, "~1", "/") |> String.replace("~0", "~")

    case Map.get(data, decoded) do
      nil ->
        # Property doesn't exist - create nested structure
        case set_segments(%{}, rest, value) do
          {:ok, nested_value} ->
            updated = Map.put(data, decoded, nested_value)
            {:ok, updated}

          error ->
            error
        end

      nested ->
        case set_segments(nested, rest, value) do
          {:ok, updated_nested} ->
            updated = Map.put(data, decoded, updated_nested)
            {:ok, updated}

          error ->
            error
        end
    end
  end

  defp set_segments(data, [segment | rest], value) when is_list(data) do
    decoded = String.replace(segment, "~1", "/") |> String.replace("~0", "~")

    case Integer.parse(decoded) do
      {index, ""} when index >= 0 and index < length(data) ->
        nested = Enum.at(data, index)

        case set_segments(nested, rest, value) do
          {:ok, updated_nested} ->
            updated_list = List.replace_at(data, index, updated_nested)
            {:ok, updated_list}

          error ->
            error
        end

      _ ->
        {:error, "Invalid array index: #{decoded}"}
    end
  end

  defp set_segments(_data, _segments, _value), do: {:error, "Cannot traverse non-map/non-list value"}
end
