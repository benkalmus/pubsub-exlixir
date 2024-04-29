defmodule PubsubTest do
  use ExUnit.Case
  doctest Pubsub

  test "Starts a pubsub topic, subscribe and publish" do
    assert {:ok, pid} = Pubsub.new_topic("my topic")
    assert :ok == Topic.subscribe("my topic",  self())
    Topic.publish(pid, "hello world")
    assert_receive {:pubsub_msg, _pid, "hello world"}
    Pubsub.stop_topic("my topic")
  end
end
