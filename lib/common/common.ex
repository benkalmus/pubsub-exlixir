defmodule Pubsub.Common do
  @moduledoc """
  A place to store macros, records and shared functions for pubsub.
  """

  # Register a named process via gproc, currently local only
  defmacro via_tuple(name) do
    quote do
      {:via, :gproc, {:n, :l, {:topic, unquote(name)}}}
    end
  end
  defmacro gproc_tuple(name) do
    quote do
      {:n, :l, {:topic, unquote(name)}}
    end
  end


end
