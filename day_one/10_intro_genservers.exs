# Day 1 – Intro to GenServers
#
# This script can be run with:
#     mix run day_one/10_intro_genservers.exs
# or inside IEx with:
#     iex -r day_one/10_intro_genservers.exs
#
# A GenServer is a special process that implements the `GenServer` behaviour.
# You specify *callback* functions (`init/1`, `handle_call/3`, `handle_cast/2`,
# etc.) and the runtime supplies the receive-loop, monitoring, logging, and
# back-pressure conveniences so you don't have to.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Minimal GenServer that echoes synchronous calls")

# Step-by-step breakdown of a minimal GenServer:
#
# 👩‍💻 Caller-level overview
#   • `IntroServer.start_link/1` spins up a **new BEAM process** that runs the
#     GenServer loop. The *link* part means the caller will be notified if the
#     server crashes (and vice-versa).
#   • The function returns a **PID**—think of it as the server's phone number.
#     We'll need it whenever we want to talk to that specific process.
#   • `IntroServer.echo/2` wraps `GenServer.call/3`, which performs a
#     *synchronous* round-trip:
#       1. Build a message `{:echo, msg}` tagged with a unique reference.
#       2. Drop it into the server's mailbox.
#       3. Suspend the caller until a reply carrying the same reference comes
#          back (default timeout: 5 s).
#   • Inside the GenServer, the runtime invokes `handle_call/3`. We return
#     `{:reply, msg, state}` so GenServer can send the reply and continue its
#     loop with the (unchanged) state.
#   • From the outside it feels like an ordinary function call—you hand in a
#     value and instantly get one back—yet two isolated processes and a mailbox
#     are doing the hard work.
#
defmodule IntroServer do
  # Step 1: "use GenServer" brings in all the GenServer behavior
  use GenServer

  # Public API (what clients call)
  # Step 2: start_link/1 starts the GenServer process
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :ok, opts)

  # Step 3: echo/2 makes a synchronous call to the server
  def echo(pid, msg), do: GenServer.call(pid, {:echo, msg})

  # Callbacks (what the GenServer framework calls)
  # Step 4: init/1 is called when the server starts - sets initial state
  @impl true
  def init(:ok), do: {:ok, nil}  # Return {:ok, state} to indicate success

  # Step 5: handle_call/3 handles synchronous requests
  @impl true
  def handle_call({:echo, msg}, _from, state) do
    {:reply, msg, state}  # Send msg back to caller, keep same state
  end

  def demo do
    {:ok, pid} = start_link([])
    IO.inspect(echo(pid, "hello"))
  end
end

IntroServer.demo()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Asynchronous casts & internal state")

# Step-by-step breakdown of stateful GenServer with named registration:
#
# 🏷️  **Name registration** (via `name: __MODULE__`) keeps us from juggling
# PIDs—any process on the node can refer to the server simply as `CounterServer`.
#
# 🔄  Two public functions, two experiences:
#   • `inc/0` uses **GenServer.cast/2**—an *asynchronous* fire-and-forget. The
#     caller enqueues `:inc` into the mailbox and continues immediately.
#   • `value/0` uses **GenServer.call/2**—a *synchronous* request that blocks
#     until the server replies with the current count. Writes stay non-blocking;
#     occasional reads remain accurate.
#
defmodule CounterServer do
  use GenServer

  # Client API
  # Step 1: start_link with named registration - no need to track PID
  def start_link(initial \\ 0), do: GenServer.start_link(__MODULE__, initial, name: __MODULE__)

  # Step 2: inc/0 uses cast for async fire-and-forget message
  def inc(), do: GenServer.cast(__MODULE__, :inc)

  # Step 3: value/0 uses call for sync request-response
  def value(), do: GenServer.call(__MODULE__, :value)

  # Server callbacks
  # Step 4: init/1 receives the initial value and sets it as state
  @impl true
  def init(count), do: {:ok, count}

  # Step 5: handle_cast/2 for async operations - no reply needed
  @impl true
  def handle_cast(:inc, count), do: {:noreply, count + 1}

  # Step 6: handle_call/3 for sync operations - must reply
  @impl true
  def handle_call(:value, _from, count), do: {:reply, count, count}
end

# Demo: Start counter at 10, increment twice, check value
{:ok, _} = CounterServer.start_link(10)
CounterServer.inc()
CounterServer.inc()
IO.inspect(CounterServer.value(), label: "counter value")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – handle_info/2 for custom messages & timeouts")

# Step-by-step breakdown of self-sending messages and continue:
#
# ⏲️  **Self-messaging for periodic work**
#   1. `init/1` returns `{:ok, 0, {:continue, :kickoff}}`. The integer `0` is
#      our starting state; `{:continue, ...}` tells GenServer to call
#      `handle_continue/2` right away—before any external messages.
#   2. `handle_continue/2` schedules the first `:tick` with
#      `Process.send_after/3` (1 000 ms) and returns.
#   3. Each `:tick` lands in `handle_info/2`, where we print, increment the
#      state, and schedule the next tick. One GenServer, zero extra processes!
defmodule TimerServer do
  use GenServer

  # Step 1: Simple start_link - no custom API needed for this demo
  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  # Step 2: init/1 returns {:ok, state, {:continue, action}} for immediate action
  @impl true
  def init(:ok) do
    # {:continue, :kickoff} ensures handle_continue runs before any other messages
    {:ok, 0, {:continue, :kickoff}}
  end

  # Step 3: handle_continue/2 runs immediately after init, before other messages
  @impl true
  def handle_continue(:kickoff, state) do
    Process.send_after(self(), :tick, 1_000)  # Schedule first tick in 1 second
    {:noreply, state}
  end

  # Step 4: handle_info/2 handles non-call/cast messages (like our :tick)
  @impl true
  def handle_info(:tick, n) do
    IO.puts("tick #{n}")
    Process.send_after(self(), :tick, 1_000)  # Schedule next tick
    {:noreply, n + 1}  # Increment the counter
  end
end

# Demo: Start timer, let it tick twice, then exit
{:ok, _} = TimerServer.start_link([])
Process.sleep(2200)  # observe two ticks then exit script

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Real-world style: in-memory feature flag cache")

# Step-by-step breakdown of a production-style GenServer with ETS caching:
# ETS is a shared memory store that can be accessed by multiple processes. (Erlang Term Storage)
#
# 🗄️  **Why ETS?** Erlang Term Storage is a high-performance in-memory table
# accessible from *any* process:
#   • Reads are lock-free—ideal for feature-flag checks that happen frequently.
#   • The GenServer acts as the **single writer** refreshing the table on a
#     fixed schedule, ensuring consistency.
#   • If the GenServer crashes the ETS table survives, so callers keep reading
#     stale-but-safe values until a supervisor restarts the refresher.
#
# Refresh workflow → `init/1` ➡️ `handle_continue/2` ➡️ `handle_info/2` (loop):
#   1. Start table and immediately `{:continue, :refresh}`.
#   2. Load latest flags and schedule `:refresh`.
#   3. Every `:refresh` message repeats step 2—hands-free updates!
defmodule FlagsCache do
  use GenServer
  # Module attributes are like constants in other languages.
  @refresh_ms 5000
  @table :flags_cache

  # Public API
  # Step 1: start_link/1 starts the cache server
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  # Step 2: enabled?/1 reads directly from ETS (fast, no GenServer call needed)
  def enabled?(flag) do
    try do
      # 2 is the index of the tuple (key, value)
      :ets.lookup_element(@table, flag, 2)
    rescue
      _ -> false
    end
  end

  # Callbacks
  # Step 3: init/1 creates ETS table and triggers initial refresh
  @impl true
  def init(:ok) do
    :ets.new(@table, [:named_table, :public, :set])
    {:ok, %{}, {:continue, :refresh}}
  end

  # Step 4: handle_continue/2 runs the first refresh and schedules next one
  @impl true
  def handle_continue(:refresh, state) do
    schedule_refresh()
    refresh_flags()
    {:noreply, state}
  end

  # Step 5: handle_info/2 handles scheduled refresh messages
  @impl true
  def handle_info(:refresh, state) do
    refresh_flags()
    schedule_refresh()
    {:noreply, state}
  end

  # Helper functions
  # Step 6: Schedule the next refresh message
  defp schedule_refresh(), do: Process.send_after(self(), :refresh, @refresh_ms)

  # Step 7: Load flags into ETS (in reality, would fetch from DB/API)
  defp refresh_flags() do
    flags = %{beta: true, dark_mode: false}
    Enum.each(flags, fn {k, v} -> :ets.insert(@table, {k, v}) end)
  end
end

# Demo: Start the cache and check a flag value
{:ok, _} = FlagsCache.start_link(nil)
IO.inspect(FlagsCache.enabled?(:beta), label: "beta enabled? (cached)")

defmodule DayOne.GenServerExercises do
  @moduledoc """
  Run the tests with: mix test day_one/10_intro_genservers.exs
  or in IEx:
  iex -r day_one/10_intro_genservers.exs
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
    :ok  # TODO: Implement todo list GenServer
  end

  @spec test_counter_persistence() :: :ok
  def test_counter_persistence do
    #   Update CounterServer to persist its count to a file every 5 seconds
    #   using `handle_info/2` and `Process.send_after/3`. Verify that when you
    #   stop and restart the server it reloads the previous count from disk.
    #   Return :ok when test is complete.
    :ok  # TODO: Implement counter persistence test
  end

  @spec test_intro_server_timeout() :: :ok
  def test_intro_server_timeout do
    #   Add a *timeout* to IntroServer so the process terminates after 3 seconds
    #   of inactivity. Observe its PID before and after the timeout expires.
    #   Return :ok when test demonstrates the timeout behavior.
    :ok  # TODO: Implement timeout test
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

defmodule DayOne.Answers do
  def answer_one do
    quote do
      # The implementation is in the `TodoList` module provided in the exercise.
      # This function demonstrates its use.
      def build_todo_list do
        {:ok, _pid} = TodoList.start_link(nil)
        TodoList.add("Write tests")
        TodoList.add("Refactor code")
        TodoList.add("Deploy")
        IO.inspect(TodoList.all(), label: "Initial Todos")
        TodoList.remove("Refactor code")
        IO.inspect(TodoList.all(), label: "Final Todos")
        :ok
      end
    end
  end

  def answer_two do
    quote do
      # The implementation is in the `PersistentCounterServer` module provided.
      # This function demonstrates its use.
      def test_counter_persistence do
        # Start fresh
        File.rm(PersistentCounterServer.persist_file())

        # Start, increment, and wait for it to persist
        {:ok, pid} = PersistentCounterServer.start_link(nil)
        PersistentCounterServer.inc(pid) # State is 1
        Process.sleep(PersistentCounterServer.persist_interval() + 500)
        GenServer.stop(pid)

        # Restart and check if it loaded state
        {:ok, _pid2} = PersistentCounterServer.start_link(nil)
        assert PersistentCounterServer.value() == 1
        :ok
      end
    end
  end

  def answer_three do
    quote do
      defmodule TimedOutServer do
        use GenServer
        # Implement a GenServer that times out after 1 second of inactivity
        def start_link(_), do: GenServer.start_link(__MODULE__, nil)
        def init(_), do: {:ok, %{}, 1000} # 1000 ms timeout
        def handle_info(:timeout, state) do
          # This is called when the server times out
          IO.puts("Server is timing out due to inactivity!")
          {:stop, :normal, state}
        end
      end

      def test_intro_server_timeout do
        {:ok, pid} = TimedOutServer.start_link(nil)
        assert Process.alive?(pid)
        # Wait for longer than the timeout
        Process.sleep(1100)
        refute Process.alive?(pid)
        :ok
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. build_todo_list/0
#{Macro.to_string(DayOne.Answers.answer_one())}
#  This is a standard GenServer implementation. `add` and `remove` use
#  `cast` because the client doesn't need to wait for a reply (fire-and-forget).
#  `all` uses `call` because the client needs the list of to-dos returned, so
#  it must wait for a synchronous reply.

# 2. test_counter_persistence/0
#{Macro.to_string(DayOne.Answers.answer_two())}
#  This shows how to use `Process.send_after/3` in `init` and `handle_info` to
#  create a recurring task. The server sends itself a `:persist` message every
#  few seconds. The `init` callback is also modified to read from the file on
#  startup, making the state durable between restarts.

# 3. test_intro_server_timeout/0
#{Macro.to_string(DayOne.Answers.answer_three())}
#  GenServer has built-in support for timeouts. By returning a timeout value
#  (in milliseconds) from `init` or any `handle_*` callback, you tell the
#  GenServer to send itself a `:timeout` message if it doesn't receive any other
#  message within that time. This is useful for cleaning up idle processes.
""")
