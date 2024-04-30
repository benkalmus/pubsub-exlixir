defmodule Pubsub do
  @moduledoc """
  An instance of PubSub dynamic supervisor. Handles startup and teardown of Topic worker gen_servers.

  """
  use DynamicSupervisor
  import Pubsub.Common

  # =====================
  # Public API

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Starts a new supervised Topic gen_server.

  ## Examples
    iex> {:ok, pid} = Pubsub.new_topic("some topic name")
    iex>  is_pid(pid)
    :true
  """
  @spec new_topic(String.t()) :: {:ok, pid()} | {:error, :already_started}
  def new_topic(topic_name) do
    case is_topic?(topic_name)  do
      true ->
        {:error, :already_started}
      false ->
        init_args = %{
          name: topic_name
        }
        spec = %{
          id: Pubsub.Topic,  #Dynamic; value is ignored
          start: {Pubsub.Topic, :start_link, [init_args]},
          restart: :transient     #restart if crashed, but not if stopped
        }
        DynamicSupervisor.start_child(__MODULE__, spec)
    end
  end

  @spec find_topic(any()) :: {:ok, pid()} | {:error, :not_found}
  def find_topic(topic_name) do
    result = :gproc.where(gproc_tuple(topic_name))
    case result do
      :undefined ->
        {:error, :not_found}
      topic_pid ->
        {:ok, topic_pid}
    end
  end

  @spec is_topic?(String.t()) :: boolean()
  def is_topic?(topic_name) do
    case find_topic(topic_name) do
      {:ok, _} -> true
      {:error, :not_found} -> false
    end
  end

  @spec stop_topic(any()) :: :ok | {:error, :not_found}
  def stop_topic(topic_name) do
    case find_topic(topic_name) do
      {:ok, pid} -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      err -> err
    end
  end

  # Supervisor API
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
