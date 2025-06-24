# ===================================================================
# Day Three Capstone Project: Real-Time Task Management System
# ===================================================================
#
# This capstone project integrates concepts from Day One and Day Two:
# - GenServer state management (Day One)
# - OTP supervision trees (Day One)
# - Ecto schemas and queries (Day Two)
# - Real-time features with PubSub (Day Two)
# - Comprehensive testing strategies (Day Two)
#
# 📌 LEARNING OBJECTIVES:
# • Apply GenServer patterns for stateful services
# • Implement proper supervision strategies
# • Design efficient database schemas with Ecto
# • Build real-time backend features
# • Write comprehensive test suites
# • Handle errors gracefully in distributed systems

# ===================================================================
# 📌 SECTION 1: PROJECT STRUCTURE AND SETUP
# ===================================================================

defmodule CapstoneProject.Setup do
  @moduledoc """
  Setup instructions and project structure for the capstone project.

  TASK: Create a Phoenix application with the following structure:

  lib/
  ├── elixir_course/
  │   ├── application.ex              # OTP Application
  │   ├── repo.ex                     # Ecto Repository
  │   ├── accounts/                   # User management context
  │   │   ├── user.ex                 # User schema
  │   │   └── accounts.ex             # Context functions
  │   ├── tasks/                      # Task management context
  │   │   ├── task.ex                 # Task schema
  │   │   ├── task_manager.ex         # GenServer for task coordination
  │   │   └── tasks.ex                # Context functions
  │   └── mailer.ex                   # Email functionality
  ├── elixir_course_web/
  │   ├── channels/                   # WebSocket channels
  │   │   └── task_board_channel.ex
  │   ├── controllers/                # API controllers
  │   │   ├── task_controller.ex
  │   │   └── user_controller.ex
  │   └── presence.ex                 # Phoenix Presence
  """

  # Mix.exs dependencies used in our implementation:
  @required_dependencies """
  def deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_presence, "~> 1.1"},
      {:jason, "~> 1.2"}
    ]
  end
  """
end

# ===================================================================
# 📌 SECTION 2: DATABASE SCHEMAS AND MIGRATIONS
# ===================================================================

defmodule CapstoneProject.Accounts.User do
  @moduledoc """
  User schema demonstrating Ecto best practices.
  Based on our working implementation in lib/elixir_course/accounts/user.ex
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__]}

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string

    has_many :assigned_tasks, ElixirCourse.Tasks.Task, foreign_key: :assignee_id
    has_many :created_tasks, ElixirCourse.Tasks.Task, foreign_key: :creator_id

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url])
    |> validate_required([:email, :name])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> validate_length(:name, min: 2, max: 100)
    |> unique_constraint(:email)
  end

  # EXERCISE 2.1: Add custom validation for professional email domains
  def professional_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> validate_professional_email()
  end

  defp validate_professional_email(changeset) do
    validate_change(changeset, :email, fn :email, email ->
      free_providers = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com"]
      domain = email |> String.split("@") |> List.last()

      if domain in free_providers do
        [email: "Professional email address required"]
      else
        []
      end
    end)
  end
end

defmodule CapstoneProject.Tasks.Task do
  @moduledoc """
  Task schema with comprehensive validations and associations.
  Based on our working implementation in lib/elixir_course/tasks/task.ex
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__, :assignee, :creator]}

  @statuses ["todo", "in_progress", "review", "done"]
  @priorities ["low", "medium", "high", "urgent"]

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "todo"
    field :priority, :string, default: "medium"
    field :due_date, :naive_datetime
    field :completed_at, :naive_datetime

    belongs_to :assignee, ElixirCourse.Accounts.User
    belongs_to :creator, ElixirCourse.Accounts.User

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :status, :priority, :due_date, :assignee_id, :creator_id])
    |> validate_required([:title])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:priority, @priorities)
    |> validate_due_date()
    |> maybe_set_completed_at()
    |> foreign_key_constraint(:assignee_id)
    |> foreign_key_constraint(:creator_id)
  end

  # EXERCISE 2.2: Implement custom validations
  defp validate_due_date(changeset) do
    validate_change(changeset, :due_date, fn :due_date, due_date ->
      if due_date && NaiveDateTime.compare(due_date, NaiveDateTime.utc_now()) == :lt do
        [due_date: "cannot be in the past"]
      else
        []
      end
    end)
  end

  defp maybe_set_completed_at(changeset) do
    status = get_change(changeset, :status)
    current_status = if changeset.data.id, do: changeset.data.status, else: nil

    cond do
      status == "done" and current_status != "done" ->
        put_change(changeset, :completed_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))

      status != "done" and current_status == "done" ->
        put_change(changeset, :completed_at, nil)

      true ->
        changeset
    end
  end
end

# Migration examples implemented in our project:
defmodule CapstoneProject.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :avatar_url, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end

defmodule CapstoneProject.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, default: "todo"
      add :priority, :string, default: "medium"
      add :due_date, :naive_datetime
      add :completed_at, :naive_datetime
      add :assignee_id, references(:users, on_delete: :nilify_all)
      add :creator_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:tasks, [:status])
    create index(:tasks, [:priority])
    create index(:tasks, [:assignee_id])
    create index(:tasks, [:creator_id])
    create index(:tasks, [:due_date])
  end
end

# ===================================================================
# 📌 SECTION 3: CONTEXT MODULES (ECTO PATTERNS)
# ===================================================================

defmodule CapstoneProject.Accounts do
  @moduledoc """
  Context module for user management.
  Based on our working implementation in lib/elixir_course/accounts.ex
  """

  import Ecto.Query, warn: false
  alias ElixirCourse.Repo
  alias ElixirCourse.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  # EXERCISE 3.1: Implement user statistics
  def user_stats() do
    from(u in User,
      select: %{
        total_users: count(u.id),
        users_with_tasks: count(u.id, :distinct),
        avg_tasks_per_user: avg(subquery(
          from(t in ElixirCourse.Tasks.Task,
            group_by: t.assignee_id,
            select: count(t.id)
          )
        ))
      }
    )
    |> Repo.one()
  end
end

defmodule CapstoneProject.Tasks do
  @moduledoc """
  Context module for task management.
  Based on our working implementation in lib/elixir_course/tasks.ex
  """

  import Ecto.Query, warn: false
  alias ElixirCourse.Repo
  alias ElixirCourse.Tasks.Task

  def list_tasks do
    Task
    |> preload([:assignee, :creator])
    |> Repo.all()
  end

  def list_tasks_with_filters(filters) do
    Task
    |> apply_filters(filters)
    |> preload([:assignee, :creator])
    |> Repo.all()
  end

  def get_task!(id), do: Repo.get!(Task, id) |> Repo.preload([:assignee, :creator])

  def get_task(id) do
    case Repo.get(Task, id) do
      nil -> nil
      task -> Repo.preload(task, [:assignee, :creator])
    end
  end

  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, task} -> {:ok, Repo.preload(task, [:assignee, :creator])}
      error -> error
    end
  end

  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, task} -> {:ok, Repo.preload(task, [:assignee, :creator])}
      error -> error
    end
  end

  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  # EXERCISE 3.2: Implement comprehensive filtering
  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn {key, value}, query ->
      case {key, value} do
        {:status, status} when status != "" ->
          where(query, [t], t.status == ^status)

        {:priority, priority} when priority != "" ->
          where(query, [t], t.priority == ^priority)

        {:assignee_id, assignee_id} when assignee_id != "" ->
          where(query, [t], t.assignee_id == ^assignee_id)

        {:search, search} when search != "" ->
          search_term = "%#{search}%"
          where(query, [t],
            ilike(t.title, ^search_term) or
            ilike(t.description, ^search_term)
          )

        {:sort_by, "priority"} ->
          order_by(query, [t],
            fragment("CASE ? WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END", t.priority)
          )

        {:sort_by, "due_date"} ->
          order_by(query, [t], [asc: t.due_date])

        {:sort_by, "created_at"} ->
          order_by(query, [t], [desc: t.inserted_at])

        _ ->
          query
      end
    end)
  end

  # EXERCISE 3.3: Task statistics and reporting
  def task_stats() do
    from(t in Task,
      select: %{
        total: count(t.id),
        todo: count(t.id, filter: t.status == "todo"),
        in_progress: count(t.id, filter: t.status == "in_progress"),
        review: count(t.id, filter: t.status == "review"),
        done: count(t.id, filter: t.status == "done"),
        urgent: count(t.id, filter: t.priority == "urgent"),
        high: count(t.id, filter: t.priority == "high"),
        medium: count(t.id, filter: t.priority == "medium"),
        low: count(t.id, filter: t.priority == "low")
      }
    )
    |> Repo.one()
  end
end

# ===================================================================
# 📌 SECTION 4: GENSERVER IMPLEMENTATIONS
# ===================================================================

defmodule CapstoneProject.Tasks.TaskManager do
  @moduledoc """
  GenServer for coordinating task operations and maintaining in-memory state.
  Based on our working implementation in lib/elixir_course/tasks/task_manager.ex
  """
  use GenServer
  require Logger

  alias ElixirCourse.{Tasks, Repo}
  alias Phoenix.PubSub

  @refresh_interval :timer.minutes(5)

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_tasks(filters \\ %{}) do
    GenServer.call(__MODULE__, {:get_tasks, filters})
  end

  def create_task(attrs) do
    GenServer.call(__MODULE__, {:create_task, attrs})
  end

  def update_task(id, attrs) do
    GenServer.call(__MODULE__, {:update_task, id, attrs})
  end

  def delete_task(id) do
    GenServer.call(__MODULE__, {:delete_task, id})
  end

  def get_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end

  def clear_cache() do
    GenServer.call(__MODULE__, :clear_cache)
  end

  # Server Callbacks
  def init(_opts) do
    state = %{
      tasks: %{},
      last_refresh: nil,
      stats: %{}
    }

    schedule_refresh()
    Logger.info("TaskManager started")

    {:ok, state}
  end

  def handle_call({:get_tasks, filters}, _from, state) do
    # EXERCISE 4.1: Implement task filtering and sorting
    filtered_tasks = state.tasks
    |> Map.values()
    |> apply_filters(filters)
    |> sort_tasks(filters[:sort_by])

    {:reply, {:ok, filtered_tasks}, state}
  end

  def handle_call({:create_task, attrs}, _from, state) do
    # EXERCISE 4.2: Implement task creation with notifications
    case Tasks.create_task(attrs) do
      {:ok, task} ->
        new_state = put_in(state.tasks[task.id], task)
        notify_subscribers({:task_created, task})
        {:reply, {:ok, task}, new_state}

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end

  def handle_call({:update_task, id, attrs}, _from, state) do
    # EXERCISE 4.3: Implement task updates with cache management
    case Tasks.get_task(id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      task ->
        case Tasks.update_task(task, attrs) do
          {:ok, updated_task} ->
            new_state = put_in(state.tasks[id], updated_task)
            notify_subscribers({:task_updated, updated_task})
            {:reply, {:ok, updated_task}, new_state}

          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end
    end
  end

  def handle_call({:delete_task, id}, _from, state) do
    # EXERCISE 4.4: Implement task deletion with cascade handling
    case Tasks.get_task(id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      task ->
        case Tasks.delete_task(task) do
          {:ok, _deleted_task} ->
            {_task, new_tasks} = Map.pop(state.tasks, id)
            new_state = %{state | tasks: new_tasks}
            notify_subscribers({:task_deleted, id})
            {:reply, :ok, new_state}

          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end
    end
  end

  def handle_call(:get_stats, _from, state) do
    stats = %{
      cached_tasks: map_size(state.tasks),
      last_refresh: state.last_refresh,
      memory_usage: :erlang.process_info(self(), :memory)
    }
    {:reply, stats, state}
  end

  def handle_call(:clear_cache, _from, state) do
    new_state = %{state | tasks: %{}}
    {:reply, :ok, new_state}
  end

  def handle_info(:refresh_cache, state) do
    # EXERCISE 4.5: Implement cache refresh from database
    case Tasks.list_tasks() do
      tasks when is_list(tasks) ->
        tasks_map = Map.new(tasks, &{&1.id, &1})
        new_state = %{state | tasks: tasks_map, last_refresh: DateTime.utc_now()}
        schedule_refresh()
        Logger.debug("TaskManager cache refreshed with #{map_size(tasks_map)} tasks")
        {:noreply, new_state}

      _ ->
        Logger.warn("Failed to refresh task cache")
        schedule_refresh()
        {:noreply, state}
    end
  end

  # Private Functions
  defp apply_filters(tasks, filters) do
    # EXERCISE 4.6: Implement comprehensive filtering
    tasks
    |> filter_by_status(filters[:status])
    |> filter_by_priority(filters[:priority])
    |> filter_by_assignee(filters[:assignee_id])
    |> filter_by_search(filters[:search])
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
  defp filter_by_assignee(tasks, ""), do: tasks
  defp filter_by_assignee(tasks, assignee_id) when is_binary(assignee_id) do
    assignee_id = String.to_integer(assignee_id)
    Enum.filter(tasks, &(&1.assignee_id == assignee_id))
  end
  defp filter_by_assignee(tasks, assignee_id) when is_integer(assignee_id) do
    Enum.filter(tasks, &(&1.assignee_id == assignee_id))
  end

  defp filter_by_search(tasks, nil), do: tasks
  defp filter_by_search(tasks, ""), do: tasks
  defp filter_by_search(tasks, search_term) do
    search_lower = String.downcase(search_term)
    Enum.filter(tasks, fn task ->
      String.contains?(String.downcase(task.title), search_lower) or
      String.contains?(String.downcase(task.description || ""), search_lower)
    end)
  end

  defp sort_tasks(tasks, nil), do: tasks
  defp sort_tasks(tasks, ""), do: tasks
  defp sort_tasks(tasks, "priority") do
    priority_order = %{"urgent" => 0, "high" => 1, "medium" => 2, "low" => 3}
    Enum.sort_by(tasks, &priority_order[&1.priority])
  end
  defp sort_tasks(tasks, "due_date") do
    Enum.sort_by(tasks, &(&1.due_date || ~N[2099-12-31 23:59:59]))
  end
  defp sort_tasks(tasks, "created_at") do
    Enum.sort_by(tasks, &(&1.inserted_at), {:desc, DateTime})
  end

  defp notify_subscribers(message) do
    PubSub.broadcast(ElixirCourse.PubSub, "tasks", message)
  end

  defp schedule_refresh() do
    Process.send_after(self(), :refresh_cache, @refresh_interval)
  end
end

# ===================================================================
# 📌 SECTION 5: REAL-TIME FEATURES WITH PUBSUB
# ===================================================================

defmodule CapstoneProjectWeb.TaskBoardChannel do
  @moduledoc """
  WebSocket channel for real-time task board updates.
  Based on our working implementation in lib/elixir_course_web/channels/task_board_channel.ex
  """
  use Phoenix.Channel
  require Logger

  alias ElixirCourse.Tasks.TaskManager
  alias ElixirCourseWeb.Presence

  def join("task_board:" <> _board_id, _params, socket) do
    # Subscribe to task updates
    Phoenix.PubSub.subscribe(ElixirCourse.PubSub, "tasks")

    # Track user presence
    {:ok, _} = Presence.track(socket, socket.assigns.user_id || "anonymous", %{
      joined_at: inspect(System.system_time(:second))
    })

    # Send initial task list
    {:ok, tasks} = TaskManager.get_tasks()
    {:ok, %{tasks: tasks}, socket}
  end

  def handle_in("create_task", params, socket) do
    case TaskManager.create_task(params) do
      {:ok, task} ->
        {:reply, {:ok, %{task: task}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: format_changeset_errors(changeset)}}, socket}
    end
  end

  def handle_in("update_task", %{"id" => id} = params, socket) do
    # EXERCISE 5.1: Implement task updates with conflict resolution
    task_params = Map.drop(params, ["id"])

    case TaskManager.update_task(String.to_integer(id), task_params) do
      {:ok, task} ->
        {:reply, {:ok, %{task: task}}, socket}

      {:error, :not_found} ->
        {:reply, {:error, %{message: "Task not found"}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: format_changeset_errors(changeset)}}, socket}
    end
  end

  def handle_in("delete_task", %{"id" => id}, socket) do
    case TaskManager.delete_task(String.to_integer(id)) do
      :ok ->
        {:reply, {:ok, %{message: "Task deleted"}}, socket}

      {:error, :not_found} ->
        {:reply, {:error, %{message: "Task not found"}}, socket}
    end
  end

  # Handle task update broadcasts from TaskManager
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

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

# ===================================================================
# 📌 SECTION 6: API CONTROLLERS
# ===================================================================

defmodule CapstoneProjectWeb.TaskController do
  @moduledoc """
  RESTful API controller for task management.
  Based on our working implementation in lib/elixir_course_web/controllers/task_controller.ex
  """
  use ElixirCourseWeb, :controller

  alias ElixirCourse.Tasks
  alias ElixirCourse.Tasks.{Task, TaskManager}

  # Convert string filter keys to atoms safely
  @valid_filter_keys [:status, :priority, :search, :sort_by, :assignee_id]

  def index(conn, params) do
    # EXERCISE 6.1: Implement API filtering and pagination
    filters = convert_filters_to_atoms(params)

    case TaskManager.get_tasks(filters) do
      {:ok, tasks} ->
        json(conn, %{data: tasks})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to fetch tasks: #{inspect(reason)}"})
    end
  end

  def show(conn, %{"id" => id}) do
    case Tasks.get_task(String.to_integer(id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      task ->
        json(conn, %{data: task})
    end
  end

  def create(conn, %{"task" => task_params}) do
    case TaskManager.create_task(task_params) do
      {:ok, task} ->
        conn
        |> put_status(:created)
        |> json(%{data: task})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "task" => task_params}) do
    case TaskManager.update_task(String.to_integer(id), task_params) do
      {:ok, task} ->
        json(conn, %{data: task})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case TaskManager.delete_task(String.to_integer(id)) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})
    end
  end

  # Helper function to safely convert filter strings to atoms
  defp convert_filters_to_atoms(params) do
    Enum.reduce(@valid_filter_keys, %{}, fn key, acc ->
      string_key = Atom.to_string(key)
      case Map.get(params, string_key) do
        value when value != "" and not is_nil(value) ->
          Map.put(acc, key, value)
        _ ->
          acc
      end
    end)
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

# ===================================================================
# 📌 SECTION 7: TESTING IMPLEMENTATION
# ===================================================================

defmodule CapstoneProject.TaskManagerTest do
  @moduledoc """
  Comprehensive testing examples for the capstone project.
  Based on our working test implementation.
  """
  use ExUnit.Case, async: false
  use ElixirCourse.DataCase

  alias ElixirCourse.Tasks.TaskManager
  alias ElixirCourse.{Tasks, Accounts}

  describe "task management" do
    setup do
      user = Accounts.create_user!(%{name: "Test User", email: "test@example.com"})
      {:ok, user: user}
    end

    test "creates task successfully with valid attributes", %{user: user} do
      attrs = %{
        title: "Test Task",
        description: "Test Description",
        priority: "high",
        creator_id: user.id
      }

      assert {:ok, task} = TaskManager.create_task(attrs)
      assert task.title == "Test Task"
      assert task.priority == "high"
      assert task.status == "todo"
    end

    test "returns error with invalid attributes" do
      attrs = %{title: ""}  # Invalid: title too short

      assert {:error, changeset} = TaskManager.create_task(attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    # EXERCISE 7.1: Add tests for task filtering
    test "filters tasks by status", %{user: user} do
      # Create tasks with different statuses
      TaskManager.create_task(%{title: "Todo Task", status: "todo", creator_id: user.id})
      TaskManager.create_task(%{title: "Done Task", status: "done", creator_id: user.id})

      {:ok, todo_tasks} = TaskManager.get_tasks(%{status: "todo"})
      {:ok, done_tasks} = TaskManager.get_tasks(%{status: "done"})

      assert length(todo_tasks) == 1
      assert length(done_tasks) == 1
      assert hd(todo_tasks).title == "Todo Task"
      assert hd(done_tasks).title == "Done Task"
    end

    # EXERCISE 7.2: Add tests for task sorting
    test "sorts tasks by priority", %{user: user} do
      TaskManager.create_task(%{title: "Low Task", priority: "low", creator_id: user.id})
      TaskManager.create_task(%{title: "Urgent Task", priority: "urgent", creator_id: user.id})
      TaskManager.create_task(%{title: "High Task", priority: "high", creator_id: user.id})

      {:ok, sorted_tasks} = TaskManager.get_tasks(%{sort_by: "priority"})

      priorities = Enum.map(sorted_tasks, & &1.priority)
      assert priorities == ["urgent", "high", "low"]
    end

    test "filters and sorts tasks", %{user: user} do
      TaskManager.create_task(%{title: "High Todo", priority: "high", status: "todo", creator_id: user.id})
      TaskManager.create_task(%{title: "Low Todo", priority: "low", status: "todo", creator_id: user.id})
      TaskManager.create_task(%{title: "High Done", priority: "high", status: "done", creator_id: user.id})

      {:ok, filtered_tasks} = TaskManager.get_tasks(%{status: "todo", sort_by: "priority"})

      assert length(filtered_tasks) == 2
      priorities = Enum.map(filtered_tasks, & &1.priority)
      assert priorities == ["high", "low"]
    end
  end

  describe "genserver state management" do
    test "maintains task cache correctly" do
      # EXERCISE 7.3: Test GenServer state management
      user = Accounts.create_user!(%{name: "Cache User", email: "cache@example.com"})

      {:ok, task} = TaskManager.create_task(%{title: "Cached Task", creator_id: user.id})

      # Verify task is in cache
      {:ok, tasks} = TaskManager.get_tasks()
      assert Enum.any?(tasks, &(&1.id == task.id))

      # Clear cache and verify it's empty
      :ok = TaskManager.clear_cache()
      {:ok, empty_tasks} = TaskManager.get_tasks()
      assert empty_tasks == []
    end

    test "handles task updates correctly" do
      user = Accounts.create_user!(%{name: "Update User", email: "update@example.com"})

      {:ok, task} = TaskManager.create_task(%{title: "Original Title", creator_id: user.id})
      {:ok, updated_task} = TaskManager.update_task(task.id, %{title: "Updated Title"})

      assert updated_task.title == "Updated Title"
      assert updated_task.id == task.id
    end

    test "handles task deletion correctly" do
      user = Accounts.create_user!(%{name: "Delete User", email: "delete@example.com"})

      {:ok, task} = TaskManager.create_task(%{title: "To Delete", creator_id: user.id})
      :ok = TaskManager.delete_task(task.id)

      # Verify task is deleted
      assert {:error, :not_found} = TaskManager.delete_task(task.id)
    end
  end

  describe "error scenarios" do
    test "handles invalid task creation gracefully" do
      # EXERCISE 7.4: Test error handling
      assert {:error, changeset} = TaskManager.create_task(%{})
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "handles non-existent task operations" do
      assert {:error, :not_found} = TaskManager.update_task(99999, %{title: "New Title"})
      assert {:error, :not_found} = TaskManager.delete_task(99999)
    end
  end
end

# ===================================================================
# 📌 SECTION 8: ADDITIONAL CHALLENGES
# ===================================================================

defmodule CapstoneProject.AdvancedChallenges do
  @moduledoc """
  Optional advanced challenges for experienced students.

  CHALLENGE 8.1: Implement task dependencies (tasks that depend on other tasks)
  CHALLENGE 8.2: Add task time tracking with start/stop functionality
  CHALLENGE 8.3: Implement task templates for recurring tasks
  CHALLENGE 8.4: Add file attachments to tasks
  CHALLENGE 8.5: Implement task history and audit logging
  """

  # Task dependency example
  defmodule TaskDependency do
    @moduledoc "Handle task dependencies and blocking relationships"

    def can_start_task?(task_id) do
      # Check if all dependent tasks are completed
      dependencies = get_task_dependencies(task_id)
      Enum.all?(dependencies, &task_completed?/1)
    end

    defp get_task_dependencies(task_id) do
      # Query for tasks that this task depends on
      []
    end

    defp task_completed?(task) do
      task.status == "done"
    end
  end

  # Time tracking example
  defmodule TimeTracker do
    use GenServer

    def start_task_timer(task_id, user_id) do
      GenServer.call(__MODULE__, {:start_timer, task_id, user_id})
    end

    def stop_task_timer(task_id, user_id) do
      GenServer.call(__MODULE__, {:stop_timer, task_id, user_id})
    end

    # CHALLENGE: Implement full time tracking with persistent storage
  end
end

# ===================================================================
# 📌 FINAL EXERCISES AND REFLECTION
# ===================================================================

defmodule CapstoneProject.FinalExercises do
  @moduledoc """
  Final integration exercises and reflection questions.

  FINAL EXERCISE 1: Integration Testing
  Write end-to-end tests that verify the complete task workflow:
  1. User creates account
  2. User creates task via API
  3. Task is cached in GenServer
  4. Task updates are handled correctly
  5. Task deletion works as expected
  6. All state remains consistent

  FINAL EXERCISE 2: Performance Analysis
  1. Use :observer to monitor GenServer performance
  2. Identify potential bottlenecks in task processing
  3. Test with large numbers of tasks (1000+)
  4. Analyze memory usage patterns

  FINAL EXERCISE 3: Error Recovery Testing
  1. Simulate database failures
  2. Test GenServer crash recovery
  3. Verify data consistency during failures
  4. Test error handling in API endpoints

  REFLECTION QUESTIONS:
  1. What are the trade-offs between in-memory caching and database queries?
  2. How would you scale this system to handle millions of tasks?
  3. What additional monitoring would you add for production?
  4. How would you handle schema migrations with cached data?
  5. What security considerations should be added to the API?

  DEPLOYMENT CONSIDERATIONS:
  1. Database connection pooling optimization
  2. GenServer monitoring and alerting
  3. API rate limiting implementation
  4. Error logging and observability
  5. Blue-green deployment strategy for GenServer state
  """
end

# ===================================================================
# 🎯 PROJECT COMPLETION CHECKLIST
# ===================================================================

# When you complete your project, you should be able to:
#
# ✅ Explain how GenServers maintain state and handle concurrent access
# ✅ Design efficient database schemas with proper constraints and indexes
# ✅ Implement context modules following Ecto best practices
# ✅ Write comprehensive tests covering unit and integration scenarios
# ✅ Handle errors gracefully in distributed systems
# ✅ Apply OTP supervision strategies for fault tolerance
# ✅ Use Ecto effectively for complex database operations and queries
# ✅ Implement Phoenix PubSub for real-time communication
# ✅ Build production-ready Elixir applications with proper observability
# ✅ Create RESTful APIs with proper error handling and validation
#
# Congratulations on completing the Elixir Course Capstone Project! 🚀
