# Day Three Capstone Teacher's Guide

## 🎯 Overview

This comprehensive teacher's guide provides step-by-step support for facilitating the Real-Time Task Management System capstone project. The project integrates all concepts from Day One (GenServer, OTP, Elixir fundamentals) and Day Two (Ecto, real-time features, testing), culminating in a production-ready backend system.

**Project Goal**: Students build a complete task management system with real-time updates, demonstrating mastery of Elixir/Phoenix patterns through practical implementation.

## 📚 Pre-Class Preparation

### Environment Setup Checklist
```bash
# Verify student environments before class
elixir --version    # Should be 1.14+
mix --version       # Should be 1.14+
mix phx.new --version # Should be 1.7+

# Test database connectivity
psql --version      # PostgreSQL 12+
createdb test_capstone
dropdb test_capstone
```

### Starter Code Repository
```bash
# Create the initial Phoenix project
mix phx.new elixir_course --database postgres --no-assets --no-html --no-gettext
cd elixir_course
mix deps.get
mix ecto.create
```

**Pre-Class Setup Tips:**
- Have backup VMs ready for students with setup issues
- Test WebSocket functionality on classroom network
- Prepare seed data scripts for consistent testing
- Create a "troubleshooting" document with common setup fixes

## 🏗️ Project Architecture Deep Dive

### Teaching the System Design

Start with this visual explanation:

```
🌐 HTTP API Layer
├── TaskController (REST endpoints)
├── UserController (User management)  
└── Error handling & validation

🧠 Business Logic Layer
├── TaskManager GenServer (State coordination)
├── Accounts Context (User operations)
├── Tasks Context (Task operations)
└── Phoenix PubSub (Event broadcasting)

💾 Data Layer
├── User Schema (Validations & relationships)
├── Task Schema (Business rules & constraints)
├── Database Migrations (Structure & indexes)
└── Ecto Repo (Database interface)

⚡ Real-Time Layer
├── TaskBoard Channel (WebSocket communication)
├── Presence Tracking (User awareness)
└── PubSub Integration (Live updates)
```

**Key Teaching Points:**
- "Each layer has a specific responsibility - this prevents chaos in larger applications"
- "GenServer sits between your API and database, coordinating state and events"
- "Context modules are your application's public API - they hide implementation details"

## 📋 Phase-by-Phase Teaching Guide

### Phase 1: Database Foundation (2-3 hours)

#### Learning Objectives
Students will:
- Design normalized schemas with proper relationships and constraints
- Implement comprehensive Ecto changesets with business rule validation
- Create efficient database queries with association preloading
- Handle database migrations and understand indexing strategies

#### 🎓 Teaching Strategy: "Schema-First Development"

**Step 1: User Schema Walkthrough (30 minutes)**

Start with the User schema and build it incrementally:

```elixir
# Begin with basic structure
defmodule ElixirCourse.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    timestamps()
  end
end
```

**Teaching Moment**: "Schemas are your data contracts - they define what your application knows about the world."

**Step 2: Add Validations Progressively**

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :name])
  |> validate_required([:email, :name])
  |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  |> validate_length(:name, min: 2, max: 100)
  |> unique_constraint(:email)
end
```

**Interactive Exercise**: Have students explain what each validation does and why it's important.

**Expected Student Answers:**
- `cast/3`: "Filters allowed fields and converts string keys to atoms safely"
- `validate_required/2`: "Ensures critical fields are never nil or empty"
- `validate_format/3`: "Uses regex to ensure email has proper structure"
- `validate_length/3`: "Prevents names that are too short or too long"
- `unique_constraint/2`: "Prevents duplicate emails in the database"

**Follow-up Questions:**
1. "What happens if we put `unique_constraint` before `validate_format`?" 
   - Answer: "Still works, but we'd hit the database unnecessarily for invalid emails"
2. "Why use `cast/3` instead of directly accessing `attrs`?"
   - Answer: "Security - prevents mass assignment attacks and ensures type safety"
3. "What's the difference between `validate_required` and database `null: false`?"
   - Answer: "validate_required gives user-friendly errors, null constraint is last line of defense"

**Step 3: Task Schema with Relationships**

Build the Task schema while explaining associations:

```elixir
defmodule ElixirCourse.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

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
end
```

**Key Teaching Points:**
- "Module attributes (@statuses) define your domain constraints"
- "belongs_to creates foreign key relationships"
- "Default values prevent nil states in your business logic"

#### 🔧 Migration Deep Dive (45 minutes)

**Live Code the Migrations:**

```elixir
defmodule ElixirCourse.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :avatar_url, :string

      timestamps()
    end

    # Explain why indexes matter
    create unique_index(:users, [:email])
  end
end
```

**Teaching Moment**: "Indexes are your performance insurance policy. Every foreign key should have an index."

```elixir
defmodule ElixirCourse.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, default: "todo"
      add :priority, :string, default: "medium"
      add :due_date, :naive_datetime
      add :completed_at, :naive_datetime
      
      # Foreign keys with proper cascade behavior
      add :assignee_id, references(:users, on_delete: :nilify_all)
      add :creator_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    # Performance indexes
    create index(:tasks, [:status])
    create index(:tasks, [:priority])
    create index(:tasks, [:assignee_id])
    create index(:tasks, [:creator_id])
    create index(:tasks, [:due_date])
  end
end
```

**Interactive Exercise**: "What happens if we delete a user who created tasks? Why `nilify_all` instead of `delete_all`?"

**Expected Student Discussion:**
- `nilify_all`: Sets foreign key to NULL, preserving task history
- `delete_all`: Would delete all tasks when user is deleted
- `restrict`: Would prevent user deletion if they have tasks

**Real-World Scenario**: "In a business application, you rarely want to lose task history when an employee leaves. Setting creator_id to NULL preserves the task while indicating the creator is no longer available."

**Code Demonstration**:
```elixir
# Test the cascade behavior
user = Repo.insert!(%User{name: "Test User", email: "test@example.com"})
task = Repo.insert!(%Task{title: "Test Task", creator_id: user.id})

# Delete the user
Repo.delete!(user)

# Check what happened to the task
reloaded_task = Repo.get!(Task, task.id)
IO.inspect(reloaded_task.creator_id)  # nil - not deleted!
```

#### 🎯 Advanced Changeset Patterns (45 minutes)

**Custom Validation Example:**

```elixir
defp validate_due_date(changeset) do
  validate_change(changeset, :due_date, fn :due_date, due_date ->
    if due_date && NaiveDateTime.compare(due_date, NaiveDateTime.utc_now()) == :lt do
      [due_date: "cannot be in the past"]
    else
      []
    end
  end)
end
```

**Business Logic in Changesets:**

```elixir
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
```

**Teaching Point**: "Changesets aren't just validation - they're where business rules live."

### Phase 2: Context Modules and Business Logic (2-3 hours)

#### Learning Objectives
Students will:
- Implement Phoenix context pattern for clean architecture
- Write efficient Ecto queries with dynamic filtering
- Handle complex data transformations and preloading
- Apply proper error handling patterns throughout the application

#### 🎓 Teaching Strategy: "Contexts as Public APIs"

**Step 1: Accounts Context Foundation (45 minutes)**

Start with basic CRUD operations:

```elixir
defmodule ElixirCourse.Accounts do
  import Ecto.Query, warn: false
  alias ElixirCourse.Repo
  alias ElixirCourse.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)
  def get_user(id), do: Repo.get(User, id)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
```

**Teaching Point**: "Context functions are your application's public API. They should read like English."

**Step 2: Tasks Context with Advanced Queries (60 minutes)**

Build the Tasks context incrementally:

```elixir
defmodule ElixirCourse.Tasks do
  import Ecto.Query, warn: false
  alias ElixirCourse.Repo
  alias ElixirCourse.Tasks.Task

  def list_tasks do
    Task
    |> preload([:assignee, :creator])
    |> Repo.all()
  end
end
```

**Teaching Moment**: "Always preload associations to avoid N+1 queries. Show the SQL being generated."

**Advanced Filtering Implementation:**

```elixir
def list_tasks_with_filters(filters) do
  Task
  |> apply_filters(filters)
  |> preload([:assignee, :creator])
  |> Repo.all()
end

defp apply_filters(query, filters) do
  Enum.reduce(filters, query, fn {key, value}, query ->
    case {key, value} do
      {:status, status} when status != "" ->
        where(query, [t], t.status == ^status)

      {:priority, priority} when priority != "" ->
        where(query, [t], t.priority == ^priority)

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

      _ ->
        query
    end
  end)
end
```

**Interactive Exercise**: "Let's trace through this code with sample filters. What SQL is generated?"

**Live Coding Session**: Walk through with actual filters:
```elixir
# In IEx with logging enabled
filters = %{status: "todo", priority: "high", search: "urgent"}

# Show the SQL generation step by step
query = from(t in Task)
|> where([t], t.status == "todo")
|> where([t], t.priority == "high")  
|> where([t], ilike(t.title, "%urgent%") or ilike(t.description, "%urgent%"))

# Enable SQL logging to see the generated query
Repo.all(query)
```

**Expected Generated SQL**:
```sql
SELECT t0."id", t0."title", t0."description", t0."status", t0."priority", 
       t0."due_date", t0."completed_at", t0."assignee_id", t0."creator_id",
       t0."inserted_at", t0."updated_at"
FROM "tasks" AS t0
WHERE (t0."status" = $1) 
AND (t0."priority" = $2) 
AND (t0."title" ILIKE $3 OR t0."description" ILIKE $4)
```

**Teaching Points**:
- "Each filter adds a WHERE clause - they're ANDed together"
- "ILIKE is PostgreSQL's case-insensitive LIKE"
- "Parameters ($1, $2, etc.) prevent SQL injection"
- "The fragment() function lets you write raw SQL when needed"

**Step 3: Error Handling Patterns (30 minutes)**

```elixir
def create_task(attrs \\ %{}) do
  %Task{}
  |> Task.changeset(attrs)
  |> Repo.insert()
  |> case do
    {:ok, task} -> {:ok, Repo.preload(task, [:assignee, :creator])}
    error -> error
  end
end
```

**Teaching Point**: "Always return consistent data structures. Preload after creation to maintain API consistency."

### Phase 3: GenServer State Management (3-4 hours)

#### Learning Objectives
Students will:
- Implement GenServer for stateful coordination and caching
- Handle concurrent access and race conditions properly
- Integrate with Phoenix PubSub for event-driven architecture
- Manage cache consistency and refresh strategies effectively

#### 🎓 Teaching Strategy: "GenServer as System Coordinator"

**Step 1: GenServer Foundation (45 minutes)**

Start with the basic structure and explain each part:

```elixir
defmodule ElixirCourse.Tasks.TaskManager do
  use GenServer
  require Logger

  alias ElixirCourse.{Tasks, Repo}
  alias Phoenix.PubSub

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_tasks(filters \\ %{}) do
    GenServer.call(__MODULE__, {:get_tasks, filters})
  end

  # Server Callbacks
  def init(_opts) do
    state = %{
      tasks: %{},           # In-memory cache
      last_refresh: nil,    # Cache metadata
      stats: %{}           # Runtime statistics
    }

    schedule_refresh()
    Logger.info("TaskManager started")
    {:ok, state}
  end
end
```

**Teaching Moments:**
- "Client functions hide the GenServer complexity from callers"
- "State structure matters - design it for your access patterns"
- "Always log important GenServer lifecycle events"

**Step 2: Implementing CRUD Operations (90 minutes)**

**Task Creation with Cache Management:**

```elixir
def handle_call({:create_task, attrs}, _from, state) do
  case Tasks.create_task(attrs) do
    {:ok, task} ->
      # Update cache immediately
      new_state = put_in(state.tasks[task.id], task)
      # Notify subscribers
      notify_subscribers({:task_created, task})
      {:reply, {:ok, task}, new_state}

    {:error, changeset} ->
      {:reply, {:error, changeset}, state}
  end
end
```

**Teaching Points:**
- "Update cache immediately after database success"
- "Always return the new state, even on errors"
- "Broadcast events after successful state changes"

**Task Updates with Conflict Handling:**

```elixir
def handle_call({:update_task, id, attrs}, _from, state) do
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
```

**Interactive Exercise**: "What happens if two users update the same task simultaneously? How does our pattern handle this?"

**Live Demonstration**: Set up a race condition scenario:

```elixir
# In IEx, simulate concurrent updates
task_id = 1
user1_attrs = %{title: "Updated by User 1", status: "in_progress"}
user2_attrs = %{title: "Updated by User 2", status: "review"}

# Simulate concurrent calls
Task.async(fn -> TaskManager.update_task(task_id, user1_attrs) end)
Task.async(fn -> TaskManager.update_task(task_id, user2_attrs) end)
```

**Expected Student Observations**:
- "Both updates succeed because they happen sequentially in the GenServer"
- "The GenServer serializes access - no true concurrency within the process"
- "Last update wins - this is 'optimistic concurrency'"

**Advanced Discussion**:
- "What if we needed pessimistic locking?"
- "How would we handle version conflicts?"
- "When might we need distributed locking?"

**Code Enhancement Example**:
```elixir
# Add version checking for conflict detection
def handle_call({:update_task, id, attrs, expected_version}, _from, state) do
  case Map.get(state.tasks, id) do
    %{version: ^expected_version} = task ->
      # Version matches, proceed with update
      case Tasks.update_task(task, attrs) do
        {:ok, updated_task} ->
          new_state = put_in(state.tasks[id], updated_task)
          {:reply, {:ok, updated_task}, new_state}
        error -> {:reply, error, state}
      end
    
    %{version: current_version} ->
      {:reply, {:error, {:version_conflict, current_version}}, state}
    
    nil ->
      {:reply, {:error, :not_found}, state}
  end
end
```

**Step 3: Advanced Filtering in Memory (60 minutes)**

```elixir
def handle_call({:get_tasks, filters}, _from, state) do
  filtered_tasks = state.tasks
  |> Map.values()
  |> apply_filters(filters)
  |> sort_tasks(filters[:sort_by])

  {:reply, {:ok, filtered_tasks}, state}
end

defp apply_filters(tasks, filters) do
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
```

**Teaching Point**: "In-memory filtering is fast but uses more memory. Trade-offs matter in system design."

**Step 4: Cache Refresh Strategy (45 minutes)**

```elixir
def handle_info(:refresh_cache, state) do
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

defp schedule_refresh() do
  Process.send_after(self(), :refresh_cache, :timer.minutes(5))
end
```

**Discussion Point**: "Why refresh the cache periodically? What are the trade-offs of different refresh strategies?"

### Phase 4: Real-Time Features with PubSub (2-3 hours)

#### Learning Objectives
Students will:
- Implement Phoenix PubSub for decoupled event messaging
- Build WebSocket channels for bidirectional real-time communication
- Handle presence tracking and user state management
- Manage message broadcasting and subscription patterns effectively

#### 🎓 Teaching Strategy: "Events Drive Everything"

**Step 1: PubSub Integration (45 minutes)**

**In TaskManager GenServer:**

```elixir
defp notify_subscribers(message) do
  PubSub.broadcast(ElixirCourse.PubSub, "tasks", message)
end
```

**Teaching Point**: "PubSub decouples your GenServer from channels. The GenServer doesn't need to know about WebSockets."

**Step 2: Channel Implementation (90 minutes)**

**Basic Channel Structure:**

```elixir
defmodule ElixirCourseWeb.TaskBoardChannel do
  use Phoenix.Channel
  require Logger

  alias ElixirCourse.Tasks.TaskManager
  alias ElixirCourseWeb.Presence

  def join("task_board:" <> _board_id, _params, socket) do
    # Subscribe to task events
    Phoenix.PubSub.subscribe(ElixirCourse.PubSub, "tasks")

    # Track user presence
    {:ok, _} = Presence.track(socket, socket.assigns.user_id || "anonymous", %{
      joined_at: inspect(System.system_time(:second))
    })

    # Send initial data
    {:ok, tasks} = TaskManager.get_tasks()
    {:ok, %{tasks: tasks}, socket}
  end
end
```

**Teaching Points:**
- "join/3 is called when a client connects"
- "Subscribe to PubSub topics to receive events"
- "Send initial state to new connections"

**Handling Incoming Messages:**

```elixir
def handle_in("create_task", params, socket) do
  case TaskManager.create_task(params) do
    {:ok, task} ->
      {:reply, {:ok, %{task: task}}, socket}

    {:error, changeset} ->
      {:reply, {:error, %{errors: format_changeset_errors(changeset)}}, socket}
  end
end

def handle_in("update_task", %{"id" => id} = params, socket) do
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
```

**Interactive Exercise**: "Let's trace a message from WebSocket client through the channel to GenServer and back."

**Step-by-Step Message Flow Demonstration**:

```javascript
// 1. Client sends WebSocket message
channel.push("create_task", {
  title: "New Task",
  priority: "high",
  creator_id: 1
})
```

**Teacher Walkthrough**:
```elixir
# 2. Channel receives message
def handle_in("create_task", params, socket) do
  # 3. Channel calls GenServer
  case TaskManager.create_task(params) do
    # 4. GenServer calls Context
    # 5. Context calls Database
    # 6. Database returns result
    # 7. Context returns to GenServer
    {:ok, task} ->
      # 8. GenServer broadcasts via PubSub
      notify_subscribers({:task_created, task})
      # 9. Channel returns success to client
      {:reply, {:ok, %{task: task}}, socket}
    
    {:error, changeset} ->
      # Error path - return validation errors
      {:reply, {:error, %{errors: format_errors(changeset)}}, socket}
  end
end

# 10. All connected channels receive broadcast
def handle_info({:task_created, task}, socket) do
  # 11. Push update to all connected clients
  push(socket, "task_created", %{task: task})
  {:noreply, socket}
end
```

**Visual Flow Diagram**:
```
Client A ──push──> Channel A ──call──> GenServer ──call──> Context ──> Database
   ↑                   ↓                    ↓
   │               broadcast            broadcast
   │                   ↓                    ↓
   └──push─── Channel A ←──info─── PubSub ←──┘
              Channel B ←──info──┘
              Channel C ←──info──┘
```

**Interactive Questions**:
1. "What happens if the GenServer is busy?"
   - Answer: "Client waits - GenServer handles one call at a time"
2. "Why broadcast instead of direct channel-to-channel communication?"
   - Answer: "Decoupling - GenServer doesn't know about channels"
3. "What if a channel crashes during broadcast?"
   - Answer: "Other channels still receive the message - fault isolation"

**Step 3: Broadcasting Events (45 minutes)**

**Handle PubSub Events:**

```elixir
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
```

**Teaching Point**: "handle_info/2 receives PubSub broadcasts and forwards them to connected clients."

### Phase 5: API Design and Controllers (2-3 hours)

#### Learning Objectives
Students will:
- Design RESTful APIs following HTTP conventions and best practices
- Implement comprehensive error handling with appropriate status codes
- Handle request validation and parameter conversion safely
- Format responses consistently across all endpoints

#### 🎓 Teaching Strategy: "API as Contract"

**Step 1: RESTful Design Principles (30 minutes)**

**URL Structure:**
```
GET    /api/tasks           # List tasks with filtering
POST   /api/tasks           # Create new task
GET    /api/tasks/:id       # Get specific task
PUT    /api/tasks/:id       # Update task
DELETE /api/tasks/:id       # Delete task
```

**Teaching Point**: "REST is about resources and actions. URLs should be nouns, HTTP verbs should be actions."

**Step 2: Controller Implementation (90 minutes)**

**Index Action with Filtering:**

```elixir
defmodule ElixirCourseWeb.TaskController do
  use ElixirCourseWeb, :controller

  alias ElixirCourse.Tasks.TaskManager

  # Safe filter conversion
  @valid_filter_keys [:status, :priority, :search, :sort_by, :assignee_id]

  def index(conn, params) do
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
end
```

**Teaching Points:**
- "Always validate and sanitize input parameters"
- "Use module attributes to define valid filter keys"
- "Return consistent error structures"

**Create Action with Validation:**

```elixir
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

defp format_changeset_errors(changeset) do
  Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end)
end
```

**Interactive Exercise**: "Let's test this API with different invalid inputs and see how errors are formatted."

**Live API Testing Session**:

```bash
# Test 1: Missing required fields
curl -X POST http://localhost:4000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"task": {}}'

# Expected Response:
{
  "errors": {
    "title": ["can't be blank"]
  }
}

# Test 2: Invalid status
curl -X POST http://localhost:4000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"task": {"title": "Test", "status": "invalid_status"}}'

# Expected Response:
{
  "errors": {
    "status": ["is invalid"]
  }
}

# Test 3: Invalid email format (if creating user)
curl -X POST http://localhost:4000/api/users \
  -H "Content-Type: application/json" \
  -d '{"user": {"name": "Test", "email": "invalid-email"}}'

# Expected Response:
{
  "errors": {
    "email": ["has invalid format"]
  }
}
```

**Teaching Discussion Points**:
1. "Why return 422 instead of 400 for validation errors?"
   - Answer: "422 specifically means 'unprocessable entity' - request was well-formed but semantically incorrect"
2. "How does our error format help frontend developers?"
   - Answer: "Consistent structure allows generic error handling and field-specific error display"
3. "What security considerations are there in error messages?"
   - Answer: "Don't leak sensitive information; be helpful but not revealing about system internals"

**Error Format Comparison**:
```elixir
# Bad - inconsistent structure
%{error: "Title can't be blank"}
%{message: "Invalid status"}
%{validation_failed: ["Email format"]}

# Good - consistent structure
%{errors: %{title: ["can't be blank"]}}
%{errors: %{status: ["is invalid"]}}
%{errors: %{email: ["has invalid format"]}}
```

### Phase 6: Comprehensive Testing Strategy (3-4 hours)

#### Learning Objectives
Students will:
- Write unit tests for GenServers and business logic components
- Test real-time features and PubSub integration effectively
- Handle test data isolation and cleanup properly
- Implement comprehensive error scenario testing

#### 🎓 Teaching Strategy: "Test Behavior, Not Implementation"

**Step 1: GenServer Testing Patterns (90 minutes)**

**Basic GenServer Tests:**

```elixir
defmodule ElixirCourse.TaskManagerTest do
  use ExUnit.Case, async: false
  use ElixirCourse.DataCase

  alias ElixirCourse.Tasks.TaskManager
  alias ElixirCourse.{Tasks, Accounts}

  describe "task creation" do
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
  end
end
```

**Teaching Points:**
- "Use setup blocks for common test data"
- "Test the public API, not internal state"
- "Use descriptive test names that explain the scenario"

**Advanced GenServer State Testing:**

```elixir
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
```

**Step 2: Integration Testing (90 minutes)**

**End-to-End Workflow Tests:**

```elixir
test "complete task workflow" do
  user = Accounts.create_user!(%{name: "Workflow User", email: "workflow@example.com"})

  # Create task
  {:ok, task} = TaskManager.create_task(%{
    title: "Workflow Task",
    creator_id: user.id,
    status: "todo"
  })

  # Update task
  {:ok, updated_task} = TaskManager.update_task(task.id, %{status: "in_progress"})
  assert updated_task.status == "in_progress"

  # Complete task
  {:ok, completed_task} = TaskManager.update_task(task.id, %{status: "done"})
  assert completed_task.status == "done"
  assert completed_task.completed_at != nil

  # Delete task
  :ok = TaskManager.delete_task(task.id)
  assert {:error, :not_found} = TaskManager.delete_task(task.id)
end
```

**Step 3: Error Scenario Testing (60 minutes)**

```elixir
describe "error handling" do
  test "handles invalid task creation gracefully" do
    assert {:error, changeset} = TaskManager.create_task(%{})
    assert %{title: ["can't be blank"]} = errors_on(changeset)
  end

  test "handles non-existent task operations" do
    assert {:error, :not_found} = TaskManager.update_task(99999, %{title: "New Title"})
    assert {:error, :not_found} = TaskManager.delete_task(99999)
  end

  test "handles database constraint violations" do
    # Test foreign key constraints
    assert {:error, changeset} = TaskManager.create_task(%{
      title: "Test Task",
      assignee_id: 99999  # Non-existent user
    })
    assert %{assignee_id: ["does not exist"]} = errors_on(changeset)
  end
end
```

## 🚀 Advanced Teaching Techniques

### Live Debugging Sessions

**Using IEx for Real-Time Debugging:**

```elixir
# In IEx during development
iex> {:ok, task} = ElixirCourse.Tasks.TaskManager.create_task(%{title: "Debug Task"})
iex> :sys.get_state(ElixirCourse.Tasks.TaskManager)
# Shows current GenServer state

iex> :observer.start()
# Visual process monitoring
```

**Teaching Moment**: "Show students how to inspect running GenServer state and monitor process behavior."

### Performance Analysis

**Memory Usage Monitoring:**

```elixir
def handle_call(:get_stats, _from, state) do
  stats = %{
    cached_tasks: map_size(state.tasks),
    last_refresh: state.last_refresh,
    memory_usage: :erlang.process_info(self(), :memory),
    message_queue_len: :erlang.process_info(self(), :message_queue_len)
  }
  {:reply, stats, state}
end
```

**Database Query Analysis:**

```bash
# Show students how to analyze queries
mix ecto.gen.migration add_query_logging
# Add logging configuration
# Demonstrate EXPLAIN ANALYZE in PostgreSQL
```

## 🎯 Common Student Challenges and Solutions

### Challenge 1: GenServer State Confusion

**Symptom**: "My GenServer isn't updating the cache"

**Debugging Steps:**
1. Check if new state is being returned
2. Verify the state update logic
3. Ensure proper pattern matching

**Solution Example:**
```elixir
# Wrong - not returning new state
def handle_call({:create_task, attrs}, _from, state) do
  case Tasks.create_task(attrs) do
    {:ok, task} ->
      put_in(state.tasks[task.id], task)  # State update lost!
      {:reply, {:ok, task}, state}       # Returns old state
  end
end

# Correct - return updated state
def handle_call({:create_task, attrs}, _from, state) do
  case Tasks.create_task(attrs) do
    {:ok, task} ->
      new_state = put_in(state.tasks[task.id], task)
      {:reply, {:ok, task}, new_state}   # Returns new state
  end
end
```

### Challenge 2: Database Connection Issues

**Symptom**: "Tests are failing with database errors"

**Solution Setup:**
```elixir
# In test_helper.exs
Ecto.Adapters.SQL.Sandbox.mode(ElixirCourse.Repo, :manual)

# In test files
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(ElixirCourse.Repo)
  :ok
end
```

### Challenge 3: PubSub Message Issues

**Symptom**: "Real-time updates aren't working"

**Debugging Checklist:**
1. Verify PubSub subscription in channel join
2. Check topic names match exactly
3. Ensure GenServer is broadcasting
4. Verify handle_info patterns match

**Solution Example:**
```elixir
# In channel
def join("task_board:" <> _board_id, _params, socket) do
  Phoenix.PubSub.subscribe(ElixirCourse.PubSub, "tasks")  # Must subscribe
  {:ok, socket}
end

# In GenServer
defp notify_subscribers(message) do
  Phoenix.PubSub.broadcast(ElixirCourse.PubSub, "tasks", message)  # Same topic
end
```

## 📊 Assessment Rubric and Guidance

### Technical Implementation (40 points)

#### Excellent (36-40 points)
**Criteria:**
- GenServer maintains state correctly with proper concurrent access handling
- Database schema well-designed with appropriate constraints and indexes
- Real-time features working smoothly with proper error handling
- Comprehensive error handling throughout all layers

**Code Review Checklist:**
```elixir
# GenServer state management
✅ Returns new state on all handle_call callbacks
✅ Proper error handling for database failures
✅ Cache refresh mechanism implemented
✅ Statistics and monitoring included

# Database design
✅ Proper foreign key constraints with cascade behavior
✅ Indexes on frequently queried columns
✅ Comprehensive changeset validations
✅ Business rules enforced at schema level
```

#### Good (30-35 points)
**Common Issues:**
- Minor state management issues in GenServer
- Some database optimization opportunities missed
- Real-time features mostly working with occasional issues
- Basic error handling present but not comprehensive

#### Satisfactory (24-29 points)
**Common Issues:**
- Basic GenServer functionality present but state issues
- Core database operations working but schema could be improved
- Some real-time features implemented but unreliable
- Minimal error handling

### Code Quality (30 points)

#### Excellent (27-30 points)
**Review Criteria:**
```elixir
# Clean code patterns
✅ Functions are small and focused
✅ Proper use of pattern matching and guards
✅ Consistent naming conventions
✅ Good separation of concerns between modules

# Documentation and comments
✅ Module documentation explains purpose
✅ Function specs for public APIs
✅ Complex business logic explained
✅ README with setup instructions
```

### Testing (20 points)

#### Excellent (18-20 points)
**Test Coverage Requirements:**
```elixir
# Unit tests
✅ All GenServer callbacks tested
✅ Changeset validations tested thoroughly
✅ Context functions tested with various inputs
✅ Error scenarios covered

# Integration tests
✅ End-to-end workflows tested
✅ Database constraints tested
✅ Real-time features tested
✅ API endpoints tested with various inputs
```

### Architecture (10 points)

#### Excellent (9-10 points)
**Architecture Review:**
```elixir
# Proper layering
✅ Controllers only handle HTTP concerns
✅ Contexts encapsulate business logic
✅ GenServer coordinates state and events
✅ Schemas contain data validation rules

# Good OTP patterns
✅ GenServer used appropriately for state management
✅ PubSub used for decoupled messaging
✅ Proper supervision tree structure
✅ Error handling follows let-it-crash philosophy
```

## 🎨 Final Project Showcase Guidelines

### Demonstration Structure (10 minutes per student)

#### 1. Architecture Overview (3 minutes)
**Student Should Explain:**
- "My system has four main layers: API, Business Logic, GenServer, and Database"
- "Data flows from HTTP request through controller to GenServer to database"
- "Events flow back through PubSub to channels for real-time updates"

**Questions to Ask:**
- "Why did you choose GenServer for task management?"
- "How does your caching strategy improve performance?"
- "What happens if your GenServer crashes?"

#### 2. Live API Demo (4 minutes)
**Demo Script:**
```bash
# Create a task
curl -X POST http://localhost:4000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"task": {"title": "Demo Task", "priority": "high"}}'

# List tasks with filters
curl "http://localhost:4000/api/tasks?status=todo&sort_by=priority"

# Update task status
curl -X PUT http://localhost:4000/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"task": {"status": "done"}}'
```

**WebSocket Demo:**
- Connect to task board channel
- Show real-time updates when tasks change
- Demonstrate presence tracking

#### 3. Code Deep Dive (3 minutes)
**Focus Areas:**
- Most interesting GenServer implementation detail
- Complex query or filtering logic
- Testing approach and coverage
- Error handling strategy

### Peer Review Questions

**For Reviewing Student:**
1. "What's the most elegant part of this implementation?"
2. "How would you handle [specific error scenario]?"
3. "What would you optimize first for production?"
4. "How does the caching strategy balance performance and consistency?"

**For Presenting Student:**
1. "Walk through the event flow for a task update"
2. "How does your GenServer handle concurrent task updates?"
3. "What was the most challenging part to implement?"
4. "How would you scale this for 10,000 concurrent users?"

## 📝 Final Checklist for Completion

### Core Competencies Verified

#### GenServer Mastery
```elixir
✅ Proper state management with immutable updates
✅ Concurrent access handled correctly
✅ Integration with supervision trees
✅ Message passing and event coordination
✅ Cache management and refresh strategies
✅ Statistics and monitoring capabilities
```

#### Ecto Proficiency
```elixir
✅ Schema design with proper relationships
✅ Comprehensive changeset validations
✅ Efficient queries with preloading
✅ Dynamic filtering and search implementation
✅ Database constraints and indexes
✅ Migration strategies and rollback handling
```

#### Phoenix Integration
```elixir
✅ RESTful API design and implementation
✅ Real-time features with PubSub/Channels
✅ Proper error handling and response formatting
✅ Request validation and parameter conversion
✅ WebSocket communication patterns
✅ Presence tracking implementation
```

#### Testing Excellence
```elixir
✅ Comprehensive test coverage (>80%)
✅ Unit tests for all business logic
✅ Integration tests for workflows
✅ Error scenario testing
✅ Proper test isolation and cleanup
✅ Performance and load testing considerations
```

### Production Readiness Indicators

```elixir
✅ Comprehensive error handling and logging
✅ Performance monitoring capabilities
✅ Database connection pooling configured
✅ Security considerations addressed
✅ Documentation and setup instructions
✅ Deployment configuration prepared
```

## 🔗 Additional Resources and Next Steps

### Immediate Follow-Up Resources
- [Phoenix Framework Guides](https://hexdocs.pm/phoenix/overview.html) - Official documentation
- [Ecto Query Guide](https://hexdocs.pm/ecto/Ecto.Query.html) - Advanced query patterns
- [GenServer Best Practices](https://hexdocs.pm/elixir/GenServer.html) - Official GenServer guide

### Advanced Topics for Continued Learning
- **Distributed Systems**: Multi-node GenServer coordination
- **Performance Optimization**: Database query optimization and caching strategies
- **Observability**: Telemetry, metrics, and monitoring in production
- **Security**: Authentication, authorization, and API security
- **Deployment**: Docker, releases, and production deployment strategies

### Project Extensions
1. **Task Dependencies**: Implement task blocking and dependency chains
2. **Time Tracking**: Add start/stop timers for task work sessions
3. **File Attachments**: Allow file uploads and associations with tasks
4. **Audit Logging**: Track all changes with user attribution
5. **Advanced Filtering**: Full-text search with PostgreSQL
6. **API Versioning**: Implement v1/v2 API versioning strategy
7. **Rate Limiting**: Implement API rate limiting and throttling
8. **Caching Layers**: Add Redis for distributed caching

**Remember**: The goal is not just to complete the project, but to deeply understand the patterns and principles that make Elixir applications robust, scalable, and maintainable. Each pattern learned here applies to larger, more complex systems in production! 🚀 

## 🔧 Capstone Project Compatibility with Existing Frontend

### Current Frontend File Analysis

The existing codebase contains working frontend files that expect specific APIs from the TaskManager GenServer. After analyzing the existing implementations, here are the compatibility requirements and recommendations:

### ✅ Compatible APIs (Already Match)

The capstone exercises are designed to implement these exact methods that the frontend expects:

```elixir
# TaskManager GenServer API
TaskManager.get_tasks(filters \\ %{})           # Returns {:ok, tasks}
TaskManager.create_task(attrs)                  # Returns {:ok, task} | {:error, changeset}
TaskManager.update_task(id, attrs)              # Returns {:ok, task} | {:error, reason}
TaskManager.delete_task(id)                     # Returns :ok | {:error, reason}
```

### ⚠️ Missing APIs That Frontend Expects

The capstone file is missing some methods that the existing frontend uses. Students will need to implement these:

```elixir
# In TaskManager GenServer - REQUIRED for frontend compatibility
def subscribe_to_updates do
  GenServer.cast(__MODULE__, {:subscribe, self()})
end

def get_cache_stats do
  GenServer.call(__MODULE__, :get_cache_stats)
end

def refresh_cache do
  GenServer.cast(__MODULE__, :refresh_cache)
end

def clear_cache do
  GenServer.call(__MODULE__, :clear_cache)
end
```

### 📋 Required GenServer Callbacks for Full Compatibility

Students must implement these handle_cast callbacks:

```elixir
def handle_cast({:subscribe, pid}, state) do
  # Monitor the subscribing process
  Process.monitor(pid)
  new_state = %{state | subscribers: [pid | state.subscribers]}
  {:noreply, new_state}
end

def handle_cast(:refresh_cache, state) do
  # Force immediate cache refresh
  {:noreply, state, {:continue, :refresh_cache}}
end

# Handle process monitoring
def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
  new_subscribers = List.delete(state.subscribers, pid)
  {:noreply, %{state | subscribers: new_subscribers}}
end
```

### 🎯 Recommended Teaching Approach

#### Option 1: Provide Missing Methods (Recommended)
Add the missing methods to the capstone answers section so students can see the complete implementation after attempting the exercises.

#### Option 2: Guided Discovery
Have students discover the missing methods by running the frontend and debugging the errors. This creates valuable learning moments about:
- Reading error messages
- Understanding API contracts
- Debugging integration issues

### 📝 Frontend Integration Testing

To verify compatibility, students should be able to:

1. **Start the Phoenix server**: `mix phx.server`
2. **Access the LiveView**: Navigate to `http://localhost:4000/live/task_board`
3. **Test real-time features**: 
   - Create tasks through the UI
   - Update task status via drag-and-drop
   - See real-time updates across browser tabs
4. **Test WebSocket channels**: Use browser developer tools to monitor WebSocket messages

### 🚨 Potential Compatibility Issues

#### Issue 1: String vs Integer IDs
The existing frontend sometimes passes string IDs, sometimes integers. The capstone should handle both:

```elixir
# In handle_call callbacks, normalize ID parameter
def handle_call({:update_task, id, attrs}, _from, state) when is_binary(id) do
  handle_call({:update_task, String.to_integer(id), attrs}, from, state)
end

def handle_call({:update_task, id, attrs}, _from, state) when is_integer(id) do
  # Main implementation here
end
```

#### Issue 2: PubSub Topic Names
Ensure PubSub topics match between GenServer and channels:
- TaskManager broadcasts to: `"tasks"`
- Channels subscribe to: `"tasks"`
- LiveView subscribes to: `"tasks"` and `"task_board"`

#### Issue 3: Message Format Consistency
The frontend expects specific message formats:

```elixir
# TaskManager should broadcast these exact formats
{:task_created, task}
{:task_updated, task}  
{:task_deleted, task_id}
```

### 🔄 Recommended Capstone Updates

To ensure full compatibility, add these to the answers section:

1. **Complete GenServer Implementation**: Include all missing client API methods
2. **Proper Error Handling**: Match the error formats expected by channels
3. **State Structure**: Ensure GenServer state includes subscribers list
4. **Process Monitoring**: Handle subscriber lifecycle properly

### 🎓 Teaching Value

This compatibility analysis provides excellent teaching opportunities:

1. **API Design**: How frontend requirements drive backend API design
2. **Integration Testing**: Importance of testing components together
3. **Error Handling**: How errors propagate through the system
4. **Real-world Development**: Dealing with existing codebases and constraints

The slight incompatibilities are actually valuable - they force students to think about integration and API contracts, which is crucial for professional development. 