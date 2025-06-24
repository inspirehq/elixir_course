defmodule ElixirCourse.Tasks.TaskManager do
  @moduledoc """
  GenServer for coordinating task operations and maintaining in-memory state.

  This GenServer demonstrates:
  - State management with caching
  - Event coordination between contexts
  - Real-time notifications via PubSub
  - Error handling and recovery
  - Performance optimization through caching
  """

  use GenServer
  require Logger

  alias ElixirCourse.Tasks
  alias ElixirCourse.Tasks.Task

  @refresh_interval :timer.minutes(5)

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets filtered and sorted tasks from cache.
  """
  def get_tasks(filters \\ %{}) do
    GenServer.call(__MODULE__, {:get_tasks, filters})
  end

  @doc """
  Creates a new task and updates cache.
  """
  def create_task(attrs) do
    GenServer.call(__MODULE__, {:create_task, attrs})
  end

  @doc """
  Updates a task and refreshes cache.
  """
  def update_task(id, attrs) do
    GenServer.call(__MODULE__, {:update_task, id, attrs})
  end

  @doc """
  Deletes a task and removes from cache.
  """
  def delete_task(id) do
    GenServer.call(__MODULE__, {:delete_task, id})
  end

  @doc """
  Subscribe to task update notifications.
  """
  def subscribe_to_updates do
    GenServer.cast(__MODULE__, {:subscribe, self()})
  end

  @doc """
  Get cache statistics for monitoring.
  """
  def get_cache_stats do
    GenServer.call(__MODULE__, :get_cache_stats)
  end

  @doc """
  Force refresh of the task cache.
  """
  def refresh_cache do
    GenServer.cast(__MODULE__, :refresh_cache)
  end

  @doc """
  Clears the task cache and resets performance counters.
  """
  def clear_cache do
    GenServer.call(__MODULE__, :clear_cache)
  end

  # Server Callbacks

  def init(_opts) do
    Logger.info("TaskManager starting up...")

    # Subscribe to PubSub events from the Tasks context (if available)
    try do
      Phoenix.PubSub.subscribe(ElixirCourse.PubSub, "tasks")
      Logger.debug("TaskManager subscribed to PubSub")
    rescue
      _ ->
        Logger.debug("PubSub not available, continuing without subscription")
    end

    state = %{
      tasks: %{},           # Map of task_id => task
      subscribers: [],      # List of monitored PIDs
      last_refresh: nil,    # Timestamp of last cache refresh
      cache_hits: 0,        # Performance metrics
      cache_misses: 0
    }

    # Initial cache load and schedule refresh
    {:ok, state, {:continue, :load_initial_cache}}
  end

  def handle_continue(:load_initial_cache, state) do
    case load_tasks_from_db() do
      {:ok, tasks} ->
        tasks_map = Map.new(tasks, &{&1.id, &1})
        new_state = %{state |
          tasks: tasks_map,
          last_refresh: DateTime.utc_now()
        }
        schedule_refresh()
        Logger.info("TaskManager cache loaded with #{map_size(tasks_map)} tasks")
        {:noreply, new_state}

      {:error, reason} ->
        Logger.error("Failed to load initial cache: #{inspect(reason)}")
        schedule_refresh()
        {:noreply, state}
    end
  end

  def handle_continue(:refresh_cache, state) do
    case load_tasks_from_db() do
      {:ok, tasks} ->
        tasks_map = Map.new(tasks, &{&1.id, &1})
        new_state = %{state |
          tasks: tasks_map,
          last_refresh: DateTime.utc_now()
        }
        schedule_refresh()
        Logger.info("TaskManager cache refreshed with #{map_size(tasks_map)} tasks")
        {:noreply, new_state}

      {:error, reason} ->
        Logger.warning("Failed to refresh task cache: #{inspect(reason)}")
        schedule_refresh()
        {:noreply, state}
    end
  end

  def handle_call({:get_tasks, filters}, _from, state) do
    filtered_tasks = state.tasks
    |> Map.values()
    |> apply_filters(filters)
    |> sort_tasks(filters[:sort_by])

    new_state = %{state | cache_hits: state.cache_hits + 1}

    {:reply, {:ok, filtered_tasks}, new_state}
  end

  def handle_call({:create_task, attrs}, _from, state) do
    case Tasks.create_task(attrs) do
      {:ok, task} ->
        new_state = put_in(state.tasks[task.id], task)
        notify_subscribers({:task_created, task}, new_state)
        {:reply, {:ok, task}, new_state}

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end

  def handle_call({:update_task, id, attrs}, _from, state) do
    case Map.get(state.tasks, id) do
      nil ->
        # Task not in cache, try to fetch from DB
        try do
          task = Tasks.get_task!(id)
          case Tasks.update_task(task, attrs) do
            {:ok, updated_task} ->
              new_state = put_in(state.tasks[id], updated_task)
              notify_subscribers({:task_updated, updated_task}, new_state)
              {:reply, {:ok, updated_task}, new_state}

            error ->
              {:reply, error, state}
          end
        rescue
          Ecto.NoResultsError ->
            {:reply, {:error, :not_found}, state}
        end

      task ->
        case Tasks.update_task(task, attrs) do
          {:ok, updated_task} ->
            new_state = put_in(state.tasks[id], updated_task)
            notify_subscribers({:task_updated, updated_task}, new_state)
            {:reply, {:ok, updated_task}, new_state}

          error ->
            {:reply, error, state}
        end
    end
  end

  def handle_call({:delete_task, id}, _from, state) do
    case Map.get(state.tasks, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      task ->
        case Tasks.delete_task(task) do
          {:ok, deleted_task} ->
            new_state = %{state | tasks: Map.delete(state.tasks, id)}
            notify_subscribers({:task_deleted, id}, new_state)
            {:reply, {:ok, deleted_task}, new_state}

          error ->
            {:reply, error, state}
        end
    end
  end

  def handle_call(:get_cache_stats, _from, state) do
    stats = %{
      cached_tasks: map_size(state.tasks),
      subscribers: length(state.subscribers),
      last_refresh: state.last_refresh,
      cache_hits: state.cache_hits,
      cache_misses: state.cache_misses,
      hit_ratio: calculate_hit_ratio(state.cache_hits, state.cache_misses)
    }
    {:reply, stats, state}
  end

  def handle_call(:clear_cache, _from, state) do
    new_state = %{state |
      tasks: %{},
      cache_hits: 0,
      cache_misses: 0
    }
    {:reply, :ok, new_state}
  end

  def handle_cast({:subscribe, pid}, state) do
    ref = Process.monitor(pid)
    new_subscribers = [{pid, ref} | state.subscribers]
    {:noreply, %{state | subscribers: new_subscribers}}
  end

  def handle_cast(:refresh_cache, state) do
    {:noreply, state, {:continue, :refresh_cache}}
  end

  # Handle PubSub events from Tasks context
  def handle_info({:task_created, task}, state) do
    new_state = put_in(state.tasks[task.id], task)
    notify_subscribers({:task_created, task}, new_state)
    {:noreply, new_state}
  end

  def handle_info({:task_updated, task}, state) do
    new_state = put_in(state.tasks[task.id], task)
    notify_subscribers({:task_updated, task}, new_state)
    {:noreply, new_state}
  end

  def handle_info({:task_deleted, task_id}, state) do
    new_state = %{state | tasks: Map.delete(state.tasks, task_id)}
    notify_subscribers({:task_deleted, task_id}, new_state)
    {:noreply, new_state}
  end

  def handle_info(:refresh_cache, state) do
    {:noreply, state, {:continue, :refresh_cache}}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    new_subscribers = Enum.reject(state.subscribers, fn {sub_pid, sub_ref} ->
      sub_pid == pid || sub_ref == ref
    end)
    {:noreply, %{state | subscribers: new_subscribers}}
  end

  def handle_info(msg, state) do
    Logger.debug("TaskManager received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private Functions

  defp load_tasks_from_db do
    try do
      tasks = Tasks.list_tasks()
      {:ok, tasks}
    rescue
      e -> {:error, e}
    end
  end

  defp apply_filters(tasks, filters) when map_size(filters) == 0, do: tasks
  defp apply_filters(tasks, filters) do
    tasks
    |> filter_by_status(filters[:status])
    |> filter_by_priority(filters[:priority])
    |> filter_by_assignee(filters[:assignee_id])
    |> filter_by_search(filters[:search])
    |> filter_by_due_date(filters[:due_soon], filters[:overdue])
    |> filter_by_tags(filters[:tags])
  end

  defp filter_by_status(tasks, nil), do: tasks
  defp filter_by_status(tasks, ""), do: tasks
  defp filter_by_status(tasks, status) do
    Enum.filter(tasks, &(&1.status == status))
  end

  defp filter_by_priority(tasks, nil), do: tasks
  defp filter_by_priority(tasks, ""), do: tasks
  defp filter_by_priority(tasks, priority) do
    Enum.filter(tasks, &(&1.priority == priority))
  end

  defp filter_by_assignee(tasks, nil), do: tasks
  defp filter_by_assignee(tasks, assignee_id) when is_binary(assignee_id) do
    case Integer.parse(assignee_id) do
      {id, ""} -> filter_by_assignee(tasks, id)
      _ -> tasks
    end
  end
  defp filter_by_assignee(tasks, assignee_id) do
    Enum.filter(tasks, &(&1.assignee_id == assignee_id))
  end

  defp filter_by_search(tasks, nil), do: tasks
  defp filter_by_search(tasks, ""), do: tasks
  defp filter_by_search(tasks, search_term) do
    search_lower = String.downcase(search_term)
    Enum.filter(tasks, fn task ->
      String.contains?(String.downcase(task.title), search_lower) or
      (task.description && String.contains?(String.downcase(task.description), search_lower))
    end)
  end

  defp filter_by_due_date(tasks, due_soon, overdue) do
    tasks
    |> maybe_filter_due_soon(due_soon)
    |> maybe_filter_overdue(overdue)
  end

  defp maybe_filter_due_soon(tasks, true) do
    Enum.filter(tasks, &Task.due_soon?/1)
  end
  defp maybe_filter_due_soon(tasks, _), do: tasks

  defp maybe_filter_overdue(tasks, true) do
    Enum.filter(tasks, &Task.overdue?/1)
  end
  defp maybe_filter_overdue(tasks, _), do: tasks

  defp filter_by_tags(tasks, nil), do: tasks
  defp filter_by_tags(tasks, []), do: tasks
  defp filter_by_tags(tasks, tags) when is_list(tags) do
    Enum.filter(tasks, fn task ->
      Enum.any?(tags, &(&1 in (task.tags || [])))
    end)
  end

  defp sort_tasks(tasks, nil), do: tasks
  defp sort_tasks(tasks, ""), do: tasks
  defp sort_tasks(tasks, "priority") do
    priority_order = %{"urgent" => 0, "high" => 1, "medium" => 2, "low" => 3}
    Enum.sort_by(tasks, &Map.get(priority_order, &1.priority, 4))
  end
  defp sort_tasks(tasks, "due_date") do
    Enum.sort_by(tasks, fn task ->
      case task.due_date do
        nil -> ~D[2099-12-31]
        date -> date
      end
    end)
  end
  defp sort_tasks(tasks, "created_at") do
    Enum.sort_by(tasks, &(&1.inserted_at), {:desc, DateTime})
  end
  defp sort_tasks(tasks, "status") do
    status_order = %{"todo" => 0, "in_progress" => 1, "review" => 2, "done" => 3}
    Enum.sort_by(tasks, &Map.get(status_order, &1.status, 4))
  end

  defp notify_subscribers(message, state) do
    Enum.each(state.subscribers, fn {pid, _ref} ->
      send(pid, message)
    end)
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh_cache, @refresh_interval)
  end

  defp calculate_hit_ratio(0, 0), do: 0.0
  defp calculate_hit_ratio(hits, misses) do
    Float.round(hits / (hits + misses) * 100, 2)
  end
end
