# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.Parser.Helpers do
  @moduledoc """
  Helper functions for HDDL parser.
  
  Provides utility functions for transforming parsed results into structured tuples.
  This module delegates to specialized sub-modules for organization.
  """

  # Basic utilities
  defdelegate keyword_to_atom(str), to: AriaPlanner.HDDL.Parser.Helpers.Utils
  defdelegate wrap_in_list(value), to: AriaPlanner.HDDL.Parser.Helpers.Utils
  defdelegate wrap_domain_name(name), to: AriaPlanner.HDDL.Parser.Helpers.Utils
  defdelegate concat_any_reduce(acc), to: AriaPlanner.HDDL.Parser.Helpers.Utils

  # Domain builders
  defdelegate build_domain_tuple_from_name_and_elements(acc), to: AriaPlanner.HDDL.Parser.Helpers.Domain
  defdelegate extract_name_and_elements_from_domain_accumulated(acc), to: AriaPlanner.HDDL.Parser.Helpers.Domain
  defdelegate build_domain_tuple_raw(acc), to: AriaPlanner.HDDL.Parser.Helpers.Domain
  defdelegate build_domain_tuple_from_tagged_and_list(acc), to: AriaPlanner.HDDL.Parser.Helpers.Domain
  defdelegate build_domain_tuple_from_tagged(tagged_list), to: AriaPlanner.HDDL.Parser.Helpers.Domain
  defdelegate build_domain_tuple_from_domain_token(acc), to: AriaPlanner.HDDL.Parser.Helpers.Domain
  defdelegate build_domain_tuple_from_list(acc), to: AriaPlanner.HDDL.Parser.Helpers.Domain

  # Problem builders
  defdelegate build_problem_tuple_from_tagged(tagged_list), to: AriaPlanner.HDDL.Parser.Helpers.Problem
  defdelegate build_problem_tuple(tagged_list), to: AriaPlanner.HDDL.Parser.Helpers.Problem

  # Legacy function name for backward compatibility
  @spec build_domain_tuple_from_accumulated(list()) :: {:domain, atom(), list()}
  defdelegate build_domain_tuple_from_accumulated(accumulated), to: AriaPlanner.HDDL.Parser.Helpers.Domain, as: :build_domain_tuple_from_name_and_elements
end
