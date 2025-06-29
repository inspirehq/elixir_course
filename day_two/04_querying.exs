# Day 2 – Querying with Ecto
#
# This script can be run with:
#     mix run day_two/04_querying.exs
# or inside IEx with:
#     iex -r day_two/04_querying.exs
#
# Ecto.Query provides a composable, type-safe DSL for building database queries.
# This module demonstrates the various ways to query data using Ecto's Query API.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic query syntax and from expressions")

defmodule DayTwo.QueryBasics do
  @moduledoc """
  Demonstrates basic Ecto query patterns.
  These examples show the structure without requiring a real database.
  """

  def show_basic_query_forms do
    quote do
      # Keyword syntax (more readable):
      from u in User,
        where: u.active == true,
        select: u

      # Pipe syntax (more composable):
      User
      |> where([u], u.active == true)
      |> select([u], u)

      # Macro syntax (most flexible):
      query = from(u in User)
      query = where(query, [u], u.active == true)
      query = select(query, [u], u)
    end
  end

  def demonstrate_query_execution do
    # Simulate query execution
    query_examples = [
      "Repo.all(query) - returns list of structs",
      "Repo.one(query) - returns single struct or nil",
      "Repo.one!(query) - returns struct or raises",
      "Repo.get(User, 1) - get by primary key",
      "Repo.get_by(User, email: \"test@example.com\") - get by field"
    ]

    IO.puts("Query execution functions:")
    Enum.each(query_examples, fn example ->
      IO.puts("  • #{example}")
    end)
  end
end

IO.puts("Basic query forms:")
IO.puts(Macro.to_string(DayTwo.QueryBasics.show_basic_query_forms()))
DayTwo.QueryBasics.demonstrate_query_execution()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Where clauses and operators")

defmodule DayTwo.WhereExamples do
  @moduledoc """
  Examples of different where clause patterns and operators.
  """

  def show_comparison_operators do
    operators = [
      "u.age > 18 - greater than",
      "u.age >= 21 - greater than or equal",
      "u.name == \"Alice\" - equality",
      "u.email != nil - not equal (not null)",
      "u.score < 100 - less than",
      "u.created_at <= ^yesterday - less than or equal with pinned variable"
    ]

    IO.puts("Comparison operators:")
    Enum.each(operators, fn op ->
      IO.puts("  • #{op}")
    end)
  end

  def show_logical_operators do
    quote do
      # AND conditions:
      from u in User,
        where: u.active == true and u.age > 18

      # OR conditions:
      from u in User,
        where: u.role == "admin" or u.role == "moderator"

      # NOT conditions:
      from u in User,
        where: not is_nil(u.email)

      # IN conditions:
      roles = ["admin", "moderator"]
      from u in User,
        where: u.role in ^roles

      # LIKE conditions:
      from u in User,
        where: like(u.name, "A%")

      # ILIKE (case-insensitive):
      from u in User,
        where: ilike(u.email, "%@gmail.com")
    end
  end

  def show_date_queries do
    quote do
      # Date comparisons:
      today = Date.utc_today()
      from p in Post,
        where: fragment("DATE(?)", p.inserted_at) == ^today

      # Date ranges:
      last_week = Date.add(Date.utc_today(), -7)
      from p in Post,
        where: p.inserted_at >= ^last_week

      # Using datetime functions:
      from u in User,
        where: fragment("EXTRACT(year FROM ?)", u.created_at) == 2023
    end
  end
end

DayTwo.WhereExamples.show_comparison_operators()
IO.puts("\nLogical operators:")
IO.puts(Macro.to_string(DayTwo.WhereExamples.show_logical_operators()))
IO.puts("\nDate-based queries:")
IO.puts(Macro.to_string(DayTwo.WhereExamples.show_date_queries()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Select, order, limit, and offset")

defmodule DayTwo.QueryClauses do
  @moduledoc """
  Demonstrates different query clauses for shaping results.
  """

  def show_select_variations do
    quote do
      # Select entire struct:
      from u in User, select: u

      # Select specific fields:
      from u in User, select: {u.id, u.name, u.email}

      # Select into map:
      from u in User, select: %{id: u.id, name: u.name}

      # Select with computed fields:
      from u in User,
        select: %{
          id: u.id,
          full_name: fragment("? || ' ' || ?", u.first_name, u.last_name),
          age_group: fragment("CASE WHEN ? < 30 THEN 'young' ELSE 'older' END", u.age)
        }

      # Select count:
      from u in User, select: count(u.id)

      # Select with aggregations:
      from p in Post,
        group_by: p.user_id,
        select: {p.user_id, count(p.id), max(p.inserted_at)}
    end
  end

  def show_ordering_examples do
    quote do
      # Simple ordering:
      from u in User, order_by: u.name

      # Descending order:
      from u in User, order_by: [desc: u.created_at]

      # Multiple order criteria:
      from u in User, order_by: [u.last_name, u.first_name]

      # Mixed ascending/descending:
      from p in Post, order_by: [desc: p.published_at, asc: p.title]

      # Dynamic ordering:
      field = :name
      direction = :asc
      from u in User, order_by: [{^direction, ^field}]
    end
  end

  def show_pagination_examples do
    quote do
      # Basic limit:
      from u in User, limit: 10

      # Limit with offset (pagination):
      page = 2
      per_page = 10
      offset = (page - 1) * per_page

      from u in User,
        limit: ^per_page,
        offset: ^offset

      # Often combined with ordering:
      from u in User,
        order_by: u.name,
        limit: 20,
        offset: 40
    end
  end
end

IO.puts("Select clause variations:")
IO.puts(Macro.to_string(DayTwo.QueryClauses.show_select_variations()))
IO.puts("\nOrdering and pagination:")
IO.puts(Macro.to_string(DayTwo.QueryClauses.show_ordering_examples()))
IO.puts(Macro.to_string(DayTwo.QueryClauses.show_pagination_examples()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Joins and associations")

defmodule DayTwo.JoinExamples do
  @moduledoc """
  Examples of different types of joins in Ecto queries.
  """

  def show_basic_joins do
    quote do
      # Inner join (only records with matches):
      from u in User,
        join: p in Post, on: p.user_id == u.id,
        select: {u.name, p.title}

      # Left join (all users, even without posts):
      from u in User,
        left_join: p in Post, on: p.user_id == u.id,
        select: {u.name, count(p.id)}

      # Right join (less common):
      from u in User,
        right_join: p in Post, on: p.user_id == u.id

      # Full outer join:
      from u in User,
        full_join: p in Post, on: p.user_id == u.id
    end
  end

  def show_association_joins do
    quote do
      # Join through associations (cleaner):
      from u in User,
        join: p in assoc(u, :posts),
        select: {u.name, p.title}

      # Preload associations (N+1 solution):
      from u in User,
        preload: [:posts, :comments]

      # Conditional preloads:
      from u in User,
        preload: [posts: ^(from p in Post, where: p.published == true)]

      # Nested preloads:
      from u in User,
        preload: [posts: [:comments, :tags]]
    end
  end

  def show_complex_join_example do
    quote do
      # Complex example: Users with their published posts and comment counts
      from u in User,
        left_join: p in Post, on: p.user_id == u.id and p.published == true,
        left_join: c in Comment, on: c.post_id == p.id,
        group_by: [u.id, u.name],
        select: %{
          user_id: u.id,
          user_name: u.name,
          published_posts: count(p.id, :distinct),
          total_comments: count(c.id)
        }
    end
  end
end

IO.puts("Basic join types:")
IO.puts(Macro.to_string(DayTwo.JoinExamples.show_basic_joins()))
IO.puts("\nAssociation-based joins:")
IO.puts(Macro.to_string(DayTwo.JoinExamples.show_association_joins()))
IO.puts("\nComplex join example:")
IO.puts(Macro.to_string(DayTwo.JoinExamples.show_complex_join_example()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Building a blog query system")

defmodule DayTwo.BlogQueries do
  @moduledoc """
  Real-world example showing a comprehensive blog query system.
  """

  def show_blog_query_functions do
    quote do
      defmodule Blog.Queries do
        import Ecto.Query

        # List published posts with author info
        def list_published_posts do
          from p in Post,
            where: not is_nil(p.published_at),
            where: p.published_at <= ^DateTime.utc_now(),
            join: u in assoc(p, :user),
            order_by: [desc: p.published_at],
            select: %{
              id: p.id,
              title: p.title,
              excerpt: fragment("LEFT(?, 200)", p.content),
              published_at: p.published_at,
              author_name: u.name,
              comment_count: fragment("(SELECT COUNT(*) FROM comments WHERE post_id = ?)", p.id)
            }
        end

        # Search posts by title and content
        def search_posts(query_string) do
          search_term = "%#{query_string}%"

          from p in Post,
            where: ilike(p.title, ^search_term) or ilike(p.content, ^search_term),
            where: not is_nil(p.published_at),
            order_by: [desc: p.published_at]
        end

        # Posts by tag with pagination
        def posts_by_tag(tag, page \\ 1, per_page \\ 10) do
          offset = (page - 1) * per_page

          from p in Post,
            where: ^tag in p.tags,
            where: not is_nil(p.published_at),
            order_by: [desc: p.published_at],
            limit: ^per_page,
            offset: ^offset,
            preload: [:user]
        end

        # Popular posts (by comment count)
        def popular_posts(limit \\ 5) do
          from p in Post,
            left_join: c in assoc(p, :comments),
            group_by: p.id,
            order_by: [desc: count(c.id)],
            limit: ^limit,
            select: %{post: p, comment_count: count(c.id)},
            preload: [:user]
        end

        # User statistics
        def user_stats(user_id) do
          from u in User,
            where: u.id == ^user_id,
            left_join: p in assoc(u, :posts),
            left_join: c in assoc(u, :comments),
            group_by: u.id,
            select: %{
              user: u,
              post_count: count(p.id, :distinct),
              comment_count: count(c.id, :distinct),
              first_post: min(p.inserted_at),
              latest_post: max(p.inserted_at)
            }
        end
      end
    end
  end

  def demonstrate_dynamic_queries do
    quote do
      # Building dynamic queries based on filters
      def filter_posts(filters) do
        Post
        |> apply_title_filter(filters[:title])
        |> apply_author_filter(filters[:author_id])
        |> apply_date_range_filter(filters[:date_from], filters[:date_to])
        |> apply_tag_filter(filters[:tags])
        |> order_by([p], desc: p.published_at)
      end

      defp apply_title_filter(query, nil), do: query
      defp apply_title_filter(query, title) do
        where(query, [p], ilike(p.title, ^"%#{title}%"))
      end

      defp apply_author_filter(query, nil), do: query
      defp apply_author_filter(query, author_id) do
        where(query, [p], p.user_id == ^author_id)
      end

      defp apply_date_range_filter(query, nil, nil), do: query
      defp apply_date_range_filter(query, date_from, date_to) do
        query
        |> maybe_where_date_from(date_from)
        |> maybe_where_date_to(date_to)
      end

      defp apply_tag_filter(query, nil), do: query
      defp apply_tag_filter(query, tags) when is_list(tags) do
        where(query, [p], fragment("? && ?", p.tags, ^tags))
      end
    end
  end
end

IO.puts("Blog query system:")
IO.puts(Macro.to_string(DayTwo.BlogQueries.show_blog_query_functions()))
IO.puts("\nDynamic query filters:")
IO.puts(Macro.to_string(DayTwo.BlogQueries.demonstrate_dynamic_queries()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Exercises")

defmodule DayTwo.QueryExercises do
  @moduledoc """
  Run the tests with: mix test day_two/04_querying.exs
  or in IEx:
  iex -r day_two/04_querying.exs
  DayTwo.QueryExercisesTest.test_get_active_users_query/0
  DayTwo.QueryExercisesTest.test_get_posts_by_tag_query/0
  DayTwo.QueryExercisesTest.test_search_products_query/0
  """

  @doc """
  Write a query that finds all active users.

  - The query should target the "users" table.
  - Filter for users where `active` is `true`.
  - Order the results by `name`.
  - Select the `name` and `email` into a map.

  Return the Ecto.Query struct.
  """
  @spec get_active_users_query() :: Ecto.Query.t()
  def get_active_users_query do
    # TODO: Build a query to select active users.
    nil
  end

  @doc """
  Write a query that finds all posts associated with a given tag name.

  - The query should join from "posts" through "posts_tags" to "tags".
  - Filter for tags where `name` matches the `tag_name` variable.
  - Order the posts by their `published_at` date in descending order.
  - Select the post's `id`, `title`, and `published_at` date into a map.

  Use the pin `^` operator for the `tag_name`.
  Return the Ecto.Query struct.
  """
  @spec get_posts_by_tag_query(String.t()) :: Ecto.Query.t()
  def get_posts_by_tag_query(_tag_name) do
    # TODO: Build a query to find posts by tag.
    nil
  end

  @doc """
  Build a function that constructs a dynamic query to search for products.

  The function should accept a list of `filters` and apply them to a base query
  on the "products" table. Support the following filters:
  - `{:name_like, value}`: case-insensitive search for `name`.
  - `{:min_price, value}`: price is greater than or equal to `value`.
  - `{:max_price, value}`: price is less than or equal to `value`.
  - `{:is_available, value}`: `is_available` matches the boolean `value`.

  Use `Enum.reduce` to build the query from the `filters` list.
  Return the final Ecto.Query struct.
  """
  @spec search_products_query(list()) :: Ecto.Query.t()
  def search_products_query(_filters) do
    # TODO: Build a dynamic query from a list of filters.
    nil
  end
end

ExUnit.start()

defmodule DayTwo.QueryExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.QueryExercises, as: EX

  # Helper to convert a query to a comparable string for testing
  defp query_to_string(query) do
    query
    |> Macro.to_string()
    |> String.replace(~r/s+/, " ")
  end

  test "get_active_users_query/0 returns a query for active users" do
    query = EX.get_active_users_query()
    str_query = query_to_string(query)

    assert is_struct(query, Ecto.Query)
    assert str_query =~ "from u in \"users\""
    assert str_query =~ "where: u.active == true"
    assert str_query =~ "order_by: u.name"
    assert str_query =~ "select: %{name: u.name, email: u.email}"
  end

  test "get_posts_by_tag_query/1 returns a query that joins to tags" do
    query = EX.get_posts_by_tag_query("elixir")
    str_query = query_to_string(query)

    assert is_struct(query, Ecto.Query)
    assert str_query =~ "join: t in \"tags\""
    assert str_query =~ "where: t.name == ^\"elixir\""
    assert str_query =~ "order_by: [desc: p.published_at]"
  end

  test "search_products_query/1 builds a dynamic query from filters" do
    filters = [
      {:name_like, "cool"},
      {:min_price, 10},
      {:is_available, true}
    ]

    query = EX.search_products_query(filters)
    str_query = query_to_string(query)

    assert is_struct(query, Ecto.Query)
    assert str_query =~ "from p in \"products\""
    assert str_query =~ "ilike(p.name"
    assert str_query =~ "p.price >= ^10"
    assert str_query =~ "p.is_available == ^true"
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      # In a real module, you would pass the Repo module in.
      # def get_active_users(repo) do
      #   query = from u in User, where: u.active == true, select: {u.name, u.email}
      #   repo.all(query)
      # end

      # For the exercise, we return the query itself.
      def get_active_users_query do
        from u in "users",
          where: u.active == true,
          order_by: u.name,
          select: %{name: u.name, email: u.email}
      end
    end
  end

  def answer_two do
    quote do
      def get_posts_by_tag_query(tag_name) do
        from p in "posts",
          join: pt in "posts_tags", on: p.id == pt.post_id,
          join: t in "tags", on: pt.tag_id == t.id,
          where: t.name == ^tag_name,
          order_by: [desc: p.published_at],
          select: %{id: p.id, title: p.title, published_at: p.published_at}
      end
    end
  end

  def answer_three do
    quote do
      def search_products_query(filters) do
        # Start with a base query
        base_query = from p in "products"

        # Dynamically build the where clause
        filters
        |> Enum.reduce(base_query, fn
          {:name_like, value}, query ->
            where(query, [p], ilike(p.name, ^"%%#{value}%%"))
          {:min_price, value}, query when is_number(value) and value > 0 ->
            where(query, [p], p.price >= ^value)
          {:max_price, value}, query when is_number(value) and value > 0 ->
            where(query, [p], p.price <= ^value)
          {:is_available, value}, query when is_boolean(value) ->
            where(query, [p], p.is_available == ^value)
          # Ignore unknown filters
          _, query ->
            query
        end)
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. get_active_users_query/0
#{Macro.to_string(DayTwo.Answers.answer_one())}
#  This is a fundamental Ecto query. It selects specific fields into a map,
#  which is a best practice for performance, as it avoids over-fetching data
#  from the database.

# 2. get_posts_by_tag_query/1
#{Macro.to_string(DayTwo.Answers.answer_two())}
#  This query demonstrates how to use `join` to traverse relationships. The pin
#  operator `^` is crucial here to safely inject the `tag_name` variable into
#  the query, preventing SQL injection.

# 3. search_products_query/1
#{Macro.to_string(DayTwo.Answers.answer_three())}
#  This is a powerful and common pattern for building dynamic queries. It starts
#  with a base query and conditionally adds `where` clauses by reducing over a
#  list of filters. This keeps the code clean and avoids complex `if` or `case`
#  statements.
""")
