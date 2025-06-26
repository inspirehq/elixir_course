# Day 1 – The Erlang/Elixir Primitives Underpinning GenServer
#
# This script can be run with:
#     mix run day_one/07_genserver_primitives.exs
# or inside IEx with:
#     iex -r day_one/07_genserver_primitives.exs
#
# GenServer is a *behaviour* that wraps several lower-level process features
# available directly in the BEAM. Understanding those primitives demystifies
# GenServer and helps when debugging lower-level issues.
# Each numbered block below is executable & independent.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – spawn/1 & send/2 + receive")

pid = spawn(fn ->
  receive do
    {:hello, from} -> send(from, :world)
  end
end)

send(pid, {:hello, self()})

response = receive do
  msg -> msg
after 1000 -> :timeout
end

IO.inspect(response, label: "response from spawned process")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Process links for crash propagation")

parent = self()
spawn_link(fn ->
  send(parent, :about_to_crash)
  raise "boom"
end)

:ok = receive do
  :about_to_crash -> :ok
end

# The linked process crashes *this* process too (unless trapping exits).
# To keep this script alive we trap exits in the next sample.

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Trapping exits + monitoring")

Process.flag(:trap_exit, true)

monitored = spawn(fn -> exit(:normal) end)
ref       = Process.monitor(monitored)

result = receive do
  {:DOWN, ^ref, :process, _pid, reason} -> reason
after 500 -> :no_message
end

IO.inspect(result, label: "DOWN reason for monitored process")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – State loop (rudimentary GenServer)")

defmodule KVLoop do
  def start_link(initial \\ %{}) do
    spawn_link(fn -> loop(initial) end)
  end

  defp loop(state) do
    receive do
      {:put, key, val} -> loop(Map.put(state, key, val))
      {:get, key, caller} -> send(caller, Map.get(state, key)); loop(state)
      :stop -> :ok
    end
  end
end

store = KVLoop.start_link()
send(store, {:put, :answer, 42})
send(store, {:get, :answer, self()})
IO.inspect(receive do val -> val end, label: "value from KVLoop")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world style: timeout and retry using receive after")

retrying = fn task_fun ->
  parent = self()
  spawn(fn ->
    task_fun.()
    send(parent, :done)
  end)

  receive do
    :done -> :ok
  after 1_000 ->
    IO.puts("taking too long, retrying…")
    retrying.(task_fun)
  end
end

_retry_demo = retrying.(fn -> Process.sleep(1200) end)

# The recursive helper models how libraries implement retry logic with raw
# `receive after`. GenServer abstracts *all* of the above patterns so you only
# write callback functions.

defmodule DayOne.PrimitivesExercises do
  @moduledoc """
  Run the tests with: mix test day_one/07_genserver_primitives.exs
  or in IEx:
  iex -r day_one/07_genserver_primitives.exs
  DayOne.PrimitivesExercisesTest.test_spawn_sum/0
  DayOne.PrimitivesExercisesTest.test_kv_loop_delete/0
  DayOne.PrimitivesExercisesTest.test_ping_pong/0
  """

  @spec spawn_sum(integer(), integer()) :: integer()
  def spawn_sum(_a, _b) do
    #   Write a function that spawns a process which receives two
    #   numbers, adds them, and replies with the result. Demonstrate by sending
    #   the numbers and returning the reply.
    #   Example: spawn_sum(40, 2) => 42
    #   Hint: spawn a process that receives a message with the parent PID and two numbers
    :not_implemented
  end

  @spec kv_loop_with_delete() :: :ok
  def kv_loop_with_delete do
    #   Modify the KVLoop module to support a `:delete` message that removes
    #   a key. Return :ok after demonstrating put, delete, and get operations.
    #   Example workflow: put :test key, delete it, then get it (should return nil)
    :not_implemented
  end

  @spec ping_pong(integer()) :: :ok
  def ping_pong(_n) do
    #   Implement a function that spawns two linked processes which
    #   bounce the atom `:ball` back and forth n times and then exit normally.
    #   Return :ok when the ping-pong is complete.
    #   Example: ping_pong(3) should bounce the ball 3 times total
    :not_implemented
  end
end

# Enhanced KVLoop for the delete exercise
defmodule KVLoopWithDelete do
  def start_link(initial \\ %{}) do
    spawn_link(fn -> loop(initial) end)
  end

  defp loop(state) do
    receive do
      {:put, key, val} -> loop(Map.put(state, key, val))
      {:get, key, caller} -> send(caller, Map.get(state, key)); loop(state)
      {:delete, key} -> loop(Map.delete(state, key))
      :stop -> :ok
    end
  end
end

ExUnit.start()

defmodule DayOne.PrimitivesExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.PrimitivesExercises, as: EX

  test "spawn_sum/2 spawns process to add numbers and return result" do
    assert EX.spawn_sum(40, 2) == 42
    assert EX.spawn_sum(10, 5) == 15
    assert EX.spawn_sum(-3, 3) == 0
  end

  test "kv_loop_with_delete/0 demonstrates delete functionality" do
    assert EX.kv_loop_with_delete() == :ok
  end

  test "ping_pong/1 bounces ball between processes n times" do
    assert EX.ping_pong(3) == :ok
    assert EX.ping_pong(1) == :ok
    assert EX.ping_pong(0) == :ok
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. spawn_sum/2
def spawn_sum(a, b) do
  parent = self()
  spawn(fn -> send(parent, a + b) end)
  receive do
    result -> result
  after 1000 -> :timeout
  end
end
#  Explanation: the spawned process has its own mailbox; by sending the parent
#  the computed sum we avoid shared state—reinforcing message-passing.

# 2. kv_loop_with_delete/0
def kv_loop_with_delete do
  store = KVLoopWithDelete.start_link()
  send(store, {:put, :test, "value"})
  send(store, {:delete, :test})
  send(store, {:get, :test, self()})
  result = receive do
    val -> val
  after 1000 -> :timeout
  end
  send(store, :stop)
  # Should be nil since key was deleted
  if result == nil, do: :ok, else: {:error, :unexpected_value}
end
#  Explanation: rather than mutating, we build a *new* map via Map.delete/2 and
#  tail-recurse, keeping the loop pattern pure.

# 3. ping_pong/1
def ping_pong(n) do
  parent = self()
  p1 = spawn_link(fn -> ping_process(parent) end)
  p2 = spawn_link(fn -> pong_process() end)
  send(p1, {:ball, n, p2})
  receive do
    :done -> :ok
  after 5000 -> :timeout
  end
end

defp ping_process(parent) do
  receive do
    {:ball, 0, _from} -> send(parent, :done)
    {:ball, k, from} ->
      send(from, {:ball, k - 1, self()})
      ping_process(parent)
  end
end

defp pong_process do
  receive do
    {:ball, k, from} ->
      send(from, {:ball, k, self()})
      pong_process()
  end
end
#  Explanation: the atom :ball is bounced n times; counting down in the message
#  payload avoids external counters and demonstrates cooperative recursion.
"""
