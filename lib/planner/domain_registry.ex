# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.DomainRegistry do
  @moduledoc """
  Domain Registry for Aria Hybrid Planner

  Manages registration and discovery of domain implementations.
  Domains register themselves when loaded, enabling dynamic discovery
  and integration with the planning system.
  """

  require Logger

  use GenServer

  @type domain_name :: atom()
  @type domain_module :: module()
  @type domain_metadata :: %{
          description: String.t(),
          optimization_supported: boolean(),
          capabilities: [atom()],
          version: String.t()
        }

  @type registration :: %{
          name: domain_name(),
          module: domain_module(),
          metadata: domain_metadata(),
          registered_at: DateTime.t()
        }

  # Client API

  @doc """
  Starts the domain registry.
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a domain with the registry.

  ## Parameters
  - `name`: Atom identifier for the domain
  - `module`: Domain module implementing the domain logic
  - `metadata`: Domain metadata including capabilities and version

  ## Examples

      iex> metadata = %{
      ...>   description: "Yumi dual-arm assembly domain",
      ...>   optimization_supported: true,
      ...>   capabilities: [:multigoal, :temporal, :collision_avoidance],
      ...>   version: "1.0.0"
      ...> }
      iex> register_domain(:yumi, AriaPlanner.Planner.Domains.YumiDomain, metadata)
      :ok
  """
  @spec register_domain(domain_name(), domain_module(), domain_metadata()) :: :ok
  def register_domain(name, module, metadata) do
    GenServer.call(__MODULE__, {:register, name, module, metadata})
  end

  @doc """
  Lists all registered domains.

  ## Returns
  List of registered domain names
  """
  @spec list_registered_domains() :: [domain_name()]
  def list_registered_domains do
    GenServer.call(__MODULE__, :list_domains)
  end

  @doc """
  Gets a domain module by name.

  ## Parameters
  - `name`: Domain name to look up

  ## Returns
  - `{:ok, module}` - Domain module found
  - `{:error, :not_found}` - Domain not registered
  """
  @spec get_domain_module(domain_name()) :: {:ok, domain_module()} | {:error, :not_found}
  def get_domain_module(name) do
    GenServer.call(__MODULE__, {:get_module, name})
  end

  @doc """
  Gets domain metadata by name.

  ## Parameters
  - `name`: Domain name to look up

  ## Returns
  - `{:ok, metadata}` - Domain metadata found
  - `{:error, :not_found}` - Domain not registered
  """
  @spec get_domain_metadata(domain_name()) :: {:ok, domain_metadata()} | {:error, :not_found}
  def get_domain_metadata(name) do
    GenServer.call(__MODULE__, {:get_metadata, name})
  end

  @doc """
  Checks if a domain is registered.

  ## Parameters
  - `name`: Domain name to check

  ## Returns
  Boolean indicating if domain is registered
  """
  @spec domain_registered?(domain_name()) :: boolean()
  def domain_registered?(name) do
    case get_domain_module(name) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc """
  Gets all domains supporting optimization.

  ## Returns
  List of domain names that support optimization
  """
  @spec get_optimization_domains() :: [domain_name()]
  def get_optimization_domains do
    GenServer.call(__MODULE__, :get_optimization_domains)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{domains: %{}}}
  end

  @impl true
  def handle_call({:register, name, module, metadata}, _from, state) do
    registration = %{
      name: name,
      module: module,
      metadata: metadata,
      registered_at: DateTime.utc_now()
    }

    new_domains = Map.put(state.domains, name, registration)
    new_state = %{state | domains: new_domains}

    Logger.info("DomainRegistry: Registered domain #{name} (#{module})")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:list_domains, _from, state) do
    domains_list = Map.values(state.domains)
    {:reply, domains_list, state}
  end

  @impl true
  def handle_call({:get_module, name}, _from, state) do
    case Map.get(state.domains, name) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %{module: module} ->
        {:reply, {:ok, module}, state}
    end
  end

  @impl true
  def handle_call({:get_metadata, name}, _from, state) do
    case Map.get(state.domains, name) do
      nil ->
        {:reply, {:error, :not_found}, state}

      registration ->
        {:reply, {:ok, registration}, state}
    end
  end

  @impl true
  def handle_call(:get_optimization_domains, _from, state) do
    optimization_domains =
      state.domains
      |> Enum.filter(fn {_name, reg} ->
        reg.metadata.optimization_supported == true
      end)
      |> Enum.map(fn {_name, reg} -> reg end)

    {:reply, optimization_domains, state}
  end
end
