# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL do
  @moduledoc """
  Public API for HDDL import/export functionality.

  Provides convenience functions for importing HDDL files/strings into aria_planner
  structs and exporting aria_planner structs to HDDL format.

  ## Examples

      # Import HDDL domain from file
      {:ok, domain} = AriaPlanner.HDDL.import_from_file("domains/fox_geese_corn.hddl")

      # Import HDDL domain from string
      hddl_string = "(define (domain test) (:requirements :strips))"
      {:ok, domain} = AriaPlanner.HDDL.import_from_string(hddl_string)

      # Export domain to HDDL
      hddl_string = AriaPlanner.HDDL.export_to_string(domain)

      # Export domain to file
      :ok = AriaPlanner.HDDL.export_to_file(domain, "output.hddl")
  """

  alias AriaCore.Plan
  alias AriaCore.PlanningDomain
  alias AriaPlanner.HDDL.Exporter
  alias AriaPlanner.HDDL.Importer
  alias AriaPlanner.HDDL.Parser

  @doc """
  Imports an HDDL file and creates a PlanningDomain or Plan.

  Returns `{:ok, struct}` on success, `{:error, reason}` on failure.
  """
  @spec import_from_file(String.t()) :: {:ok, PlanningDomain.t() | Plan.t()} | {:error, String.t()}
  def import_from_file(path) do
    case Parser.parse_file(path) do
      {:ok, ast} ->
        import_ast(ast)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Imports an HDDL string and creates a PlanningDomain or Plan.

  Returns `{:ok, struct}` on success, `{:error, reason}` on failure.
  """
  @spec import_from_string(String.t()) :: {:ok, PlanningDomain.t() | Plan.t()} | {:error, String.t()}
  def import_from_string(hddl_string) when is_binary(hddl_string) do
    case Parser.parse(hddl_string) do
      {:ok, ast, _, _, _, _} ->
        import_ast(ast)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Exports a PlanningDomain or Plan to HDDL string.
  """
  @spec export_to_string(PlanningDomain.t() | Plan.t()) :: String.t()
  def export_to_string(%PlanningDomain{} = domain) do
    Exporter.export_domain(domain)
  end

  def export_to_string(%Plan{} = plan) do
    Exporter.export_problem(plan)
  end

  @doc """
  Exports a PlanningDomain or Plan to HDDL file.
  """
  @spec export_to_file(PlanningDomain.t() | Plan.t(), String.t()) :: :ok | {:error, atom()}
  def export_to_file(%PlanningDomain{} = domain, path) do
    hddl_string = Exporter.export_domain(domain)
    File.write(path, hddl_string)
  end

  def export_to_file(%Plan{} = plan, path) do
    hddl_string = Exporter.export_problem(plan)
    File.write(path, hddl_string)
  end

  @doc """
  Validates HDDL syntax without importing.

  Returns `:ok` if valid, `{:error, reason}` if invalid.
  """
  @spec validate_hddl(String.t()) :: :ok | {:error, String.t()}
  def validate_hddl(hddl_string) when is_binary(hddl_string) do
    case Parser.parse(hddl_string) do
      {:ok, _, _, _, _, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helper to import AST
  defp import_ast({:domain, _, _} = ast) do
    Importer.import_domain(ast)
  end

  defp import_ast({:problem, _, _} = ast) do
    Importer.import_problem(ast)
  end

  defp import_ast(_) do
    {:error, "Invalid HDDL AST - expected :domain or :problem"}
  end
end
