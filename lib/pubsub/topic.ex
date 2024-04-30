defmodule Pubsub.Topic do
  @moduledoc """
  A Topic is a channel on which Subscribers can receive messages from Publishers.
  Topics broadcast published messages to all subscribers currently subscribed (stored as in memory by Topic).

  """
  use GenServer
  import Pubsub.Common

  defstruct [
    name: "",
    subscriber_pids: MapSet.new()
  ]

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: via_tuple(init_args.name))
  end

  # =====================
  # Public API
  @spec subscribe(String.t(), pid()) :: :ok | {:error, :not_found}
  def subscribe(topic_name, subscriber_pid) do
    GenServer.call(via_tuple(topic_name), {:subscribe, subscriber_pid})
  end

  def unsubscribe(topic_name, subscriber_pid) do
    GenServer.call(via_tuple(topic_name), {:unsubscribe, subscriber_pid})
  end

  def publish(topic_name, message) do
    GenServer.cast(via_tuple(topic_name), {:publish, message})
  end

  def stop(topic_name) do
    GenServer.stop(via_tuple(topic_name))
  end

  # =====================
  # Gen server callbacks
  @impl true
  def init(%{:name => topic_name}) do

    {:ok, %Pubsub.Topic{:name =>topic_name}}
  end

  @doc """
  Handles async messages published to the topic
  """
  @impl true
  def handle_cast({:publish, message}, state) do
    Enum.each(state.subscriber_pids,
      fn pid ->
        send(pid, {:pubsub_msg, self(), message})
      end)
    {:noreply, state}
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    state = update_in(state.subscriber_pids, &MapSet.put(&1, pid))
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:unsubscribe, pid}, _from, state) do
    state = update_in(state.subscriber_pids, &MapSet.delete(&1, pid))
    {:reply, :ok, state}
  end
  # ====================
  # Private Functions

end