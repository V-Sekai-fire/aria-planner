defmodule AriaPlanner.Domains.BlocksWorld do
  @moduledoc """
  Blocks World domain for the aria-planner.

  This domain implements the classic block stacking problem where blocks
  can be picked up, put down, stacked, and unstacked.

  The domain composes interactivity commands to implement block manipulation
  operations, demonstrating domain composition: BlocksWorld ∘ Interactivity.
  """

  alias AriaCore.PlanningDomain

  @doc """
  Creates and registers the Blocks World domain.
  """
  def create_domain do
    {:ok, domain} =
      PlanningDomain.create(%{
        domain_type: "blocks_world",
        name: "Blocks World",
        description: "Classic block stacking problem domain"
      })

    # Add tasks
    {:ok, domain} =
      PlanningDomain.add_element(domain, :task, %{
        name: "t_move_blocks",
        module: AriaPlanner.Domains.BlocksWorld.Tasks.MoveBlocks
      })

    {:ok, domain} =
      PlanningDomain.add_element(domain, :task, %{
        name: "t_move_one",
        module: AriaPlanner.Domains.BlocksWorld.Tasks.MoveOne
      })

    {:ok, domain} =
      PlanningDomain.add_element(domain, :task, %{
        name: "t_get",
        module: AriaPlanner.Domains.BlocksWorld.Tasks.Get
      })

    {:ok, domain} =
      PlanningDomain.add_element(domain, :task, %{
        name: "t_put",
        module: AriaPlanner.Domains.BlocksWorld.Tasks.Put
      })

    {:ok, domain}
  end
end
