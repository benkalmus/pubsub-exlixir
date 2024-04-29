defmodule Topic do
  @moduledoc """
  A Topic is a channel on which Subscribers can receive messages from Publishers.
  Topics broadcast published messages to all subscribers currently subscribed (stored as in memory by Topic).

  """
  use GenServer

  defstruct [
    name: "",
    subscriber_pids: MapSet.new()
  ]

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  # =====================
  # Public API
  @spec subscribe(String.t(), pid()) :: :ok | {:error, :not_found}
  def subscribe(topic_name, subscriber_pid) do
    ## TODO register pid names as string so we don't need to do a lookup each time
    case Pubsub.find_topic(topic_name) do
      {:ok, pid} -> GenServer.call(pid, {:subscribe, subscriber_pid})
      err -> err
    end
  end

  def unsubscribe(topic_pid, subscriber_pid) do
    GenServer.call(topic_pid, {:unsubscribe, subscriber_pid})
  end

  def publish(topic_pid, message) do
    GenServer.cast(topic_pid, {:publish, message})
  end

  def stop(topic_pid) do
    GenServer.stop(topic_pid)
  end

  def name(topic_pid) do
    GenServer.call(topic_pid, :name)
  end

  # =====================
  # Gen server callbacks
  def init(%{:name => topic_name}) do

    {:ok, %Topic{:name =>topic_name}}
  end

  @doc """
  Handles async messages published to the topic
  """
  def handle_cast({:publish, message}, state) do
    Enum.each(state.subscriber_pids,
      fn pid ->
        send(pid, {:pubsub_msg, self(), message})
      end)
    {:noreply, state}
  end

  def handle_call(:name, _from, state) do
    {:reply, state.name, state}
  end

  def handle_call({:subscribe, pid}, _from, state) do
    state = update_in(state.subscriber_pids, &MapSet.put(&1, pid))
    {:reply, :ok, state}
  end

  def handle_call({:unsubscribe, pid}, _from, state) do
    state = update_in(state.subscriber_pids, &MapSet.delete(&1, pid))
    {:reply, :ok, state}
  end
  # ====================
  # Private Functions

end
