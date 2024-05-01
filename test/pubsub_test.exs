defmodule PubsubTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import ExUnit.Assertions
  import Pubsub.Common
  require Logger

  # doctests aren't sandboxed and leave lingering processes.
  doctest Pubsub, only: []

  test "should start a pubsub topic, subscribe and publish" do
    topic_name = "my topic"
    assert {:ok, _pid} = Pubsub.new_topic(topic_name)
    assert :ok == Pubsub.Topic.subscribe(topic_name,  self())
    Pubsub.Topic.publish(topic_name, "hello world")
    assert_receive {:pubsub_msg, _pid, "hello world"}
    Pubsub.Topic.stop(topic_name)
    assert_retry(5, 10, fn ->
      assert [] == Pubsub.all_topics()
    end)
  end

  test "get all topics" do
    topic1_name = "topic 1"
    topic2_name = "topic 2"
    assert {:ok, _pid} = Pubsub.new_topic(topic1_name)
    assert {:ok, _pid} = Pubsub.new_topic(topic2_name)
    assert [topic1_name, topic2_name] == Pubsub.all_topics()
    Pubsub.Topic.stop(topic1_name)
    Pubsub.Topic.stop(topic2_name)
  end

  test "stop pubsub should stop all topics" do
    topic_name = "my topic"
    Pubsub.new_topic(topic_name)
    assert [topic_name] == Pubsub.all_topics()
    Pubsub.stop()
    assert_retry(5, 10, fn ->
      assert [] == Pubsub.all_topics()
    end)
  end

  test "crashed topic gets restarted by supervisor" do
    topic_name = "topic_1"
    assert {:ok, pid} = Pubsub.new_topic(topic_name)
    assert :ok == Pubsub.Topic.subscribe(topic_name, self())
    assert [topic_name] == Pubsub.all_topics()
    Pubsub.Topic.publish(topic_name, "hello world")
    assert_receive {:pubsub_msg, _pid, "hello world"}

    #send crash signal
    log =
      capture_log(fn ->
        GenServer.stop(pid, :"abnormal stop")
      end)
    # Ensure gen server has terminated
    assert log =~ "GenServer #{inspect(gproc_tuple(topic_name))} terminating"
    assert log =~ "(stop) :\"abnormal stop\""
    Process.sleep(100)
    # await supervisor to restart worker
    assert_retry(5, 10, fn ->
      assert [topic_name] == Pubsub.all_topics()
    end)
    #must resubscribe to topic
    assert :ok == Pubsub.Topic.subscribe(topic_name, self())
    Pubsub.Topic.publish(topic_name, "hello world")
    assert_receive {:pubsub_msg, _pid, "hello world"}
    assert :ok == Pubsub.Topic.stop(topic_name)
  end

  test "unsubscribed should no longer receive messages" do
    topic_name = "my topic"
    assert {:ok, _pid} = Pubsub.new_topic(topic_name)
    assert :ok == Pubsub.Topic.subscribe(topic_name,  self())
    Pubsub.Topic.publish(topic_name, "hello world")
    assert_receive {:pubsub_msg, _pid, "hello world"}
    Pubsub.Topic.unsubscribe(topic_name, self())
    Pubsub.Topic.publish(topic_name, "hello world")
    refute_receive {:pubsub_msg, _pid, "hello world"}
    Pubsub.Topic.stop(topic_name)
  end

  test "publish to multiple subscribers async" do
    topic_name = "my topic"
    assert {:ok, _pid} = Pubsub.new_topic(topic_name)

    tasks = 1..3 |>
      Enum.map(fn _ ->
        Task.async(fn ->
          pid = self()
          Logger.debug("Subscribing #{inspect(pid)} to room  #{topic_name}")
          Pubsub.Topic.subscribe(topic_name,  pid)
          assert_receive {:pubsub_msg, _source, "msg"}
          Pubsub.Topic.unsubscribe(topic_name, pid)
        end)
      end)

    #wait for all tasks to start
    Process.sleep(10)
    #publish message
    Pubsub.Topic.publish(topic_name, "msg")
    #wait for all tasks to receive "msg"
    tasks |> Enum.map(&Task.await(&1))
    Pubsub.Topic.stop(topic_name)
  end

  test "multiple topics, multiple published messages separately" do
    topics = ["t1", "t2"]
    parent = self()
    #spawn topics and immediately subscribe to all
    pids = topics |> Enum.map(fn topic ->
      {:ok, pid} = Pubsub.new_topic(topic)
      assert :ok == Pubsub.Topic.subscribe(topic, parent)
      pid
    end)
    #publish message each topic, expect a separate message from each
    Enum.zip(pids, topics) |> Enum.map(fn {p, t} ->
      Pubsub.Topic.publish(t, "msg")
      assert_receive {:pubsub_msg, ^p, "msg"}
    end)
    assert :ok == Pubsub.stop()
  end

  # TODO, more tests:

  # test "should not be able to publish to non existing topic" do
  #   topic_name = "my topic"
  #   Pubsub.Topic.publish(topic_name, "msg")
  #   refute_receive {:pubsub_msg, _p, "msg"}
  # end
  #
  # should not be able to subscribe to a non existing topic
  # should not be able to unsubscribe from a non existing topic
  # stopped topic should unsubscribe and inform subscriber pids



  # =========================
  # Helpers
  defp assert_retry(1, _delay, function) do
    # run the function one last time, if it fails, we will get an assertion error
    function.()
  end
  defp assert_retry(times, delay, function) do
    try do
      function.()
    rescue
      ExUnit.AssertionError ->
        Process.sleep(delay)
        assert_retry(times - 1, delay, function)
    end
  end
end
