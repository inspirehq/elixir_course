# Day 2 – Intro to Ecto
#
# This script can be run with:
#     mix run day_two/01_intro_to_ecto.exs
# or inside IEx with:
#     iex -r day_two/01_intro_to_ecto.exs
#
# Ecto is Elixir's database wrapper and query generator. It provides:
# - Database connections and connection pooling
# - Schema definitions for mapping database tables to Elixir structs
# - Changesets for data validation and casting
# - Query composition using a DSL
# - Migrations for schema evolution
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Understanding Ecto's role in the stack")

# Ecto sits between your application and the database, providing:
# 1. Repo - handles database connections
# 2. Schema - defines data structure and types
# 3. Changeset - validates and transforms data
# 4. Query - composes database queries
# 5. Migration - evolves database schema

defmodule DayTwo.ExampleRepo do
  @moduledoc """
  A mock repo to demonstrate Ecto concepts without a real database.
  In a real Phoenix app, this would be configured to connect to PostgreSQL,
  MySQL, or another supported database.
  """

  def insert(_changeset) do
    {:ok, %{id: 1, inserted_at: DateTime.utc_now()}}
  end

  def get(_schema, id) do
    %{id: id, name: "Sample User", email: "user@example.com"}
  end

  def all(_query) do
    [
      %{id: 1, name: "Alice", email: "alice@example.com"},
      %{id: 2, name: "Bob", email: "bob@example.com"}
    ]
  end
end

IO.puts("✓ Ecto Repo provides database interface")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Ecto types and their Elixir counterparts")

# Ecto maps database types to Elixir types:
types_mapping = %{
  # Database Type => Elixir Type
  ":integer" => "42",
  ":string" => "\"hello\"",
  ":boolean" => "true | false",
  ":date" => "~D[2023-12-25]",
  ":datetime" => "~N[2023-12-25 10:30:00]",
  ":utc_datetime" => "DateTime.utc_now()",
  ":decimal" => "Decimal.new(\"99.99\")",
  ":binary" => "<<1, 2, 3>>",
  ":map" => "%{key: \"value\"}",
  "{:array, :string}" => "[\"one\", \"two\"]"
}

IO.puts("Common Ecto type mappings:")
Enum.each(types_mapping, fn {db_type, elixir_example} ->
  IO.puts("  #{db_type} -> #{elixir_example}")
end)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Basic Ecto configuration pattern")

# In a real Phoenix app, your config would look like:
sample_config = """
# config/dev.exs
config :my_app, MyApp.Repo,
  database: "my_app_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
"""

IO.puts("Example Ecto configuration:")
IO.puts(sample_config)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Ecto's query building philosophy")

# Ecto queries are composable and compile-time checked
defmodule DayTwo.QueryDemo do
  @moduledoc """
  Demonstrates Ecto's composable query building.
  These are examples - they won't actually run without a real schema.
  """

  def show_query_composition do
    # This is pseudo-code showing how Ecto queries compose:
    query_description = """
    # Base query
    query = from u in User

    # Add conditions
    query = where(query, [u], u.active == true)

    # Add ordering
    query = order_by(query, [u], u.name)

    # Add limit
    query = limit(query, 10)

    # Execute
    users = Repo.all(query)
    """

    IO.puts("Ecto query composition pattern:")
    IO.puts(query_description)
  end
end

DayTwo.QueryDemo.show_query_composition()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Ecto's benefits in practice")

defmodule DayTwo.EctoBenefits do
  @moduledoc """
  Why teams choose Ecto over raw SQL or other ORMs.
  """

  def demonstrate_benefits do
    benefits = [
      "Type safety: Queries are validated at compile-time",
      "Composability: Build complex queries from simple parts",
      "Performance: Explicit queries prevent N+1 problems",
      "Testability: Easy to test with sandbox transactions",
      "Migrations: Version-controlled schema evolution",
      "Multi-database: Same code works with PostgreSQL, MySQL, SQLite"
    ]

    IO.puts("Key Ecto advantages:")
    Enum.with_index(benefits, 1)
    |> Enum.each(fn {benefit, index} ->
      IO.puts("  #{index}. #{benefit}")
    end)
  end

  def show_typical_workflow do
    workflow = """
    Typical Ecto development workflow:

    1. Generate migration: `mix ecto.gen.migration create_users`
    2. Define schema: Create User schema module
    3. Run migration: `mix ecto.migrate`
    4. Create changeset functions for validation
    5. Use in controllers/contexts with Repo functions
    6. Query data with Ecto.Query DSL
    """

    IO.puts(workflow)
  end
end

DayTwo.EctoBenefits.demonstrate_benefits()
DayTwo.EctoBenefits.show_typical_workflow()

defmodule DayTwo.EctoExercises do
  @moduledoc """
  Run the tests with: mix test day_two/01_intro_to_ecto.exs
  or in IEx:
  iex -r day_two/01_intro_to_ecto.exs
  DayTwo.EctoExercisesTest.test_build_blog_repo/0
  """

  @spec build_blog_repo() :: :ok
  def build_blog_repo do
    #   Create a mock `BlogRepo` module similar to `ExampleRepo` above, but with
    #   functions for `insert_post/1`, `get_post/1`, and `list_posts/0`. Make
    #   them return fake blog post data with fields: id, title, content, published_at.
    #   Return :ok after creating and demonstrating the repo.
    :ok  # TODO: Implement blog repo with post functions
  end
end

# Mock BlogRepo for testing
defmodule BlogRepo do
  def insert_post(attrs) do
    post = %{
      id: :rand.uniform(1000),
      title: attrs[:title] || "Untitled",
      content: attrs[:content] || "",
      published_at: DateTime.utc_now()
    }
    {:ok, post}
  end

  def get_post(id) do
    %{
      id: id,
      title: "Sample Blog Post",
      content: "This is sample content...",
      published_at: ~N[2023-12-01 10:00:00]
    }
  end

  def list_posts do
    [
      %{id: 1, title: "First Post", published_at: ~N[2023-12-01 10:00:00]},
      %{id: 2, title: "Second Post", published_at: ~N[2023-12-02 11:00:00]}
    ]
  end
end

ExUnit.start()

defmodule DayTwo.EctoExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.EctoExercises, as: EX


  test "build_blog_repo/0 creates and demonstrates blog repository" do
    assert EX.build_blog_repo() == :ok
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      defmodule BlogRepo do
        def insert_post(attrs) do
          post = %{
            id: :rand.uniform(1000),
            title: attrs.title || "Untitled",
            content: attrs.content || "",
            published_at: DateTime.utc_now()
          }
          {:ok, post}
        end

        def get_post(id) do
          %{
            id: id,
            title: "Sample Blog Post",
            content: "This is sample content...",
            published_at: ~N[2023-12-01 10:00:00]
          }
        end

        def list_posts do
          [
            %{id: 1, title: "First Post", content: "...", published_at: ~N[2023-12-01 10:00:00]},
            %{id: 2, title: "Second Post", content: "...", published_at: ~N[2023-12-02 11:00:00]}
          ]
        end
      end

      def build_blog_repo do
        # In a real scenario, the module definition itself is the implementation.
        {:ok, post} = BlogRepo.insert_post(%{title: "New Post", content: "..."})
        IO.inspect(post, label: "Inserted Post")

        retrieved_post = BlogRepo.get_post(post.id)
        IO.inspect(retrieved_post, label: "Retrieved Post")

        posts = BlogRepo.list_posts()
        IO.inspect(posts, label: "All Posts")

        :ok
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. build_blog_repo/0
#{Macro.to_string(DayTwo.Answers.answer_one())}
#  This shows a mock `BlogRepo` module. In a real application, this module would `use Ecto.Repo`
#  and you would call functions like `BlogRepo.insert()` instead of defining `insert_post/1`.
#  This exercise simulates the "Repo" pattern of having a dedicated module for database interactions.
""")
