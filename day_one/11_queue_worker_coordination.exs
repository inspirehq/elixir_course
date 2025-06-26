# Day 1 – Queue & Worker Coordination with GenServer
#
# This script can be run with:
#     mix run day_one/11_queue_worker_coordination.exs
# or inside IEx with:
#     iex -r day_one/11_queue_worker_coordination.exs
#
# This script implements a *producer/consumer* pattern: a Queue GenServer holds
# jobs, and a pool of Worker processes fetch jobs and execute them.
# The example purposely avoids external deps (e.g., GenStage) so students can
# see the raw coordination mechanics.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Simple bounded queue with back-pressure")

defmodule JobQueue do
  use GenServer
  @max 5  # max in-flight jobs stored in queue
  # API
  def start_link(_), do: GenServer.start_link(__MODULE__, :queue.new(), name: __MODULE__)
  def push(job),     do: GenServer.call(__MODULE__, {:push, job})
  def pop(),         do: GenServer.call(__MODULE__, :pop)
  def size(),        do: GenServer.call(__MODULE__, :size)

  # Callbacks
  @impl true
  def handle_call({:push, job}, _from, q) do
    if :queue.len(q) >= @max do
      {:reply, {:error, :full}, q}
    else
      {:reply, :ok, :queue.in(job, q)}
    end
  end

  @impl true
  def handle_call(:pop, _from, q) do
    case :queue.out(q) do
      {{:value, job}, q2} -> {:reply, {:ok, job}, q2}
      {:empty, _} -> {:reply, :empty, q}
    end
  end

  @impl true
  def handle_call(:size, _from, q) do
    {:reply, :queue.len(q), q}
  end
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Worker that polls the queue and processes jobs")

defmodule Worker do
  use GenServer
  def start_link(id), do: GenServer.start_link(__MODULE__, id)

  @impl true
  def init(id) do
    send(self(), :work)
    {:ok, id}
  end

  @impl true
  def handle_info(:work, id) do
    case JobQueue.pop() do
      {:ok, job} ->
        IO.puts("Worker #{id} got #{inspect(job)}")
        Process.sleep(200) # simulate work
      :empty ->
        :noop
    end
    # Poll again soon-ish
    Process.send_after(self(), :work, 100)
    {:noreply, id}
  end
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Supervisor tree bootstrapping queue + workers")

{:ok, _sup} = Supervisor.start_link([
  JobQueue,
  {Worker, 1},
  {Worker, 2},
  {Worker, 3}
], strategy: :one_for_one)

# Push some jobs
Enum.each(1..8, fn n ->
  IO.inspect(JobQueue.push({:job, n}))
end)

# Observe output for a couple seconds
Process.sleep(1500)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Real-world extension: automatic retry & DLQ")

# For brevity we'll illustrate how a worker *could* push failed jobs back on the
# queue or into a Dead-Letter Queue (DLQ). See comments in code.

"""
Inside handle_info of Worker:

  try do
    MyApp.JobRunner.perform(job)
    :ok
  rescue
    e ->
      if attempts(job) < 3 do
        JobQueue.push(increment_attempt(job))
      else
        DLQ.push({job, e})
      end
  end

The pattern above is the basis of many background-job and task-processing
libraries in Elixir.
"""

defmodule DayOne.QueueExercises do
  @moduledoc """
  Run the tests with: mix test day_one/11_queue_worker_coordination.exs
  or in IEx:
  iex -r day_one/11_queue_worker_coordination.exs
  DayOne.QueueExercisesTest.test_sized_queue/0
  DayOne.QueueExercisesTest.test_limited_worker/0
  DayOne.QueueExercisesTest.test_priority_queue/0
  """

  @spec test_sized_queue() :: :ok
  def test_sized_queue do
    #   Add a `size/0` function to `JobQueue` that returns the number of jobs
    #   currently waiting. Print the size before and after pushing jobs.
    #   Return :ok after demonstrating the size functionality.
    :not_implemented
  end

  @spec test_limited_worker() :: :ok
  def test_limited_worker do
    #   Modify `Worker` so each worker only processes a maximum of 3 jobs before
    #   terminating itself gracefully. Ensure the supervisor automatically
    #   restarts new workers to keep the pool at three. Return :ok when demonstrated.
    :not_implemented
  end

  @spec test_priority_queue() :: :ok
  def test_priority_queue do
    #   Implement priorities: allow `push/2` to accept `:high | :low`
    #   and make workers always consume high-priority jobs first.
    #   Return :ok after demonstrating priority handling.
    :not_implemented
  end
end

# Enhanced JobQueue with size function
defmodule SizedJobQueue do
  use GenServer
  @max 5

  def start_link(_), do: GenServer.start_link(__MODULE__, :queue.new(), name: __MODULE__)
  def push(job), do: GenServer.call(__MODULE__, {:push, job})
  def pop(), do: GenServer.call(__MODULE__, :pop)
  def size(), do: GenServer.call(__MODULE__, :size)

  @impl true
  def init(queue), do: {:ok, queue}

  @impl true
  def handle_call({:push, job}, _from, q) do
    if :queue.len(q) >= @max do
      {:reply, {:error, :full}, q}
    else
      {:reply, :ok, :queue.in(job, q)}
    end
  end

  @impl true
  def handle_call(:pop, _from, q) do
    case :queue.out(q) do
      {{:value, job}, q2} -> {:reply, {:ok, job}, q2}
      {:empty, _} -> {:reply, :empty, q}
    end
  end

  @impl true
  def handle_call(:size, _from, q), do: {:reply, :queue.len(q), q}
end

# Limited worker that terminates after processing max jobs
defmodule LimitedWorker do
  use GenServer
  @max_jobs 3

  def start_link(id), do: GenServer.start_link(__MODULE__, {id, 0})

  @impl true
  def init({id, processed_count}) do
    send(self(), :work)
    {:ok, {id, processed_count}}
  end

  @impl true
  def handle_info(:work, {id, processed_count}) do
    if processed_count >= @max_jobs do
      {:stop, :normal, {id, processed_count}}
    else
      case JobQueue.pop() do
        {:ok, job} ->
          IO.puts("Limited Worker #{id} processed #{inspect(job)} (#{processed_count + 1}/#{@max_jobs})")
          Process.send_after(self(), :work, 100)
          {:noreply, {id, processed_count + 1}}
        :empty ->
          Process.send_after(self(), :work, 100)
          {:noreply, {id, processed_count}}
      end
    end
  end
end

# Priority queue implementation
defmodule PriorityJobQueue do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, %{high: :queue.new(), low: :queue.new()}, name: __MODULE__)
  def push(job, priority \\ :low), do: GenServer.call(__MODULE__, {:push, job, priority})
  def pop(), do: GenServer.call(__MODULE__, :pop)
  def size(), do: GenServer.call(__MODULE__, :size)

  @impl true
  def init(queues), do: {:ok, queues}

  @impl true
  def handle_call({:push, job, priority}, _from, %{high: high_q, low: low_q} = queues) do
    case priority do
      :high -> {:reply, :ok, %{queues | high: :queue.in(job, high_q)}}
      :low -> {:reply, :ok, %{queues | low: :queue.in(job, low_q)}}
      _ -> {:reply, {:error, :invalid_priority}, queues}
    end
  end

  @impl true
  def handle_call(:pop, _from, %{high: high_q, low: low_q} = queues) do
    # Try high priority first
    case :queue.out(high_q) do
      {{:value, job}, new_high_q} ->
        {:reply, {:ok, {job, :high}}, %{queues | high: new_high_q}}
      {:empty, _} ->
        # Try low priority
        case :queue.out(low_q) do
          {{:value, job}, new_low_q} ->
            {:reply, {:ok, {job, :low}}, %{queues | low: new_low_q}}
          {:empty, _} ->
            {:reply, :empty, queues}
        end
    end
  end

  @impl true
  def handle_call(:size, _from, %{high: high_q, low: low_q} = queues) do
    total_size = :queue.len(high_q) + :queue.len(low_q)
    {:reply, total_size, queues}
  end
end

ExUnit.start()

defmodule DayOne.QueueExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.QueueExercises, as: EX

  test "test_sized_queue/0 demonstrates queue size functionality" do
    assert EX.test_sized_queue() == :ok
  end

  test "test_limited_worker/0 shows worker lifecycle management" do
    assert EX.test_limited_worker() == :ok
  end

  test "test_priority_queue/0 demonstrates priority job processing" do
    assert EX.test_priority_queue() == :ok
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. test_sized_queue/0
def test_sized_queue do
  {:ok, _} = SizedJobQueue.start_link(nil)

  initial_size = SizedJobQueue.size()
  IO.puts("Initial queue size: #{initial_size}")

  SizedJobQueue.push({:job, 1})
  SizedJobQueue.push({:job, 2})

  after_push_size = SizedJobQueue.size()
  IO.puts("Size after pushing 2 jobs: #{after_push_size}")

  {:ok, _job} = SizedJobQueue.pop()

  after_pop_size = SizedJobQueue.size()
  IO.puts("Size after popping 1 job: #{after_pop_size}")

  :ok
end
#  Shows queue state tracking with size/0, useful for monitoring and backpressure.

# 2. test_limited_worker/0
def test_limited_worker do
  {:ok, sup} = Supervisor.start_link([
    JobQueue,
    Supervisor.child_spec({LimitedWorker, 1}, id: :worker_1, restart: :permanent),
    Supervisor.child_spec({LimitedWorker, 2}, id: :worker_2, restart: :permanent)
  ], strategy: :one_for_one)

  # Add jobs for workers to process
  Enum.each(1..10, fn n -> JobQueue.push({:job, n}) end)

  # Wait for workers to process jobs and terminate
  Process.sleep(2000)

  # Check that supervisor has restarted workers
  children = Supervisor.which_children(sup)
  IO.puts("Active children after worker restarts: #{length(children)}")

  Supervisor.stop(sup)
  :ok
end
#  Demonstrates worker lifecycle management and supervisor restart behavior.

# 3. test_priority_queue/0
def test_priority_queue do
  {:ok, _} = PriorityJobQueue.start_link(nil)

  # Add mixed priority jobs
  PriorityJobQueue.push({:job, "low1"}, :low)
  PriorityJobQueue.push({:job, "high1"}, :high)
  PriorityJobQueue.push({:job, "low2"}, :low)
  PriorityJobQueue.push({:job, "high2"}, :high)

  # Pop jobs - should get high priority first
  {:ok, {job1, priority1}} = PriorityJobQueue.pop()
  {:ok, {job2, priority2}} = PriorityJobQueue.pop()
  {:ok, {job3, priority3}} = PriorityJobQueue.pop()
  {:ok, {job4, priority4}} = PriorityJobQueue.pop()

  IO.puts("Job order: #{inspect(job1)} (#{priority1}), #{inspect(job2)} (#{priority2})")
  IO.puts("           #{inspect(job3)} (#{priority3}), #{inspect(job4)} (#{priority4})")

  # Verify high priority jobs came first
  if priority1 == :high and priority2 == :high and priority3 == :low and priority4 == :low do
    :ok
  else
    {:error, :incorrect_priority_order}
  end
end
#  Highlights queue coordination by showing how to implement job priorities,
#  demonstrating advanced queue management patterns.
"""
