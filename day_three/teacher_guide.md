# Day Three Capstone Teacher's Guide

## 🎯 Overview

This teacher's guide provides comprehensive support for facilitating the Real-Time Task Management System capstone project. The project integrates all concepts from Day One (GenServer, OTP, Elixir fundamentals) and Day Two (Ecto, real-time features, testing), culminating in a production-ready backend system with API and real-time capabilities.

## 📚 Pre-Class Preparation

### Environment Setup
- Ensure all students have Phoenix 1.7+ installed
- Verify database connections (PostgreSQL recommended)
- Test WebSocket functionality in classroom network
- Prepare backup VMs for students with setup issues

### Repository Preparation
```bash
# Create starter repository with basic Phoenix app
mix phx.new capstone_task_manager --database postgres
cd capstone_task_manager
mix deps.get
mix ecto.create
```

## 🏗️ Project Architecture Deep Dive

### System Design Philosophy

The capstone demonstrates a **layered, event-driven architecture** that showcases:

1. **State Management**: GenServers handle in-memory caching and coordination
2. **Persistence Layer**: Ecto provides reliable data storage with ACID properties
3. **Real-Time Communication**: Phoenix PubSub/Channels enable live updates
4. **API Layer**: RESTful controllers provide HTTP interface
5. **Context Pattern**: Business logic encapsulation following Phoenix conventions

### Teaching Architecture Patterns

#### The "Layered Architecture" Explanation
```
🏗️ API Layer (HTTP Interface)
  ├── TaskController - RESTful endpoints
  ├── UserController - User management
  └── WebSocket Channels - Real-time communication

🧠 Application Layer (Business Logic)
  ├── TaskManager GenServer - State coordination
  ├── Context Modules (Accounts, Tasks)
  └── Phoenix PubSub - Event broadcasting

💾 Data Layer (Persistence)
  ├── Ecto Schemas (User, Task)
  ├── Database Migrations
  └── Repo Module - Database interface
```

## 📋 Phase-by-Phase Teaching Guide

### Phase 1: Database Foundation (2-3 hours)

#### Learning Objectives
- Design normalized database schemas with proper relationships
- Implement comprehensive validations with Ecto changesets
- Create efficient queries with associations and preloading
- Handle database migrations and constraints

#### Teaching Strategy: "Data-Driven Development"

Start with the database schema as the foundation:

```elixir
# Demo: Build schema incrementally
defmodule User do
  use Ecto.Schema
  
  # Start simple
  schema "users" do
    field :email, :string
    field :name, :string
    timestamps()
  end
  
  # Add relationships
  has_many :assigned_tasks, Task, foreign_key: :assignee_id
  has_many :created_tasks, Task, foreign_key: :creator_id
end
```

#### Teaching Talking Points

**Schema Design:**
- "Think of schemas as your data contracts - they define what your application knows about"
- "Associations create relationships, but indexes make them fast"
- "Constraints in the database are your last line of defense against bad data"

**Common Student Mistakes:**
1. **Missing indexes**: Forgetting foreign key indexes
2. **N+1 queries**: Not using preload appropriately
3. **Validation vs. constraints**: Confusion between changeset validations and DB constraints

#### Interactive Exercise: Schema Visualization
```bash
# Show students the actual database structure
mix ecto.gen.migration --dry-run create_tasks
# Then show the indexes and foreign keys in detail
```

### Phase 2: Context Modules and Business Logic (2-3 hours)

#### Learning Objectives
- Implement Phoenix context pattern for business logic encapsulation
- Write efficient queries with dynamic filtering
- Handle complex data transformations
- Apply proper error handling patterns

#### Teaching Strategy: "Contexts as Boundaries"

**Context Design Session (45 minutes):**
1. Explain context as "public API" for your domain
2. Discuss when to create new contexts vs. extending existing ones
3. Show how contexts hide implementation details

```elixir
# Demo: Context evolution
defmodule Tasks do
  # Start with basic CRUD
  def get_task(id), do: Repo.get(Task, id)
  def create_task(attrs), do: %Task{} |> Task.changeset(attrs) |> Repo.insert()
  
  # Add business logic
  def list_tasks_with_filters(filters) do
    Task
    |> apply_filters(filters)
    |> preload([:assignee, :creator])
    |> Repo.all()
  end
  
  # Add advanced features
  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, &apply_filter/2)
  end
end
```

#### Query Optimization Teaching

**Dynamic Query Building:**
```elixir
# Show the problem and solution
defp apply_filter({:status, status}, query) when status != "" do
  where(query, [t], t.status == ^status)
end

defp apply_filter({:search, term}, query) when term != "" do
  term = "%#{term}%"
  where(query, [t], ilike(t.title, ^term) or ilike(t.description, ^term))
end

defp apply_filter(_, query), do: query
```

### Phase 3: GenServer State Management (3-4 hours)

#### Learning Objectives
- Implement GenServer for stateful coordination
- Handle concurrent access and race conditions
- Integrate with Phoenix PubSub for event-driven architecture
- Manage cache consistency and refresh strategies

#### Teaching Strategy: "GenServer as Coordinator"

**GenServer Architecture:**
```
Client Requests ──┐
                  ▼
            ┌─────────────┐
            │ TaskManager │
            │  GenServer  │ ──── Cache Management
            └─────────────┘
                  │
                  ▼
            Database Updates ──── PubSub Events
```

#### Live Coding Session: GenServer Implementation

```elixir
# Start with basic structure
defmodule TaskManager do
  use GenServer
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    state = %{
      tasks: %{},           # In-memory cache
      last_refresh: nil,    # Cache metadata
      stats: %{}           # Runtime statistics
    }
    {:ok, state}
  end
end
```

#### State Management Deep Dive

**Teaching Moment: "State is Sacred"**
```elixir
def handle_call({:create_task, attrs}, _from, state) do
  case Tasks.create_task(attrs) do
    {:ok, task} ->
      # Update cache
      new_state = put_in(state.tasks[task.id], task)
      # Notify subscribers
      notify_subscribers({:task_created, task})
      {:reply, {:ok, task}, new_state}
    
    error ->
      {:reply, error, state}  # Keep original state on error
  end
end
```

### Phase 4: Real-Time Features with PubSub (2-3 hours)

#### Learning Objectives
- Implement Phoenix PubSub for decoupled messaging
- Build WebSocket channels for real-time communication
- Handle presence tracking and user state
- Manage message broadcasting and subscription patterns

#### Teaching Strategy: "Events Drive Everything"

**PubSub Pattern:**
```
GenServer ─── broadcast ───┐
                           ▼
                    Phoenix.PubSub
                           │
                           ├── Channel A
                           ├── Channel B
                           └── Other Subscribers
```

#### Channel Implementation

```elixir
# Demo: Channel message flow
defmodule TaskBoardChannel do
  use Phoenix.Channel
  
  def join("task_board:" <> _board_id, _params, socket) do
    # Subscribe to events
    Phoenix.PubSub.subscribe(MyApp.PubSub, "tasks")
    {:ok, socket}
  end
  
  # Handle incoming messages
  def handle_in("create_task", params, socket) do
    case TaskManager.create_task(params) do
      {:ok, task} ->
        {:reply, {:ok, %{task: task}}, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: format_errors(changeset)}}, socket}
    end
  end
  
  # Handle PubSub broadcasts
  def handle_info({:task_created, task}, socket) do
    push(socket, "task_created", %{task: task})
    {:noreply, socket}
  end
end
```

### Phase 5: API Design and Controllers (2-3 hours)

#### Learning Objectives
- Design RESTful APIs following HTTP conventions
- Implement proper error handling and status codes
- Handle request validation and parameter conversion
- Format responses consistently

#### Teaching Strategy: "API as Contract"

**RESTful Design Principles:**
```
GET    /api/tasks           # List tasks with filtering
POST   /api/tasks           # Create new task
GET    /api/tasks/:id       # Get specific task
PUT    /api/tasks/:id       # Update task
DELETE /api/tasks/:id       # Delete task
```

#### Controller Implementation

```elixir
# Demo: Progressive controller building
defmodule TaskController do
  use MyAppWeb, :controller
  
  def index(conn, params) do
    filters = convert_filters_to_atoms(params)
    
    case TaskManager.get_tasks(filters) do
      {:ok, tasks} ->
        json(conn, %{data: tasks})
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to fetch tasks"})
    end
  end
end
```

### Phase 6: Testing Strategy (3-4 hours)

#### Learning Objectives
- Write unit tests for GenServers and business logic
- Test real-time features and PubSub integration
- Handle test data isolation and cleanup
- Implement comprehensive error scenario testing

#### Teaching Strategy: "Test the Behavior, Not the Implementation"

**Testing Pyramid for Backend Systems:**
```
           🔺 Integration Tests (Some)
          ──────────────────
         🔺🔺 GenServer Tests (Many)
        ──────────────────────────
       🔺🔺🔺 Unit Tests (Most)
      ──────────────────────────────
```

#### GenServer Testing Patterns

```elixir
# Test the public API, not internal state
test "creates task and updates cache" do
  # Setup
  attrs = %{title: "Test Task", priority: "high"}
  
  # Action
  {:ok, task} = TaskManager.create_task(attrs)
  
  # Verification
  assert task.title == "Test Task"
  
  # Verify it's in cache
  {:ok, cached_tasks} = TaskManager.get_tasks()
  assert Enum.any?(cached_tasks, &(&1.id == task.id))
end
```

## 🎨 Student Support Strategies

### Debugging Common Issues

#### 1. GenServer State Confusion
**Symptom:** "My GenServer isn't updating the cache"
**Diagnosis:** Not returning new state or cache refresh issues
**Solution:** 
```elixir
# Show the state flow clearly
def handle_call({:create_task, attrs}, _from, state) do
  case Tasks.create_task(attrs) do
    {:ok, task} ->
      new_state = put_in(state.tasks[task.id], task)  # Update cache
      {:reply, {:ok, task}, new_state}                # Return new state
    error ->
      {:reply, error, state}                          # Keep old state
  end
end
```

#### 2. Database Connection Issues
**Symptom:** "Tests are failing with database errors"
**Solution:** Ensure proper test setup:
```elixir
# In test files
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  :ok
end
```

#### 3. PubSub Message Issues
**Symptom:** "Real-time updates aren't working"
**Solution:** Check subscription and broadcasting:
```elixir
# In channel
def join("task_board:" <> _board_id, _params, socket) do
  Phoenix.PubSub.subscribe(MyApp.PubSub, "tasks")  # Must subscribe
  {:ok, socket}
end

# In GenServer
defp notify_subscribers(message) do
  Phoenix.PubSub.broadcast(MyApp.PubSub, "tasks", message)  # Same topic
end
```

### Progressive Difficulty Scaffolding

#### For Struggling Students:
1. **Provide schema templates** with basic structure
2. **Pair programming** sessions for GenServer concepts
3. **Simplified filtering** focusing on core functionality
4. **Extra support** for debugging and testing

#### For Advanced Students:
1. **Performance optimization** challenges
2. **Advanced filtering** with complex queries
3. **Error recovery** scenarios
4. **Mentoring** other students

## 📊 Assessment Rubric

### Technical Implementation (40 points)

#### Excellent (36-40 points)
- All GenServers working with proper state management
- Database schema well-designed with efficient queries
- Real-time features working smoothly
- Comprehensive error handling throughout

#### Good (30-35 points)
- GenServer mostly working with minor state issues
- Database operations functional with some optimization needed
- Real-time features mostly working
- Basic error handling present

#### Satisfactory (24-29 points)
- Basic GenServer functionality present
- Core database operations working
- Some real-time features implemented
- Minimal error handling

### Code Quality (30 points)

#### Excellent (27-30 points)
- Clean, readable, well-documented code
- Proper use of Elixir idioms and Phoenix patterns
- Consistent formatting and naming
- Good separation of concerns

#### Good (21-26 points)
- Generally clean code with minor issues
- Most patterns used correctly
- Some style inconsistencies
- Adequate documentation

### Testing (20 points)

#### Excellent (18-20 points)
- Comprehensive test coverage (>80%)
- Good mix of unit and integration tests
- Proper test isolation and cleanup
- Clear, maintainable test code

#### Good (14-17 points)
- Good test coverage (60-79%)
- Basic test structure in place
- Some areas undertested
- Generally clear tests

### Architecture (10 points)

#### Excellent (9-10 points)
- Proper layered architecture
- Good use of contexts and boundaries
- Efficient data flow
- Appropriate OTP patterns

## 🚀 Advanced Topics for Discussion

### Performance Optimization

#### Database Optimization
- Query optimization with proper indexes
- Association preloading strategies
- Connection pooling configuration
- Query analysis with EXPLAIN

#### GenServer Optimization
- State size management and memory usage
- Message queue monitoring
- Cache refresh strategies
- Process monitoring with :observer

### Production Considerations

#### Deployment Architecture
```
[Load Balancer] → [Phoenix Nodes] → [Database Cluster]
       ↓              ↓                    ↓
[API Gateway]   [GenServer Pool]    [Read Replicas]
```

#### Monitoring and Observability
- Telemetry for key metrics
- Error tracking and alerting
- Performance monitoring
- Database query analysis

## 🎯 Final Project Showcase

### Demonstration Guidelines

Each student should prepare a 10-minute demonstration covering:

1. **Architecture Overview** (3 minutes)
   - System design and component interaction
   - Data flow through the system

2. **Live API Demo** (4 minutes)
   - CRUD operations via HTTP endpoints
   - Real-time updates via WebSocket
   - Error handling examples

3. **Code Deep Dive** (3 minutes)
   - GenServer implementation highlights
   - Interesting query or filtering logic
   - Testing approach and coverage

### Evaluation Questions

**For Students:**
1. "How does your GenServer handle concurrent access to the cache?"
2. "Explain your database indexing strategy."
3. "How would you scale this system for 1000+ concurrent users?"
4. "Walk through the event flow for a task update."

**For Peer Review:**
1. "What did you learn from this implementation?"
2. "How would you handle [specific error scenario]?"
3. "What would you optimize first for production?"

## 📝 Final Assessment Points

### Core Competencies Demonstrated

Students should successfully show:

1. **GenServer Mastery**
   - Proper state management and concurrent access
   - Integration with supervision trees
   - Message passing and event coordination

2. **Ecto Proficiency**
   - Schema design with proper relationships
   - Efficient queries with preloading
   - Dynamic filtering and search implementation

3. **Phoenix Integration**
   - RESTful API design and implementation
   - Real-time features with PubSub/Channels
   - Proper error handling and response formatting

4. **Testing Excellence**
   - Comprehensive test coverage
   - Proper test isolation and cleanup
   - Both unit and integration testing

5. **Production Readiness**
   - Error handling and logging
   - Performance considerations
   - Security best practices

### Final Project Status

**Successfully Completed Implementation Includes:**
- ✅ 20+ passing tests with 0 failures
- ✅ Full CRUD operations for tasks and users
- ✅ Real-time updates via PubSub and WebSockets
- ✅ Comprehensive filtering and sorting
- ✅ Production-ready error handling
- ✅ Clean, maintainable architecture

## 🔗 Additional Resources

### Documentation
- [Phoenix Framework Guides](https://hexdocs.pm/phoenix/overview.html)
- [Ecto Query Documentation](https://hexdocs.pm/ecto/Ecto.Query.html)
- [GenServer Best Practices](https://hexdocs.pm/elixir/GenServer.html)

### Extended Learning
- "Programming Phoenix 1.4" by Chris McCord
- "Designing Elixir Systems with OTP" by James Edward Gray II
- "Testing Elixir" by Andrea Leopardi and Jeffrey Matthias

### Community Resources
- ElixirForum.com for technical discussions
- Elixir Slack for real-time help
- Local Elixir meetups and conferences

**Remember: The goal is not just to complete the project, but to deeply understand the patterns and principles that make Elixir applications robust, scalable, and maintainable!** 🚀 