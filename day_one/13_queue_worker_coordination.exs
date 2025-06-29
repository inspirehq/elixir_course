# Day 1 – Queue & Worker Coordination with GenServer
#
# This script can be run with:
#     mix run day_one/13_queue_worker_coordination.exs
# or inside IEx with:
#     iex -r day_one/13_queue_worker_coordination.exs
#
# This script implements a *producer/consumer* pattern: a Queue GenServer holds
# jobs, and a pool of Worker processes fetch jobs and execute them.
# The example purposely avoids external deps (e.g., GenStage) so students can
# see the raw coordination mechanics behind distributed work systems.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Simple bounded queue with back-pressure")
# STEP 1: Understanding the Producer/Consumer Pattern
# In distributed systems, we often need to decouple job creation (producers)
# from job processing (consumers). This prevents fast producers from overwhelming
# slow consumers and provides buffer space during traffic spikes.

defmodule JobQueue do
  use GenServer
  @max 5  # Maximum jobs stored in queue - this creates back-pressure

  # STEP 2: Public API for queue operations
  # These functions provide a clean interface for other processes to interact
  # with the queue without knowing GenServer implementation details
  def start_link(_), do: GenServer.start_link(__MODULE__, :queue.new(), name: __MODULE__)
  def push(job),     do: GenServer.call(__MODULE__, {:push, job})  # Synchronous - returns result
  def pop(),         do: GenServer.call(__MODULE__, :pop)          # Synchronous - blocks until response
  def size(),        do: GenServer.call(__MODULE__, :size)         # Useful for monitoring queue depth

  # STEP 3: GenServer callbacks implementing queue logic
  @impl true
  def init(queue), do: {:ok, queue}

  @impl true
  def handle_call({:push, job}, _from, q) do
    # STEP 4: Implementing back-pressure through queue size limits
    # When queue is full, we reject new jobs rather than consuming unlimited memory
    # This forces producers to slow down or implement their own buffering
    if :queue.len(q) >= @max do
      {:reply, {:error, :full}, q}  # Return error, don't change state
    else
      {:reply, :ok, :queue.in(job, q)}  # Add job to rear of queue
    end
  end

  @impl true
  def handle_call(:pop, _from, q) do
    # STEP 5: FIFO job retrieval with empty queue handling
    # :queue.out/1 returns {{:value, item}, new_queue} or {:empty, queue}
    case :queue.out(q) do
      {{:value, job}, q2} -> {:reply, {:ok, job}, q2}  # Return job and update state
      {:empty, _} -> {:reply, :empty, q}               # No jobs available
    end
  end

  @impl true
  def handle_call(:size, _from, q) do
      # STEP 6: Queue introspection for monitoring and debugging
  # This allows external processes to monitor queue depth for alerting,
  # auto-scaling decisions, or debugging slow consumer issues
  {:reply, :queue.len(q), q}
  end
end

# STEP 6.1: Demonstrating the queue in isolation
# Let's see how the queue behaves with back-pressure
{:ok, _queue_pid} = JobQueue.start_link(nil)

IO.puts("=== Demonstrating Queue Back-pressure ===")
IO.puts("Queue starts empty, size: #{JobQueue.size()}")

# Fill the queue to capacity
Enum.each(1..5, fn n ->
  result = JobQueue.push({:task, "job_#{n}"})
  IO.puts("Push job #{n}: #{inspect(result)} | Queue size: #{JobQueue.size()}")
end)

# Try to exceed capacity - should see back-pressure
IO.puts("Attempting to exceed queue capacity...")
result = JobQueue.push({:task, "overflow_job"})
IO.puts("Push overflow job: #{inspect(result)} | Queue size: #{JobQueue.size()}")

# Pop a couple jobs to show retrieval
{:ok, job1} = JobQueue.pop()
{:ok, job2} = JobQueue.pop()
IO.puts("Popped: #{inspect(job1)} and #{inspect(job2)} | Queue size: #{JobQueue.size()}")

# Now we can add more jobs
JobQueue.push({:task, "new_job"})
IO.puts("Added new job after popping | Queue size: #{JobQueue.size()}")

GenServer.stop(JobQueue)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Worker that polls the queue and processes jobs")
# STEP 7: Understanding the Worker Pattern
# Workers continuously poll the queue for available jobs. This polling pattern
# is simple but not the most efficient (better: GenStage, Broadway, or message-passing).
# However, it's easy to understand and works well for many use cases.

defmodule Worker do
  use GenServer

  # STEP 8: Worker identification and startup
  # Each worker gets a unique ID for logging and debugging purposes
  def start_link(id), do: GenServer.start_link(__MODULE__, id)

  @impl true
  def init(id) do
    # STEP 9: Self-scheduling pattern for continuous work
    # Worker immediately schedules itself to start looking for work
    # This ensures work begins as soon as the worker process starts
    send(self(), :work)
    {:ok, id}
  end

  @impl true
  def handle_info(:work, id) do
    # STEP 10: The core work polling loop
    # Worker attempts to get a job from the queue and process it
    case JobQueue.pop() do
      {:ok, job} ->
        # STEP 11: Job processing simulation
        # In real systems: decode job, call business logic, handle errors
        IO.puts("Worker #{id} got #{inspect(job)}")
        Process.sleep(200) # Simulate actual work taking time
      :empty ->
        # STEP 12: Graceful handling of empty queue
        # Worker doesn't crash when no work is available
        # Could implement exponential backoff here for efficiency
        :noop
    end

      # STEP 13: Continuous polling with delay
  # Worker reschedules itself to check for more work after a brief delay
  Process.send_after(self(), :work, 100)
  {:noreply, id}
  end
end

# STEP 13.1: Demonstrating a single worker with a queue
# Let's see how one worker processes jobs from a queue
{:ok, _queue_pid} = JobQueue.start_link(nil)
{:ok, worker_pid} = Worker.start_link("demo")

IO.puts("=== Demonstrating Single Worker Processing ===")

# Add some jobs for the worker to process
JobQueue.push({:email, "user@example.com"})
JobQueue.push({:report, "monthly_sales"})
JobQueue.push({:notification, "system_alert"})

IO.puts("Added 3 jobs to queue, worker will process them...")
Process.sleep(800)  # Give worker time to process

IO.puts("Queue size after processing: #{JobQueue.size()}")

# Clean up
GenServer.stop(worker_pid)
GenServer.stop(JobQueue)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Supervisor tree bootstrapping queue + workers")
# STEP 14: Understanding Supervision in Work Distribution Systems
# We supervise both the queue and workers together. If the queue crashes,
# workers will restart and reconnect. If workers crash, they restart and
# resume polling. This provides fault isolation and automatic recovery.

{:ok, _sup} = Supervisor.start_link([
  JobQueue,  # STEP 15: Queue starts first (workers depend on it)
  # STEP 16: Multiple workers with unique supervision IDs
  # Each worker gets its own supervision identity to avoid conflicts
  Supervisor.child_spec({Worker, 1}, id: :worker_1),
  Supervisor.child_spec({Worker, 2}, id: :worker_2),
  Supervisor.child_spec({Worker, 3}, id: :worker_3)
], strategy: :one_for_one)  # STEP 17: Independent restart strategy

# STEP 18: Demonstrating the working system
# We'll push several jobs and observe how they're distributed among workers
Enum.each(1..8, fn n ->
  # STEP 19: Observing back-pressure in action
  # The first 5 jobs will succeed, then queue becomes full
  IO.inspect(JobQueue.push({:job, n}))
end)

# STEP 20: Observing worker coordination
# Watch how the 3 workers coordinate to process jobs from the shared queue
# Each worker independently polls and processes jobs
Process.sleep(1500)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Real-world extension: automatic retry & DLQ")
# STEP 21: Understanding Production-Ready Job Processing
# Real job systems need error handling, retries, and dead letter queues (DLQ)
# for jobs that fail repeatedly. This pattern is used by most background job
# libraries like Oban, Exq, and Broadway.

_retry_pattern_example = """
Inside handle_info of Worker:

  try do
    MyApp.JobRunner.perform(job)
    :ok
  rescue
    e ->
      # STEP 22: Implementing retry logic
      if attempts(job) < 3 do
        # STEP 23: Retry failed job with incremented attempt counter
        JobQueue.push(increment_attempt(job))
      else
        # STEP 24: Move permanently failed job to Dead Letter Queue
        # DLQ allows manual inspection and reprocessing of failed jobs
        DLQ.push({job, e})
      end
  end

The pattern above is the basis of many background-job and task-processing
libraries in Elixir.
"""

# STEP 24.1: Demonstrating error handling patterns
# Let's create a simple example showing job retry logic
defmodule RetryDemo do
  def simulate_job_with_retries do
    IO.puts("=== Demonstrating Job Retry Pattern ===")

    # Simulate different job outcomes
    jobs = [
      %{id: 1, type: :email, attempts: 0, max_attempts: 3},
      %{id: 2, type: :payment, attempts: 2, max_attempts: 3},  # Already failed twice
      %{id: 3, type: :report, attempts: 0, max_attempts: 3}
    ]

    Enum.each(jobs, fn job ->
      case attempt_job(job) do
        :success ->
          IO.puts("✅ Job #{job.id} (#{job.type}) completed successfully")
        {:retry, updated_job} ->
          IO.puts("🔄 Job #{job.id} (#{job.type}) failed, attempt #{updated_job.attempts}/#{updated_job.max_attempts}")
          if updated_job.attempts < updated_job.max_attempts do
            IO.puts("   → Will retry job #{job.id}")
          else
            IO.puts("   → Job #{job.id} moved to dead letter queue after #{updated_job.attempts} attempts")
          end
        {:dead_letter, reason} ->
          IO.puts("💀 Job #{job.id} (#{job.type}) permanently failed: #{reason}")
      end
    end)
  end

  defp attempt_job(%{id: 1} = _job), do: :success  # Job 1 always succeeds
  defp attempt_job(%{id: 2, attempts: attempts} = _job) when attempts >= 2 do
    {:dead_letter, "payment gateway timeout"}  # Job 2 fails permanently
  end
  defp attempt_job(%{id: 3, attempts: attempts} = job) when attempts < 2 do
    {:retry, %{job | attempts: attempts + 1}}  # Job 3 needs retries
  end
  defp attempt_job(%{id: 3} = _job), do: :success  # Job 3 succeeds on 3rd attempt
  defp attempt_job(job), do: {:retry, %{job | attempts: job.attempts + 1}}
end

RetryDemo.simulate_job_with_retries()

defmodule DayOne.QueueExercises do
  @moduledoc """
  Practice exercises using the enhanced queue and worker modules provided below.

  Run the tests with: mix test day_one/13_queue_worker_coordination.exs
  or in IEx:
  iex -r day_one/13_queue_worker_coordination.exs
  DayOne.QueueExercisesTest.test_sized_queue/0
  DayOne.QueueExercisesTest.test_limited_worker/0
  DayOne.QueueExercisesTest.test_priority_queue/0

  The exercises use these enhanced modules:
  - SizedJobQueue: Adds size tracking to the basic queue
  - LimitedWorker: Workers that terminate after processing N jobs
  - PriorityJobQueue: Queue with high/low priority job handling
  """

  @spec test_sized_queue() :: :ok
  def test_sized_queue do
    #   Use the `SizedJobQueue` module (provided below) to demonstrate queue
    #   size tracking. Start the queue, push some jobs, check sizes, pop jobs,
    #   and show how size changes. Return :ok after demonstrating the functionality.
    :ok  # TODO: Implement using SizedJobQueue module
  end

  @spec test_limited_worker() :: :ok
  def test_limited_worker do
    #   Use the `LimitedWorker` module (provided below) to demonstrate worker lifecycle
    #   management. Create a supervisor with LimitedWorkers, add jobs to a queue,
    #   and show how workers terminate after processing 3 jobs and get restarted.
    #   Return :ok after demonstrating the worker lifecycle.
    :ok  # TODO: Implement using LimitedWorker module and supervision
  end

  @spec test_priority_queue() :: :ok
  def test_priority_queue do
    #   Use the `PriorityJobQueue` module (provided below) to demonstrate priority
    #   job processing. Push jobs with different priorities (:high and :low),
    #   then pop them to show that high-priority jobs are processed first.
    #   Return :ok after demonstrating the priority ordering.
    :ok  # TODO: Implement using PriorityJobQueue module
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

defmodule DayOne.CoordinationExercises do
  @moduledoc """
  Run the tests with: mix test day_one/13_queue_worker_coordination.exs
  or in IEx:
  iex -r day_one/13_queue_worker_coordination.exs
  DayOne.CoordinationExercisesTest.test_sized_queue/0
  DayOne.CoordinationExercisesTest.test_limited_worker/0
  DayOne.CoordinationExercisesTest.test_priority_queue/0
  """

  @spec test_sized_queue() :: :ok
  def test_sized_queue do
    # Utilize the SizedJobQueue module that can report its size.
    # Demonstrate by pushing and popping jobs and printing the size.
    :ok
  end

  @spec test_limited_worker() :: :ok
  def test_limited_worker do
    # Utilize the LimitedWorker module that only processes 3 jobs and then terminates.
    # Supervise two of these workers and show that they are restarted.
    :ok
  end

  @spec test_priority_queue() :: :ok
  def test_priority_queue do
    # Utilize the PriorityJobQueue module that supports :high and :low priority jobs.
    # Show that high priority jobs are always processed first.
    :ok
  end
end

# Helper modules for exercises
defmodule SizedJobQueue do
  use GenServer
  def start_link(_), do: GenServer.start_link(__MODULE__, :queue.new(), name: __MODULE__)
  def push(job), do: GenServer.cast(__MODULE__, {:push, job})
  def pop, do: GenServer.call(__MODULE__, :pop)
  def size, do: GenServer.call(__MODULE__, :size)

  @impl true
  def init(q), do: {:ok, q}
  @impl true
  def handle_cast({:push, job}, q), do: {:noreply, :queue.in(job, q)}
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

defmodule LimitedWorker do
  use GenServer
  def start_link(id), do: GenServer.start_link(__MODULE__, {id, 3}) # 3 jobs max
  @impl true
  def init(state) do
    send(self(), :work)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, {id, 0}) do
    IO.puts("Worker #{id} finished its work.")
    {:stop, :normal, {id, 0}}
  end
  def handle_info(:work, {id, remaining}) do
    # For simplicity, we don't interact with a real queue here.
    IO.puts("Worker #{id} processing job, #{remaining - 1} left.")
    Process.sleep(100)
    send(self(), :work)
    {:noreply, {id, remaining - 1}}
  end
end

defmodule PriorityJobQueue do
  use GenServer
  def start_link(_), do: GenServer.start_link(__MODULE__, {:queue.new(), :queue.new()})
  def push(job, prio), do: GenServer.cast(__MODULE__, {:push, job, prio})
  def pop, do: GenServer.call(__MODULE__, :pop)

  @impl true
  def init(state), do: {:ok, state}
  @impl true
  def handle_cast({:push, job, :high}, {high, low}), do: {:noreply, {:queue.in(job, high), low}}
  def handle_cast({:push, job, :low}, {high, low}), do: {:noreply, {high, :queue.in(job, low)}}
  @impl true
  def handle_call(:pop, _from, {high, low}) do
    case :queue.out(high) do
      {{:value, job}, new_high} -> {:reply, {:ok, {job, :high}}, {new_high, low}}
      {:empty, _} ->
        case :queue.out(low) do
          {{:value, job}, new_low} -> {:reply, {:ok, {job, :low}}, {high, new_low}}
          {:empty, _} -> {:reply, :empty, {high, low}}
        end
    end
  end
end

ExUnit.start()

defmodule DayOne.CoordinationExercisesTest do
  use ExUnit.Case, async: true
  alias DayOne.CoordinationExercises, as: EX

  test "sized queue reports its size correctly" do
    assert EX.test_sized_queue() == :ok
  end

  test "limited worker is restarted by supervisor" do
    assert EX.test_limited_worker() == :ok
  end

  test "priority queue serves high-priority jobs first" do
    assert EX.test_priority_queue() == :ok
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def test_sized_queue do
        {:ok, _} = SizedJobQueue.start_link(nil)
        assert SizedJobQueue.size() == 0
        SizedJobQueue.push({:job, 1})
        SizedJobQueue.push({:job, 2})
        assert SizedJobQueue.size() == 2
        {:ok, _job} = SizedJobQueue.pop()
        assert SizedJobQueue.size() == 1
        :ok
      end
    end
  end

  def answer_two do
    quote do
      def test_limited_worker do
        {:ok, sup} = Supervisor.start_link(
          [
            Supervisor.child_spec({LimitedWorker, 1}, id: :worker_1),
            Supervisor.child_spec({LimitedWorker, 2}, id: :worker_2)
          ],
          strategy: :one_for_one
        )
        Process.sleep(1000) # Give time for workers to finish and be restarted
        children = Supervisor.which_children(sup)
        # Both workers should have been restarted and are now alive.
        assert length(children) == 2
        Supervisor.stop(sup)
        :ok
      end
    end
  end

  def answer_three do
    quote do
      def test_priority_queue do
        {:ok, _} = PriorityJobQueue.start_link(nil)
        PriorityJobQueue.push({:job, "low1"}, :low)
        PriorityJobQueue.push({:job, "high1"}, :high)
        PriorityJobQueue.push({:job, "low2"}, :low)
        PriorityJobQueue.push({:job, "high2"}, :high)

        assert {:ok, {"high1", :high}} = PriorityJobQueue.pop()
        assert {:ok, {"high2", :high}} = PriorityJobQueue.pop()
        assert {:ok, {"low1", :low}} = PriorityJobQueue.pop()
        assert {:ok, {"low2", :low}} = PriorityJobQueue.pop()
        :ok
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. test_sized_queue/0
#{Macro.to_string(DayOne.Answers.answer_one())}
#  Shows queue state tracking with size/0, useful for monitoring and backpressure.

# 2. test_limited_worker/0
#{Macro.to_string(DayOne.Answers.answer_two())}
#  Demonstrates worker lifecycle management and supervisor restart behavior.
#  The worker stops itself normally, and the supervisor (with restart: :permanent)
#  restarts it.

# 3. test_priority_queue/0
#{Macro.to_string(DayOne.Answers.answer_three())}
#  Highlights queue coordination by showing how to implement job priorities,
#  demonstrating advanced queue management patterns by having the state
#  be a tuple of two queues.
""")
