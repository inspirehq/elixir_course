# Day 1 – The Erlang/Elixir Primitives Underpinning GenServer
#
# Run with `mix run elixir_course/day_one/07_genserver_primitives.exs`
# (from the umbrella root, adjust path if needed).
#
# GenServer is a *behaviour* that wraps several lower-level process features
# available directly in the BEAM.  Understanding those primitives demystifies
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

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES – try these on your own
#
# 1. Write a function `spawn_sum/2` that spawns a process which receives two
#    numbers, adds them, and replies with the result.  Demonstrate by sending
#    `{self(), 40, 2}` and printing the reply (42).
# 2. Modify the `KVLoop` module so it supports a `:delete` message that removes
#    a key.  Verify it by putting a key, deleting it, and then attempting to
#    get it (should return nil).
# 3. Implement a `ping_pong(n)` function that spawns two linked processes which
#    bounce the atom `:ball` back and forth *n* times and then exit normally.

"""
🔑 ANSWERS

# 1. spawn_sum/2
spawn_sum = fn a, b ->
  parent = self()
  spawn(fn -> send(parent, a + b) end)
end
spawn_sum.(40, 2)
IO.inspect(receive do x -> x end, label: "sum reply")
#  Explanation: the spawned process has its own mailbox; by sending the parent
#  the computed sum we avoid shared state—reinforcing message-passing.

# 2. delete support in KVLoop (patch):
#   add clause {:delete, key} -> loop(Map.delete(state, key))
#   Usage:
#       send(store, {:delete, :answer})
#  Explanation: rather than mutating, we build a *new* map via Map.delete/2 and
#  tail-recurse, keeping the loop pattern pure.

# 3. ping_pong/1
ping_pong = fn n ->
  parent = self()
  p1 = spawn_link(fn ->
    receive do
      {:ball, 0, _from} -> send(parent, :done)
      {:ball, k, from}  -> send(from, {:ball, k - 1, self()})
    end
  end)
  p2 = spawn_link(fn ->
    receive do
      {:ball, k, from} -> send(from, {:ball, k, self()})
    end
  end)
  send(p1, {:ball, n, p2})
  receive do :done -> :ok end
end

ping_pong.(3)
#  Explanation: the atom :ball is bounced n times; counting down in the message
#  payload avoids external counters and demonstrates cooperative recursion.
"""
