defmodule ElixirCourseWeb.TaskBoardChannel do
  @moduledoc """
  WebSocket channel for real-time task board functionality.

  This channel demonstrates:
  - Real-time bidirectional communication
  - User presence tracking
  - Event broadcasting
  - Authentication and authorization
  - Error handling for WebSocket connections
  """

  use Phoenix.Channel
  require Logger

  alias ElixirCourse.Tasks
  alias ElixirCourse.Tasks.TaskManager
  alias ElixirCourse.Accounts
  alias ElixirCourseWeb.Presence

  @doc """
  Join the task board channel.

  Requires user authentication and sets up presence tracking.
  """
  def join("task_board", params, socket) do
    user_id = socket.assigns[:user_id]

    case authorize_user(user_id, params) do
      {:ok, user} ->
        # Subscribe to task updates from TaskManager
        TaskManager.subscribe_to_updates()

        # Track user presence
        {:ok, _} =
          Presence.track(socket, user_id, %{
            user_id: user_id,
            name: user.name,
            status: "online",
            joined_at: inspect(System.system_time(:second))
          })

        # Update user status to online
        Accounts.update_user_status(user, "online")

        # Send initial data
        {:ok, tasks} = TaskManager.get_tasks()
        stats = Tasks.get_task_stats()

        response = %{
          tasks: tasks,
          stats: stats,
          user: user,
          online_users: get_online_users()
        }

        Logger.info("User #{user.name} joined task board")
        {:ok, response, socket}

      {:error, reason} ->
        Logger.warning("Failed to join task board: #{inspect(reason)}")
        {:error, %{reason: reason}}
    end
  end

  @doc """
  Leave the task board channel and update presence.
  """
  def terminate(reason, socket) do
    user_id = socket.assigns[:user_id]

    if user_id do
      user = Accounts.get_user!(user_id)
      Accounts.update_user_status(user, "offline")
      Logger.info("User #{user.name} left task board (#{inspect(reason)})")
    else
      Logger.warning("Could not find user #{user_id} during channel termination")
    end

    :ok
  end

  # Handle task creation
  def handle_in("create_task", params, socket) do
    user_id = socket.assigns.user_id
    task_params = Map.put(params, "creator_id", user_id)

    case TaskManager.create_task(task_params) do
      {:ok, task} ->
        # Broadcast to all channel subscribers
        broadcast!(socket, "task_created", %{
          task: task,
          creator: task.creator
        })

        # Send updated stats
        stats = Tasks.get_task_stats()
        broadcast!(socket, "stats_updated", %{stats: stats})

        {:reply, {:ok, %{task: task}}, socket}

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)
        {:reply, {:error, %{errors: errors}}, socket}
    end
  end

  # Handle task updates
  def handle_in("update_task", %{"id" => id} = params, socket) do
    user_id = socket.assigns.user_id

    case TaskManager.update_task(id, params) do
      {:ok, task} ->
        # Broadcast task update
        broadcast!(socket, "task_updated", %{
          task: task,
          updated_by: user_id
        })

        # Send updated stats if status changed
        if Map.has_key?(params, "status") do
          stats = Tasks.get_task_stats()
          broadcast!(socket, "stats_updated", %{stats: stats})
        end

        {:reply, {:ok, %{task: task}}, socket}

      {:error, :not_found} ->
        {:reply, {:error, %{message: "Task not found"}}, socket}

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)
        {:reply, {:error, %{errors: errors}}, socket}
    end
  end

  # Handle task deletion
  def handle_in("delete_task", %{"id" => id}, socket) do
    user_id = socket.assigns.user_id

    case TaskManager.delete_task(id) do
      {:error, :not_found} ->
        {:reply, {:error, %{message: "Task not found"}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{message: "Failed to delete task: #{inspect(reason)}"}}, socket}

      {:ok, _task} ->
        # Broadcast task deletion
        broadcast!(socket, "task_deleted", %{
          task_id: id,
          deleted_by: user_id
        })

        # Send updated stats
        stats = Tasks.get_task_stats()
        broadcast!(socket, "stats_updated", %{stats: stats})

        {:reply, :ok, socket}
    end
  end

  # Handle task filtering/searching
  def handle_in("filter_tasks", filters, socket) do
    case TaskManager.get_tasks(filters) do
      {:ok, tasks} ->
        push(socket, "tasks_filtered", %{tasks: tasks, filters: filters})
        {:noreply, socket}

      {:error, reason} ->
        {:reply, {:error, %{message: "Filter failed: #{inspect(reason)}"}}, socket}
    end
  end

  # Handle typing indicators
  def handle_in("typing", %{"task_id" => task_id}, socket) do
    user_id = socket.assigns.user_id

    # Broadcast typing indicator to others (not sender)
    broadcast_from!(socket, "user_typing", %{
      user_id: user_id,
      task_id: task_id,
      timestamp: System.system_time(:millisecond)
    })

    {:noreply, socket}
  end

  # Handle stop typing
  def handle_in("stop_typing", %{"task_id" => task_id}, socket) do
    user_id = socket.assigns.user_id

    broadcast_from!(socket, "user_stop_typing", %{
      user_id: user_id,
      task_id: task_id
    })

    {:noreply, socket}
  end

  # Handle user status updates
  def handle_in("update_status", %{"status" => status}, socket) do
    user_id = socket.assigns.user_id

    user = Accounts.get_user!(user_id)

    if user do
      case Accounts.update_user_status(user, status) do
        {:ok, updated_user} ->
          # Update presence
          Presence.update(socket, user_id, %{
            user_id: user_id,
            name: updated_user.name,
            status: status,
            joined_at: inspect(System.system_time(:second))
          })

          broadcast!(socket, "user_status_updated", %{
            user_id: user_id,
            status: status
          })

          {:reply, {:ok, %{status: status}}, socket}

        {:error, changeset} ->
          errors = format_changeset_errors(changeset)
          {:reply, {:error, %{errors: errors}}, socket}
      end
    else
      {:reply, {:error, %{message: "User not found"}}, socket}
    end
  end

  # Handle presence list requests
  def handle_in("get_presence", _params, socket) do
    online_users = get_online_users()
    push(socket, "presence_state", %{users: online_users})
    {:noreply, socket}
  end

  # Handle task events from TaskManager GenServer
  def handle_info({:task_created, task}, socket) do
    push(socket, "task_created", %{task: task})
    {:noreply, socket}
  end

  def handle_info({:task_updated, task}, socket) do
    push(socket, "task_updated", %{task: task})
    {:noreply, socket}
  end

  def handle_info({:task_deleted, task_id}, socket) do
    push(socket, "task_deleted", %{task_id: task_id})
    {:noreply, socket}
  end

  # Handle presence updates
  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    # Broadcast presence changes to all clients
    push(socket, "presence_diff", diff)
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    Logger.debug("TaskBoardChannel received unexpected message: #{inspect(msg)}")
    {:noreply, socket}
  end

  # Private helper functions

  defp authorize_user(nil, _params) do
    {:error, "Authentication required"}
  end

  defp authorize_user(user_id, _params) do
    try do
      user = Accounts.get_user!(user_id)
      {:ok, user}
    rescue
      Ecto.NoResultsError ->
        {:error, "User not found"}

      e ->
        Logger.error("Authorization error: #{inspect(e)}")
        {:error, "Authorization failed"}
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp get_online_users do
    Presence.list("task_board")
    |> Enum.map(fn {user_id, %{metas: [meta | _]}} ->
      %{
        user_id: String.to_integer(user_id),
        name: meta.name,
        status: meta.status,
        joined_at: meta.joined_at
      }
    end)
  rescue
    e ->
      Logger.error("Error getting online users: #{inspect(e)}")
      []
  end
end
