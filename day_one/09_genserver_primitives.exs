# Day 1 – The Erlang/Elixir Primitives Underpinning GenServer
#
# This script can be run with:
#     mix run day_one/09_genserver_primitives.exs
# or inside IEx with:
#     iex -r day_one/09_genserver_primitives.exs
#
# GenServer is a *behaviour* that wraps several lower-level process features
# available directly in the BEAM. Understanding those primitives demystifies
# GenServer and helps when debugging lower-level issues.
# Each numbered block below is executable & independent.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – spawn/1 & send/2 + receive")

# Step-by-step breakdown of basic process communication:
# Step 1: Spawn a new process that waits for a message
pid = spawn(fn ->
  receive do
    {:hello, from} -> send(from, :world)  # When we get {:hello, sender}, reply with :world
  end
end)

# Step 2: Send a message to the spawned process, including our PID so it can reply
send(pid, {:hello, self()})

# Step 3: Wait for the reply from the spawned process
response = receive do
  msg -> msg          # Accept any message that arrives
after 1000 -> :timeout  # Give up after 1 second if no reply
end

IO.inspect(response, label: "response from spawned process")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Process links for crash propagation")

# spawn/1 vs spawn_link/1:
# - spawn/1 creates an independent process. If it crashes, the parent continues.
# - spawn_link/1 creates a process AND establishes a bidirectional link.
#   If either process crashes, the other one crashes too (unless trapping exits).
# This "fail fast" approach helps detect problems early and prevents
# zombie processes from running with corrupted state.

# Step-by-step breakdown of process linking and crash propagation:
# Step 1: Trap exits so we can handle crashes instead of dying ourselves
Process.flag(:trap_exit, true)

parent = self()
# Step 2: spawn_link creates a process AND links it to us (bidirectional connection)
spawn_link(fn ->
  send(parent, :about_to_crash)  # Tell parent we're about to crash
  raise "boom"                   # Crash with an exception
end)

# Step 3: Wait for the normal message the process sends before crashing
:ok = receive do
  :about_to_crash -> :ok
end

# Step 4: Wait for the special EXIT message that linked processes send when they crash
receive do
  {:EXIT, _pid, reason} ->
    IO.inspect(reason, label: "EXIT reason from linked process")
after 1000 ->
  IO.puts("No EXIT message received")  # This won't run - EXIT arrives quickly
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Trapping exits + monitoring")

# Step-by-step breakdown of process monitoring (vs linking):
# Step 1: Spawn a process that exits normally (not a crash)
monitored = spawn(fn -> exit(:normal) end)

# Step 2: Monitor the process (one-way: we watch it, but it doesn't affect us)
ref = Process.monitor(monitored)

# Step 3: Wait for the DOWN message (monitoring sends DOWN, linking sends EXIT)
result = receive do
  {:DOWN, ^ref, :process, _pid, reason} -> reason  # Pattern match on our specific monitor reference
after 500 -> :no_message
end

IO.inspect(result, label: "DOWN reason for monitored process")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – State loop (rudimentary GenServer)")

# Step-by-step breakdown of a stateful process (like GenServer does internally):
defmodule KVLoop do
  # Step 1: Start function spawns a process running our loop with initial state
  def start_link(initial \\ %{}) do
    spawn_link(fn -> loop(initial) end)  # Start the loop with empty map by default
  end

  # Step 2: The core loop - receives messages and maintains state through recursion
  defp loop(state) do
    receive do
      # Put: store a key-value pair, recurse with new state
      {:put, key, val} -> loop(Map.put(state, key, val))

      # Get: retrieve a value and send it back, continue with same state
      {:get, key, caller} -> send(caller, Map.get(state, key)); loop(state)

      # Stop: exit the loop (terminates the process)
      :stop -> :ok
    end
  end
end

# Step 3: Use our stateful process like a key-value store
store = KVLoop.start_link()              # Create the process
send(store, {:put, :answer, 42})         # Store a value
send(store, {:get, :answer, self()})     # Request the value back
IO.inspect(receive do val -> val end, label: "value from KVLoop")  # Print the result

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world style: timeout and retry using receive after")

# Step-by-step breakdown of the retry pattern:
# task_fun = the function we want to execute (passed in as first argument)
# retry_fn = reference to ourselves for recursion (passed in as second argument)
retrying = fn task_fun, retry_fn ->
  # Step 1: Remember who the parent process is (so spawned process can send back)
  parent = self()

  # Step 2: Spawn a process to run the potentially slow task
  spawn(fn ->
    task_fun.()           # Execute the task (might be slow)
    send(parent, :done)   # Tell parent we're finished
  end)

  # Step 3: Wait for completion with a timeout
  receive do
    :done ->
      IO.puts("task completed in time - success!")
      :ok
  after 1_000 ->          # Task took longer than 1 second
    IO.puts("taking too long, retrying…")
    retry_fn.(task_fun, retry_fn)  # Try again (recursive call)
  end
end

# Demo: task that sleeps 1200ms (longer than 1000ms timeout) so it will retry
# Here, task_fun becomes: fn -> Process.sleep(1200) end
# And retry_fn becomes: retrying (reference to the function itself)
_retry_demo = retrying.(fn -> Process.sleep(1200) end, retrying)

# The recursive helper models how libraries implement retry logic with raw
# `receive after`. GenServer abstracts *all* of the above patterns so you only
# write callback functions.

defmodule DayOne.PrimitivesExercises do
  @moduledoc """
  Run the tests with: mix test day_one/09_genserver_primitives.exs
  or in IEx:
  iex -r day_one/09_genserver_primitives.exs
  DayOne.PrimitivesExercisesTest.test_spawn_sum/0
  DayOne.PrimitivesExercisesTest.test_kv_loop_delete/0
  DayOne.PrimitivesExercisesTest.test_ping_pong/0
  """

  @spec spawn_sum(integer(), integer()) :: integer()
  def spawn_sum(a, b) do
    #   Write a function that spawns a process which receives two
    #   numbers, adds them, and replies with the result. Demonstrate by sending
    #   the numbers and returning the reply.
    #   Example: spawn_sum(40, 2) => 42
    #   Hint: spawn a process that receives a message with the parent PID and two numbers
    a + b  # TODO: Implement using spawn and message passing
  end

  @spec kv_loop_with_delete() :: :ok
  def kv_loop_with_delete do
    #   Modify the KVLoop module to support a `:delete` message that removes
    #   a key. Return :ok after demonstrating put, delete, and get operations.
    #   Example workflow: put :test key, delete it, then get it (should return nil)
    :ok  # TODO: Implement KV loop with delete functionality
  end

  @spec ping_pong(integer()) :: :ok
  def ping_pong(_n) do
    #   Implement a function that spawns two linked processes which
    #   bounce the atom `:ball` back and forth n times and then exit normally.
    #   Return :ok when the ping-pong is complete.
    #   Example: ping_pong(3) should bounce the ball 3 times total
    :ok  # TODO: Implement ping-pong process communication
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
