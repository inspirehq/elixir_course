# ===================================================================
# 📌 SECTION 1: PROJECT STRUCTURE AND SETUP
# ===================================================================
#EXERCISE 1.1: Create a Phoenix application with the following structure:

defmodule CapstoneProject.Setup do
  @moduledoc """
  TASK: Create a Phoenix application with the following structure:

  After running `mix phx.new task_manager --database postgres`, you'll build:

  lib/
  ├── task_manager/
  │   ├── application.ex              # OTP Application (already exists)
  │   ├── repo.ex                     # Ecto Repository (already exists)
  │   ├── accounts/                   # User management context (you'll create)
  │   │   ├── user.ex                 # User schema
  │   │   └── accounts.ex             # Context functions
  │   ├── tasks/                      # Task management context (you'll create)
  │   │   ├── task.ex                 # Task schema
  │   │   ├── task_manager.ex         # GenServer for task coordination
  │   │   └── tasks.ex                # Context functions
  │   └── mailer.ex                   # Email functionality (already exists)
  ├── task_manager_web/
  │   ├── channels/                   # WebSocket channels (you'll create)
  │   │   ├── user_socket.ex          # Socket configuration (already exists)
  │   │   └── task_board_channel.ex   # Task board channel
  │   ├── controllers/                # API controllers (you'll create)
  │   │   ├── task_controller.ex      # Task API
  │   │   └── user_controller.ex      # User API
  │   ├── live/                       # LiveView components (you'll create)
  │   │   ├── task_board_live.ex      # Main task board interface (take from live/task_board_live.ex)
  │   │   └── task_board_live.html.heex # Task board template (take from live/task_board_live.html.heex)
  │   ├── components/                 # UI components (already exists)
  │   │   └── core_components.ex      # Phoenix default components
  │   ├── router.ex                   # Route definitions (already exists but you'll need to add the new routes)
  │   └── presence.ex                 # Phoenix Presence (you'll create)

  """
end

# ===================================================================
# 📌 SECTION 2: DATABASE SCHEMAS AND MIGRATIONS
# ===================================================================

defmodule TaskManager.Accounts.User do
  @moduledoc """
  User schema demonstrating Ecto best practices.
  Implementation for your task_manager project.
  """
  use Ecto.Schema
  import Ecto.Changeset

  #derive is used to specify the module that should be used to encode the schema to JSON.
  #Jason.Encoder is a module that provides a function to encode a schema to JSON.
  #except: [:__meta__] is used to exclude the __meta__ field from the JSON encoding.
  #__meta__ is a field that is used to store metadata about the schema.
  @derive {Jason.Encoder, except: [:__meta__]}

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string

    has_many :assigned_tasks, TaskManager.Tasks.Task, foreign_key: :assignee_id
    has_many :created_tasks, TaskManager.Tasks.Task, foreign_key: :creator_id

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
  # See ANSWERS section at end of file for implementation
end

defmodule TaskManager.Tasks.Task do
  @moduledoc """
  Task schema with comprehensive validations and associations.
  Implementation for your task_manager project.
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

    belongs_to :assignee, TaskManager.Accounts.User
    belongs_to :creator, TaskManager.Accounts.User

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
  # See ANSWERS section at end of file for implementation
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

defmodule TaskManager.Accounts do
  @moduledoc """
  Context module for user management.
  Implementation for your task_manager project.
  """

  import Ecto.Query, warn: false
  alias TaskManager.Repo
  alias TaskManager.Accounts.User

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
  # See ANSWERS section at end of file for implementation
end

defmodule TaskManager.Tasks do
  @moduledoc """
  Context module for task management.
  Implementation for your task_manager project.
  """

  import Ecto.Query, warn: false
  alias TaskManager.Repo
  alias TaskManager.Tasks.Task

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
  # EXERCISE 3.3: Task statistics and reporting
  # See ANSWERS section at end of file for implementation
end

# ===================================================================
# 📌 SECTION 4: GENSERVER IMPLEMENTATIONS
# ===================================================================

defmodule TaskManager.Tasks.TaskManager do
  @moduledoc """
  GenServer for coordinating task operations and maintaining in-memory state.
  Implementation for your task_manager project.
  """
  use GenServer
  require Logger

  alias TaskManager.{Tasks, Repo}
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

  def subscribe_to_updates() do
    GenServer.cast(__MODULE__, {:subscribe, self()})
  end

  def get_cache_stats() do
    GenServer.call(__MODULE__, :get_cache_stats)
  end

  def refresh_cache() do
    GenServer.cast(__MODULE__, :refresh_cache)
  end

  # Server Callbacks
  def init(_opts) do
    state = %{
      tasks: %{},
      last_refresh: nil,
      stats: %{},
      subscribers: []
    }

    schedule_refresh()
    Logger.info("TaskManager started")

    {:ok, state}
  end

  def handle_call({:get_tasks, filters}, _from, state) do
    # EXERCISE 4.1: Implement task filtering and sorting
    # See ANSWERS section at end of file for implementation
    {:reply, {:error, :not_implemented}, state}
  end

  def handle_call({:create_task, attrs}, _from, state) do
    # EXERCISE 4.2: Implement task creation with notifications
    # See ANSWERS section at end of file for implementation
    {:reply, {:error, :not_implemented}, state}
  end

  def handle_call({:update_task, id, attrs}, _from, state) do
    # EXERCISE 4.3: Implement task updates with cache management
    # See ANSWERS section at end of file for implementation
    {:reply, {:error, :not_implemented}, state}
  end

  def handle_call({:delete_task, id}, _from, state) do
    # EXERCISE 4.4: Implement task deletion with cascade handling
    # See ANSWERS section at end of file for implementation
    {:reply, {:error, :not_implemented}, state}
  end

  def handle_call(:get_stats, _from, state) do
    stats = %{
      cached_tasks: map_size(state.tasks),
      last_refresh: state.last_refresh,
      memory_usage: :erlang.process_info(self(), :memory)
    }
    {:reply, stats, state}
  end

  def handle_call(:get_cache_stats, _from, state) do
    stats = %{
      cached_tasks: map_size(state.tasks),
      last_refresh: state.last_refresh,
      memory_usage: :erlang.process_info(self(), :memory),
      message_queue_len: :erlang.process_info(self(), :message_queue_len)
    }
    {:reply, stats, state}
  end

  def handle_call(:clear_cache, _from, state) do
    new_state = %{state | tasks: %{}}
    {:reply, :ok, new_state}
  end

  def handle_cast({:subscribe, pid}, state) do
    # Monitor the subscribing process to clean up when it dies
    Process.monitor(pid)
    new_state = %{state | subscribers: [pid | state.subscribers]}
    Logger.debug("Added subscriber: #{inspect(pid)}")
    {:noreply, new_state}
  end

  def handle_cast(:refresh_cache, state) do
    # Force immediate cache refresh
    {:noreply, state, {:continue, :refresh_cache}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Clean up dead subscribers
    new_subscribers = List.delete(state.subscribers, pid)
    new_state = %{state | subscribers: new_subscribers}
    Logger.debug("Removed dead subscriber: #{inspect(pid)}")
    {:noreply, new_state}
  end

  def handle_info(:refresh_cache, state) do
    # EXERCISE 4.5: Implement cache refresh from database
    # See ANSWERS section at end of file for implementation
    {:noreply, state}
  end

  # Private Functions - EXERCISE 4.6: Implement comprehensive filtering
  # See ANSWERS section at end of file for implementation

  defp notify_subscribers(message) do
    PubSub.broadcast(TaskManager.PubSub, "tasks", message)
  end

  # Enhanced notification with subscriber support
  defp notify_subscribers_enhanced(message, state) do
    # Broadcast via PubSub for channels and LiveView
    PubSub.broadcast(TaskManager.PubSub, "tasks", message)

    # Direct notification to subscribers (for testing and monitoring)
    Enum.each(state.subscribers, fn pid ->
      send(pid, {:task_manager_event, message})
    end)
  end

  defp schedule_refresh() do
    Process.send_after(self(), :refresh_cache, @refresh_interval)
  end
end

# ===================================================================
# 📌 SECTION 5: REAL-TIME FEATURES WITH PUBSUB
# ===================================================================

defmodule TaskManagerWeb.TaskBoardChannel do
  @moduledoc """
  WebSocket channel for real-time task board updates.
  Implementation for your task_manager project.
  """
  use Phoenix.Channel
  require Logger

  alias TaskManager.Tasks.TaskManager
  alias TaskManagerWeb.Presence

  def join("task_board:" <> _board_id, _params, socket) do
    # Subscribe to task updates
    Phoenix.PubSub.subscribe(TaskManager.PubSub, "tasks")

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
    # See ANSWERS section at end of file for implementation
    {:reply, {:error, %{message: "Not implemented"}}, socket}
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

defmodule TaskManagerWeb.TaskController do
  @moduledoc """
  RESTful API controller for task management.
  Implementation for your task_manager project.
  """
  use TaskManagerWeb, :controller

  alias TaskManager.Tasks
  alias TaskManager.Tasks.{Task, TaskManager}

  # Convert string filter keys to atoms safely
  @valid_filter_keys [:status, :priority, :search, :sort_by, :assignee_id]

  def index(conn, params) do
    # EXERCISE 6.1: Implement API filtering and pagination
    # See ANSWERS section at end of file for implementation
    json(conn, %{error: "Not implemented"})
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

  # Helper functions - See ANSWERS section at end of file for implementation
end

# ===================================================================
# 📌 SECTION 7: TESTING IMPLEMENTATION
# ===================================================================

defmodule TaskManager.TaskManagerTest do
  @moduledoc """
  Comprehensive testing examples for the capstone project.
  Implementation for your task_manager project.
  """
  use ExUnit.Case, async: false
  use TaskManager.DataCase

  alias TaskManager.Tasks.TaskManager
  alias TaskManager.{Tasks, Accounts}

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
    # EXERCISE 7.2: Add tests for task sorting
    # See ANSWERS section at end of file for implementation

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
    # EXERCISE 7.3: Test GenServer state management
    # See ANSWERS section at end of file for implementation

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
    # EXERCISE 7.4: Test error handling
    # See ANSWERS section at end of file for implementation

    test "handles non-existent task operations" do
      assert {:error, :not_found} = TaskManager.update_task(99999, %{title: "New Title"})
      assert {:error, :not_found} = TaskManager.delete_task(99999)
    end
  end
end

# ===================================================================
# 📚 ANSWERS SECTION
# ===================================================================

defmodule CapstoneProject.Answers do
  @moduledoc false

  import Ecto.Query, warn: false
  import Ecto.Changeset

  # ===================================================================
  # 📌 EXERCISE 2.1: Professional Email Validation
  # ===================================================================

  @doc """
  Custom changeset validation for professional email domains.
  Rejects common free email providers for business applications.

  Usage:
    user
    |> professional_changeset(attrs)
    |> Repo.insert()
  """
  def professional_changeset(user, attrs) do
    user
    |> ElixirCourse.Accounts.User.changeset(attrs)
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

  # ===================================================================
  # 📌 EXERCISE 2.2: Task Custom Validations
  # ===================================================================

  @doc """
  Custom validation to ensure due dates are not in the past.
  This prevents users from creating tasks with impossible deadlines.
  """
  def validate_due_date(changeset) do
    validate_change(changeset, :due_date, fn :due_date, due_date ->
      if due_date && NaiveDateTime.compare(due_date, NaiveDateTime.utc_now()) == :lt do
        [due_date: "cannot be in the past"]
      else
        []
      end
    end)
  end

  @doc """
  Business logic to automatically set completed_at when task status changes to 'done'.
  Also clears completed_at when status changes away from 'done'.

  This ensures data consistency and provides automatic audit trails.
  """
  def maybe_set_completed_at(changeset) do
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

  # ===================================================================
  # 📌 EXERCISE 3.1: User Statistics
  # ===================================================================

  @doc """
  Advanced Ecto query demonstrating aggregations and subqueries.
  Calculates comprehensive user statistics including average tasks per user.

  Key techniques:
  - count() with :distinct for unique counts
  - Subqueries for complex aggregations
  - avg() function for statistical analysis
  """
  def user_stats do
    from(u in ElixirCourse.Accounts.User,
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
    |> ElixirCourse.Repo.one()
  end

  # ===================================================================
  # 📌 EXERCISES 3.2 & 3.3: Task Filtering and Statistics
  # ===================================================================

  @doc """
  Comprehensive dynamic query building with multiple filter types.
  Demonstrates proper use of guards and pattern matching in query building.

  Key patterns:
  - Guard clauses to handle empty/nil values
  - Pattern matching on filter types
  - Fragment() for custom SQL expressions
  - Proper use of ilike for case-insensitive search
  """
  def apply_filters(query, filters) do
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

  @doc """
  Task statistics using advanced Ecto aggregation with filters.
  Demonstrates conditional counting with filter clauses.

  The filter: syntax allows counting only rows that match specific conditions.
  """
  def task_stats do
    from(t in ElixirCourse.Tasks.Task,
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
    |> ElixirCourse.Repo.one()
  end

  # ===================================================================
  # 📌 EXERCISES 4.1-4.6: GenServer Implementation
  # ===================================================================

  @doc """
  Complete GenServer handle_call implementations demonstrating:
  - Proper state management with immutable updates
  - Error handling with tagged tuples
  - PubSub integration for real-time notifications
  - Cache consistency patterns
  """

  # EXERCISE 4.1: Task filtering and sorting in GenServer
  def handle_call_get_tasks({:get_tasks, filters}, _from, state) do
    filtered_tasks = state.tasks
    |> Map.values()
    |> apply_filters_in_memory(filters)
    |> sort_tasks(filters[:sort_by])

    {:reply, {:ok, filtered_tasks}, state}
  end

  # EXERCISE 4.2: Task creation with notifications
  def handle_call_create_task({:create_task, attrs}, _from, state) do
    case TaskManager.Tasks.create_task(attrs) do
      {:ok, task} ->
        # Update cache immediately after successful database operation
        new_state = put_in(state.tasks[task.id], task)
        # Notify all subscribers about the new task
        notify_subscribers_enhanced({:task_created, task}, new_state)
        {:reply, {:ok, task}, new_state}

      {:error, changeset} ->
        # Don't update state on error
        {:reply, {:error, changeset}, state}
    end
  end

  # EXERCISE 4.3: Task updates with cache management
  def handle_call_update_task({:update_task, id, attrs}, _from, state) do
          case TaskManager.Tasks.get_task(id) do
        nil ->
          {:reply, {:error, :not_found}, state}

        task ->
          case TaskManager.Tasks.update_task(task, attrs) do
            {:ok, updated_task} ->
              # Update cache with new task data
              new_state = put_in(state.tasks[id], updated_task)
              # Broadcast update to all subscribers
              notify_subscribers_enhanced({:task_updated, updated_task}, new_state)
              {:reply, {:ok, updated_task}, new_state}

            {:error, changeset} ->
              {:reply, {:error, changeset}, state}
          end
    end
  end

  # EXERCISE 4.4: Task deletion with cascade handling
  def handle_call_delete_task({:delete_task, id}, _from, state) do
          case TaskManager.Tasks.get_task(id) do
        nil ->
          {:reply, {:error, :not_found}, state}

        task ->
          case TaskManager.Tasks.delete_task(task) do
          {:ok, _deleted_task} ->
            # Remove from cache
            {_task, new_tasks} = Map.pop(state.tasks, id)
            new_state = %{state | tasks: new_tasks}
            # Notify subscribers of deletion
            notify_subscribers_enhanced({:task_deleted, id}, new_state)
            {:reply, :ok, new_state}

          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end
    end
  end

  # EXERCISE 4.5: Cache refresh from database
  def handle_info_refresh_cache(:refresh_cache, state) do
    case TaskManager.Tasks.list_tasks() do
      tasks when is_list(tasks) ->
        # Rebuild cache from database
        tasks_map = Map.new(tasks, &{&1.id, &1})
        new_state = %{state | tasks: tasks_map, last_refresh: DateTime.utc_now()}
        # Schedule next refresh
        schedule_refresh()
        Logger.debug("TaskManager cache refreshed with #{map_size(tasks_map)} tasks")
        {:noreply, new_state}

      _ ->
        Logger.warn("Failed to refresh task cache")
        # Still schedule next refresh even on failure
        schedule_refresh()
        {:noreply, state}
    end
  end

  # EXERCISE 4.6: Comprehensive in-memory filtering
  @doc """
  In-memory filtering functions for cached task data.
  These mirror the database filtering but work on loaded data.
  """
  def apply_filters_in_memory(tasks, filters) do
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

  def sort_tasks(tasks, nil), do: tasks
  def sort_tasks(tasks, ""), do: tasks
  def sort_tasks(tasks, "priority") do
    priority_order = %{"urgent" => 0, "high" => 1, "medium" => 2, "low" => 3}
    Enum.sort_by(tasks, &priority_order[&1.priority])
  end
  def sort_tasks(tasks, "due_date") do
    Enum.sort_by(tasks, &(&1.due_date || ~N[2099-12-31 23:59:59]))
  end
  def sort_tasks(tasks, "created_at") do
    Enum.sort_by(tasks, &(&1.inserted_at), {:desc, DateTime})
  end

  # Helper functions for GenServer
  defp notify_subscribers(message) do
    Phoenix.PubSub.broadcast(ElixirCourse.PubSub, "tasks", message)
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh_cache, :timer.minutes(5))
  end

  # EXERCISE 4.7: Subscriber management implementation
  def handle_cast_subscribe({:subscribe, pid}, state) do
    # Monitor the subscribing process to clean up when it dies
    Process.monitor(pid)
    new_state = %{state | subscribers: [pid | state.subscribers]}
    {:noreply, new_state}
  end

  # Handle process monitoring - clean up dead subscribers
  def handle_info_monitor({:DOWN, _ref, :process, pid, _reason}, state) do
    new_subscribers = List.delete(state.subscribers, pid)
    new_state = %{state | subscribers: new_subscribers}
    Logger.debug("Removed dead subscriber: #{inspect(pid)}")
    {:noreply, new_state}
  end

    # Enhanced notification with subscriber support
  defp notify_subscribers_enhanced(message, state) do
    # Broadcast via PubSub for channels and LiveView
    PubSub.broadcast(TaskManager.PubSub, "tasks", message)

    # Direct notification to subscribers (for testing and monitoring)
    Enum.each(state.subscribers, fn pid ->
      send(pid, {:task_manager_event, message})
    end)
  end

  # ===================================================================
  # 📌 EXERCISE 5.1: Channel Task Updates with Conflict Resolution
  # ===================================================================

  @doc """
  WebSocket channel implementation with proper error handling and validation.
  Demonstrates conflict resolution and parameter sanitization.

  Key patterns:
  - Parameter sanitization (removing id from params)
  - Comprehensive error handling
  - Proper WebSocket response formatting
  """
  def handle_in_update_task("update_task", %{"id" => id} = params, socket) do
    # Remove id from params to prevent parameter pollution
    task_params = Map.drop(params, ["id"])

    case TaskManager.Tasks.TaskManager.update_task(String.to_integer(id), task_params) do
      {:ok, task} ->
        {:reply, {:ok, %{task: task}}, socket}

      {:error, :not_found} ->
        {:reply, {:error, %{message: "Task not found"}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: format_changeset_errors(changeset)}}, socket}
    end
  end

  # ===================================================================
  # 📌 EXERCISE 6.1: API Controller Implementation
  # ===================================================================

  @doc """
  Complete controller implementation with comprehensive filtering,
  error handling, and proper HTTP status codes.

  Key patterns:
  - Safe parameter conversion
  - Proper HTTP status codes
  - Consistent error responses
  - Input validation and sanitization
  """
  def controller_index(conn, params) do
    filters = convert_filters_to_atoms(params)

    case TaskManager.Tasks.TaskManager.get_tasks(filters) do
      {:ok, tasks} ->
        json(conn, %{data: tasks})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to fetch tasks: #{inspect(reason)}"})
    end
  end

  @doc """
  Safe parameter conversion preventing atom table pollution.
  Only converts known, safe filter keys to atoms.

  This prevents attackers from creating arbitrary atoms that could
  exhaust the atom table and crash the system.
  """
  def convert_filters_to_atoms(params) do
    valid_filter_keys = [:status, :priority, :search, :sort_by, :assignee_id]

    Enum.reduce(valid_filter_keys, %{}, fn key, acc ->
      string_key = Atom.to_string(key)
      case Map.get(params, string_key) do
        value when value != "" and not is_nil(value) ->
          Map.put(acc, key, value)
        _ ->
          acc
      end
    end)
  end

  @doc """
  Consistent error formatting for API responses.
  Converts Ecto changeset errors to user-friendly messages.

  This ensures all API errors have a consistent format that
  frontend applications can reliably parse and display.
  """
  def format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  # ===================================================================
  # 📌 EXERCISES 7.1-7.4: Comprehensive Testing Examples
  # ===================================================================

  @doc """
  Complete test implementations demonstrating:
  - Proper test setup and teardown
  - GenServer state testing
  - Error scenario coverage
  - Integration testing patterns
  """

  # EXERCISE 7.1: Task filtering tests
  def test_task_filtering do
    quote do
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

      test "filters tasks by priority", %{user: user} do
        TaskManager.create_task(%{title: "Low Task", priority: "low", creator_id: user.id})
        TaskManager.create_task(%{title: "High Task", priority: "high", creator_id: user.id})

        {:ok, high_tasks} = TaskManager.get_tasks(%{priority: "high"})
        {:ok, low_tasks} = TaskManager.get_tasks(%{priority: "low"})

        assert length(high_tasks) == 1
        assert length(low_tasks) == 1
        assert hd(high_tasks).title == "High Task"
        assert hd(low_tasks).title == "Low Task"
      end

      test "filters tasks by search term", %{user: user} do
        TaskManager.create_task(%{title: "Important Meeting", description: "Weekly sync", creator_id: user.id})
        TaskManager.create_task(%{title: "Code Review", description: "Review PR #123", creator_id: user.id})

        {:ok, meeting_tasks} = TaskManager.get_tasks(%{search: "meeting"})
        {:ok, review_tasks} = TaskManager.get_tasks(%{search: "review"})

        assert length(meeting_tasks) == 1
        assert length(review_tasks) == 1
        assert hd(meeting_tasks).title == "Important Meeting"
        assert hd(review_tasks).title == "Code Review"
      end
    end
  end

  # EXERCISE 7.2: Task sorting tests
  def test_task_sorting do
    quote do
      test "sorts tasks by priority", %{user: user} do
        TaskManager.create_task(%{title: "Low Task", priority: "low", creator_id: user.id})
        TaskManager.create_task(%{title: "Urgent Task", priority: "urgent", creator_id: user.id})
        TaskManager.create_task(%{title: "High Task", priority: "high", creator_id: user.id})
        TaskManager.create_task(%{title: "Medium Task", priority: "medium", creator_id: user.id})

        {:ok, sorted_tasks} = TaskManager.get_tasks(%{sort_by: "priority"})

        priorities = Enum.map(sorted_tasks, & &1.priority)
        assert priorities == ["urgent", "high", "medium", "low"]
      end

      test "sorts tasks by due date", %{user: user} do
        tomorrow = NaiveDateTime.utc_now() |> NaiveDateTime.add(1, :day)
        next_week = NaiveDateTime.utc_now() |> NaiveDateTime.add(7, :day)

        TaskManager.create_task(%{title: "Later Task", due_date: next_week, creator_id: user.id})
        TaskManager.create_task(%{title: "Sooner Task", due_date: tomorrow, creator_id: user.id})
        TaskManager.create_task(%{title: "No Due Date", creator_id: user.id})

        {:ok, sorted_tasks} = TaskManager.get_tasks(%{sort_by: "due_date"})

        titles = Enum.map(sorted_tasks, & &1.title)
        assert titles == ["Sooner Task", "Later Task", "No Due Date"]
      end

      test "sorts tasks by creation date", %{user: user} do
        {:ok, first_task} = TaskManager.create_task(%{title: "First Task", creator_id: user.id})
        :timer.sleep(10)  # Ensure different timestamps
        {:ok, second_task} = TaskManager.create_task(%{title: "Second Task", creator_id: user.id})

        {:ok, sorted_tasks} = TaskManager.get_tasks(%{sort_by: "created_at"})

        titles = Enum.map(sorted_tasks, & &1.title)
        assert titles == ["Second Task", "First Task"]  # Newest first
      end
    end
  end

  # EXERCISE 7.3: GenServer state management tests
  def test_genserver_state do
    quote do
      test "maintains task cache correctly" do
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

      test "handles concurrent task updates correctly" do
        user = Accounts.create_user!(%{name: "Concurrent User", email: "concurrent@example.com"})

        {:ok, task} = TaskManager.create_task(%{title: "Concurrent Task", creator_id: user.id})

        # Simulate concurrent updates
        task1 = Task.async(fn -> TaskManager.update_task(task.id, %{title: "Update 1"}) end)
        task2 = Task.async(fn -> TaskManager.update_task(task.id, %{title: "Update 2"}) end)

        results = [Task.await(task1), Task.await(task2)]

        # Both should succeed (last one wins)
        assert Enum.all?(results, fn {status, _} -> status == :ok end)
      end

      test "cache refresh updates state correctly" do
        user = Accounts.create_user!(%{name: "Refresh User", email: "refresh@example.com"})

        # Create task directly in database (bypassing GenServer)
        {:ok, task} = Tasks.create_task(%{title: "Direct DB Task", creator_id: user.id})

        # Cache won't have this task initially
        {:ok, cached_tasks} = TaskManager.get_tasks()
        refute Enum.any?(cached_tasks, &(&1.id == task.id))

        # Force cache refresh
        send(TaskManager, :refresh_cache)
        :timer.sleep(100)  # Wait for refresh to complete

        # Now cache should have the task
        {:ok, refreshed_tasks} = TaskManager.get_tasks()
        assert Enum.any?(refreshed_tasks, &(&1.id == task.id))
      end
    end
  end

  # EXERCISE 7.4: Error handling tests
  def test_error_handling do
    quote do
      test "handles invalid task creation gracefully" do
        # Test missing required fields
        assert {:error, changeset} = TaskManager.create_task(%{})
        assert %{title: ["can't be blank"]} = errors_on(changeset)

        # Test invalid status
        assert {:error, changeset} = TaskManager.create_task(%{title: "Test", status: "invalid"})
        assert %{status: ["is invalid"]} = errors_on(changeset)

        # Test invalid priority
        assert {:error, changeset} = TaskManager.create_task(%{title: "Test", priority: "invalid"})
        assert %{priority: ["is invalid"]} = errors_on(changeset)
      end

      test "handles database constraint violations" do
        # Test foreign key constraint
        assert {:error, changeset} = TaskManager.create_task(%{
          title: "Test Task",
          assignee_id: 99999  # Non-existent user
        })
        assert %{assignee_id: ["does not exist"]} = errors_on(changeset)
      end

      test "handles GenServer crashes gracefully" do
        user = Accounts.create_user!(%{name: "Crash User", email: "crash@example.com"})

        {:ok, task} = TaskManager.create_task(%{title: "Crash Test", creator_id: user.id})

        # Force GenServer restart (simulating crash)
        GenServer.stop(TaskManager, :normal)
        :timer.sleep(100)  # Wait for restart

        # Should still work after restart (cache will be empty but functional)
        {:ok, tasks} = TaskManager.get_tasks()
        assert is_list(tasks)
      end

      test "handles network timeouts and database failures" do
        # Mock database failure
        with_mock(Tasks, [create_task: fn(_) -> {:error, :database_timeout} end]) do
          assert {:error, :database_timeout} = TaskManager.create_task(%{title: "Test"})
        end
      end
    end
  end
end
