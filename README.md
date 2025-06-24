# Elixir Course - Comprehensive Learning Program

A complete 3-day Elixir course covering fundamentals to advanced Phoenix LiveView applications with real-time features.

## 📚 Course Overview

This repository contains a comprehensive Elixir learning program designed to take you from beginner to intermediate level in just 3 days:

- **Day One**: Elixir fundamentals, pattern matching, GenServers, and OTP basics
- **Day Two**: Ecto, Phoenix PubSub, Channels, Presence, and testing strategies  
- **Day Three**: Capstone project - Real-time Task Management System with LiveView

## 🚀 Getting Started

### Prerequisites

Before starting the course, ensure you have the following installed on your system:

- **Git** (for cloning the repository)
- **Text Editor/IDE** (VS Code with ElixirLS extension recommended)
- **Terminal/Command Prompt** access

### 1. Install Elixir and Erlang

#### macOS (using Homebrew)
```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Elixir (includes Erlang)
brew install elixir
```

#### Windows
1. Download and install [Erlang/OTP](https://www.erlang.org/downloads)
2. Download and install [Elixir](https://elixir-lang.org/install.html#windows)

Or use [Chocolatey](https://chocolatey.org/):
```powershell
# Install Chocolatey first, then:
choco install elixir
```

#### Linux (Ubuntu/Debian)
```bash
# Add Erlang Solutions repository
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb

# Update and install
sudo apt update
sudo apt install esl-erlang elixir
```

#### Verify Installation
```bash
elixir --version
# Should show something like:
# Erlang/OTP 26 [erts-14.0] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit:ns]
# Elixir 1.15.4 (compiled with Erlang/OTP 26)
```

### 2. Install PostgreSQL (Required for Day Two & Three)

#### macOS
```bash
# Using Homebrew
brew install postgresql@15
brew services start postgresql@15

# Create a database user (optional, for development)
createuser -s postgres
```

#### Windows
1. Download and install [PostgreSQL](https://www.postgresql.org/download/windows/)
2. Remember your postgres user password during installation

#### Linux
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set postgres user password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
```

### 3. Clone and Setup the Project

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

### 4. Verify Everything Works

```bash
# Run tests to ensure everything is working
mix test

# Start the Phoenix server
mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000) in your browser. You should see the Task Management Demo application!

## 📖 Course Structure

### Day One: Elixir Fundamentals
**Location**: `day_one/` directory

Start with these files in order:
1. `01_immutability_and_rebinding.exs` - Core Elixir concepts
2. `02_pattern_matching_function_heads_guards.exs` - Pattern matching mastery
3. `03_with_clause.exs` - Error handling with `with`
4. `04_tuple_return_patterns.exs` - Common Elixir patterns
5. `05_enum_library.exs` - Working with collections
6. `06_pipe_operator.exs` - Functional programming style
7. `07_genserver_primitives.exs` - State management basics
8. `08_intro_genservers.exs` - Building your first GenServer
9. `09_counter_genserver.exs` - Practical GenServer example
10. `10_supervision_basics.exs` - Fault tolerance with supervisors
11. `11_queue_worker_coordination.exs` - Advanced OTP patterns
12. `12_testing_debug_tips.exs` - Development best practices

**Teacher Resource**: `day_one/day_one_teachers_manual.md`

### Day Two: Phoenix & Advanced Topics
**Location**: `day_two/` directory

Continue with these advanced topics:
1. `01_intro_to_ecto.exs` - Database interactions
2. `02_schemas_and_migrations.exs` - Data modeling
3. `03_changesets_and_validations.exs` - Data validation
4. `04_querying.exs` - Database queries with Ecto
5. `05_associations_and_constraints.exs` - Relational data
6. `06_transactions_and_multi.exs` - Complex database operations
7. `07_behaviour_refresher.exs` - Custom behaviours
8. `08_phoenix_pubsub.exs` - Real-time messaging
9. `09_channels.exs` - WebSocket communication
10. `10_presence.exs` - User presence tracking
11. `11_streams_backend.exs` - Streaming data
12. `12_intro_to_exunit.exs` - Testing fundamentals
13. `13_property_testing.exs` - Property-based testing
14. `14_testing_third_party_services.exs` - Integration testing

**Teacher Resource**: `day_two/day_two_teachers_manual.md`

### Day Three: Capstone Project
**Location**: `day_three/` directory + Live Application

Build a complete real-time task management system:
- **Architecture Overview**: `day_three/capstone.md`
- **Implementation Guide**: `day_three/capstone.ex`
- **Teaching Notes**: `day_three/teacher_guide.md`

**Live Demo**: The complete working application is available at [`http://localhost:4000`](http://localhost:4000)

## 🎯 Learning Objectives

By the end of this course, you will be able to:

### Day One
- ✅ Understand Elixir's functional programming paradigm
- ✅ Use pattern matching effectively in function definitions
- ✅ Handle errors gracefully with `with` statements
- ✅ Write and test GenServers for state management
- ✅ Design fault-tolerant systems with supervisors

### Day Two  
- ✅ Model data with Ecto schemas and migrations
- ✅ Validate data with changesets
- ✅ Write complex database queries
- ✅ Implement real-time features with PubSub and Channels
- ✅ Test your applications comprehensively

### Day Three
- ✅ Build a complete Phoenix LiveView application
- ✅ Implement real-time user interfaces
- ✅ Integrate WebSocket channels with LiveView
- ✅ Deploy and debug production applications

## 🛠️ Development Workflow

### Running Individual Exercises

For Day One and Day Two exercises:
```bash
# Run any .exs file directly
elixir day_one/01_immutability_and_rebinding.exs
elixir day_two/04_querying.exs
```

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
```

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

## 🎮 Interactive Features

The capstone project includes several interactive demonstrations:

### 1. Task Management Interface
- Create, edit, and delete tasks
- Real-time status updates
- User assignment and filtering
- Priority management

### 2. User Presence Tracking
- See who's currently online
- Real-time join/leave notifications
- User activity monitoring

### 3. WebSocket Channel Demo
- Send real-time messages
- Simulate channel events
- Multi-tab synchronization testing

**Pro Tip**: Open [`http://localhost:4000`](http://localhost:4000) in multiple browser tabs to see real-time features in action!

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

### Community
- [Elixir Forum](https://elixirforum.com/)
- [Elixir Slack](https://elixir-slackin.herokuapp.com/)
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

**2. Database connection errors**
```bash
# Check PostgreSQL is running
brew services start postgresql@15  # macOS
sudo systemctl start postgresql    # Linux

# Verify database exists
mix ecto.create
```

**3. Dependencies not compiling**
```bash
# Clean and reinstall
mix deps.clean --all
mix deps.get
mix deps.compile
```

**4. Assets not loading**
```bash
cd assets
npm install
cd ..
mix assets.deploy
```

### Getting Help

If you encounter issues:

1. **Check the error message carefully** - Elixir has excellent error messages
2. **Review the lesson materials** - Most concepts are explained in detail
3. **Run tests** - `mix test` to verify your environment
4. **Check Phoenix logs** - The server output shows detailed information
5. **Ask for help** - Use the community resources listed above

## 🎉 Congratulations!

You're now ready to start your Elixir journey! Begin with `day_one/01_immutability_and_rebinding.exs` and work through the course materials at your own pace.

Remember: Elixir is designed to be enjoyable to write and maintain. Don't worry if some concepts feel unfamiliar at first - the functional programming paradigm becomes natural with practice.

Happy coding! 🚀

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
