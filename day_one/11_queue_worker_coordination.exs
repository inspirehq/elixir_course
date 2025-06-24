# Day 1 – Queue & Worker Coordination with GenServer
#
# Run with `mix run elixir_course/day_one/11_queue_worker_coordination.exs`
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
# queue or into a Dead-Letter Queue (DLQ).  See comments in code.

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

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Add a `size/0` function to `JobQueue` that returns the number of jobs
#    currently waiting.  Print the size before and after pushing jobs.
# 2. Modify `Worker` so each worker only processes a maximum of 3 jobs before
#    terminating itself gracefully.  Ensure the supervisor automatically
#    restarts new workers to keep the pool at three.
# 3. (Challenge) Implement priorities: allow `push/2` to accept `:high | :low`
#    and make workers always consume high-priority jobs first.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. size/0 could be implemented by adding:
#      def size(), do: GenServer.call(__MODULE__, :size)
#    and a matching handle_call that returns `:queue.len(q)`.
# 2. In Worker.handle_info/2 keep a processed_count and if ==3 return
#      {:stop, :normal, state}. Supervisor restarts new worker automatically.
# 3. Priorities idea: store two queues %{high: qh, low: ql}; push/2 picks queue,
#    pop fetches from high first else low. Highlights queue coordination.
"""
