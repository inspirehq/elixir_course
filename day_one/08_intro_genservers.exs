# Day 1 – Intro to GenServers
#
# Run with `iex -S mix` and then `IntroServer.demo/0` OR simply:
#     mix run elixir_course/day_one/08_intro_genservers.exs
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

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Build a GenServer `TodoList` that holds a list of strings. Expose
#    `add/1`, `remove/1`, and `all/0` public functions.  Write a short script
#    that starts the server, adds three items, removes one, and prints the
#    remaining list.
# 2. Update `CounterServer` so it persists its count to a file every 5 seconds
#    using `handle_info/2` and `Process.send_after/3`.  Verify that when you
#    stop and restart the server (within the same VM) it reloads the previous
#    count from disk.
# 3. (Challenge) Add a *timeout* to `IntroServer` so the process terminates
#    after 3 seconds of inactivity.  Observe its PID before and after the
#    timeout expires.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. TodoList GenServer
#    Keeps list state, demonstrates handle_cast / handle_call pattern.
#
#    defmodule TodoList do
#      use GenServer
#      def start_link(_),    do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
#      def add(item),        do: GenServer.cast(__MODULE__, {:add, item})
#      def remove(item),     do: GenServer.cast(__MODULE__, {:remove, item})
#      def all,              do: GenServer.call(__MODULE__, :all)
#      @impl true
#      def init(l), do: {:ok, l}
#      @impl true
#      def handle_cast({:add, i}, l),    do: {:noreply, [i | l]}
#      def handle_cast({:remove, i}, l), do: {:noreply, List.delete(l, i)}
#      @impl true
#      def handle_call(:all, _f, l),     do: {:reply, Enum.reverse(l), l}
#    end
#
#    # Demo
#    {:ok, _} = TodoList.start_link(nil)
#    TodoList.add("buy milk"); TodoList.add("code")
#    TodoList.remove("buy milk")
#    IO.inspect(TodoList.all())
#
#    Why correct?  State is internal; public API shows GenServer encapsulation.
#
# 2. Persistence with CounterServer
#    Add in init:
#       count = if File.exists?("count.txt"), do: {:ok, c} = Integer.parse(File.read!("count.txt")); c, else: init
#    Add in handle_info(:persist,…): File.write!("count.txt", Integer.to_string(count)); schedule again.
#    Explanation: demonstrates side-effects via handle_info while keeping API pure.
#
# 3. Timeout for IntroServer
#    In start_link/1 pass `timeout: 3_000` or inside init return {:ok, nil, 3_000}.
#    handle_info(:timeout, state) -> {:stop, :normal, state}.
#    Observe that after inactivity PID goes down, showing built-in idle timeout.
"""
