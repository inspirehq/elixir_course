defmodule ElixirCourse.Tasks do
  @moduledoc """
  The Tasks context for managing task operations.

  This module provides the public API for task-related operations
  and demonstrates best practices for Phoenix contexts.
  """

  import Ecto.Query, warn: false
  alias ElixirCourse.Repo
  alias ElixirCourse.Tasks.Task

  @doc """
  Returns the list of tasks with optional filtering and preloading.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

      iex> list_tasks(%{status: "todo", assignee_id: 1})
      [%Task{}, ...]
  """
  def list_tasks(filters \\ %{}) do
    Task
    |> apply_filters(filters)
    |> preload([:creator, :assignee])
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single task with preloaded associations.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)
  """
  def get_task!(id) do
    Task
    |> preload([:creator, :assignee])
    |> Repo.get!(id)
  end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{title: "New Task", creator_id: 1})
      {:ok, %Task{}}

      iex> create_task(%{title: ""})
      {:error, %Ecto.Changeset{}}
  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, task} ->
        # Broadcast task creation event
        Phoenix.PubSub.broadcast(
          ElixirCourse.PubSub,
          "tasks",
          {:task_created, get_task!(task.id)}
        )
        {:ok, get_task!(task.id)}

      error ->
        error
    end
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{title: "Updated Title"})
      {:ok, %Task{}}

      iex> update_task(task, %{title: ""})
      {:error, %Ecto.Changeset{}}
  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_task} ->
        # Broadcast task update event
        Phoenix.PubSub.broadcast(
          ElixirCourse.PubSub,
          "tasks",
          {:task_updated, get_task!(updated_task.id)}
        )
        {:ok, get_task!(updated_task.id)}

      error ->
        error
    end
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}
  """
  def delete_task(%Task{} = task) do
    case Repo.delete(task) do
      {:ok, deleted_task} ->
        # Broadcast task deletion event
        Phoenix.PubSub.broadcast(
          ElixirCourse.PubSub,
          "tasks",
          {:task_deleted, deleted_task.id}
        )
        {:ok, deleted_task}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}
  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  @doc """
  Gets tasks statistics for dashboard.

  ## Examples

      iex> get_task_stats()
      %{total: 10, completed: 5, in_progress: 3, todo: 2}
  """
  def get_task_stats do
    query = from(t in Task,
      group_by: t.status,
      select: {t.status, count(t.id)}
    )

    stats = Repo.all(query) |> Enum.into(%{})

    %{
      total: Enum.sum(Map.values(stats)),
      todo: Map.get(stats, "todo", 0),
      in_progress: Map.get(stats, "in_progress", 0),
      review: Map.get(stats, "review", 0),
      done: Map.get(stats, "done", 0)
    }
  end

  @doc """
  Marks a task as completed.

  ## Examples

      iex> complete_task(task)
      {:ok, %Task{status: "done", completed_at: ~N[...]}}
  """
  def complete_task(%Task{} = task) do
    update_task(task, %{
      status: "done",
      completed_at: NaiveDateTime.utc_now()
    })
  end

  # Private functions for query filtering
  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn {key, value}, query ->
      filter_by(query, key, value)
    end)
  end

  defp filter_by(query, :status, status) when status != "" do
    from(t in query, where: t.status == ^status)
  end

  defp filter_by(query, :priority, priority) when priority != "" do
    from(t in query, where: t.priority == ^priority)
  end

  defp filter_by(query, :assignee_id, assignee_id) when not is_nil(assignee_id) do
    from(t in query, where: t.assignee_id == ^assignee_id)
  end

  defp filter_by(query, :creator_id, creator_id) when not is_nil(creator_id) do
    from(t in query, where: t.creator_id == ^creator_id)
  end

  defp filter_by(query, :search, search_term) when search_term != "" do
    search_pattern = "%#{search_term}%"
    from(t in query,
      where: ilike(t.title, ^search_pattern) or
             ilike(t.description, ^search_pattern)
    )
  end

  defp filter_by(query, :due_soon, true) do
    tomorrow = Date.add(Date.utc_today(), 1)
    from(t in query,
      where: t.due_date <= ^tomorrow and t.status != "done"
    )
  end

  defp filter_by(query, :overdue, true) do
    today = Date.utc_today()
    from(t in query,
      where: t.due_date < ^today and t.status != "done"
    )
  end

  defp filter_by(query, _key, _value), do: query
end
