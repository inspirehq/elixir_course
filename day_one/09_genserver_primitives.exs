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

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def spawn_sum(a, b) do
        parent = self()
        # Spawn a process that will do the work.
        spawn(fn ->
          # Send the result back to the parent process.
          send(parent, a + b)
        end)
        # Wait to receive the result from the spawned process.
        receive do
          result when is_integer(result) -> result
        after
          1000 -> :timeout
        end
      end
    end
  end

  def answer_two do
    quote do
      # This function demonstrates the new functionality. The implementation
      # is in the `KVLoopWithDelete` module provided in the exercise.
      def kv_loop_with_delete do
        store = KVLoopWithDelete.start_link(%{a: 1})
        # Put
        send(store, {:put, :b, 2})
        send(store, {:get, :b, self()})
        assert receive(do: (val -> val)) == 2
        # Delete
        send(store, {:delete, :b})
        send(store, {:get, :b, self()})
        assert receive(do: (val -> val)) == nil
        # Stop
        send(store, :stop)
        :ok
      end
    end
  end

  def answer_three do
    quote do
      def ping_pong(n) do
        # Get a reference to the current process (the "parent")
        parent = self()
        # Spawn player_one, giving it the parent's PID
        player_one_pid = spawn_link(fn -> player_one(parent, n) end)
        # Send the "ball" to player one to start the game
        send(player_one_pid, {:ball, self()})
        # Wait for the game to be over
        receive do
          :game_over -> :ok
        end
      end

      # Player one waits for the ball from player two
      defp player_one(player_two_pid, 0) do
        # Base case: game is over, tell the parent
        send(player_two_pid, :game_over)
      end
      defp player_one(player_two_pid, n) do
        receive do
          # Got the ball, send it back to player two
          {:ball, _} -> send(player_two_pid, {:ball, self()})
        end
        # Recurse with n-1
        player_one(player_two_pid, n - 1)
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. spawn_sum/2
#{Macro.to_string(DayOne.Answers.answer_one())}
#  This demonstrates the fundamental "client-server" pattern in Erlang/Elixir.
#  The parent process (`self()`) acts as the client, spawning a server process
#  to do some work. The client sends a message and then enters a `receive`
#  block to await the response.

# 2. kv_loop_with_delete/0
#{Macro.to_string(DayOne.Answers.answer_two())}
#  This shows how to extend a stateful process loop. By adding a new `receive`
#  clause for `{:delete, key}`, we can handle a new type of message. The state
#  (the map) is immutable, so `Map.delete/2` returns a *new* map, which is then
#  passed into the next iteration of the `loop`.

# 3. ping_pong/1
#{Macro.to_string(DayOne.Answers.answer_three())}
#  This is a more complex example of two processes communicating. It shows how
#  PIDs are passed around to allow processes to know who to send messages to.
#  The recursive calls with a decreasing counter (`n`) serve as the state that
#  determines when the process should stop.
""")
