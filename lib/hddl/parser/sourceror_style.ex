# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Parser.SourcerorStyle do
  @moduledoc """
  HDDL parser using Sourceror-style pattern matching and AST transformation.

  This parser uses recursive descent parsing with pattern matching instead of
  NimbleParsec combinators, inspired by Sourceror's approach to code transformation.
  """

  @type token ::
          {:lparen, char()}
          | {:rparen, char()}
          | {:identifier, atom()}
          | {:keyword, atom()}
          | {:string, String.t()}
          | {:number, integer()}
          | {:variable, String.t()}
  @type parsed_sexp :: {list(), list()} | token()
  @type hddl_ast ::
          {:domain, atom() | String.t(), list()}
          | {:problem, atom() | String.t(), list()}
          | term()

  @doc """
  Parses HDDL source code into AST.

  ## Examples

      iex> AriaPlanner.HDDL.Parser.SourcerorStyle.parse("(define (domain test) ())")
      {:ok, {:domain, "test", []}}
  """
  @spec parse(String.t()) :: {:ok, hddl_ast()} | {:error, String.t()}
  def parse(source) when is_binary(source) do
    case tokenize_and_parse(source) do
      {:ok, ast} -> {:ok, transform_ast(ast)}
      error -> error
    end
  end

  @spec tokenize_and_parse(String.t()) :: {:ok, parsed_sexp()} | {:error, String.t()}
  defp tokenize_and_parse(source) do
    case tokenize(source) do
      {:ok, tokens} -> parse_sexp(tokens)
      error -> error
    end
  end

  # Expose tokenize for debugging (temporary)
  def __tokenize__(source), do: tokenize(source)

  @spec tokenize(String.t()) :: {:ok, [token()]} | {:error, String.t()}
  defp tokenize(source) do
    try do
      source
      |> String.to_charlist()
      |> tokenize([], [])
    rescue
      e -> {:error, "Tokenization error: #{inspect(e)}"}
    end
  end

  @spec tokenize([char()], [char()], [token()]) :: {:ok, [token()]} | {:error, String.t()}
  defp tokenize([], [], acc), do: {:ok, Enum.reverse(acc)}
  defp tokenize([], current, acc) when current != [], do: {:ok, Enum.reverse([token_from_chars(current) | acc])}

  # When we have a current token and hit whitespace/paren/string/comment, finish token first
  defp tokenize([char | rest], current, acc)
       when current != [] and char in [?\s, ?\t, ?\n, ?\r, ?(, ?), ?", ?;] do
    new_acc = [token_from_chars(current) | acc]
    tokenize([char | rest], [], new_acc)
  end

  # Whitespace - skip when no current token
  defp tokenize([?\s | rest], [], acc), do: tokenize(rest, [], acc)
  defp tokenize([?\t | rest], [], acc), do: tokenize(rest, [], acc)
  defp tokenize([?\n | rest], [], acc), do: tokenize(rest, [], acc)
  defp tokenize([?\r | rest], [], acc), do: tokenize(rest, [], acc)

  # Comments
  @spec tokenize([char()], [char()], [token()]) :: {:ok, [token()]} | {:error, String.t()}
  defp tokenize([?; | rest], [], acc) do
    {comment_rest, _comment} = consume_until_newline(rest, [])
    tokenize(comment_rest, [], acc)
  end

  # String literals
  @spec tokenize([char()], [char()], [token()]) :: {:ok, [token()]} | {:error, String.t()}
  defp tokenize([?" | rest], [], acc) do
    case consume_string(rest, []) do
      {:error, reason} ->
        {:error, reason}

      {string_rest, string_chars} ->
        token = {:string, List.to_string(string_chars)}
        tokenize(string_rest, [], [token | acc])
    end
  end

  # Parentheses
  defp tokenize([?( | rest], [], acc), do: tokenize(rest, [], [{:lparen, ?(} | acc])
  defp tokenize([?) | rest], [], acc), do: tokenize(rest, [], [{:rparen, ?)} | acc])

  # Accumulate identifier/keyword/number/variable (works for both empty and non-empty current)
  # This must come before the "unknown character" patterns
  defp tokenize([char | rest], current, acc)
       when char in ?a..?z or char in ?A..?Z or char in ?0..?9 or char in [?_, ?:, ?-, ??] do
    tokenize(rest, [char | current], acc)
  end

  # Unknown character when we have a current token - finish token and retry
  defp tokenize([char | rest], current, acc) when current != [] do
    new_acc = [token_from_chars(current) | acc]
    tokenize([char | rest], [], new_acc)
  end

  # Unknown character with no current token - this should rarely happen if patterns are correct
  defp tokenize([char | _rest], [], _acc) do
    {:error, "Unexpected character: #{<<char>>} (code: #{char})"}
  end

  @spec consume_until_newline([char()], [char()]) :: {[char()], [char()]}
  defp consume_until_newline([?\n | rest], _acc), do: {rest, []}
  defp consume_until_newline([], acc), do: {[], acc}
  defp consume_until_newline([char | rest], acc), do: consume_until_newline(rest, [char | acc])

  @spec consume_string([char()], [char()]) :: {[char()], [char()]} | {:error, String.t()}
  defp consume_string([?" | rest], acc), do: {rest, Enum.reverse(acc)}
  defp consume_string([?\\, ?" | rest], acc), do: consume_string(rest, [?" | acc])
  defp consume_string([char | rest], acc), do: consume_string(rest, [char | acc])
  defp consume_string([], _acc), do: {:error, "Unterminated string"}

  @spec token_from_chars([char()]) :: token()
  defp token_from_chars(chars) do
    str = List.to_string(Enum.reverse(chars))

    cond do
      String.starts_with?(str, ":") -> {:keyword, String.to_atom(String.slice(str, 1..-1//1))}
      String.starts_with?(str, "?") -> {:variable, str}
      String.match?(str, ~r/^-?\d+$/) -> {:number, String.to_integer(str)}
      true -> {:identifier, String.to_atom(str)}
    end
  end

  # Expose parse_sexp for debugging (temporary)
  def __parse_sexp__(tokens), do: parse_sexp(tokens)

  # Parse S-expressions from tokens
  @spec parse_sexp([token()]) :: {:ok, parsed_sexp()} | {:error, String.t()}
  defp parse_sexp([]), do: {:error, "Unexpected end of input"}

  defp parse_sexp([{:lparen, _} | rest]) do
    case parse_list(rest, []) do
      {:ok, {list, remaining}} -> {:ok, {list, remaining}}
      error -> error
    end
  end

  defp parse_sexp([token | rest]) when elem(token, 0) in [:identifier, :keyword, :string, :number, :variable] do
    {:ok, {token, rest}}
  end

  defp parse_sexp([{:rparen, _} | _rest]), do: {:error, "Unexpected closing parenthesis"}

  @spec parse_list([token()], list()) :: {:ok, {list(), [token()]}} | {:error, String.t()}
  defp parse_list([{:rparen, _} | rest], acc), do: {:ok, {Enum.reverse(acc), rest}}
  defp parse_list([], _acc), do: {:error, "Unterminated list"}

  defp parse_list(tokens, acc) do
    case parse_sexp(tokens) do
      {:ok, {item, remaining}} -> parse_list(remaining, [item | acc])
      error -> error
    end
  end

  # Transform parsed AST into HDDL structure
  @spec transform_ast(parsed_sexp()) :: hddl_ast()
  defp transform_ast({list, _remaining}) when is_list(list) do
    transform_define_statement(list)
  end

  defp transform_ast(other), do: transform_element(other)

  # Extract helper to reduce nesting depth (fixes Credo issue)
  @spec transform_define_statement(list()) :: hddl_ast()
  defp transform_define_statement([{:identifier, :define}, list_sexp | rest]) do
    # Filter out empty lists from rest (empty () becomes {[], _})
    filtered_rest = Enum.reject(rest, fn
      {elem_list, _} when is_list(elem_list) -> elem_list == []
      _ -> false
    end)
    transform_define_content(list_sexp, filtered_rest)
  end

  defp transform_define_statement([{:identifier, :define} | rest]) do
    # Handle case where list_sexp might be a token instead of a tuple
    case rest do
      [list_sexp | remaining] ->
        filtered_rest = Enum.reject(remaining, fn
          {elem_list, _} when is_list(elem_list) -> elem_list == []
          _ -> false
        end)
        transform_define_content(list_sexp, filtered_rest)
      _ ->
        {:domain, :unknown, []}
    end
  end

  defp transform_define_statement(list), do: transform_element({list, []})

  @spec transform_define_content(parsed_sexp(), list()) :: hddl_ast()
  defp transform_define_content({domain_list, _}, rest) when is_list(domain_list) do
    # Filter out empty lists from rest before transforming
    filtered_rest = Enum.reject(rest, fn
      {elem_list, _} when is_list(elem_list) -> elem_list == []
      _ -> false
    end)
    transform_domain_or_problem(domain_list, filtered_rest)
  end

  defp transform_define_content(domain_list, rest) when is_list(domain_list) do
    # Filter out empty lists from rest before transforming
    filtered_rest = Enum.reject(rest, fn
      {elem_list, _} when is_list(elem_list) -> elem_list == []
      _ -> false
    end)
    transform_domain_or_problem(domain_list, filtered_rest)
  end

  defp transform_define_content(_other, _rest), do: {:domain, :unknown, []}

  @spec transform_domain_or_problem(list(), list()) :: hddl_ast()
  defp transform_domain_or_problem([{:identifier, :domain}, name_token | _], rest) do
    name = extract_name(name_token)
    elements = transform_elements(rest)
    {:domain, name, elements}
  end

  defp transform_domain_or_problem([{:identifier, :problem}, name_token | _], rest) do
    name = extract_name(name_token)
    elements = transform_elements(rest)
    {:problem, name, elements}
  end

  defp transform_domain_or_problem(_other, _rest), do: {:domain, :unknown, []}

  @spec transform_elements(list()) :: list()
  defp transform_elements(rest) do
    rest
    |> Enum.reject(fn
      {elem_list, _} when is_list(elem_list) -> elem_list == []
      elem_list when is_list(elem_list) -> elem_list == []
      _ -> false
    end)
    |> Enum.map(fn
      {elem_list, _} when is_list(elem_list) ->
        # elem_list is a list of tokens from the S-expression
        # For (:requirements :strips), elem_list is [{:keyword, :requirements}, {:keyword, :strips}]
        # parse_list accumulates items directly (not wrapped in {item, remaining} tuples)
        # So elem_list is already a list of tokens, not a list of {item, remaining} tuples
        transform_list_element(elem_list)
      elem_list when is_list(elem_list) ->
        # Handle case where rest contains plain lists (not wrapped in tuples)
        # This happens when parse_list returns a list directly
        transform_list_element(elem_list)
      other ->
        transform_element(other)
    end)
  end

  @spec extract_name(parsed_sexp() | token()) :: atom() | String.t()
  defp extract_name({list, _}) when is_list(list) do
    case list do
      [{:identifier, name} | _] -> name
      [{:string, name} | _] -> name
      _ -> :unknown
    end
  end

  defp extract_name({:identifier, name}), do: name
  defp extract_name({:string, name}), do: name

  defp extract_name({token, _}) when is_tuple(token) and tuple_size(token) == 2 do
    case token do
      {:identifier, name} -> name
      {:string, name} -> name
      _ -> :unknown
    end
  end

  defp extract_name(other) when is_tuple(other) and tuple_size(other) == 2 do
    case other do
      {:identifier, name} -> name
      {:string, name} -> name
      _ -> :unknown
    end
  end

  defp extract_name(_), do: :unknown

  @spec transform_element(parsed_sexp() | token() | term()) :: term()
  defp transform_element({list, _}) when is_list(list) do
    transform_list_element(list)
  end

  defp transform_element({:keyword, key}), do: key
  defp transform_element({:identifier, id}), do: id
  defp transform_element({:string, str}), do: str
  defp transform_element({:number, num}), do: num
  defp transform_element({:variable, var}), do: var
  defp transform_element({tag, value}) when is_atom(tag), do: {tag, value}
  defp transform_element(other), do: other

  @spec transform_list_element(list()) :: term()
  # Specific patterns must come first - use function clause pattern matching
  defp transform_list_element([{:keyword, :requirements} | rest]) do
    # Extract all requirement atoms
    reqs = Enum.map(rest, fn
      {:keyword, req} -> req
      other -> transform_element(other)
    end)
    {:requirements, reqs}
  end

  defp transform_list_element([{:keyword, :predicates} | predicates]) do
    {:predicates, Enum.map(predicates, &transform_element/1)}
  end

  defp transform_list_element([{:keyword, :action}, {:identifier, name} | action_elements]) do
    elements = transform_keyword_list(action_elements)
    {:action, name, elements}
  end

  defp transform_list_element([{:keyword, key} | values]) do
    {key, Enum.map(values, &transform_element/1)}
  end

  # Catch-all for other lists - must come last
  defp transform_list_element(items) when is_list(items) do
    # Transform each item individually
    Enum.map(items, &transform_element/1)
  end

  @spec transform_keyword_list(list()) :: list()
  defp transform_keyword_list(list) do
    list
    |> Enum.chunk_every(2)
    |> Enum.reduce([], fn
      [{:keyword, key}, value], acc -> [{key, transform_element(value)} | acc]
      [{:keyword, key}], acc -> [{key, true} | acc]
      _other, acc -> acc
    end)
    |> Enum.reverse()
  end
end
