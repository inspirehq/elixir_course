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
