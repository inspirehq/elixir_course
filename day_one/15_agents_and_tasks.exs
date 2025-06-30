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

# Parallel timing using Task.async_stream
{par_time, par_results} = :timer.tc(fn ->
  numbers
  |> Task.async_stream(slow_computation)
  |> Enum.map(fn {:ok, result} -> result end)
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
    #   Using the ShoppingCart Agent:
    #   1. Start the ShoppingCart agent.
    #   2. Add a few items (e.g., "apples", "bananas").
    #   3. Use `get_total_items/0` to check the total.
    #   4. Remove an item and check the total again.
    #   5. Return :ok.
    :ok  # TODO: Implement the shopping cart logic.
  end

  @spec test_parallel_http_simulation() :: :ok
  def test_parallel_http_simulation do
    #   1. Create a list of 5 dummy URLs.
    #   2. Create a `mock_fetch` function that sleeps for 100-500ms.
    #   3. Use `:timer.tc` to time a parallel run with `Task.async_stream`.
    #   4. Use `:timer.tc` to time a sequential run with `Enum.each` or `Enum.map`.
    #   5. Print the times and return :ok.
    :ok  # TODO: Implement the parallel simulation.
  end

  @spec compare_agent_vs_genserver() :: :ok
  def compare_agent_vs_genserver do
    #   1. Use `:timer.tc` to benchmark 1000 increments on `SimpleCounterAgent`.
    #      - Remember to start it first and `get` the final value.
    #   2. Use `:timer.tc` to benchmark 1000 increments on `SimpleCounterGenServer`.
    #      - Remember to start it first and `get` the final value.
    #   3. Print the results and return :ok.
    :ok  # TODO: Implement the Agent vs. GenServer comparison.
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

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def build_shopping_cart do
        # Start the agent and interact with its API
        {:ok, _} = ShoppingCart.start_link()
        ShoppingCart.add_item("apples", 5)
        ShoppingCart.add_item("bananas", 2)
        IO.inspect(ShoppingCart.get_total_items(), label: "Total after adds")
        ShoppingCart.remove_item("bananas")
        IO.inspect(ShoppingCart.get_total_items(), label: "Total after remove")
        ShoppingCart.clear()
        IO.inspect(ShoppingCart.get_total_items(), label: "Total after clear")
        :ok
      end
    end
  end

  def answer_two do
    quote do
      def test_parallel_http_simulation do
        urls = ["api1", "api2", "api3", "api4", "api5"]

        # This function simulates an HTTP fetch that takes a variable
        # amount of time (100-500ms) to complete. We use it to demonstrate
        # how parallel execution can speed up I/O-bound work.
        mock_fetch = fn _url ->
          Process.sleep(:rand.uniform(400) + 100) # 100-500ms
          {:ok, "data"}
        end

        # Time the parallel execution
        {par_time, _} = :timer.tc(fn ->
          urls
          |> Task.async_stream(mock_fetch, timeout: 600)
          |> Enum.to_list()
        end)

        # Time the sequential execution
        {seq_time, _} = :timer.tc(fn -> Enum.each(urls, mock_fetch) end)

        IO.puts("Parallel time: #{par_time / 1000}ms, Sequential time: #{seq_time / 1000}ms")
        :ok
      end
    end
  end

  def answer_three do
    quote do
      def compare_agent_vs_genserver do
        iterations = 1000
        # Agent benchmark
        {:ok, _ag} = SimpleCounterAgent.start_link()
        {agent_time, _} = :timer.tc(fn ->
          for _ <- 1..iterations, do: SimpleCounterAgent.increment()
          SimpleCounterAgent.get() # Ensure all updates are processed
        end)

        # GenServer benchmark
        {:ok, _gs} = SimpleCounterGenServer.start_link()
        {genserver_time, _} = :timer.tc(fn ->
          for _ <- 1..iterations, do: SimpleCounterGenServer.increment()
          SimpleCounterGenServer.get() # Ensure all updates are processed
        end)

        IO.puts("Agent: #{agent_time}µs, GenServer: #{genserver_time}µs for #{iterations} increments.")
        :ok
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. build_shopping_cart/0
#{Macro.to_string(DayOne.Answers.answer_one())}
#  An `Agent` is ideal for simple state. The `ShoppingCart` module provides a clean
#  API to start the process and interact with it, hiding the Agent details.

# 2. test_parallel_http_simulation/0
#{Macro.to_string(DayOne.Answers.answer_two())}
#  `Task.async_stream/2` is perfect for I/O-bound work. It runs operations
#  concurrently and streams results, often leading to a significant speedup.

# 3. compare_agent_vs_genserver/0
#{Macro.to_string(DayOne.Answers.answer_three())}
#  For simple state updates, `Agent` and `GenServer` performance is very close.
#  The key is that Agent provides a much simpler API for the common case of
#  managing a single piece of state. Use an Agent for simplicity; upgrade to
#  a GenServer when you need more complex logic, messages, or state structure.

#  A GenServer is optimized for a fixed set of operations. You define the logic
#  ahead of time in the server, and clients simply send commands to trigger that
#  logic. This is more performant if you have a known, high-throughput workload.
#  An Agent is optimized for flexibility. It allows the caller to define the
#  state update logic at runtime. This is incredibly convenient, but it comes at
#  the small performance cost you've just measured.
""")
