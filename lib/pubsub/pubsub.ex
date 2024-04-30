defmodule Pubsub do
  @moduledoc """
  An instance of PubSub dynamic supervisor. Handles startup and teardown of Topic worker gen_servers.

  """
  use DynamicSupervisor
  import Pubsub.Common

  # ====
  # Type Specs
  @type topic_name :: String.t()

  # =====================
  # Public API

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Starts a new supervised Topic gen_server.

  ## Examples
    iex>  = Pubsub.new_topic("some topic name")
    {:ok, #PID<0.126.0>}
  """
  @spec new_topic(topic_name()) :: {:ok, pid()} | {:error, :already_started}
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

  @doc """
  Returns a topic pid (if found) given topic_name()
  """
  @spec find_topic(topic_name()) :: {:ok, pid()} | {:error, :not_found}
  def find_topic(topic_name) do
    result = :gproc.where(gproc_tuple(topic_name))
    case result do
      :undefined ->
        {:error, :not_found}
      topic_pid ->
        {:ok, topic_pid}
    end
  end


  @doc """
  Performs a check if topic gen server exists
  """
  @spec is_topic?(topic_name()) :: boolean()
  def is_topic?(topic_name) do
    case find_topic(topic_name) do
      {:ok, _} -> true
      {:error, :not_found} -> false
    end
  end

  @doc """
  Stops a Topic gen_server if found.

  ## Examples
    iex> Pubsub.stop_topic("some topic name")
    :ok
  """
  @spec stop_topic(topic_name()) :: :ok | {:error, :not_found}
  def stop_topic(topic_name) do
    case find_topic(topic_name) do
      {:ok, pid} -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      err -> err
    end
  end

  @doc """
  Lists all supervised Topics.

  ## Examples
    iex> Pubsub.all_topics()
    ["topic 1", "topic 2"]
  """
  @spec all_topics() :: [] | list(topic_name())
  def all_topics() do
    # similar to ETS' match spec, see examples  https://gist.github.com/rustyio/188032
    # return only processes registered under atom :topic
    key = {:topic, :_}  #our defined pubsub key tuple
	  gproc_key = {:_, :_, key}  #gproc processes take the form {}
    match_head = {gproc_key, :_, :_}   #gproc_key, pid, value
    guard = []
    result = [:"$_"]
    #can limit select context to just local processes. TODO if distributed
    :gproc.select([{match_head, guard, result}])
      |> Enum.map(fn {{_, _, {:topic, topic_name}}, _, _} -> topic_name end)

    end

  # Supervisor API
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
