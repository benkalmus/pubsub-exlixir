defmodule Topic do
  @moduledoc """
  Broadcasts published messages to subscribers map stored in this Topic

  """
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Gen server callbacks
  def init(_list) do
    {:ok, %{}}
  end
end
