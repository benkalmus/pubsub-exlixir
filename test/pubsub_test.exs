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

  # cannot subscribe to a non existing topic

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
