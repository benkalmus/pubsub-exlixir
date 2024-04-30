defmodule PubsubTest do
  use ExUnit.Case
  doctest Pubsub

  test "Starts a pubsub topic, subscribe and publish" do
    assert {:ok, _pid} = Pubsub.new_topic("my topic")
    assert :ok == Pubsub.Topic.subscribe("my topic",  self())
    Pubsub.Topic.publish("my topic", "hello world")
    assert_receive {:pubsub_msg, _pid, "hello world"}
    Pubsub.stop_topic("my topic")
  end
end
