# Script for populating the database for the Elixir Course Demo
# Run with: mix run priv/repo/seeds.exs

alias ElixirCourse.{Accounts, Tasks}
alias ElixirCourse.Tasks.TaskManager

# Clear existing data (be careful in production!)
IO.puts("🧹 Clearing existing data...")

# Clear TaskManager cache
TaskManager.clear_cache()

# Clear database tables (in reverse dependency order)
ElixirCourse.Repo.delete_all(ElixirCourse.Tasks.Task)
ElixirCourse.Repo.delete_all(ElixirCourse.Accounts.User)

IO.puts("✅ Existing data cleared")

# Create Users
IO.puts("👥 Creating sample users...")

users_data = [
  %{
    name: "Alice Johnson",
    email: "alice.johnson@company.com"
  },
  %{
    name: "Bob Smith",
    email: "bob.smith@company.com"
  },
  %{
    name: "Carol Davis",
    email: "carol.davis@company.com"
  },
  %{
    name: "David Wilson",
    email: "david.wilson@company.com"
  },
  %{
    name: "Eva Martinez",
    email: "eva.martinez@company.com"
  }
]

users =
  Enum.map(users_data, fn user_attrs ->
    case Accounts.create_user(user_attrs) do
      {:ok, user} ->
        IO.puts("  ✓ Created user: #{user.name}")
        user
      {:error, changeset} ->
        IO.puts("  ✗ Failed to create user #{user_attrs.name}: #{inspect(changeset.errors)}")
        nil
    end
  end)
  |> Enum.filter(& &1)

IO.puts("✅ Created #{length(users)} users")

# Create Tasks
IO.puts("📋 Creating sample tasks...")

# Get some users for assignment
[alice, bob, carol, david, eva] = users

task_templates = [
  # High Priority/Urgent Tasks
  %{
    title: "Fix critical production bug",
    description: "Database connection timeout causing 500 errors on user dashboard",
    priority: "urgent",
    status: "in_progress",
    creator_id: alice.id,
    assignee_id: bob.id
  },
  %{
    title: "Security vulnerability patch",
    description: "Apply latest security patches to prevent SQL injection attacks",
    priority: "urgent",
    status: "todo",
    creator_id: bob.id,
    assignee_id: alice.id
  },
  %{
    title: "Server maintenance window",
    description: "Scheduled maintenance for database optimization and backup",
    priority: "high",
    status: "review",
    creator_id: carol.id,
    assignee_id: david.id
  },

  # Medium Priority Tasks
  %{
    title: "Implement user authentication",
    description: "Add OAuth2 integration for Google and GitHub login",
    priority: "medium",
    status: "in_progress",
    creator_id: david.id,
    assignee_id: eva.id
  },
  %{
    title: "Design new landing page",
    description: "Create modern, responsive landing page with better conversion rates",
    priority: "medium",
    status: "todo",
    creator_id: eva.id,
    assignee_id: carol.id
  },
  %{
    title: "API documentation update",
    description: "Update OpenAPI specs and generate new documentation",
    priority: "medium",
    status: "review",
    creator_id: alice.id,
    assignee_id: bob.id
  },
  %{
    title: "Mobile app bug fixes",
    description: "Fix iOS keyboard covering input fields and Android back button issues",
    priority: "medium",
    status: "done",
    creator_id: bob.id,
    assignee_id: david.id
  },

  # Low Priority Tasks
  %{
    title: "Refactor legacy code",
    description: "Clean up old modules and improve code maintainability",
    priority: "low",
    status: "todo",
    creator_id: carol.id,
    assignee_id: alice.id
  },
  %{
    title: "Add dark mode theme",
    description: "Implement dark mode toggle for better user experience",
    priority: "low",
    status: "todo",
    creator_id: david.id
  },
  %{
    title: "Performance monitoring setup",
    description: "Set up APM tools and performance dashboards",
    priority: "low",
    status: "in_progress",
    creator_id: eva.id,
    assignee_id: carol.id
  },
  %{
    title: "Internationalization support",
    description: "Add i18n support for Spanish and French languages",
    priority: "low",
    status: "review",
    creator_id: alice.id
  },
  %{
    title: "Unit test coverage improvement",
    description: "Increase test coverage from 75% to 90%",
    priority: "low",
    status: "done",
    creator_id: bob.id,
    assignee_id: eva.id
  },

  # Additional variety tasks
  %{
    title: "Database migration script",
    description: "Migrate user preferences to new schema format",
    priority: "high",
    status: "todo",
    creator_id: carol.id,
    assignee_id: david.id
  },
  %{
    title: "Customer feedback integration",
    description: "Add in-app feedback widget and notification system",
    priority: "medium",
    status: "todo",
    creator_id: david.id,
    assignee_id: alice.id
  },
  %{
    title: "Load testing infrastructure",
    description: "Set up automated load testing for peak traffic scenarios",
    priority: "high",
    status: "in_progress",
    creator_id: eva.id,
    assignee_id: bob.id
  }
]

tasks =
  Enum.map(task_templates, fn task_attrs ->
    case TaskManager.create_task(task_attrs) do
      {:ok, task} ->
        IO.puts("  ✓ Created task: #{task.title} (#{task.priority}/#{task.status})")
        task
      {:error, changeset} ->
        IO.puts("  ✗ Failed to create task #{task_attrs.title}: #{inspect(changeset.errors)}")
        nil
    end
  end)
  |> Enum.filter(& &1)

IO.puts("✅ Created #{length(tasks)} tasks")

# Display summary statistics
IO.puts("\n📊 Database Summary:")
IO.puts("Users: #{length(users)}")
IO.puts("Tasks: #{length(tasks)}")

task_stats = Enum.group_by(tasks, & &1.status)
IO.puts("\nTask Status Distribution:")
for {status, task_list} <- task_stats do
  IO.puts("  #{String.capitalize(String.replace(status, "_", " "))}: #{length(task_list)}")
end

priority_stats = Enum.group_by(tasks, & &1.priority)
IO.puts("\nTask Priority Distribution:")
for {priority, task_list} <- priority_stats do
  IO.puts("  #{String.capitalize(priority)}: #{length(task_list)}")
end

# Test TaskManager cache
IO.puts("\n🔧 Testing TaskManager integration...")
{:ok, cached_tasks} = TaskManager.get_tasks()
IO.puts("TaskManager cache contains #{length(cached_tasks)} tasks")

# Test filtering
{:ok, urgent_tasks} = TaskManager.get_tasks(%{priority: "urgent"})
IO.puts("Found #{length(urgent_tasks)} urgent tasks")

{:ok, todo_tasks} = TaskManager.get_tasks(%{status: "todo"})
IO.puts("Found #{length(todo_tasks)} todo tasks")

# Display cache stats
stats = TaskManager.get_cache_stats()
IO.puts("\nTaskManager Cache Stats:")
IO.puts("  Cached tasks: #{stats.cached_tasks}")
IO.puts("  Cache hits: #{stats.cache_hits}")
IO.puts("  Cache misses: #{stats.cache_misses}")

IO.puts("\n🎉 Demo database seeded successfully!")
IO.puts("Visit http://localhost:4000/tasks to see the LiveView demo")
IO.puts("Visit http://localhost:4000/demo to see the static demo")
IO.puts("API endpoints available at /api/users and /api/tasks")
