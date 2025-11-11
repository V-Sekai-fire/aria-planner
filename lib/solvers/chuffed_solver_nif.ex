# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Solvers.ChuffedSolverNif do
  @moduledoc """
  NIF bindings for Chuffed constraint solver.
  
  This module provides direct C++ integration with Chuffed solver.
  Chuffed is a lazy clause generation constraint programming solver.
  
  ## Requirements
  
  - Chuffed must be installed and available in the system
  - The NIF library must be compiled (run `make` in c_src/)
  - MiniZinc must be installed for MiniZinc model support
  
  ## Usage
  
      # Solve a FlatZinc problem
      {:ok, result} = ChuffedSolverNif.solve_flatzinc(flatZincContent, "{}")
      
      # Solve a MiniZinc problem
      {:ok, result} = ChuffedSolverNif.solve_minizinc(modelContent, dataContent)
  """

  @on_load :load_nif

  def load_nif do
    nif_path = :filename.join(:code.priv_dir(:aria_planner), 'chuffed_solver_nif')
    :erlang.load_nif(nif_path, 0)
  end

  @doc """
  Solves a FlatZinc problem using Chuffed.
  
  ## Parameters
  
  - `flatZincContent`: FlatZinc problem as a binary string
  - `options`: JSON string with solver options (optional)
  
  ## Returns
  
  - `{:ok, result}` - Solution as a binary string
  - `{:error, reason}` - Error reason
  """
  def solve_flatzinc(_flatZincContent, _options) do
    :erlang.nif_error(:nif_not_loaded)
  end


  @doc """
  Creates a new Chuffed solver instance.
  
  Returns a resource handle that can be used for multiple solves.
  """
  def create_solver do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Destroys a Chuffed solver instance.
  
  ## Parameters
  
  - `solver`: Solver resource handle from `create_solver/0`
  """
  def destroy_solver(_solver) do
    :erlang.nif_error(:nif_not_loaded)
  end
end

