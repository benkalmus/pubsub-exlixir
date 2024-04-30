defmodule Pubsub.RootSup do
  @moduledoc """
  Root pubsub supervisor.
  Spawns Dynamic Pubsub supervisor.
  """
  use Supervisor
  require Logger


  # =====================
  # Public API
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      {Pubsub, []}
    ]
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
