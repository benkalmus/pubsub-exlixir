# Pubsub

A simple Pubsub application written as an Elixir exercise. 
In this implementation, a dynamic supervisor is used to start and stop `Topic` gen_servers that store subscribers. Messages published on the Topic will be broadcast to each sub. 

## TODO
add task that publishes a message from a list of predefined messages on the "info" channel, which is created on startup. 
Messages consist of some notes about the making of this app & elixir
Store notes in .json 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pubsub` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pubsub, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/pubsub>.

