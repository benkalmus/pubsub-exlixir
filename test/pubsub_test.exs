defmodule PubsubTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Pubsub.Common

  # doctests aren't sandboxed and leave lingering processes.
  doctest Pubsub, only: []

  test "should start a pubsub topic, subscribe and publish" do
    topic_name = "my topic"
    assert {:ok, _pid} = Pubsub.new_topic(topic_name)
    assert :ok == Pubsub.Topic.subscribe(topic_name,  self())
    Pubsub.Topic.publish(topic_name, "hello world")
    assert_receive {:pubsub_msg, _pid, "hello world"}
    Pubsub.stop_topic(topic_name)
  end

  test "get all topics" do
    topic1_name = "topic 1"
    topic2_name = "topic 2"
    assert {:ok, _pid} = Pubsub.new_topic(topic1_name)
    assert {:ok, _pid} = Pubsub.new_topic(topic2_name)
    assert [topic1_name, topic2_name] == Pubsub.all_topics()
    Pubsub.stop_topic(topic1_name)
    Pubsub.stop_topic(topic2_name)
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
        GenServer.stop(pid, :kill)
      end)
    # Ensure gen server has terminated
    assert log =~ "GenServer #{inspect(gproc_tuple(topic_name))} terminating"
    assert log =~ "(stop) :kill"

    # wait for supervisor to restart worker
    Process.sleep(10)
    assert [topic_name] == Pubsub.all_topics()
    #must resubscribe to topic
    assert :ok == Pubsub.Topic.subscribe(topic_name, self())
    Pubsub.Topic.publish(topic_name, "hello world")
    assert_receive {:pubsub_msg, _pid, "hello world"}
    Pubsub.stop_topic(topic_name)
  end

end
