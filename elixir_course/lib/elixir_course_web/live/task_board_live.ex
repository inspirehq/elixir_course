defmodule ElixirCourseWeb.TaskBoardLive do
  @moduledoc """
  LiveView for the Task Management Demo - Capstone Project

  This LiveView demonstrates:
  - Real-time task management
  - Live filtering and sorting
  - WebSocket communication
  - GenServer integration
  - Form handling with Phoenix LiveView
  - User presence tracking
  - Channel integration demonstration
  """

  use ElixirCourseWeb, :live_view

  alias ElixirCourse.Tasks.TaskManager
  alias ElixirCourse.Accounts
  alias ElixirCourseWeb.Presence

  # Valid filter keys - these atoms must already exist
  @valid_filter_keys [:status, :priority, :search, :sort_by, :assignee_id]

  # Default filter values
  @default_filters %{
    status: "",
    priority: "",
    search: "",
    sort_by: ""
  }

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to task updates if connected
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ElixirCourse.PubSub, "tasks")
      Phoenix.PubSub.subscribe(ElixirCourse.PubSub, "task_board")

      # Track user presence
      user_id = generate_user_id()
      Presence.track(self(), "task_board", user_id, %{
        joined_at: :os.system_time(:second),
        user_agent: get_user_agent(socket)
      })

      # Subscribe to presence updates
      Phoenix.PubSub.subscribe(ElixirCourse.PubSub, "presence:task_board")

      # Subscribe to channel demo messages
      Phoenix.PubSub.subscribe(ElixirCourse.PubSub, "channel_demo")
    end

    # Get initial data
    {:ok, tasks} = TaskManager.get_tasks()
    users = Accounts.list_users()
    stats = calculate_stats(tasks)

    # Get current presence list
    presence_list = if connected?(socket) do
      Presence.list("task_board")
    else
      %{}
    end

    socket =
      socket
      |> assign(:tasks, tasks)
      |> assign(:users, users)
      |> assign(:stats, stats)
      |> assign(:filters, @default_filters)
      |> assign(:show_create_form, false)
      |> assign(:show_user_form, false)
      |> assign(:show_channel_demo, false)
      |> assign(:activity_log, ["Demo loaded - ready for testing"])
      |> assign(:page_title, "Task Management Demo")
      |> assign(:presence_list, presence_list)
      |> assign(:user_id, if(connected?(socket), do: generate_user_id(), else: nil))
      |> assign(:channel_messages, [])
      |> assign(:channel_status, "Disconnected")

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_create_task", _params, socket) do
    {:noreply, assign(socket, :show_create_form, !socket.assigns.show_create_form)}
  end

  @impl true
  def handle_event("toggle_create_user", _params, socket) do
    {:noreply, assign(socket, :show_user_form, !socket.assigns.show_user_form)}
  end

  @impl true
  def handle_event("create_task", %{"task" => task_params}, socket) do
    case TaskManager.create_task(task_params) do
      {:ok, task} ->
        # Refresh tasks with current filters applied
        atom_filters = convert_filters_to_atoms(socket.assigns.filters)
        {:ok, filtered_tasks} = TaskManager.get_tasks(atom_filters)
        stats = calculate_stats(filtered_tasks)

        socket =
          socket
          |> assign(:tasks, filtered_tasks)
          |> assign(:stats, stats)
          |> assign(:show_create_form, false)
          |> log_activity("Task created: #{task.title}", "success")

        {:noreply, socket}

      {:error, changeset} ->
        errors =
          changeset.errors
          |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)
          |> Enum.join(", ")

        socket =
          socket
          |> log_activity("Failed to create task: #{errors}", "error")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create_user", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        socket =
          socket
          |> assign(:users, [user | socket.assigns.users])
          |> assign(:show_user_form, false)
          |> log_activity("User created: #{user.name}", "success")

        {:noreply, socket}

      {:error, changeset} ->
        errors =
          changeset.errors
          |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)
          |> Enum.join(", ")

        socket =
          socket
          |> log_activity("Failed to create user: #{errors}", "error")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter_params}, socket) do
    # Convert string keys to atom keys and remove empty values
    atom_filters =
      filter_params
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        if value != "" and value != nil do
          Map.put(acc, String.to_atom(key), value)
        else
          acc
        end
      end)

    # Merge with current filters (keeping the original string keys for UI state)
    filters = Map.merge(socket.assigns.filters, filter_params)
    {:ok, filtered_tasks} = TaskManager.get_tasks(atom_filters)
    stats = calculate_stats(filtered_tasks)

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:tasks, filtered_tasks)
      |> assign(:stats, stats)
      |> log_activity("Filters applied", "info")

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh_data", _params, socket) do
    # Convert string keys to atom keys for TaskManager
    atom_filters = convert_filters_to_atoms(socket.assigns.filters)
    {:ok, tasks} = TaskManager.get_tasks(atom_filters)
    users = Accounts.list_users()
    stats = calculate_stats(tasks)

    socket =
      socket
      |> assign(:tasks, tasks)
      |> assign(:users, users)
      |> assign(:stats, stats)
      |> log_activity("Data refreshed", "info")

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_task_status", %{"task_id" => task_id, "status" => status}, socket) do
    case TaskManager.update_task(String.to_integer(task_id), %{status: status}) do
      {:ok, _task} ->
        # Refresh tasks with current filters applied
        atom_filters = convert_filters_to_atoms(socket.assigns.filters)
        {:ok, filtered_tasks} = TaskManager.get_tasks(atom_filters)
        stats = calculate_stats(filtered_tasks)

        socket =
          socket
          |> assign(:tasks, filtered_tasks)
          |> assign(:stats, stats)
          |> log_activity("Task status updated to #{status}", "success")
        {:noreply, socket}

      {:error, :not_found} ->
        socket =
          socket
          |> log_activity("Failed to update task: not found", "error")
        {:noreply, socket}

      {:error, changeset} ->
        errors =
          changeset.errors
          |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)
          |> Enum.join(", ")

        socket =
          socket
          |> log_activity("Failed to update task: #{errors}", "error")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_task", %{"task_id" => task_id}, socket) do
    case TaskManager.delete_task(String.to_integer(task_id)) do
      {:ok, _task} ->
        # Refresh tasks with current filters applied
        atom_filters = convert_filters_to_atoms(socket.assigns.filters)
        {:ok, filtered_tasks} = TaskManager.get_tasks(atom_filters)
        stats = calculate_stats(filtered_tasks)

        socket =
          socket
          |> assign(:tasks, filtered_tasks)
          |> assign(:stats, stats)
          |> log_activity("Task deleted", "success")
        {:noreply, socket}

      {:error, :not_found} ->
        socket =
          socket
          |> log_activity("Failed to delete task: not found", "error")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_channel_demo", _params, socket) do
    {:noreply, assign(socket, :show_channel_demo, !socket.assigns.show_channel_demo)}
  end

  @impl true
  def handle_event("send_channel_message", %{"message" => message_params}, socket) do
    message = Map.get(message_params, "content", "")

    if String.trim(message) != "" do
      # Broadcast via PubSub to simulate channel behavior
      Phoenix.PubSub.broadcast(ElixirCourse.PubSub, "channel_demo", {
        :channel_message,
        %{
          content: message,
          user_id: socket.assigns.user_id,
          timestamp: DateTime.utc_now() |> DateTime.to_time() |> Time.to_string(),
          type: "user_message"
        }
      })

      socket = log_activity(socket, "Channel message sent: #{String.slice(message, 0, 30)}...", "info")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("simulate_channel_event", %{"event_type" => event_type}, socket) do
    case event_type do
      "user_joined" ->
        Phoenix.PubSub.broadcast(ElixirCourse.PubSub, "channel_demo", {
          :channel_message,
          %{
            content: "#{socket.assigns.user_id} joined the channel",
            user_id: "system",
            timestamp: DateTime.utc_now() |> DateTime.to_time() |> Time.to_string(),
            type: "system_event"
          }
        })

      "user_typing" ->
        Phoenix.PubSub.broadcast(ElixirCourse.PubSub, "channel_demo", {
          :channel_message,
          %{
            content: "#{socket.assigns.user_id} is typing...",
            user_id: "system",
            timestamp: DateTime.utc_now() |> DateTime.to_time() |> Time.to_string(),
            type: "typing_indicator"
          }
        })

      "task_broadcast" ->
        Phoenix.PubSub.broadcast(ElixirCourse.PubSub, "channel_demo", {
          :channel_message,
          %{
            content: "Task update broadcasted to all channel subscribers",
            user_id: "system",
            timestamp: DateTime.utc_now() |> DateTime.to_time() |> Time.to_string(),
            type: "broadcast_event"
          }
        })

      _ ->
        nil
    end

    socket = log_activity(socket, "Channel event simulated: #{event_type}", "info")
    {:noreply, socket}
  end

  # Handle PubSub messages for real-time updates
  @impl true
  def handle_info({:task_created, task}, socket) do
    atom_filters = convert_filters_to_atoms(socket.assigns.filters)
    {:ok, tasks} = TaskManager.get_tasks(atom_filters)
    stats = calculate_stats(tasks)

    socket =
      socket
      |> assign(:tasks, tasks)
      |> assign(:stats, stats)
      |> log_activity("New task created: #{task.title}", "info")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:task_updated, task}, socket) do
    atom_filters = convert_filters_to_atoms(socket.assigns.filters)
    {:ok, tasks} = TaskManager.get_tasks(atom_filters)
    stats = calculate_stats(tasks)

    socket =
      socket
      |> assign(:tasks, tasks)
      |> assign(:stats, stats)
      |> log_activity("Task updated: #{task.title}", "info")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:task_deleted, task_id}, socket) do
    atom_filters = convert_filters_to_atoms(socket.assigns.filters)
    {:ok, tasks} = TaskManager.get_tasks(atom_filters)
    stats = calculate_stats(tasks)

    socket =
      socket
      |> assign(:tasks, tasks)
      |> assign(:stats, stats)
      |> log_activity("Task deleted (ID: #{task_id})", "info")

    {:noreply, socket}
  end

  # Handle presence updates
  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    presence_list = Presence.list("task_board")

    socket = assign(socket, :presence_list, presence_list)

    # Log presence changes
    socket = Enum.reduce(joins, socket, fn {user_id, _meta}, acc ->
      log_activity(acc, "User #{user_id} joined the task board", "info")
    end)

    socket = Enum.reduce(leaves, socket, fn {user_id, _meta}, acc ->
      log_activity(acc, "User #{user_id} left the task board", "info")
    end)

    {:noreply, socket}
  end

  # Handle channel demo messages
  @impl true
  def handle_info({:channel_message, message}, socket) do
    # Add message to channel message history
    new_messages = [message | socket.assigns.channel_messages] |> Enum.take(50)

    # Update channel status if it's our message
    channel_status = if message.user_id == socket.assigns.user_id do
      "Message sent successfully"
    else
      "Receiving messages"
    end

    socket =
      socket
      |> assign(:channel_messages, new_messages)
      |> assign(:channel_status, channel_status)
      |> log_activity("Channel: #{message.content}", "info")

    {:noreply, socket}
  end

  # Helper functions
  defp calculate_stats(tasks) do
    %{
      total: length(tasks),
      todo: count_by_status(tasks, "todo"),
      in_progress: count_by_status(tasks, "in_progress"),
      review: count_by_status(tasks, "review"),
      done: count_by_status(tasks, "done")
    }
  end

  defp count_by_status(tasks, status) do
    Enum.count(tasks, &(&1.status == status))
  end

  defp log_activity(socket, message, _type) do
    timestamp = DateTime.utc_now() |> DateTime.to_time() |> Time.to_string()
    log_entry = "#{timestamp} - #{message}"

    activity_log = [log_entry | socket.assigns.activity_log] |> Enum.take(20)
    assign(socket, :activity_log, activity_log)
  end

  defp get_status_class("todo"), do: "bg-gray-100 text-gray-700"
  defp get_status_class("in_progress"), do: "bg-blue-100 text-blue-700"
  defp get_status_class("review"), do: "bg-blue-50 text-blue-600"
  defp get_status_class("done"), do: "bg-gray-200 text-gray-800"
  defp get_status_class(_), do: "bg-gray-100 text-gray-700"

  defp get_priority_class("urgent"), do: "bg-gray-800 text-white"
  defp get_priority_class("high"), do: "bg-gray-600 text-white"
  defp get_priority_class("medium"), do: "bg-gray-400 text-white"
  defp get_priority_class("low"), do: "bg-gray-200 text-gray-700"
  defp get_priority_class(_), do: "bg-gray-100 text-gray-700"

  defp format_status(status) do
    status |> String.replace("_", " ") |> String.capitalize()
  end

  defp format_datetime(nil), do: "Not set"
  defp format_datetime(datetime) do
    datetime |> DateTime.to_date() |> Date.to_string()
  end

  defp convert_filters_to_atoms(filters) do
    filters
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

  # Generate a simple user ID for demonstration
  defp generate_user_id() do
    "user_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}"
  end

  # Get user agent for presence metadata
  defp get_user_agent(socket) do
    case get_connect_info(socket, :user_agent) do
      nil -> "Unknown"
      user_agent ->
        cond do
          String.contains?(user_agent, "Chrome") -> "Chrome"
          String.contains?(user_agent, "Firefox") -> "Firefox"
          String.contains?(user_agent, "Safari") -> "Safari"
          true -> "Unknown Browser"
        end
    end
  end

  # Calculate online users count
  defp online_users_count(presence_list) do
    map_size(presence_list)
  end

  # Format presence for display
  defp format_presence_info(presence_list) do
    presence_list
    |> Enum.map(fn {user_id, %{metas: [meta | _]}} ->
      joined_time = DateTime.from_unix!(meta.joined_at) |> DateTime.to_time() |> Time.to_string()
      "#{user_id} (#{meta.user_agent}) - joined at #{joined_time}"
    end)
    |> Enum.sort()
  end

  # Helper function for channel message styling
  defp get_message_style(type) do
    case type do
      "user_message" -> "bg-blue-50 border-blue-200 text-blue-900"
      "system_event" -> "bg-green-50 border-green-200 text-green-900"
      "typing_indicator" -> "bg-yellow-50 border-yellow-200 text-yellow-900"
      "broadcast_event" -> "bg-purple-50 border-purple-200 text-purple-900"
      _ -> "bg-gray-50 border-gray-200 text-gray-900"
    end
  end
end
