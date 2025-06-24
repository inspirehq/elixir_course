# Day 1 – Guided Exercise: Building a Simple Counter GenServer
#
# This file is *interactive* – the first half gives students a **prompt** with
# TODO markers.  Scroll further down and you'll find the **Answer Key** for
# self-checking (collapsed in a multi-line string so it won't execute unless
# intentionally required).
#
# Instructions:
#   1. Duplicate this file to your own workspace or comment out the answer.
#   2. Fill in the TODO blocks until the tests at the bottom pass.
#   3. Compare with the Answer Key when you get stuck.
#
# You can run the exercise with:
#     mix run elixir_course/day_one/09_counter_genserver.exs
# or in IEx using `iex -S mix` and then `CounterExercise.manual_demo/0`.

IO.puts("\n🎯 Exercise Prompt – implement the missing pieces!")

defmodule CounterExercise do
  @moduledoc """
  Implement a GenServer that keeps an integer count in its state.

  Public API requirements:
  • start_link/1 – initial count (default 0)
  • inc/1 – increment by n (default 1)
  • value/0 – synchronous call returning the current count.
  """

  use GenServer

  # ── Public API ───────────────────────────────────────────────
  def start_link(initial \\ 0) do
    # TODO: start the GenServer process and return {:ok, pid}
    GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def inc(n \\ 1) do
    # TODO: send an *asynchronous* message to increment by n
    GenServer.cast(__MODULE__, {:inc, n})
  end

  def value, do: GenServer.call(__MODULE__, :value)

  # ── Callbacks ────────────────────────────────────────────────
  @impl true
  def init(initial), do: {:ok, initial}

  @impl true
  def handle_cast({:inc, n}, state) do
    # TODO: return the new state
    {:noreply, state + n}
  end

  @impl true
  def handle_call(:value, _from, state), do: {:reply, state, state}

  # ── Convenience for manual demo ─────────────────────────────
  def manual_demo do
    {:ok, _} = start_link(10)
    inc()
    inc(5)
    IO.inspect(value(), label: "counter value")
  end
end

# Quick assertion-style tests so students know when they're done.
{:ok, _} = CounterExercise.start_link(2)
CounterExercise.inc()
CounterExercise.inc(3)

expected = 6
actual   = CounterExercise.value()
if expected == actual do
  IO.puts("✅  All good! Counter is #{actual} as expected.")
else
  IO.puts("❌  Expected #{expected}, got #{actual}")
end

# ────────────────────────────────────────────────────────────────
"""
📖 Answer Key (uncomment to compare) –––––––––––––––––––––––––––––

defmodule CounterAnswer do
  use GenServer
  # API
  def start_link(initial \\ 0), do: GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  def inc(n \\ 1),            do: GenServer.cast(__MODULE__, {:inc, n})
  def value(),                do: GenServer.call(__MODULE__, :value)

  # Callbacks
  @impl true
  def init(initial), do: {:ok, initial}
  @impl true
  def handle_cast({:inc, n}, state), do: {:noreply, state + n}
  @impl true
  def handle_call(:value, _from, state), do: {:reply, state, state}
end

# Explanation:
# • Public API converts directly to GenServer.call/cast keeping synchronous vs
#   async clear.
# • State is *immutable*; each increment returns a new integer stored for the
#   next message.
# • Separation of concerns: tests use only the public API, demonstrating
#   black-box usage.

"""
