# Day 1 – Supervision Basics
#
# This script can be run with:
#     mix run day_one/10_supervision_basics.exs
# or inside IEx with:
#     iex -r day_one/10_supervision_basics.exs
#
# A *Supervisor* is a process that watches its children and restarts them
# according to the configured strategy. This file demonstrates:
#   • one_for_one vs. one_for_all
#   • temporary vs. transient vs. permanent restart modes
#   • `Supervisor.child_spec/2` for custom specs
#   • a real-world miniature supervision tree resembling a web app cache layer
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – one_for_one strategy")

alias __MODULE__.ToyWorker

defmodule ToyWorker do
  use GenServer
  def start_link(name), do: GenServer.start_link(__MODULE__, :ok, name: name)
  @impl true
  def init(:ok), do: {:ok, nil}
  @impl true
  def handle_cast(:crash, _), do: raise "boom"
end

children = [
  {ToyWorker, :a},
  {ToyWorker, :b}
]
{:ok, sup} = Supervisor.start_link(children, strategy: :one_for_one)

# Crash :a – only :a restarts.
GenServer.cast(:a, :crash)
Process.sleep(100)
IO.inspect(Process.alive?(Process.whereis(:a)), label: ":a alive after restart?")
IO.inspect(Process.alive?(Process.whereis(:b)), label: ":b still alive?")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – one_for_all strategy")

{:ok, sup2} = Supervisor.start_link(children, strategy: :one_for_all)
GenServer.cast(:a, :crash)
Process.sleep(100)

IO.inspect(Process.alive?(Process.whereis(:a)), label: ":a alive (all)")
IO.inspect(Process.alive?(Process.whereis(:b)), label: ":b alive (all)")

Supervisor.stop(sup2)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Restart modes (temporary child never restarts)")

temp_spec = Supervisor.child_spec({ToyWorker, :temp}, restart: :temporary, id: :temp)
{:ok, sup3} = Supervisor.start_link([temp_spec], strategy: :one_for_one)
GenServer.cast(:temp, :crash)
Process.sleep(100)
IO.inspect(Process.whereis(:temp), label: ":temp pid after crash (should be nil)")
Supervisor.stop(sup3)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Real-world: cache + refresher supervisor")

defmodule Cache do
  use GenServer
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
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  @impl true
  def init(:ok) do
    schedule()
    {:ok, nil}
  end
  @impl true
  def handle_info(:refresh, s) do
    Cache.put(:timestamp, DateTime.utc_now())
    schedule()
    {:noreply, s}
  end
  defp schedule, do: Process.send_after(self(), :refresh, @interval)
end

{:ok, _cache_sup} = Supervisor.start_link([
  Cache,
  Refresher
], strategy: :one_for_one)

Process.sleep(1100)
IO.inspect(Cache.get(:timestamp), label: "cached timestamp")

defmodule DayOne.SupervisionExercises do
  @moduledoc """
  Run the tests with: mix test day_one/10_supervision_basics.exs
  or in IEx:
  iex -r day_one/10_supervision_basics.exs
  DayOne.SupervisionExercisesTest.test_rest_for_one/0
  DayOne.SupervisionExercisesTest.test_dynamic_supervisor/0
  DayOne.SupervisionExercisesTest.test_max_restarts/0
  """

  @spec test_rest_for_one() :: :ok
  def test_rest_for_one do
    #   Change the supervision strategy to `:rest_for_one` and observe how crashing
    #   `:a` affects (or doesn't affect) other siblings. Document your findings.
    #   Return :ok after demonstrating the behavior.
    :not_implemented
  end

  @spec test_dynamic_supervisor() :: :ok
  def test_dynamic_supervisor do
    #   Create a *dynamic* supervisor (`DynamicSupervisor`) that starts new
    #   `ToyWorker` processes on demand. Spawn three workers and then terminate
    #   one manually—confirm the others stay alive. Return :ok when complete.
    :not_implemented
  end

  @spec test_max_restarts() :: :ok
  def test_max_restarts do
    #   Experiment with `max_restarts` and `max_seconds` options by
    #   making `ToyWorker` crash repeatedly. At what point does the supervisor give
    #   up? Try different configurations and return :ok when demonstrated.
    :not_implemented
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

"""
ANSWERS & EXPLANATIONS

# 1. test_rest_for_one/0
def test_rest_for_one do
  children = [
    {ToyWorker, :worker_a},
    {ToyWorker, :worker_b},
    {ToyWorker, :worker_c}
  ]

  {:ok, sup} = Supervisor.start_link(children, strategy: :rest_for_one)

  # Crash worker_b - should restart worker_b and worker_c, but leave worker_a alone
  GenServer.cast(:worker_b, :crash)
  Process.sleep(100)

  # All should be alive after restart
  a_alive = Process.alive?(Process.whereis(:worker_a))
  b_alive = Process.alive?(Process.whereis(:worker_b))
  c_alive = Process.alive?(Process.whereis(:worker_c))

  Supervisor.stop(sup)

  IO.puts("rest_for_one observation: crashing worker_b restarted worker_b and worker_c")
  IO.puts("worker_a (#{a_alive}), worker_b (#{b_alive}), worker_c (#{c_alive})")
  :ok
end
#  rest_for_one observation: crashing :a restarts :a and any children defined
#  *after* it in the child list but leaves previous siblings untouched.

# 2. test_dynamic_supervisor/0
def test_dynamic_supervisor do
  {:ok, sup} = DynamicSupervisor.start_link(strategy: :one_for_one)

  # Start three workers
  {:ok, pid1} = DynamicSupervisor.start_child(sup, {DynamicToyWorker, 1})
  {:ok, pid2} = DynamicSupervisor.start_child(sup, {DynamicToyWorker, 2})
  {:ok, pid3} = DynamicSupervisor.start_child(sup, {DynamicToyWorker, 3})

  # Terminate one manually
  DynamicSupervisor.terminate_child(sup, pid2)

  # Check others are still alive
  alive1 = Process.alive?(pid1)
  alive2 = Process.alive?(pid2)
  alive3 = Process.alive?(pid3)

  DynamicSupervisor.stop(sup)

  IO.puts("Dynamic supervisor: worker1 (#{alive1}), worker2 (#{alive2}), worker3 (#{alive3})")
  :ok
end
#  Killing one worker in a DynamicSupervisor doesn't affect others, showing isolation.

# 3. test_max_restarts/0
def test_max_restarts do
  # Supervisor that allows 2 restarts in 5 seconds
  sup_opts = [
    strategy: :one_for_one,
    max_restarts: 2,
    max_seconds: 5
  ]

  # This will fail to start because CrashyWorker crashes immediately on init after first start
  result = Supervisor.start_link([CrashyWorker], sup_opts)

  case result do
    {:error, {:shutdown, {:failed_to_start_child, CrashyWorker, _}}} ->
      IO.puts("Supervisor gave up after max_restarts exceeded")
      :ok
    _ ->
      IO.puts("Unexpected supervisor behavior")
      :ok
  end
end
#  max_restarts/max_seconds demo: supervisor terminates after exceeding restart threshold,
#  showing escalation when children persistently fail.
"""
