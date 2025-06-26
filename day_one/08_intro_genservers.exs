# Day 1 – Intro to GenServers
#
# This script can be run with:
#     mix run day_one/08_intro_genservers.exs
# or inside IEx with:
#     iex -r day_one/08_intro_genservers.exs
#
# A GenServer is a special process that implements the `GenServer` behaviour.
# You specify *callback* functions (`init/1`, `handle_call/3`, `handle_cast/2`,
# etc.) and the runtime supplies the receive-loop, monitoring, logging, and
# back-pressure conveniences so you don't have to.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Minimal GenServer that echoes synchronous calls")

alias __MODULE__, as: IntroServer

defmodule IntroServer do
  use GenServer

  # Public API
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :ok, opts)
  def echo(pid, msg),         do: GenServer.call(pid, {:echo, msg})

  # Callbacks
  @impl true
  def init(:ok), do: {:ok, nil}

  @impl true
  def handle_call({:echo, msg}, _from, state) do
    {:reply, msg, state}
  end

  # Demo helper so learners can run with mix run
  def demo do
    {:ok, pid} = start_link([])
    IO.inspect(echo(pid, "hello"))
  end
end

IntroServer.demo()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Asynchronous casts & internal state")

defmodule CounterServer do
  use GenServer
  # Client API
  def start_link(initial \\ 0), do: GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  def inc(), do: GenServer.cast(__MODULE__, :inc)
  def value(), do: GenServer.call(__MODULE__, :value)

  # Server callbacks
  @impl true
  def init(count), do: {:ok, count}

  @impl true
  def handle_cast(:inc, count), do: {:noreply, count + 1}

  @impl true
  def handle_call(:value, _from, count), do: {:reply, count, count}
end

{:ok, _} = CounterServer.start_link(10)
CounterServer.inc()
CounterServer.inc()
IO.inspect(CounterServer.value(), label: "counter value")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – handle_info/2 for custom messages & timeouts")

defmodule TimerServer do
  use GenServer
  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    # send self a message after 1s
    {:ok, 0, {:continue, :kickoff}}
  end

  @impl true
  def handle_continue(:kickoff, state) do
    Process.send_after(self(), :tick, 1_000)
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, n) do
    IO.puts("tick #{n}")
    Process.send_after(self(), :tick, 1_000)
    {:noreply, n + 1}
  end
end

{:ok, _} = TimerServer.start_link([])
Process.sleep(2200)  # observe two ticks then exit script

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Real-world style: in-memory feature flag cache")

defmodule Flags.Cache do
  use GenServer
  @refresh_ms 5_000
  @table :flags_cache

  # API
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  def enabled?(flag), do: :ets.lookup_element(@table, flag, 2) rescue false

  # Callbacks
  @impl true
  def init(:ok) do
    :ets.new(@table, [:named_table, :public, :set])
    {:ok, %{}, {:continue, :refresh}}
  end

  @impl true
  def handle_continue(:refresh, state) do
    schedule_refresh()
    refresh_flags()
    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    refresh_flags()
    schedule_refresh()
    {:noreply, state}
  end

  # Helpers
  defp schedule_refresh(), do: Process.send_after(self(), :refresh, @refresh_ms)

  defp refresh_flags() do
    # In reality fetch from DB/external service.
    flags = %{beta: true, dark_mode: false}
    Enum.each(flags, fn {k, v} -> :ets.insert(@table, {k, v}) end)
  end
end

{:ok, _} = Flags.Cache.start_link(nil)
IO.inspect(Flags.Cache.enabled?(:beta), label: "beta enabled? (cached)")

defmodule DayOne.GenServerExercises do
  @moduledoc """
  Run the tests with: mix test day_one/08_intro_genservers.exs
  or in IEx:
  iex -r day_one/08_intro_genservers.exs
  DayOne.GenServerExercisesTest.test_todo_list/0
  DayOne.GenServerExercisesTest.test_counter_persistence/0
  DayOne.GenServerExercisesTest.test_intro_server_timeout/0
  """

  @spec build_todo_list() :: :ok
  def build_todo_list do
    #   Build a GenServer `TodoList` that holds a list of strings. Expose
    #   `add/1`, `remove/1`, and `all/0` public functions. Write a short script
    #   that starts the server, adds three items, removes one, and prints the
    #   remaining list. Return :ok when complete.
    :not_implemented
  end

  @spec test_counter_persistence() :: :ok
  def test_counter_persistence do
    #   Update CounterServer to persist its count to a file every 5 seconds
    #   using `handle_info/2` and `Process.send_after/3`. Verify that when you
    #   stop and restart the server it reloads the previous count from disk.
    #   Return :ok when test is complete.
    :not_implemented
  end

  @spec test_intro_server_timeout() :: :ok
  def test_intro_server_timeout do
    #   Add a *timeout* to IntroServer so the process terminates after 3 seconds
    #   of inactivity. Observe its PID before and after the timeout expires.
    #   Return :ok when test demonstrates the timeout behavior.
    :not_implemented
  end
end

defmodule TodoList do
  use GenServer

  # Public API
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def add(item), do: GenServer.cast(__MODULE__, {:add, item})
  def remove(item), do: GenServer.cast(__MODULE__, {:remove, item})
  def all, do: GenServer.call(__MODULE__, :all)

  # Callbacks
  @impl true
  def init(list), do: {:ok, list}

  @impl true
  def handle_cast({:add, item}, list), do: {:noreply, [item | list]}

  @impl true
  def handle_cast({:remove, item}, list), do: {:noreply, List.delete(list, item)}

  @impl true
  def handle_call(:all, _from, list), do: {:reply, Enum.reverse(list), list}
end

defmodule PersistentCounterServer do
  use GenServer
  @persist_file "counter_state.txt"
  @persist_interval 5_000

  # Client API
  def start_link(initial \\ 0) do
    count = load_count() || initial
    GenServer.start_link(__MODULE__, count, name: __MODULE__)
  end

  def inc(), do: GenServer.cast(__MODULE__, :inc)
  def value(), do: GenServer.call(__MODULE__, :value)

  # Server callbacks
  @impl true
  def init(count) do
    schedule_persist()
    {:ok, count}
  end

  @impl true
  def handle_cast(:inc, count), do: {:noreply, count + 1}

  @impl true
  def handle_call(:value, _from, count), do: {:reply, count, count}

  @impl true
  def handle_info(:persist, count) do
    File.write!(@persist_file, Integer.to_string(count))
    schedule_persist()
    {:noreply, count}
  end

  defp schedule_persist(), do: Process.send_after(self(), :persist, @persist_interval)

  defp load_count do
    if File.exists?(@persist_file) do
      @persist_file |> File.read!() |> String.trim() |> String.to_integer()
    else
      nil
    end
  end
end

defmodule TimeoutIntroServer do
  use GenServer
  @timeout 3_000

  # Public API
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :ok, opts)
  def echo(pid, msg), do: GenServer.call(pid, {:echo, msg})

  # Callbacks
  @impl true
  def init(:ok), do: {:ok, nil, @timeout}

  @impl true
  def handle_call({:echo, msg}, _from, state) do
    {:reply, msg, state, @timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end
end

ExUnit.start()

defmodule DayOne.GenServerExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.GenServerExercises, as: EX

  test "build_todo_list/0 creates and manipulates a todo list GenServer" do
    assert EX.build_todo_list() == :ok
  end

  test "test_counter_persistence/0 verifies counter persists to disk" do
    # Clean up any existing state file
    File.rm("counter_state.txt")
    assert EX.test_counter_persistence() == :ok
  end

  test "test_intro_server_timeout/0 demonstrates server timeout behavior" do
    assert EX.test_intro_server_timeout() == :ok
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. build_todo_list/0
def build_todo_list do
  {:ok, _} = TodoList.start_link(nil)
  TodoList.add("buy milk")
  TodoList.add("write code")
  TodoList.add("exercise")
  TodoList.remove("buy milk")
  remaining = TodoList.all()
  IO.inspect(remaining, label: "remaining todos")
  :ok
end
#  Why correct? State is internal; public API shows GenServer encapsulation.
#  The TodoList keeps items in reverse order for O(1) prepend, then reverses for display.

# 2. test_counter_persistence/0
def test_counter_persistence do
  {:ok, _} = PersistentCounterServer.start_link(5)
  PersistentCounterServer.inc()
  PersistentCounterServer.inc()
  initial_value = PersistentCounterServer.value()

  # Wait for persistence to occur
  Process.sleep(6000)

  # Simulate restart by stopping current server and starting new one
  GenServer.stop(PersistentCounterServer)
  {:ok, _} = PersistentCounterServer.start_link(0)  # Would start at 0 without persistence
  reloaded_value = PersistentCounterServer.value()

  if initial_value == reloaded_value do
    :ok
  else
    {:error, {:values_differ, initial_value, reloaded_value}}
  end
end
#  Explanation: demonstrates side-effects via handle_info while keeping API pure.
#  The counter loads from disk on startup and persists every 5 seconds.

# 3. test_intro_server_timeout/0
def test_intro_server_timeout do
  {:ok, pid} = TimeoutIntroServer.start_link()
  IO.inspect(pid, label: "server pid before timeout")

  # Test that server is alive initially
  result = TimeoutIntroServer.echo(pid, "test")
  IO.inspect(result, label: "echo result")

  # Wait for timeout to occur
  Process.sleep(4000)

  # Check if process is still alive
  alive_after_timeout = Process.alive?(pid)
  IO.inspect(alive_after_timeout, label: "alive after timeout?")

  if alive_after_timeout == false do
    :ok
  else
    {:error, :server_did_not_timeout}
  end
end
#  Explanation: After inactivity, the built-in idle timeout terminates the process,
#  showing how GenServer provides timeout handling out of the box.
"""
