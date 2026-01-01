# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Parser.RecursiveDescent do
  @moduledoc """
  HDDL parser using recursive descent parsing with pattern matching and AST transformation.

  This parser uses recursive descent parsing with pattern matching instead of
  NimbleParsec combinators, following a pattern-matching-based approach to code transformation.
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

      iex> AriaPlanner.HDDL.Parser.RecursiveDescent.parse("(define (domain test) ())")
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
    source
    |> String.to_charlist()
    |> tokenize([], [])
  rescue
    e -> {:error, "Tokenization error: #{inspect(e)}"}
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
  # Support common operators: <, >, <=, >=, =, +, -, *, /
  # Support decimal numbers: allow . when current token is a number
  defp tokenize([?. | rest], current, acc) when current != [] do
    # Check if current token is a number (all digits)
    current_str = List.to_string(Enum.reverse(current))

    if String.match?(current_str, ~r/^-?\d+$/) do
      # This is a decimal number, continue accumulating
      tokenize(rest, [?. | current], acc)
    else
      # Not a number, finish current token and treat . as unknown
      new_acc = [token_from_chars(current) | acc]
      tokenize([?. | rest], [], new_acc)
    end
  end

  defp tokenize([char | rest], current, acc)
       when char in ?a..?z or char in ?A..?Z or char in ?0..?9 or char in [?_, ?:, ?-, ??, ?=, ?<, ?>, ?+, ?*, ?/] do
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
      String.starts_with?(str, ":") ->
        keyword_str = String.slice(str, 1..-1//1)
        # Convert hyphens to underscores for keyword atoms
        keyword_atom = keyword_str |> String.replace("-", "_") |> String.to_atom()
        {:keyword, keyword_atom}

      String.starts_with?(str, "?") ->
        {:variable, str}

      String.match?(str, ~r/^-?\d+$/) ->
        {:number, String.to_integer(str)}

      String.match?(str, ~r/^-?\d+\.\d+$/) ->
        {:number, String.to_float(str)}

      str == "=" ->
        {:identifier, :=}

      true ->
        {:identifier, String.to_atom(str)}
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
    filtered_rest =
      Enum.reject(rest, fn
        {elem_list, _} when is_list(elem_list) -> elem_list == []
        _ -> false
      end)

    transform_define_content(list_sexp, filtered_rest)
  end

  defp transform_define_statement([{:identifier, :define} | rest]) do
    # Handle case where list_sexp might be a token instead of a tuple
    case rest do
      [list_sexp | remaining] ->
        filtered_rest =
          Enum.reject(remaining, fn
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
    filtered_rest =
      Enum.reject(rest, fn
        {elem_list, _} when is_list(elem_list) -> elem_list == []
        _ -> false
      end)

    transform_domain_or_problem(domain_list, filtered_rest)
  end

  defp transform_define_content(domain_list, rest) when is_list(domain_list) do
    # Filter out empty lists from rest before transforming
    filtered_rest =
      Enum.reject(rest, fn
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
    # Keep :domain reference in problem elements (tests expect it)
    # Transform domain reference to {:domain, domain_name} format
    transformed_rest =
      Enum.map(rest, fn
        {list, _} when is_list(list) ->
          case list do
            [{:keyword, :domain}, domain_name_token | _] ->
              domain_name = extract_name(domain_name_token)
              {:domain, domain_name}

            _ ->
              {list, []}
          end

        list when is_list(list) ->
          case list do
            [{:keyword, :domain}, domain_name_token | _] ->
              domain_name = extract_name(domain_name_token)
              {:domain, domain_name}

            _ ->
              list
          end

        other ->
          other
      end)

    elements = transform_elements(transformed_rest)
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

  # Standard HDDL constructs
  defp transform_list_element([{:keyword, :requirements} | rest]) do
    # Extract all requirement atoms
    reqs =
      Enum.map(rest, fn
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

  defp transform_list_element([{:keyword, :durative_action}, {:identifier, name} | action_elements]) do
    elements = transform_keyword_list(action_elements)
    {:durative_action, name, elements}
  end

  defp transform_list_element([{:keyword, :method}, {:identifier, name} | method_elements]) do
    elements = transform_keyword_list(method_elements)
    {:method, name, elements}
  end

  defp transform_list_element([{:keyword, :durative_method}, {:identifier, name} | method_elements]) do
    elements = transform_keyword_list(method_elements)
    {:durative_method, name, elements}
  end

  defp transform_list_element([{:keyword, :task}, task_spec | _rest]) do
    {:task, transform_element(task_spec)}
  end

  # aria_planner extensions - Commands
  defp transform_list_element([{:keyword, :command}, {:identifier, name} | command_elements]) do
    elements = transform_keyword_list(command_elements)
    {:command, name, elements}
  end

  # aria_planner extensions - Multigoals
  defp transform_list_element([{:keyword, :multigoal}, {:identifier, name} | multigoal_elements]) do
    elements = transform_keyword_list(multigoal_elements)
    {:multigoal, name, elements}
  end

  # aria_planner extensions - Goal methods
  defp transform_list_element([{:keyword, :goal_method}, {:identifier, name} | method_elements]) do
    elements = transform_keyword_list(method_elements)
    {:goal_method, name, elements}
  end

  defp transform_list_element([{:keyword, :"goal-method"}, {:identifier, name} | method_elements]) do
    elements = transform_keyword_list(method_elements)
    {:goal_method, name, elements}
  end

  # aria_planner extensions - Multigoal methods
  defp transform_list_element([{:keyword, :multigoal_method}, {:identifier, name} | method_elements]) do
    elements = transform_keyword_list(method_elements)
    {:multigoal_method, name, elements}
  end

  defp transform_list_element([{:keyword, :"multigoal-method"}, {:identifier, name} | method_elements]) do
    elements = transform_keyword_list(method_elements)
    {:multigoal_method, name, elements}
  end

  # aria_planner extensions - Domain metadata
  defp transform_list_element([{:keyword, :aria_domain_metadata} | metadata_elements]) do
    elements = transform_keyword_list(metadata_elements)
    {:aria_domain_metadata, elements}
  end

  defp transform_list_element([{:keyword, :"aria-domain-metadata"} | metadata_elements]) do
    elements = transform_keyword_list(metadata_elements)
    {:aria_domain_metadata, elements}
  end

  # aria_planner extensions - Entities
  defp transform_list_element([{:keyword, :entities} | entity_list]) do
    entities =
      Enum.map(entity_list, fn
        {list, _} when is_list(list) -> transform_entity(list)
        list when is_list(list) -> transform_entity(list)
        other -> transform_element(other)
      end)

    {:entities, entities}
  end

  # aria_planner extensions - Predicate schemas
  defp transform_list_element([{:keyword, :aria_predicate_schemas} | schema_list]) do
    schemas =
      Enum.map(schema_list, fn
        {list, _} when is_list(list) -> transform_predicate_schema(list)
        list when is_list(list) -> transform_predicate_schema(list)
        other -> transform_element(other)
      end)

    {:aria_predicate_schemas, schemas}
  end

  defp transform_list_element([{:keyword, :"aria-predicate-schemas"} | schema_list]) do
    schemas =
      Enum.map(schema_list, fn
        {list, _} when is_list(list) -> transform_predicate_schema(list)
        list when is_list(list) -> transform_predicate_schema(list)
        other -> transform_element(other)
      end)

    {:aria_predicate_schemas, schemas}
  end

  # aria_planner extensions - Planner state
  defp transform_list_element([{:keyword, :aria_initial_state} | state_elements]) do
    elements = transform_keyword_list(state_elements)
    {:aria_initial_state, elements}
  end

  defp transform_list_element([{:keyword, :"aria-initial-state"} | state_elements]) do
    elements = transform_keyword_list(state_elements)
    {:aria_initial_state, elements}
  end

  # aria_planner extensions - Plans
  defp transform_list_element([{:keyword, :aria_plan} | plan_elements]) do
    elements = transform_keyword_list(plan_elements)
    {:aria_plan, elements}
  end

  defp transform_list_element([{:keyword, :"aria-plan"} | plan_elements]) do
    elements = transform_keyword_list(plan_elements)
    {:aria_plan, elements}
  end

  # aria_planner extensions - Blacklisting
  defp transform_list_element([{:keyword, :aria_blacklist} | blacklist_elements]) do
    elements = transform_keyword_list(blacklist_elements)
    {:aria_blacklist, elements}
  end

  defp transform_list_element([{:keyword, :"aria-blacklist"} | blacklist_elements]) do
    elements = transform_keyword_list(blacklist_elements)
    {:aria_blacklist, elements}
  end

  # aria_planner extensions - Solution graph
  defp transform_list_element([{:keyword, :aria_solution_graph} | graph_elements]) do
    nodes =
      Enum.map(graph_elements, fn
        {list, _} when is_list(list) -> transform_solution_node(list)
        list when is_list(list) -> transform_solution_node(list)
        other -> transform_element(other)
      end)

    {:aria_solution_graph, nodes}
  end

  defp transform_list_element([{:keyword, :"aria-solution-graph"} | graph_elements]) do
    nodes =
      Enum.map(graph_elements, fn
        {list, _} when is_list(list) -> transform_solution_node(list)
        list when is_list(list) -> transform_solution_node(list)
        other -> transform_element(other)
      end)

    {:aria_solution_graph, nodes}
  end

  # aria_planner extensions - STN temporal constraints
  defp transform_list_element([{:keyword, :aria_temporal_constraints} | constraint_elements]) do
    elements = transform_keyword_list(constraint_elements)
    {:aria_temporal_constraints, elements}
  end

  defp transform_list_element([{:keyword, :"aria-temporal-constraints"} | constraint_elements]) do
    elements = transform_keyword_list(constraint_elements)
    {:aria_temporal_constraints, elements}
  end

  # aria_planner extensions - Temporal metadata (used in actions, methods, etc.)
  defp transform_list_element([{:keyword, :aria_temporal_metadata} | metadata_elements]) do
    elements = transform_keyword_list(metadata_elements)
    {:aria_temporal_metadata, elements}
  end

  defp transform_list_element([{:keyword, :"aria-temporal-metadata"} | metadata_elements]) do
    elements = transform_keyword_list(metadata_elements)
    {:aria_temporal_metadata, elements}
  end

  # aria_planner extensions - Command metadata
  defp transform_list_element([{:keyword, :aria_command_metadata} | metadata_elements]) do
    elements = transform_keyword_list(metadata_elements)
    {:aria_command_metadata, elements}
  end

  defp transform_list_element([{:keyword, :"aria-command-metadata"} | metadata_elements]) do
    elements = transform_keyword_list(metadata_elements)
    {:aria_command_metadata, elements}
  end

  # Generic keyword pattern (must come after specific patterns)
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
    transform_keyword_list(list, [])
  end

  @spec transform_keyword_list(list(), list()) :: list()
  defp transform_keyword_list([], acc), do: Enum.reverse(acc)

  defp transform_keyword_list([{:keyword, key}, value | rest], acc) do
    transformed_value =
      case value do
        {list, _} when is_list(list) -> transform_nested_structure(list, key)
        list when is_list(list) -> transform_nested_structure(list, key)
        other -> transform_element(other)
      end

    transform_keyword_list(rest, [{key, transformed_value} | acc])
  end

  defp transform_keyword_list([{:keyword, key} | rest], acc) do
    transform_keyword_list(rest, [{key, true} | acc])
  end

  defp transform_keyword_list([other | rest], acc) do
    # Handle nested lists (like aria extensions) that appear as values
    transformed =
      case other do
        {list, _} when is_list(list) ->
          # Check if this is an aria extension list
          case list do
            [{:keyword, aria_key} | aria_rest]
            when aria_key in [
                   :aria_temporal_metadata,
                   :aria_command_metadata,
                   :"aria-temporal-metadata",
                   :"aria-command-metadata"
                 ] ->
              # Transform as aria extension
              elements = transform_keyword_list(aria_rest)
              {aria_key, elements}

            _ ->
              # Transform as regular nested structure
              transform_list_element(list)
          end

        list when is_list(list) ->
          # Check if this is an aria extension list
          case list do
            [{:keyword, aria_key} | aria_rest]
            when aria_key in [
                   :aria_temporal_metadata,
                   :aria_command_metadata,
                   :"aria-temporal-metadata",
                   :"aria-command-metadata"
                 ] ->
              # Transform as aria extension
              elements = transform_keyword_list(aria_rest)
              {aria_key, elements}

            _ ->
              # Transform as regular nested structure
              transform_list_element(list)
          end

        {:keyword, :domain} ->
          # Domain reference in problem - include as-is
          {:domain, true}

        _ ->
          transform_element(other)
      end

    transform_keyword_list(rest, [transformed | acc])
  end

  # Transform nested structures based on key context
  @spec transform_nested_structure(list(), atom()) :: term()
  defp transform_nested_structure(list, :requires_entities) do
    # Transform (:entity type :capabilities (cap1 cap2 ...))
    Enum.map(list, fn
      {entity_list, _} when is_list(entity_list) -> transform_entity_requirement(entity_list)
      entity_list when is_list(entity_list) -> transform_entity_requirement(entity_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, :entity_capabilities) do
    # Transform (:entity id :capabilities (cap1 cap2 ...))
    Enum.map(list, fn
      {entity_list, _} when is_list(entity_list) -> transform_entity_capability(entity_list)
      entity_list when is_list(entity_list) -> transform_entity_capability(entity_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, :facts) do
    # Transform (:fact subject predicate :value value)
    Enum.map(list, fn
      {fact_list, _} when is_list(fact_list) -> transform_fact(fact_list)
      fact_list when is_list(fact_list) -> transform_fact(fact_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, :timeline) do
    # Transform (:event name :time "ISO8601")
    Enum.map(list, fn
      {event_list, _} when is_list(event_list) -> transform_timeline_event(event_list)
      event_list when is_list(event_list) -> transform_timeline_event(event_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, :objectives) do
    # Transform list of goal expressions
    Enum.map(list, &transform_element/1)
  end

  defp transform_nested_structure(list, :goals) do
    # Transform list of goal expressions
    Enum.map(list, &transform_element/1)
  end

  defp transform_nested_structure(list, :subtasks) do
    # Transform list of task expressions
    Enum.map(list, &transform_element/1)
  end

  defp transform_nested_structure(list, :constraints) do
    # Transform (:constraint name :type type :value value)
    Enum.map(list, fn
      {constraint_list, _} when is_list(constraint_list) -> transform_constraint(constraint_list)
      constraint_list when is_list(constraint_list) -> transform_constraint(constraint_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, :temporal_constraints) do
    # Transform (:constraint name :value "ISO8601")
    Enum.map(list, fn
      {constraint_list, _} when is_list(constraint_list) -> transform_temporal_constraint(constraint_list)
      constraint_list when is_list(constraint_list) -> transform_temporal_constraint(constraint_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, :risk_assessment) do
    # Transform (:risk name :probability prob)
    Enum.map(list, fn
      {risk_list, _} when is_list(risk_list) -> transform_risk(risk_list)
      risk_list when is_list(risk_list) -> transform_risk(risk_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, :performance_metrics) do
    # Transform (:metric name :value value)
    Enum.map(list, fn
      {metric_list, _} when is_list(metric_list) -> transform_metric(metric_list)
      metric_list when is_list(metric_list) -> transform_metric(metric_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, :blacklisted_commands) do
    # Transform list of command expressions
    Enum.map(list, &transform_element/1)
  end

  defp transform_nested_structure(list, :blacklisted_methods) do
    # Transform list of method expressions
    Enum.map(list, &transform_element/1)
  end

  defp transform_nested_structure(list, :stn) do
    # Transform STN structure with time points and constraints
    Enum.map(list, fn
      {stn_list, _} when is_list(stn_list) -> transform_stn_element(stn_list)
      stn_list when is_list(stn_list) -> transform_stn_element(stn_list)
      other -> transform_element(other)
    end)
  end

  defp transform_nested_structure(list, _key) do
    # Default: transform as list of elements
    Enum.map(list, &transform_element/1)
  end

  # Transform entity requirement: (:entity type :capabilities (cap1 cap2 ...))
  @spec transform_entity_requirement(list()) :: map()
  defp transform_entity_requirement([{:keyword, :entity}, type | rest]) do
    elements = transform_keyword_list(rest)
    %{type: :entity, entity_type: transform_element(type), capabilities: extract_capabilities(elements)}
  end

  defp transform_entity_requirement([{:identifier, :entity}, type | rest]) do
    elements = transform_keyword_list(rest)
    %{type: :entity, entity_type: transform_element(type), capabilities: extract_capabilities(elements)}
  end

  defp transform_entity_requirement(other), do: transform_element(other)

  # Transform entity capability: (:entity id :capabilities (cap1 cap2 ...))
  @spec transform_entity_capability(list()) :: map()
  defp transform_entity_capability([{:keyword, :entity}, id | rest]) do
    elements = transform_keyword_list(rest)
    %{type: :entity, entity_id: transform_element(id), capabilities: extract_capabilities(elements)}
  end

  defp transform_entity_capability([{:identifier, :entity}, id | rest]) do
    elements = transform_keyword_list(rest)
    %{type: :entity, entity_id: transform_element(id), capabilities: extract_capabilities(elements)}
  end

  defp transform_entity_capability(other), do: transform_element(other)

  # Extract capabilities from keyword list
  @spec extract_capabilities(list()) :: [atom()]
  defp extract_capabilities(elements) do
    case Keyword.get(elements, :capabilities) do
      list when is_list(list) ->
        Enum.map(list, fn
          {:keyword, cap} -> cap
          {:identifier, cap} -> cap
          atom when is_atom(atom) -> atom
          other -> transform_element(other)
        end)

      _ ->
        []
    end
  end

  # Transform entity: (:entity name :type type :capabilities (cap1 cap2 ...))
  @spec transform_entity(list()) :: map()
  defp transform_entity([{:keyword, :entity}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :entity,
      name: transform_element(name),
      entity_type: Keyword.get(elements, :type),
      capabilities: extract_capabilities(elements),
      metadata: Keyword.get(elements, :metadata, %{})
    }
  end

  defp transform_entity([{:identifier, :entity}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :entity,
      name: transform_element(name),
      entity_type: Keyword.get(elements, :type),
      capabilities: extract_capabilities(elements),
      metadata: Keyword.get(elements, :metadata, %{})
    }
  end

  defp transform_entity(other), do: transform_element(other)

  # Transform predicate schema: (:predicate name :category cat :multi-valued bool)
  @spec transform_predicate_schema(list()) :: map()
  defp transform_predicate_schema([{:keyword, :predicate}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :predicate,
      name: transform_element(name),
      category: Keyword.get(elements, :category),
      multi_valued: Keyword.get(elements, :"multi-valued", false),
      metadata: Keyword.get(elements, :metadata, %{})
    }
  end

  defp transform_predicate_schema([{:identifier, :predicate}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :predicate,
      name: transform_element(name),
      category: Keyword.get(elements, :category),
      multi_valued: Keyword.get(elements, :"multi-valued", false),
      metadata: Keyword.get(elements, :metadata, %{})
    }
  end

  defp transform_predicate_schema(other), do: transform_element(other)

  # Transform fact: (:fact predicate subject :value value)
  # Format: predicate comes first, then subject, then :value value
  @spec transform_fact(list()) :: map()
  defp transform_fact([{:keyword, :fact}, predicate, subject | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :fact,
      predicate: transform_element(predicate),
      subject: transform_element(subject),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_fact([{:identifier, :fact}, predicate, subject | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :fact,
      predicate: transform_element(predicate),
      subject: transform_element(subject),
      value: Keyword.get(elements, :value)
    }
  end

  # Backward compatibility: (:fact subject :value value) - predicate is implicit
  defp transform_fact([{:keyword, :fact}, subject | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :fact,
      subject: transform_element(subject),
      predicate: Keyword.get(elements, :predicate),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_fact([{:identifier, :fact}, subject | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :fact,
      subject: transform_element(subject),
      predicate: Keyword.get(elements, :predicate),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_fact(other), do: transform_element(other)

  # Transform timeline event: (:event name :time "ISO8601")
  @spec transform_timeline_event(list()) :: map()
  defp transform_timeline_event([{:keyword, :event}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :event,
      name: transform_element(name),
      time: Keyword.get(elements, :time)
    }
  end

  defp transform_timeline_event([{:identifier, :event}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :event,
      name: transform_element(name),
      time: Keyword.get(elements, :time)
    }
  end

  defp transform_timeline_event(other), do: transform_element(other)

  # Transform constraint: (:constraint name :type type :value value)
  @spec transform_constraint(list()) :: map()
  defp transform_constraint([{:keyword, :constraint}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :constraint,
      name: transform_element(name),
      constraint_type: Keyword.get(elements, :type),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_constraint([{:identifier, :constraint}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :constraint,
      name: transform_element(name),
      constraint_type: Keyword.get(elements, :type),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_constraint(other), do: transform_element(other)

  # Transform temporal constraint: (:constraint name :value "ISO8601")
  @spec transform_temporal_constraint(list()) :: map()
  defp transform_temporal_constraint([{:keyword, :constraint}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :temporal_constraint,
      name: transform_element(name),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_temporal_constraint([{:identifier, :constraint}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :temporal_constraint,
      name: transform_element(name),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_temporal_constraint(other), do: transform_element(other)

  # Transform risk: (:risk name :probability prob)
  @spec transform_risk(list()) :: map()
  defp transform_risk([{:keyword, :risk}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :risk,
      name: transform_element(name),
      probability: Keyword.get(elements, :probability)
    }
  end

  defp transform_risk([{:identifier, :risk}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :risk,
      name: transform_element(name),
      probability: Keyword.get(elements, :probability)
    }
  end

  defp transform_risk(other), do: transform_element(other)

  # Transform metric: (:metric name :value value)
  @spec transform_metric(list()) :: map()
  defp transform_metric([{:keyword, :metric}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :metric,
      name: transform_element(name),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_metric([{:identifier, :metric}, name | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :metric,
      name: transform_element(name),
      value: Keyword.get(elements, :value)
    }
  end

  defp transform_metric(other), do: transform_element(other)

  # Transform solution node: (:node id :type type :status status :info info :successors (id1 id2))
  @spec transform_solution_node(list()) :: map()
  defp transform_solution_node([{:keyword, :node}, id | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :node,
      node_id: transform_element(id),
      node_type: Keyword.get(elements, :type),
      status: Keyword.get(elements, :status),
      info: Keyword.get(elements, :info),
      successors: Keyword.get(elements, :successors, []),
      duration: Keyword.get(elements, :duration)
    }
  end

  defp transform_solution_node([{:identifier, :node}, id | rest]) do
    elements = transform_keyword_list(rest)

    %{
      type: :node,
      node_id: transform_element(id),
      node_type: Keyword.get(elements, :type),
      status: Keyword.get(elements, :status),
      info: Keyword.get(elements, :info),
      successors: Keyword.get(elements, :successors, []),
      duration: Keyword.get(elements, :duration)
    }
  end

  defp transform_solution_node(other), do: transform_element(other)

  # Transform STN element: (:time-point name) or (:constraint start end min max)
  @spec transform_stn_element(list()) :: map()
  defp transform_stn_element([{:keyword, :time_point}, name]) do
    %{type: :time_point, name: transform_element(name)}
  end

  defp transform_stn_element([{:keyword, :"time-point"}, name]) do
    %{type: :time_point, name: transform_element(name)}
  end

  defp transform_stn_element([{:keyword, :constraint}, start, end_point, min, max]) do
    %{
      type: :stn_constraint,
      start: transform_element(start),
      end: transform_element(end_point),
      min: transform_element(min),
      max: transform_element(max)
    }
  end

  defp transform_stn_element([{:identifier, :time_point}, name]) do
    %{type: :time_point, name: transform_element(name)}
  end

  defp transform_stn_element([{:identifier, :constraint}, start, end_point, min, max]) do
    %{
      type: :stn_constraint,
      start: transform_element(start),
      end: transform_element(end_point),
      min: transform_element(min),
      max: transform_element(max)
    }
  end

  defp transform_stn_element(other), do: transform_element(other)
end
