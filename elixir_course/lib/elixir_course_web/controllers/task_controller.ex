defmodule ElixirCourseWeb.TaskController do
  use ElixirCourseWeb, :controller

  alias ElixirCourse.Tasks
  alias ElixirCourse.Tasks.TaskManager

  # Valid filter keys - these atoms must already exist
  @valid_filter_keys [:status, :priority, :assignee_id, :search, :sort_by]

  # API endpoints
  def index(conn, params) do
    filters =
      params
      |> Map.take(["status", "priority", "assignee_id", "search", "sort_by"])
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        if value != "" and value != nil do
          atom_key = safe_string_to_atom(key)
          if atom_key && atom_key in @valid_filter_keys do
            Map.put(acc, atom_key, value)
          else
            acc
          end
        else
          acc
        end
      end)
    {:ok, tasks} = TaskManager.get_tasks(filters)

    conn
    |> put_status(:ok)
    |> json(%{tasks: tasks})
  end

  def show(conn, %{"id" => id}) do
    try do
      task = Tasks.get_task!(id)

      conn
      |> put_status(:ok)
      |> json(%{task: task})
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})
    end
  end

  def create(conn, %{"task" => task_params}) do
    case TaskManager.create_task(task_params) do
      {:ok, task} ->
        conn
        |> put_status(:created)
        |> json(%{task: task})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "task" => task_params}) do
    case TaskManager.update_task(String.to_integer(id), task_params) do
      {:ok, task} ->
        conn
        |> put_status(:ok)
        |> json(%{task: task})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case TaskManager.delete_task(String.to_integer(id)) do
      {:ok, _task} ->
        conn
        |> put_status(:no_content)
        |> json(%{})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})
    end
  end

  # Helper function to format changeset errors
  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp safe_string_to_atom(key) when is_atom(key), do: key
  defp safe_string_to_atom(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> nil
    end
  end
  defp safe_string_to_atom(_), do: nil
end
