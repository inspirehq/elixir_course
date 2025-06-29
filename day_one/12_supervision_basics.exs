# Day 1 – Supervision Basics
#
# This script can be run with:
#     mix run day_one/12_supervision_basics.exs
# or inside IEx with:
#     iex -r day_one/12_supervision_basics.exs
#
# A *Supervisor* is a process that watches its children and restarts them
# according to the configured strategy. This file demonstrates:
#   • one_for_one vs. one_for_all supervision strategies
#   • temporary vs. transient vs. permanent restart modes
#   • `Supervisor.child_spec/2` for custom specifications
#   • a real-world miniature supervision tree resembling a web app cache layer
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – one_for_one strategy")
# STEP 1: Understanding the one_for_one strategy
# In one_for_one supervision, when a child process crashes, ONLY that specific
# child is restarted. Other children continue running unaffected.
# This is the most commonly used strategy in production systems.

alias __MODULE__.ToyWorker

defmodule ToyWorker do
  use GenServer

  # STEP 2: Creating a minimal GenServer for demonstration
  # This worker does almost nothing - it just starts up and can be told to crash
  def start_link(name), do: GenServer.start_link(__MODULE__, :ok, name: name)

  @impl true
  def init(:ok), do: {:ok, nil}

  # STEP 3: Implementing a deliberate crash mechanism
  # In real systems, processes crash due to bugs, network issues, resource exhaustion, etc.
  # For learning purposes, we provide a way to crash on demand
  @impl true
  def handle_cast(:crash, _), do: raise "boom"
end

# STEP 4: Setting up children and supervisor
# Children list defines what processes the supervisor manages
# Each child spec contains: {module, arguments_for_start_link}
# When using the same module multiple times, we need unique IDs
children = [
  Supervisor.child_spec({ToyWorker, :a}, id: :worker_a),  # Unique ID for first worker
  Supervisor.child_spec({ToyWorker, :b}, id: :worker_b)   # Unique ID for second worker
]

# STEP 5: Starting the supervisor with one_for_one strategy
# The supervisor becomes responsible for these two child processes
{:ok, sup} = Supervisor.start_link(children, strategy: :one_for_one)

# STEP 6: Demonstrating isolated restart behavior
# When we crash :a, only :a should restart - :b should be unaffected
GenServer.cast(:a, :crash)

# STEP 7: Giving time for the restart to complete
# Process restarts are asynchronous, so we pause briefly to let it happen
Process.sleep(100)

# STEP 8: Verifying the isolation principle
# Both processes should be alive after the restart:
# - :a is alive because the supervisor restarted it
# - :b is alive because it was never affected by :a's crash
IO.inspect(Process.alive?(Process.whereis(:a)), label: ":a alive after restart?")
IO.inspect(Process.alive?(Process.whereis(:b)), label: ":b still alive?")

# STEP 8.5: Clean up the first supervisor before starting the second example
Supervisor.stop(sup)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – one_for_all strategy")
# STEP 9: Understanding the one_for_all strategy
# In one_for_all supervision, when ANY child crashes, ALL children are terminated
# and then ALL are restarted. This ensures all children start from a clean state.
# Use this when child processes have interdependencies.

# STEP 10: Creating a new supervisor with different strategy
# Same children, but now with one_for_all strategy
{:ok, sup2} = Supervisor.start_link(children, strategy: :one_for_all)

# STEP 11: Demonstrating cascade restart behavior
# Crashing :a will now cause BOTH :a and :b to be restarted
GenServer.cast(:a, :crash)
Process.sleep(100)

# STEP 12: Observing that both processes were affected
# Both should be alive, but both were restarted (got new PIDs)
IO.inspect(Process.alive?(Process.whereis(:a)), label: ":a alive (all)")
IO.inspect(Process.alive?(Process.whereis(:b)), label: ":b alive (all)")

# STEP 13: Cleaning up supervisor resources
# Important: Always clean up supervisors to prevent resource leaks in scripts
Supervisor.stop(sup2)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Restart modes (temporary child never restarts)")
# STEP 14: Understanding restart modes
# - :permanent (default): Always restart when child terminates
# - :transient: Restart only if child terminates abnormally (crash)
# - :temporary: Never restart, even if child crashes

# STEP 15: Creating a custom child specification
# child_spec/2 allows us to override default behaviors like restart mode
temp_spec = Supervisor.child_spec({ToyWorker, :temp}, restart: :temporary, id: :temp)

# STEP 16: Starting supervisor with temporary child
# This child will NOT be restarted if it crashes
{:ok, sup3} = Supervisor.start_link([temp_spec], strategy: :one_for_one)

# STEP 17: Crashing a temporary child
# Since restart mode is :temporary, this child won't be restarted
GenServer.cast(:temp, :crash)
Process.sleep(100)

# STEP 18: Confirming no restart occurred
# Process.whereis/1 returns nil when a named process doesn't exist
# This proves the temporary child was not restarted after crashing
IO.inspect(Process.whereis(:temp), label: ":temp pid after crash (should be nil)")
Supervisor.stop(sup3)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Real-world: cache + refresher supervisor")
# STEP 19: Building a realistic supervision tree
# This example shows how supervision works in real applications
# We'll build a simple cache system with automatic refresh capability

defmodule Cache do
  use GenServer

  # STEP 20: Cache GenServer for storing key-value data
  # This represents a typical caching layer in web applications
  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def put(k, v), do: GenServer.cast(__MODULE__, {:put, k, v})
  def get(k), do: GenServer.call(__MODULE__, {:get, k})

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast({:put, k, v}, s), do: {:noreply, Map.put(s, k, v)}

  @impl true
  def handle_call({:get, k}, _f, s), do: {:reply, Map.get(s, k), s}
end

defmodule Refresher do
  use GenServer
  @interval 1_000

  # STEP 21: Background process for automatic cache updates
  # This simulates a worker that periodically refreshes cached data
  # Common pattern: background jobs, health checks, metrics collection
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    # STEP 22: Self-scheduling pattern
    # Process schedules its own work using send_after
    # This ensures work continues even after restarts
    schedule()
    {:ok, nil}
  end

  @impl true
  def handle_info(:refresh, s) do
    # STEP 23: Performing the background work
    # Updates cache with current timestamp every second
    # In real apps: fetch from database, call external APIs, etc.
    Cache.put(:timestamp, DateTime.utc_now())

    # STEP 24: Scheduling next iteration
    # Critical: reschedule after each execution to continue the cycle
    schedule()
    {:noreply, s}
  end

  # STEP 25: Private helper for consistent scheduling
  defp schedule, do: Process.send_after(self(), :refresh, @interval)
end

# STEP 26: Creating the supervision tree
# Both Cache and Refresher are supervised together
# If either crashes, only that one restarts (one_for_one)
# The other continues working, maintaining system availability
{:ok, _cache_sup} = Supervisor.start_link([
  Cache,     # Will be restarted if it crashes
  Refresher  # Will be restarted if it crashes, and will resume scheduling
], strategy: :one_for_one)

# STEP 27: Demonstrating the working system
# After 1+ seconds, the refresher should have updated the cache
Process.sleep(1100)
IO.inspect(Cache.get(:timestamp), label: "cached timestamp")

defmodule DayOne.SupervisionExercises do
  @moduledoc """
  Run the tests with: mix test day_one/12_supervision_basics.exs
  or in IEx:
  iex -r day_one/12_supervision_basics.exs
  DayOne.SupervisionExercisesTest.test_rest_for_one/0
  DayOne.SupervisionExercisesTest.test_dynamic_supervisor/0
  DayOne.SupervisionExercisesTest.test_max_restarts/0
  """

  @spec test_rest_for_one() :: :ok
  def test_rest_for_one do
    #   Change the supervision strategy to `:rest_for_one` and observe how crashing
    #   `:a` affects (or doesn't affect) other siblings. Document your findings.
    #   Return :ok after demonstrating the behavior.
    :ok  # TODO: Implement rest_for_one strategy test
  end

  @spec test_dynamic_supervisor() :: :ok
  def test_dynamic_supervisor do
    #   Create a *dynamic* supervisor (`DynamicSupervisor`) that starts new
    #   `ToyWorker` processes on demand. Spawn three workers and then terminate
    #   one manually—confirm the others stay alive. Return :ok when complete.
    :ok  # TODO: Implement dynamic supervisor test
  end

  @spec test_max_restarts() :: :ok
  def test_max_restarts do
    #   Experiment with `max_restarts` and `max_seconds` options by
    #   making `ToyWorker` crash repeatedly. At what point does the supervisor give
    #   up? Try different configurations and return :ok when demonstrated.
    :ok  # TODO: Implement max restarts test
  end
end

# Helper worker for dynamic supervisor exercise
defmodule DynamicToyWorker do
  use GenServer

  def start_link(id), do: GenServer.start_link(__MODULE__, id, name: :"worker_#{id}")

  @impl true
  def init(id), do: {:ok, id}

  @impl true
  def handle_cast(:crash, _), do: raise "boom"

  @impl true
  def handle_call(:get_id, _from, id), do: {:reply, id, id}
end

# Crashy worker for max_restarts exercise
defmodule CrashyWorker do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, 0, name: __MODULE__)

  @impl true
  def init(count) do
    # Crash immediately on every restart except the first
    if count > 0, do: raise("crash ##{count}")
    {:ok, count + 1}
  end
end

ExUnit.start()

defmodule DayOne.SupervisionExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.SupervisionExercises, as: EX

  test "test_rest_for_one/0 demonstrates rest_for_one supervision strategy" do
    assert EX.test_rest_for_one() == :ok
  end

  test "test_dynamic_supervisor/0 shows dynamic child management" do
    assert EX.test_dynamic_supervisor() == :ok
  end

  test "test_max_restarts/0 demonstrates supervisor restart limits" do
    assert EX.test_max_restarts() == :ok
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def test_rest_for_one do
        children = [
          Supervisor.child_spec({ToyWorker, :a}, id: :a),
          Supervisor.child_spec({ToyWorker, :b}, id: :b),
          Supervisor.child_spec({ToyWorker, :c}, id: :c)
        ]

        {:ok, sup} = Supervisor.start_link(children, strategy: :rest_for_one)
        # B is before A in the start list, so it's unaffected.
        b_pid_before = Process.whereis(:b)
        # A is after B, so it will be restarted.
        c_pid_before = Process.whereis(:c)

        # Crash worker B
        GenServer.cast(:b, :crash)
        Process.sleep(100)

        # A is unaffected, B and C are restarted.
        assert Process.whereis(:a) == b_pid_before
        assert Process.whereis(:b) != c_pid_before
        assert Process.whereis(:c) != nil
        Supervisor.stop(sup)
        :ok
      end
    end
  end

  def answer_two do
    quote do
      def test_dynamic_supervisor do
        {:ok, sup} = DynamicSupervisor.start_link(strategy: :one_for_one)
        # Start three children dynamically
        {:ok, _pid1} = DynamicSupervisor.start_child(sup, DynamicToyWorker)
        {:ok, pid2} = DynamicSupervisor.start_child(sup, DynamicToyWorker)
        {:ok, _pid3} = DynamicSupervisor.start_child(sup, DynamicToyWorker)

        # Terminate one child
        DynamicSupervisor.terminate_child(sup, pid2)
        Process.sleep(100)

        # Verify others are still alive
        assert length(DynamicSupervisor.which_children(sup)) == 2
        Supervisor.stop(sup)
        :ok
      end
    end
  end

  def answer_three do
    quote do
      def test_max_restarts do
        # Allow 2 restarts in 1 second
        opts = [strategy: :one_for_one, max_restarts: 2, max_seconds: 1]
        children = [CrashyWorker]

        {:ok, sup} = Supervisor.start_link(children, opts)
        worker_pid = hd(Supervisor.which_children(sup)) |> elem(1)

        # 3 crashes in quick succession should exceed the limit
        Process.exit(worker_pid, :kill)
        Process.sleep(100)
        Process.exit(hd(Supervisor.which_children(sup)) |> elem(1), :kill)
        Process.sleep(100)
        Process.exit(hd(Supervisor.which_children(sup)) |> elem(1), :kill)
        Process.sleep(100)

        # The supervisor itself should now be dead
        refute Process.alive?(sup)
        :ok
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. test_rest_for_one/0
#{Macro.to_string(DayOne.Answers.answer_one())}
#  The `:rest_for_one` strategy is useful when children have dependencies based
#  on their start order. When a child crashes, it and any children started *after*
#  it are restarted. Children started *before* it are unaffected.

# 2. test_dynamic_supervisor/0
#{Macro.to_string(DayOne.Answers.answer_two())}
#  A `DynamicSupervisor` is the right tool when you don't know all the children
#  up front. Unlike a regular `Supervisor`, you can add and remove children
#  at runtime using `start_child`/`terminate_child`, making it ideal for things
#  like managing user session processes or connection pools.

# 3. test_max_restarts/0
#{Macro.to_string(DayOne.Answers.answer_three())}
#  The `max_restarts` and `max_seconds` options are a safety valve. They prevent
#  a faulty child from getting stuck in an infinite crash-restart loop, which
#  could consume system resources. If the restart frequency exceeds the limit,
#  the supervisor terminates itself and all its children, escalating the failure.
""")
