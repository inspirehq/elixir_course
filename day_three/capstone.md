# Day Three Capstone Project: Real-Time Task Management System

## 🚀 Getting Started: Create Your Phoenix Project

### Step 1: Generate a New Phoenix Application

Create a completely new Phoenix project that you'll build from scratch:

```bash
# Create new Phoenix project with database support
mix phx.new task_manager --database postgres

# Navigate to your project directory
cd task_manager

# Install dependencies
mix deps.get

# Create your database
mix ecto.create
```

### Step 2: Configure Your Database

Update your database configuration in `config/dev.exs`:

```elixir
config :task_manager, TaskManager.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "task_manager_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### Step 3: Verify Your Setup

Test that everything is working:

```bash
# Start your Phoenix server
mix phx.server

# Visit http://localhost:4000 - you should see the Phoenix welcome page
```

### Step 4: Add Required Dependencies

Update your `mix.exs` file to include these dependencies (if they don't already):

```elixir
defp deps do
  [
    {:phoenix, "~> 1.7.0"},
    {:phoenix_ecto, "~> 4.4"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, ">= 0.0.0"},
    {:phoenix_html, "~> 3.3"},
    {:phoenix_live_reload, "~> 1.2", only: :dev},
    {:phoenix_live_view, "~> 0.18.16"},
    {:floki, ">= 0.30.0", only: :test},
    {:phoenix_live_dashboard, "~> 0.7.2"},
    {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
    {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
    {:swoosh, "~> 1.3"},
    {:finch, "~> 0.13"},
    {:telemetry_metrics, "~> 0.6"},
    {:telemetry_poller, "~> 1.0"},
    {:gettext, "~> 0.20"},
    {:jason, "~> 1.2"},
    {:plug_cowboy, "~> 2.5"},
    {:phoenix_pubsub, "~> 2.1"},
    {:phoenix_presence, "~> 1.1"}
  ]
end
```

Then install the new dependencies:

```bash
mix deps.get
```

### Step 5: Enable Phoenix PubSub and Presence

Your Phoenix application already has PubSub configured, but you'll need to set up Presence. Add this to your `lib/task_manager/application.ex` supervision tree:

```elixir
children = [
  # Start the Ecto repository
  TaskManager.Repo,
  # Start the Telemetry supervisor
  TaskManagerWeb.Telemetry,
  # Start the PubSub system
  {Phoenix.PubSub, name: TaskManager.PubSub},
  # Start Presence
  TaskManagerWeb.Presence,
  # Start the Endpoint (http/https)
  TaskManagerWeb.Endpoint
  # Start a worker by calling: TaskManager.Worker.start_link(arg)
  # {TaskManager.Worker, arg}
]
```

---

## 🎯 Project Overview

Now that you have your Phoenix project set up, you'll build a **Real-Time Task Management System** that includes GenServer-based task coordination, real-time updates via Phoenix PubSub/Channels, database persistence with Ecto, and comprehensive testing.

### System Requirements

Your task management system must implement:

1. **Task Management**: Create, update, complete, and delete tasks via GenServer coordination
2. **Real-Time Backend**: Live notifications when tasks change using Phoenix PubSub
3. **User Management**: Store and manage users with proper validations
4. **Database Persistence**: Store all data with proper validations and constraints
5. **RESTful API**: HTTP endpoints for task and user management
6. **WebSocket Channels**: Real-time communication via Phoenix Channels
7. **Comprehensive Testing**: Unit and integration tests with proper coverage

---

## 🏗️ Architecture Overview

Your system consists of these core components:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   API Layer     │    │  Task Manager    │    │   Database      │
│   (Controllers) │───▶│  (GenServer)     │───▶│   (Ecto)        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        
         ▼                        ▼                        
┌─────────────────┐    ┌──────────────────┐                
│  WebSocket      │    │  Context Modules │                
│  Channels       │    │  (Accounts/Tasks)│                
└─────────────────┘    └──────────────────┘                
         │                        │                        
         ▼                        ▼                        
┌─────────────────┐    ┌──────────────────┐                
│   Phoenix       │    │  Presence        │                
│   PubSub        │    │  Tracking        │                
└─────────────────┘    └──────────────────┘                
```

---

## 📋 Implementation Checklist

### Phase 1: Core Database Layer

#### ✅ Schema Design
- [x] Define User schema with proper field types and validations
- [x] Define Task schema with associations and comprehensive validations
- [x] Implement proper timestamps (inserted_at, updated_at)
- [x] Set up foreign key relationships between users and tasks
- [x] Add JSON encoding support for API responses

#### ✅ Migrations
- [x] Create users table migration with unique email constraint
- [x] Create tasks table migration with indexes for performance
- [x] Add foreign key constraints with proper cascade behavior
- [x] Create indexes for query optimization (status, priority, assignee, creator)
- [x] Implement proper rollback functionality

#### ✅ Changesets and Validations
- [x] Implement comprehensive user changeset with email validation
- [x] Create task changeset with business rules and status transitions
- [x] Validate required fields and field lengths
- [x] Implement unique constraints and foreign key constraints
- [x] Add custom validations (due date, professional emails, completed_at)

#### ✅ Context Modules
- [x] Implement Accounts context for user management
- [x] Implement Tasks context for task management
- [x] Add efficient queries with proper association preloading
- [x] Implement filtering and search functionality
- [x] Add statistics and reporting functions

### Phase 2: GenServer State Management (Day One Concepts)

#### ✅ TaskManager GenServer
- [x] Implement GenServer with proper init/1 and state management
- [x] Handle synchronous calls for task operations (CRUD)
- [x] Maintain in-memory cache with tasks and metadata
- [x] Use pattern matching in function heads for different operations
- [x] Apply guards for input validation
- [x] Implement proper error handling with tagged tuples
- [x] Use pipe operator for data transformations
- [x] Apply Enum functions for task filtering and sorting

#### ✅ State Management Features
- [x] Cache refresh mechanism with periodic updates
- [x] Statistics tracking (memory usage, cache size)
- [x] Cache clearing functionality for testing
- [x] Proper error handling for database failures
- [x] Integration with Phoenix PubSub for real-time updates

### Phase 3: Real-Time Features (Day Two Phoenix Concepts)

#### ✅ Phoenix PubSub Integration
- [x] Set up PubSub for task change notifications
- [x] Implement event-driven architecture with task events
- [x] Use proper topic naming conventions ("tasks")
- [x] Broadcast task updates to relevant subscribers
- [x] Handle PubSub errors gracefully

#### ✅ WebSocket Channels
- [x] Implement TaskBoard channel for real-time updates
- [x] Handle task creation, updates, and deletion via WebSocket
- [x] Manage channel state and user tracking
- [x] Implement bidirectional messaging between client and server
- [x] Format and handle changeset errors properly

#### ✅ Presence Tracking
- [x] Track users viewing the task board
- [x] Display online users with join timestamps
- [x] Handle presence synchronization
- [x] Integration with channel join events

### Phase 4: API Layer

#### ✅ RESTful Controllers
- [x] Implement TaskController with full CRUD operations
- [x] Add comprehensive filtering (status, priority, assignee, search)
- [x] Implement safe string-to-atom conversion for filters
- [x] Proper HTTP status codes and error responses
- [x] JSON API responses with consistent formatting
- [x] Input validation and error handling

#### ✅ Request/Response Handling
- [x] Convert string parameters to appropriate types
- [x] Handle missing resources with 404 responses
- [x] Validate request parameters safely
- [x] Format changeset errors for API consumption
- [x] Implement proper content negotiation

### Phase 5: Comprehensive Testing (Day Two Testing Concepts)

#### ✅ Unit Testing with ExUnit
- [x] Test all GenServer callbacks and state management
- [x] Test changeset validations thoroughly
- [x] Use describe blocks for organized test structure
- [x] Test both success and failure cases
- [x] Comprehensive task filtering and sorting tests

#### ✅ Integration Testing
- [x] Test end-to-end task workflows
- [x] Test GenServer cache management
- [x] Use Ecto.Adapters.SQL.Sandbox for database isolation
- [x] Test error scenarios and edge cases
- [x] Verify proper CRUD operations integration

#### ✅ Test Coverage Areas
- [x] Task creation with various attributes
- [x] Task filtering by status, priority, assignee
- [x] Task sorting by different criteria
- [x] Error handling for invalid data
- [x] GenServer state consistency
- [x] Cache management functionality

---

## 🔧 Technical Implementation Details

### Database Schema Design

The system uses a normalized database schema with proper relationships:

```sql
-- Users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  name VARCHAR NOT NULL,
  avatar_url VARCHAR,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Tasks table  
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  title VARCHAR NOT NULL,
  description TEXT,
  status VARCHAR DEFAULT 'todo',
  priority VARCHAR DEFAULT 'medium',
  due_date TIMESTAMP,
  completed_at TIMESTAMP,
  assignee_id INTEGER REFERENCES users(id),
  creator_id INTEGER REFERENCES users(id),
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### GenServer State Architecture

The TaskManager GenServer maintains efficient in-memory state:

```elixir
%{
  tasks: %{},           # Map of task_id => task struct
  last_refresh: nil,    # Timestamp of last cache refresh
  stats: %{}           # Runtime statistics
}
```

### Real-Time Event Flow

1. **API Request** → TaskController receives HTTP request
2. **GenServer Call** → Controller calls TaskManager GenServer
3. **Database Operation** → GenServer performs Ecto operation
4. **Cache Update** → GenServer updates in-memory cache
5. **PubSub Broadcast** → GenServer broadcasts event
6. **Channel Push** → WebSocket channels receive and forward updates

### Front End Parts

Once you have completed your backend implementation, you can test it using the provided frontend components. The frontend demonstrates all the real-time features and provides a complete user interface for your task management system.

#### 🎨 Provided Frontend Files

The following files are **already implemented** and ready to use with your backend:

**Router Configuration** (`lib/elixir_course_web/router.ex`):
```elixir
# LiveView route for the task board interface
live "/live/task_board", TaskBoardLive

# WebSocket endpoint for real-time communication
socket "/socket", ElixirCourseWeb.UserSocket,
  websocket: true,
  longpoll: false
```

**LiveView Interface** (`lib/elixir_course_web/live/task_board_live.ex`)
**LiveView Template** (`lib/elixir_course_web/live/task_board_live.html.heex`)
**WebSocket Channel** (`lib/elixir_course_web/channels/task_board_channel.ex`)

#### 🚀 Testing Your Backend Implementation

##### Step 1: Start Your Phoenix Server
```bash
# Ensure your database is set up
mix ecto.create
mix ecto.migrate

# Optionally add some seed data (use /priv/repo/seeds.exs)
mix run priv/repo/seeds.exs

# Start the Phoenix server
mix phx.server
```

##### Step 2: Access the LiveView Interface
Navigate to: **http://localhost:4000/live/task_board**

You should see a complete task management interface with:
- Task creation and management forms
- Real-time task updates across browser tabs
- User presence tracking
- Live statistics and activity logging

##### Step 3: Test Real-Time Features

**Multi-Tab Testing**:
1. Open multiple browser tabs to the same URL
2. Create tasks in one tab - see them appear instantly in others
3. Update task status - watch real-time synchronization
4. Notice user presence indicators showing active users

**WebSocket Channel Testing**:
1. Use the "Channel Demo" section in the interface
2. Send WebSocket messages directly to your backend
3. Monitor message flow in browser developer tools
4. Test error handling with invalid data

**API Testing**:
```bash
# Test your REST API endpoints
curl -X GET "http://localhost:4000/api/tasks"
curl -X POST "http://localhost:4000/api/tasks" \
  -H "Content-Type: application/json" \
  -d '{"task": {"title": "API Test Task", "priority": "high"}}'
```

#### 🎯 Success Criteria

Your backend implementation is complete when:
- ✅ LiveView loads without errors at `http://localhost:4000/live/task_board`
- ✅ Tasks can be created, updated, and deleted via UI
- ✅ Real-time updates work across multiple browser tabs
- ✅ Filtering and search produce correct results
- ✅ WebSocket channels connect and communicate properly
- ✅ API endpoints return proper JSON responses
- ✅ Error handling displays user-friendly messages
- ✅ User presence tracking functions correctly

---

## 🎉 Next Steps

Other features / topics to explore:

1. **Deploy to Production**: Learn about releases and deployment strategies
2. **Add Features**: Implement file uploads, email notifications, or advanced search
3. **Scale the System**: Explore distributed Elixir with multiple nodes
4. **Monitor and Observe**: Add telemetry, metrics, and logging
5. **Optimize Performance**: Database query optimization and caching strategies
