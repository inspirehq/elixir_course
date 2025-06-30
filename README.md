# Elixir Course - Crash Course

### Prerequisites

Before starting the course, ensure you have the following installed on your system:

- **Git** (for cloning the repository)
- **Text Editor/IDE** (VS Code with ElixirLS extension recommended)
- **Terminal/Command Prompt** access
- **Erlang/Elixir installed**
- **Postgres installed**

### 1. Clone and Setup the Project

```bash
# Clone the repository
git clone https://github.com/inspirehq/elixir_course.git
cd elixir_course

# Install Hex package manager (if not already installed)
mix local.hex --force

# Install Phoenix installer (for future projects)
mix archive.install hex phx_new --force

# Install project dependencies
mix deps.get

# Setup the database (creates database and runs migrations)
mix ecto.setup

# Install Node.js dependencies for assets
cd assets && npm install && cd ..

# Compile the project
mix compile
```


### 2. Verify Everything Works

```bash
# Run tests to ensure everything is working
mix test

# Start the Phoenix server
mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000) in your browser. You should see the Task Management Demo application!

### Working with the Phoenix Application

```bash
# Start the development server
mix phx.server

# Run in interactive mode
iex -S mix phx.server

# Run tests
mix test

# Run tests with coverage
mix test --cover

# Format code
mix format

# Check for issues
mix credo

# Checkout branch for exercises
git checkout -b "exercises"
```

## 🔬 Interactive Development with IEx

**IEx (Interactive Elixir)** is your most powerful tool for learning and developing in Elixir. It's like a supercharged REPL that lets you experiment, debug, and interact with your running application in real-time.

### Starting IEx

```bash
# Basic IEx shell
iex

# IEx with project loaded (most common for development)
iex -S mix

# IEx with Phoenix server running (great for live debugging)
iex -S mix phx.server

# IEx with specific script loaded
iex -r day_one/01_immutability_and_rebinding.exs
```

### Essential IEx Patterns

#### **1. Getting Help and Information**
```elixir
# Get help on any function
iex> h(Enum.map)
iex> h(String.split/2)

# Search for functions
iex> h String.
# Press Tab to see all String functions

# Get information about data types
iex> i("hello")
iex> i([1, 2, 3])
iex> i(%{name: "Alex"})
```

#### **2. Exploring Your Application**
```elixir
# See all loaded modules
iex> :code.all_loaded() |> length()

# Explore your application modules
iex> ElixirCourse.
# Press Tab to see available modules

# Check if a process is running
iex> Process.registered()

# Look at ETS tables
iex> :ets.all()
```

#### **3. Working with Phoenix in IEx**
```elixir
# Access your Repo directly
iex> ElixirCourse.Repo.all(ElixirCourse.Accounts.User)

# Test your contexts
iex> ElixirCourse.Accounts.list_users()

# Create test data
iex> attrs = %{email: "test@example.com", name: "Test User"}
iex> ElixirCourse.Accounts.create_user(attrs)

# Inspect database queries
iex> import Ecto.Query
iex> ElixirCourse.Repo.all(from u in ElixirCourse.Accounts.User, select: u.email)
```

#### **4. Course Exercise Patterns**
```elixir
# Load and test Day One exercises
iex> c("day_one/01_immutability_and_rebinding.exs")

# Test GenServer examples
iex> {:ok, pid} = GenServer.start_link(MyServer, :ok)
iex> GenServer.call(pid, :get_state)
iex> :sys.get_state(pid)  # Peek inside

# Debug pipe operations step by step
iex> [1, 2, 3, 4]
...> |> IO.inspect(label: "Initial")
...> |> Enum.filter(&(&1 > 2))
...> |> IO.inspect(label: "After filter")
...> |> Enum.map(&(&1 * 2))
```

#### **5. Debugging and Introspection**
```elixir
# See all running processes
iex> Process.list() |> length()

# Find processes by name
iex> Process.whereis(:my_server)

# Monitor system resources
iex> :observer.start()  # Opens GUI (see Observer setup guide)

# Check memory usage
iex> :erlang.memory()

# See message queue of a process
iex> Process.info(pid, :message_queue_len)
```

#### **6. File and Code Operations**
```elixir
# Compile and reload modules
iex> c("lib/my_module.ex")
iex> r(MyModule)  # Reload module

# Execute external files
iex> Code.eval_file("day_one/05_enum_library.exs")

# Check if module exists
iex> Code.ensure_loaded?(MyModule)
```

### IEx Productivity Tips

#### **Keyboard Shortcuts**
- `Tab` - Auto-completion (your best friend!)
- `Ctrl+C` - Exit IEx (press twice)
- `Ctrl+G` - User switch command (advanced)
- `↑/↓` - Command history
- `Ctrl+A/E` - Beginning/End of line

#### **Built-in Helpers**
```elixir
# History and evaluation
iex> v()     # Get last result
iex> v(3)    # Get result from line 3
iex> h()     # Command history

# Process and system info
iex> i(self())     # Info about current process
iex> pid(0,250,0)  # Create PID from numbers
iex> flush()       # Show messages in current process mailbox

# Compilation and modules
iex> c("file.ex", ".")  # Compile to current directory
iex> ls()               # List files in current directory
iex> pwd()              # Show current directory
```

#### **Configuration**
Create `~/.iex.exs` for persistent IEx configuration:
```elixir
# Add commonly used aliases
alias ElixirCourse.Repo
alias ElixirCourse.Accounts
alias ElixirCourse.Tasks

# Helper functions
defmodule H do
  def clear, do: IO.puts("\e[H\e[2J")  # Clear screen
  def time(fun), do: :timer.tc(fun) |> elem(0) |> Kernel./(1000)
end

# Auto-import useful modules
import Ecto.Query, warn: false
```

### Course-Specific IEx Usage

#### **Day One - GenServers**
```elixir
# Test your GenServer implementations
iex> {:ok, pid} = MyCounter.start_link(0)
iex> MyCounter.increment(pid)
iex> MyCounter.get_count(pid)
iex> :sys.get_state(pid)  # White-box inspection
```

#### **Day Two - Ecto**
```elixir
# Query building and testing
iex> import Ecto.Query
iex> query = from t in Task, where: t.status == "completed"
iex> Repo.all(query)

# Changeset testing
iex> changeset = Task.changeset(%Task{}, %{title: "Test"})
iex> changeset.valid?
iex> changeset.errors
```

### When to Use IEx

- **Learning**: Test language features and library functions
- **Development**: Prototype code before writing tests
- **Debugging**: Inspect application state in real-time
- **Database**: Query and modify data directly
- **Experimentation**: Try out new libraries and patterns
- **Production**: Connect to running applications for debugging (advanced)

**💡 Pro Tip**: Keep an IEx session running while coding. It's faster than recompiling for small experiments!

### Database Operations

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback migrations
mix ecto.rollback

# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Seed database with sample data
mix run priv/repo/seeds.exs
```

## 📚 Additional Resources

### Documentation
- [Elixir Official Docs](https://elixir-lang.org/docs.html)
- [Phoenix Framework](https://phoenixframework.org/)
- [Ecto Documentation](https://hexdocs.pm/ecto/)
- [LiveView Guide](https://hexdocs.pm/phoenix_live_view/)

### Learning Resources
- [Elixir School](https://elixirschool.com/)
- [Exercism Elixir Track](https://exercism.io/tracks/elixir)
- [Pragmatic Programmer - Programming Elixir](https://pragprog.com/titles/elixir16/)
- [Pragmatic Studio](https://pragmaticstudio.com/elixir)
- [Testing LiveView](https://www.testingliveview.com/)

### Community
- [Elixir Forum](https://elixirforum.com/)
- [Elixir Slack](https://elixir-lang.slack.com/join/shared_invite/zt-2apqof3wh-QVSNtcdERC8YkY99leoWyQ#/shared-invite/email)
- [Reddit r/elixir](https://www.reddit.com/r/elixir/)

## 🐛 Troubleshooting

### Common Issues

**1. Port 4000 already in use**
```bash
# Kill process using port 4000
lsof -ti:4000 | xargs kill -9
# Or use a different port
mix phx.server --port 4001
```

**2. Dependencies not compiling**
```bash
# Clean and reinstall
mix deps.clean --all
mix deps.get
mix deps.compile
```

**3. Assets not loading**
```bash
cd assets
npm install
cd ..
mix assets.deploy
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
