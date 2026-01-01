# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Parser do
  @moduledoc """
  Parser for HDDL 2.1 + aria_planner extensions.

  Parses HDDL (Hierarchical Domain Definition Language) syntax into structured AST.
  Supports full HDDL 2.1 syntax and aria_planner-specific extensions.

  HDDL uses Lisp-like S-expression syntax. This parser handles:
  - Domain definitions: `(define (domain <name>) ...)`
  - Problem definitions: `(define (problem <name>) ...)`
  - Actions, durative actions, methods, commands
  - aria_planner extensions: `:aria-*` blocks
  """

  import NimbleParsec

  # Basic tokens
  whitespace = ascii_string([?\s, ?\t, ?\n, ?\r], min: 1)
  optional_whitespace = ascii_string([?\s, ?\t, ?\n, ?\r], min: 0)

  comment =
    string(";")
    |> ascii_string([not: ?\n], min: 0)
    |> ignore()

  # skip_ws combinator - inline where used due to NimbleParsec scoping

  identifier =
    ascii_string([?a..?z, ?A..?Z, ?_], min: 1)
    |> ascii_string([?a..?z, ?A..?Z, ?_, ?0..?9], min: 0)
    |> map({String, :to_atom, []})

  string_literal =
    ignore(string("\""))
    |> ascii_string([not: ?"], min: 0)
    |> ignore(string("\""))

  number =
    optional(string("-"))
    |> ascii_string([?0..?9], min: 1)
    |> reduce({Enum, :join, [""]})
    |> map({String, :to_integer, []})

  variable =
    string("?")
    |> ascii_string([?a..?z, ?A..?Z, ?_, ?0..?9], min: 1)
    |> reduce({Enum, :join, [""]})

  keyword =
    string(":")
    |> ascii_string([?a..?z, ?A..?Z, ?_, ?-, ?0..?9], min: 1)
    |> reduce({Enum, :join, [""]})
    |> map(fn ":" <> rest -> String.to_atom(rest) end)

  # S-expression parsing (recursive)
  defparsecp(
    :sexp,
    ignore(string("("))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> choice([
      # Keyword list (starts with :)
      parsec(:keyword_list),
      # Regular list
      parsec(:list)
    ])
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> ignore(string(")"))
  )

  defparsecp(
    :keyword_list,
    lookahead(string(":"))
    |> tag(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:keyword_value_pair),
          keyword |> tag(:keyword)
        ])
      ),
      :keyword_list
    )
  )

  defparsecp(
    :list,
    tag(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:sexp),
          parsec(:atom)
        ])
      ),
      :list
    )
  )

  defparsecp(
    :atom,
    choice([
      identifier |> tag(:identifier),
      string_literal |> tag(:string),
      number |> tag(:number),
      variable |> tag(:variable)
    ])
  )

  defparsecp(
    :keyword_value_pair,
    keyword
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      choice([
        parsec(:sexp),
        parsec(:list),
        parsec(:atom)
      ])
    )
    |> tag(:pair)
  )

  # HDDL domain elements
  defparsecp(
    :domain_element,
    choice([
      parsec(:requirements),
      parsec(:predicates),
      parsec(:action),
      parsec(:durative_action),
      parsec(:command),
      parsec(:method),
      parsec(:durative_method),
      parsec(:goal_method),
      parsec(:multigoal),
      parsec(:multigoal_method),
      parsec(:entities),
      parsec(:aria_domain_metadata),
      parsec(:aria_predicate_schemas),
      parsec(:aria_temporal_constraints)
    ])
  )

  defparsecp(
    :problem_element,
    choice([
      parsec(:domain_reference),
      parsec(:aria_initial_state),
      parsec(:aria_plan),
      parsec(:aria_blacklist)
    ])
  )

  # Requirements
  defparsecp(
    :requirements,
    string(":requirements")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> keyword
      )
    )
    |> tag(:requirements)
  )

  # Predicates
  defparsecp(
    :predicates,
    string(":predicates")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:sexp)
      )
    )
    |> tag(:predicates)
  )

  # Actions
  defparsecp(
    :action,
    string(":action")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:parameters),
          parsec(:precondition),
          parsec(:effect),
          parsec(:aria_temporal_metadata)
        ])
      )
    )
    |> tag(:action)
  )

  defparsecp(
    :durative_action,
    string(":durative-action")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:parameters),
          parsec(:duration),
          parsec(:condition),
          parsec(:effect),
          parsec(:aria_temporal_metadata)
        ])
      )
    )
    |> tag(:durative_action)
  )

  defparsecp(
    :command,
    string(":command")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:parameters),
          parsec(:precondition),
          parsec(:effect),
          parsec(:aria_temporal_metadata),
          parsec(:aria_command_metadata)
        ])
      )
    )
    |> tag(:command)
  )

  # Methods
  defparsecp(
    :method,
    string(":method")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:parameters),
          parsec(:task),
          parsec(:subtasks),
          parsec(:aria_temporal_metadata)
        ])
      )
    )
    |> tag(:method)
  )

  defparsecp(
    :durative_method,
    string(":durative-method")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:parameters),
          parsec(:task),
          parsec(:duration),
          parsec(:subtasks),
          parsec(:aria_temporal_metadata)
        ])
      )
    )
    |> tag(:durative_method)
  )

  defparsecp(
    :goal_method,
    string(":goal-method")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:parameters),
          parsec(:goal),
          parsec(:subtasks),
          parsec(:aria_temporal_metadata)
        ])
      )
    )
    |> tag(:goal_method)
  )

  # Multigoals
  defparsecp(
    :multigoal,
    string(":multigoal")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:goal_tag),
          parsec(:goals),
          parsec(:aria_temporal_metadata)
        ])
      )
    )
    |> tag(:multigoal)
  )

  defparsecp(
    :multigoal_method,
    string(":multigoal-method")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:parameters),
          parsec(:multigoal_ref),
          parsec(:subtasks),
          parsec(:aria_temporal_metadata)
        ])
      )
    )
    |> tag(:multigoal_method)
  )

  # Entities
  defparsecp(
    :entities,
    string(":entities")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:entity_declaration)
      )
    )
    |> tag(:entities)
  )

  defparsecp(
    :entity_declaration,
    ignore(string("("))
    |> ignore(string(":entity"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:entity_type),
          parsec(:entity_capabilities),
          parsec(:entity_metadata)
        ])
      )
    )
    |> ignore(string(")"))
  )

  defparsecp(
    :entity_type,
    string(":type")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> tag(:type)
  )

  defparsecp(
    :entity_capabilities,
    string(":capabilities")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      ignore(string("("))
      |> repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> identifier
      )
      |> ignore(string(")"))
    )
    |> tag(:capabilities)
  )

  defparsecp(
    :entity_metadata,
    string(":metadata")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:metadata)
  )

  # aria_planner extensions
  defparsecp(
    :aria_domain_metadata,
    string(":aria-domain-metadata")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:keyword_value_pair)
      )
    )
    |> tag(:aria_domain_metadata)
  )

  defparsecp(
    :aria_predicate_schemas,
    string(":aria-predicate-schemas")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:predicate_schema)
      )
    )
    |> tag(:aria_predicate_schemas)
  )

  defparsecp(
    :predicate_schema,
    ignore(string("("))
    |> ignore(string(":predicate"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:keyword_value_pair)
      )
    )
    |> ignore(string(")"))
  )

  defparsecp(
    :aria_temporal_metadata,
    string(":aria-temporal-metadata")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      ignore(string("("))
      |> repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:duration_iso8601),
          parsec(:start_time_iso8601),
          parsec(:end_time_iso8601),
          parsec(:requires_entities)
        ])
      )
      |> ignore(string(")"))
    )
    |> tag(:aria_temporal_metadata)
  )

  defparsecp(
    :aria_command_metadata,
    string(":aria-command-metadata")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      ignore(string("("))
      |> repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:keyword_value_pair)
      )
      |> ignore(string(")"))
    )
    |> tag(:aria_command_metadata)
  )

  defparsecp(
    :aria_temporal_constraints,
    string(":aria-temporal-constraints")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:aria_temporal_constraints)
  )

  defparsecp(
    :aria_initial_state,
    string(":aria-initial-state")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> choice([
          parsec(:current_time_iso8601),
          parsec(:timeline),
          parsec(:entity_capabilities_list),
          parsec(:facts)
        ])
      )
    )
    |> tag(:aria_initial_state)
  )

  defparsecp(
    :aria_plan,
    string(":aria-plan")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:keyword_value_pair)
      )
    )
    |> tag(:aria_plan)
  )

  defparsecp(
    :aria_blacklist,
    string(":aria-blacklist")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:keyword_value_pair)
      )
    )
    |> tag(:aria_blacklist)
  )

  # Common elements
  defparsecp(
    :parameters,
    string(":parameters")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:parameters)
  )

  defparsecp(
    :precondition,
    string(":precondition")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:precondition)
  )

  defparsecp(
    :condition,
    string(":condition")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:condition)
  )

  defparsecp(
    :effect,
    string(":effect")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:effect)
  )

  defparsecp(
    :duration,
    string(":duration")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:duration)
  )

  defparsecp(
    :task,
    string(":task")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:task)
  )

  defparsecp(
    :goal,
    string(":goal")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:goal)
  )

  defparsecp(
    :goal_tag,
    string(":goal-tag")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> tag(:goal_tag)
  )

  defparsecp(
    :goals,
    string(":goals")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:goals)
  )

  defparsecp(
    :multigoal_ref,
    string(":multigoal")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> tag(:multigoal_ref)
  )

  defparsecp(
    :subtasks,
    string(":subtasks")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:subtasks)
  )

  defparsecp(
    :domain_reference,
    string(":domain")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> tag(:domain)
  )

  # ISO 8601 values
  defparsecp(
    :duration_iso8601,
    string(":duration")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(string_literal)
    |> tag(:duration)
  )

  defparsecp(
    :start_time_iso8601,
    string(":start-time")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(string_literal)
    |> tag(:start_time)
  )

  defparsecp(
    :end_time_iso8601,
    string(":end-time")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(string_literal)
    |> tag(:end_time)
  )

  defparsecp(
    :current_time_iso8601,
    string(":current-time")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(string_literal)
    |> tag(:current_time)
  )

  defparsecp(
    :requires_entities,
    string(":requires-entities")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      ignore(string("("))
      |> repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:entity_requirement)
      )
      |> ignore(string(")"))
    )
    |> tag(:requires_entities)
  )

  defparsecp(
    :entity_requirement,
    ignore(string("("))
    |> ignore(string(":entity"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(identifier)
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:entity_capabilities)
      )
    )
    |> ignore(string(")"))
  )

  defparsecp(
    :timeline,
    string(":timeline")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:timeline)
  )

  defparsecp(
    :entity_capabilities_list,
    string(":entity-capabilities")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:entity_capabilities)
  )

  defparsecp(
    :facts,
    string(":facts")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(parsec(:sexp))
    |> tag(:facts)
  )

  # Top-level parsers
  defparsec(
    :define_domain,
    skip_ws
    |> string("define")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> ignore(string("("))
    |> ignore(string("domain"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> ignore(string("("))
    |> concat(identifier)
    |> ignore(string(")"))
    |> ignore(string(")"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:domain_element)
      )
    )
    |> tag(:domain)
  )

  defparsec(
    :define_problem,
    skip_ws
    |> string("define")
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> ignore(string("("))
    |> ignore(string("problem"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> ignore(string("("))
    |> concat(identifier)
    |> ignore(string(")"))
    |> ignore(string(")"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat(
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:problem_element)
      )
    )
    |> tag(:problem)
  )

  defparsec(
    :hddl_file,
    skip_ws
    |> choice([
      parsec(:define_domain),
      parsec(:define_problem)
    ])
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> eos()
  )

  @doc """
  Parses an HDDL string and returns an AST.

  ## Examples

      iex> AriaPlanner.HDDL.Parser.parse("(define (domain test) (:requirements :strips))")
      {:ok, {:domain, :test, [{:requirements, [:strips]}]}, "", ...}

  """
  @spec parse(String.t()) :: {:ok, term(), String.t(), integer(), integer(), integer()} | {:error, String.t()}
  def parse(hddl_string) when is_binary(hddl_string) do
    case hddl_file(hddl_string) do
      {:ok, ast, rest, _, _, _} ->
        normalized_ast = normalize_ast(ast)
        {:ok, normalized_ast, rest, 0, 0, 0}

      {:error, reason, rest, context, line, column} ->
        {:error,
         "Parse error at line #{line}, column #{column}: #{inspect(reason)}. Context: #{inspect(context)}. Remaining: #{
           String.slice(rest, 0, 50)
         }"}
    end
  end

  @doc """
  Parses an HDDL file and returns an AST.
  """
  @spec parse_file(String.t()) :: {:ok, term()} | {:error, String.t()}
  def parse_file(path) do
    case File.read(path) do
      {:ok, content} ->
        case parse(content) do
          {:ok, ast, _, _, _, _} -> {:ok, ast}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  # Normalize AST to cleaner structure
  defp normalize_ast(ast) do
    case ast do
      {:domain, name, elements} ->
        normalized_elements = Enum.map(elements, &normalize_element/1)
        {:domain, name, normalized_elements}

      {:problem, name, elements} ->
        normalized_elements = Enum.map(elements, &normalize_element/1)
        {:problem, name, normalized_elements}

      other ->
        normalize_element(other)
    end
  end

  defp normalize_element({:keyword_list, pairs}) do
    Enum.reduce(pairs, %{}, fn
      {:pair, [key, value]} ->
        Map.put(%{}, key, normalize_value(value))

      {:keyword, key} when is_atom(key) ->
        Map.put(%{}, key, true)

      other ->
        %{}
    end)
  end

  defp normalize_element({:list, items}) do
    Enum.map(items, &normalize_value/1)
  end

  defp normalize_element({tag, value}) when is_atom(tag) do
    {tag, normalize_value(value)}
  end

  defp normalize_element({tag, name, elements}) when is_atom(tag) do
    normalized_elements = Enum.map(elements, &normalize_element/1)
    {tag, name, normalized_elements}
  end

  defp normalize_element(other) do
    normalize_value(other)
  end

  defp normalize_value({:keyword_list, pairs}) do
    Enum.reduce(pairs, %{}, fn
      {:pair, [key, value]} ->
        Map.put(%{}, key, normalize_value(value))

      {:keyword, key} when is_atom(key) ->
        Map.put(%{}, key, true)

      other ->
        %{}
    end)
  end

  defp normalize_value({:list, items}) do
    Enum.map(items, &normalize_value/1)
  end

  defp normalize_value({tag, value}) when is_atom(tag) do
    {tag, normalize_value(value)}
  end

  defp normalize_value(value) when is_atom(value) or is_binary(value) or is_integer(value) do
    value
  end

  defp normalize_value(other) do
    other
  end
end
