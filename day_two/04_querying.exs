# Day 2 – Querying with Ecto
#
# Run with `mix run elixir_course/day_two/04_querying.exs`
# or inside IEx with:
#     iex -S mix
#     c "elixir_course/day_two/04_querying.exs"
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
    """
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
    """
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
IO.puts(DayTwo.QueryBasics.show_basic_query_forms())
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
    """
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
    """
  end

  def show_date_queries do
    """
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
    """
  end
end

DayTwo.WhereExamples.show_comparison_operators()
IO.puts("\nLogical operators:")
IO.puts(DayTwo.WhereExamples.show_logical_operators())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Select, order, limit, and offset")

defmodule DayTwo.QueryClauses do
  @moduledoc """
  Demonstrates different query clauses for shaping results.
  """

  def show_select_variations do
    """
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
    """
  end

  def show_ordering_examples do
    """
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
    """
  end

  def show_pagination_examples do
    """
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
    """
  end
end

IO.puts("Select clause variations:")
IO.puts(DayTwo.QueryClauses.show_select_variations())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Joins and associations")

defmodule DayTwo.JoinExamples do
  @moduledoc """
  Examples of different types of joins in Ecto queries.
  """

  def show_basic_joins do
    """
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
    """
  end

  def show_association_joins do
    """
    # Join through associations (cleaner):
    from u in User,
      join: p in assoc(u, :posts),
      select: {u.name, p.title}

    # Preload associations (N+1 solution):
    from u in User,
      preload: [:posts, :comments]

    # Conditional preloads:
    from u in User,
      preload: [posts: ^from(p in Post, where: p.published == true)]

    # Nested preloads:
    from u in User,
      preload: [posts: [:comments, :tags]]
    """
  end

  def show_complex_join_example do
    """
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
    """
  end
end

IO.puts("Basic join types:")
IO.puts(DayTwo.JoinExamples.show_basic_joins())
IO.puts("\nAssociation-based joins:")
IO.puts(DayTwo.JoinExamples.show_association_joins())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Building a blog query system")

defmodule DayTwo.BlogQueries do
  @moduledoc """
  Real-world example showing a comprehensive blog query system.
  """

  def show_blog_query_functions do
    """
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
    """
  end

  def demonstrate_dynamic_queries do
    """
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
    """
  end
end

IO.puts("Blog query system:")
IO.puts(DayTwo.BlogQueries.show_blog_query_functions())

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Write a query that finds all users who have posted in the last 30 days,
#    ordered by their most recent post date. Include the user info and their
#    post count in that period.
# 2. Create a "related posts" query that finds posts with similar tags to a
#    given post, excluding the original post, limited to 5 results.
# 3. (Challenge) Build a query for a comment moderation system that finds
#    comments needing approval (approved = false), includes the post title
#    and author name, and groups by user to show repeat offenders first.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. Active users in last 30 days
def active_users_last_30_days do
  thirty_days_ago = DateTime.add(DateTime.utc_now(), -30, :day)

  from u in User,
    join: p in assoc(u, :posts),
    where: p.inserted_at >= ^thirty_days_ago,
    group_by: u.id,
    order_by: [desc: max(p.inserted_at)],
    select: %{
      user: u,
      recent_post_count: count(p.id),
      latest_post_date: max(p.inserted_at)
    }
end

# 2. Related posts by tags
def related_posts(post_id, limit \\ 5) do
  # First get the tags of the original post
  original_post = Repo.get!(Post, post_id)

  from p in Post,
    where: p.id != ^post_id,
    where: fragment("? && ?", p.tags, ^original_post.tags),
    order_by: [desc: fragment("array_length(? & ?, 1)", p.tags, ^original_post.tags)],
    limit: ^limit,
    preload: [:user]
end

# 3. Comments needing moderation with repeat offender detection
def comments_for_moderation do
  from c in Comment,
    where: c.approved == false,
    join: p in assoc(c, :post),
    join: u in assoc(c, :user),
    group_by: [c.user_id, u.name],
    order_by: [desc: count(c.id)],
    select: %{
      user_id: c.user_id,
      user_name: u.name,
      pending_comment_count: count(c.id),
      sample_posts: fragment("array_agg(DISTINCT ?)", p.title)
    }
end

# Why these work:
# 1. Uses join + group_by to aggregate user data, orders by latest activity
# 2. Uses PostgreSQL array operators && for tag intersection, orders by overlap
# 3. Groups by user to identify patterns, uses array_agg to show affected posts
"""
