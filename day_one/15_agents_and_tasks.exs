# Day 1 – Agents and Tasks: Simple Abstractions Over GenServer
#
# This script can be run with:
#     mix run day_one/15_agents_and_tasks.exs
# or inside IEx with:
#     iex -r day_one/15_agents_and_tasks.exs
#
# Agent and Task are two simple abstractions built on top of GenServer:
# - Agent: for maintaining state with a simple API
# - Task: for running asynchronous operations and collecting results
# Understanding these helps you choose the right tool for the job.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Agent basics: simple state management")

# Step-by-step breakdown of Agent usage:
# Step 1: Start an Agent with initial state
{:ok, agent} = Agent.start_link(fn -> 0 end)  # Start with counter at 0

# Step 2: Get current state with Agent.get/2
current = Agent.get(agent, fn state -> state end)
IO.inspect(current, label: "initial agent state")

# Step 3: Update state with Agent.update/2
Agent.update(agent, fn state -> state + 5 end)  # Add 5 to counter

# Step 4: Get and update in one operation with Agent.get_and_update/2
old_value = Agent.get_and_update(agent, fn state ->
  {state, state * 2}  # Return {old_value, new_state}
end)
IO.inspect(old_value, label: "old value from get_and_update")

# Step 5: Check final state
final = Agent.get(agent, fn state -> state end)
IO.inspect(final, label: "final agent state")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Named Agent for global state")

# Step-by-step breakdown of named Agent:
defmodule CounterAgent do
  # Step 1: Start a named Agent so we don't need to track PID
  def start_link(initial_value \\ 0) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  # Step 2: Wrapper functions provide a clean API
  def get() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def increment() do
    Agent.update(__MODULE__, fn state -> state + 1 end)
  end

  def decrement() do
    Agent.update(__MODULE__, fn state -> state - 1 end)
  end

  def reset() do
    Agent.update(__MODULE__, fn _state -> 0 end)
  end
end

# Demo: Use the named Agent
{:ok, _} = CounterAgent.start_link(10)
IO.inspect(CounterAgent.get(), label: "initial counter")
CounterAgent.increment()
CounterAgent.increment()
IO.inspect(CounterAgent.get(), label: "after increments")
CounterAgent.reset()
IO.inspect(CounterAgent.get(), label: "after reset")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Task basics: async operations")

# Step-by-step breakdown of Task usage:
# Step 1: Start an async task that runs in the background
task = Task.async(fn ->
  Process.sleep(1000)  # Simulate some work
  "Task completed after 1 second!"
end)

IO.puts("Task started, doing other work...")

# Step 2: Do other work while task runs in background
Enum.each(1..3, fn i ->
  IO.puts("Other work step #{i}")
  Process.sleep(200)
end)

# Step 3: Wait for task to complete and get result
result = Task.await(task)
IO.inspect(result, label: "task result")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Multiple Tasks: parallel processing")

# Step-by-step breakdown of parallel processing with Tasks:
# Step 1: Define a function that takes time to compute
slow_computation = fn n ->
  Process.sleep(500)  # Simulate expensive computation
  n * n
end

# Step 2: Start multiple tasks to run in parallel
numbers = [1, 2, 3, 4, 5]
IO.puts("Starting #{length(numbers)} tasks in parallel...")

tasks = Enum.map(numbers, fn n ->
  Task.async(fn -> slow_computation.(n) end)
end)

# Step 3: Collect all results (waits for all to complete)
results = Enum.map(tasks, &Task.await/1)
IO.inspect(results, label: "parallel computation results")

# Step 4: Compare with sequential processing time
IO.puts("Timing sequential vs parallel...")

# Sequential timing
{seq_time, seq_results} = :timer.tc(fn ->
  Enum.map(numbers, slow_computation)
end)

# Parallel timing
{par_time, par_results} = :timer.tc(fn ->
  numbers
  |> Enum.map(fn n -> Task.async(fn -> slow_computation.(n) end) end)
  |> Enum.map(&Task.await/1)
end)

IO.puts("Sequential: #{seq_time / 1000}ms")
IO.puts("Parallel: #{par_time / 1000}ms")
IO.puts("Speedup: #{Float.round(seq_time / par_time, 2)}x faster")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Task.Supervisor for resilient async operations")

# Step-by-step breakdown of supervised tasks:
# Step 1: Start a Task.Supervisor
{:ok, supervisor} = Task.Supervisor.start_link()

# Step 2: Start tasks under supervision using async_nolink (they can fail safely)
safe_task = Task.Supervisor.async_nolink(supervisor, fn ->
  if :rand.uniform() > 0.5 do
    "Success!"
  else
    raise "Random failure!"
  end
end)

# Step 3: Handle potential task failures gracefully (won't crash our process)
try do
  safe_result = Task.await(safe_task, 1000)
  IO.inspect(safe_result, label: "supervised task result")
rescue
  e ->
    IO.puts("supervised task failed but didn't crash our process!")
    IO.inspect(e.message, label: "error message")
catch
  :exit, reason ->
    IO.puts("supervised task exited, but our process continues")
    IO.inspect(reason, label: "exit reason")
end

# ────────────────────────────────────────────────────────────────

defmodule DayOne.AgentsTasksExercises do
  @moduledoc """
  Run the tests with: mix test day_one/15_agents_and_tasks.exs
  or in IEx:
  iex -r day_one/15_agents_and_tasks.exs
  DayOne.AgentsTasksExercisesTest.test_shopping_cart/0
  DayOne.AgentsTasksExercisesTest.test_parallel_http_simulation/0
  DayOne.AgentsTasksExercisesTest.test_agent_vs_genserver/0
  """

  @spec build_shopping_cart() :: :ok
  def build_shopping_cart do
    #   Build a ShoppingCart Agent that maintains a list of items with quantities.
    #   Implement add_item/2, remove_item/1, get_total_items/0, and clear/0.
    #   Demonstrate adding 3 different items, removing one, and showing the total.
    #   Return :ok when complete.
    :ok  # TODO: Implement shopping cart Agent
  end

  @spec test_parallel_http_simulation() :: :ok
  def test_parallel_http_simulation do
    #   Simulate fetching data from 5 different "APIs" using Tasks.
    #   Each API call should take a random time between 100-500ms.
    #   Use Task.async_stream/2 to process them in parallel with a timeout.
    #   Compare the total time vs sequential processing.
    #   Return :ok when complete.
    :ok  # TODO: Implement parallel HTTP simulation
  end

  @spec compare_agent_vs_genserver() :: :ok
  def compare_agent_vs_genserver do
    #   Create equivalent counter functionality using both an Agent and a GenServer.
    #   Time 1000 increment operations on each and compare performance.
    #   Demonstrate that Agent is simpler for basic state management.
    #   Return :ok showing the performance comparison.
    :ok  # TODO: Implement Agent vs GenServer comparison
  end
end

# Example implementations for the exercises
defmodule ShoppingCart do
  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_item(item, quantity \\ 1) do
    Agent.update(__MODULE__, fn cart ->
      Map.update(cart, item, quantity, &(&1 + quantity))
    end)
  end

  def remove_item(item) do
    Agent.update(__MODULE__, fn cart ->
      Map.delete(cart, item)
    end)
  end

  def get_total_items() do
    Agent.get(__MODULE__, fn cart ->
      cart |> Map.values() |> Enum.sum()
    end)
  end

  def clear() do
    Agent.update(__MODULE__, fn _cart -> %{} end)
  end

  def get_cart() do
    Agent.get(__MODULE__, fn cart -> cart end)
  end
end

defmodule SimpleCounterGenServer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def increment() do
    GenServer.cast(__MODULE__, :increment)
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  @impl true
  def init(count), do: {:ok, count}

  @impl true
  def handle_cast(:increment, count), do: {:noreply, count + 1}

  @impl true
  def handle_call(:get, _from, count), do: {:reply, count, count}
end

defmodule SimpleCounterAgent do
  def start_link() do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def increment() do
    Agent.update(__MODULE__, &(&1 + 1))
  end

  def get() do
    Agent.get(__MODULE__, & &1)
  end
end

ExUnit.start()

defmodule DayOne.AgentsTasksExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.AgentsTasksExercises, as: EX

  test "build_shopping_cart/0 creates and manages shopping cart with Agent" do
    assert EX.build_shopping_cart() == :ok
  end

  test "test_parallel_http_simulation/0 demonstrates parallel vs sequential processing" do
    assert EX.test_parallel_http_simulation() == :ok
  end

  test "compare_agent_vs_genserver/0 shows performance and complexity differences" do
    assert EX.compare_agent_vs_genserver() == :ok
  end
end

# ANSWERS & EXPLANATIONS (in comments to avoid syntax issues)
#
# 1. build_shopping_cart/0
# def build_shopping_cart do
#   {:ok, _} = ShoppingCart.start_link()
#   ShoppingCart.add_item("apples", 3)
#   ShoppingCart.add_item("bananas", 2)
#   ShoppingCart.add_item("oranges", 1)
#   ShoppingCart.remove_item("bananas")
#   total = ShoppingCart.get_total_items()
#   cart = ShoppingCart.get_cart()
#   IO.inspect(cart, label: "final cart")
#   IO.inspect(total, label: "total items")
#   :ok
# end
# Explanation: Agent provides a simple wrapper around GenServer for basic state.
# Perfect for cases where you just need get/update operations without complex logic.
#
# 2. test_parallel_http_simulation/0
# def test_parallel_http_simulation do
#   apis = 1..5
#   {seq_time, _} = :timer.tc(fn ->
#     Enum.map(apis, fn i ->
#       Process.sleep(:rand.uniform(400) + 100)
#       "API #{i} response"
#     end)
#   end)
#   {par_time, _} = :timer.tc(fn ->
#     Task.async_stream(apis, fn i ->
#       Process.sleep(:rand.uniform(400) + 100)
#       "API #{i} response"
#     end, timeout: 1000) |> Enum.to_list()
#   end)
#   IO.puts("Sequential: #{seq_time / 1000}ms")
#   IO.puts("Parallel: #{par_time / 1000}ms")
#   :ok
# end
# Explanation: Task.async_stream/2 is perfect for parallel processing of collections.
# Automatically handles concurrency and backpressure for you.
#
# 3. compare_agent_vs_genserver/0
# def compare_agent_vs_genserver do
#   {:ok, _} = SimpleCounterAgent.start_link()
#   {:ok, _} = SimpleCounterGenServer.start_link()
#
#   {agent_time, _} = :timer.tc(fn ->
#     Enum.each(1..1000, fn _ -> SimpleCounterAgent.increment() end)
#   end)
#
#   {genserver_time, _} = :timer.tc(fn ->
#     Enum.each(1..1000, fn _ -> SimpleCounterGenServer.increment() end)
#   end)
#
#   IO.puts("Agent: #{agent_time / 1000}ms")
#   IO.puts("GenServer: #{genserver_time / 1000}ms")
#   IO.puts("Agent is simpler but both use GenServer underneath")
#   :ok
# end
# Explanation: Agent is just a GenServer with a constrained API.
# Use Agent for simple state, GenServer when you need complex callbacks and logic.
