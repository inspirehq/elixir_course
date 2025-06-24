# Day 1 – Supervision Basics
#
# Run with `mix run elixir_course/day_one/10_supervision_basics.exs`
#
# A *Supervisor* is a process that watches its children and restarts them
# according to the configured strategy.  This file demonstrates:
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

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Change the supervision strategy to `:rest_for_one` and observe how crashing
#    `:a` affects (or doesn't affect) other siblings. Document your findings.
# 2. Create a *dynamic* supervisor (`DynamicSupervisor`) that starts new
#    `ToyWorker` processes on demand.  Spawn three workers and then terminate
#    one manually—confirm the others stay alive.
# 3. (Stretch) Experiment with `max_restarts` and `max_seconds` options by
#    making `ToyWorker` crash repeatedly. At what point does the supervisor give
#    up? Try different configurations.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. rest_for_one observation: crashing :a restarts :a and any children defined
#    *after* it in the child list (e.g., :b) but leaves previous siblings
#    untouched. Students see ordering impact.
# 2. DynamicSupervisor snippet:
#      {:ok, sup} = DynamicSupervisor.start_link(strategy: :one_for_one)
#      DynamicSupervisor.start_child(sup, {ToyWorker, :w1})
#    Killing :w1 -> it restarts, pool maintained.
# 3. max_restarts/max_seconds demo: start supervisor with
#       Supervisor.start_link(children, strategy: :one_for_one,
#                              max_restarts: 3, max_seconds: 5)
#    Loop crash child; after 3 crashes within 5s supervisor terminates, showing
#    escalation.
"""
