# Day 2 – Phoenix Streams (Backend)
#
# This script can be run with:
#     mix run day_two/11_streams_backend.exs
# or inside IEx with:
#     iex -r day_two/11_streams_backend.exs
#
# Phoenix Streams enable efficient real-time data streaming to LiveViews,
# providing automatic updates when data changes without manual pubsub setup.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Stream concepts and architecture")

defmodule DayTwo.StreamConcepts do
  @moduledoc """
  Understanding Phoenix Streams and their role in real-time updates.
  """

  def explain_streams_vs_pubsub do
    """
    Streams vs Traditional PubSub:

    TRADITIONAL PUBSUB:
    • Manual subscription/unsubscription
    • Manual message handling in handle_info/2
    • Need to track what changed
    • Imperative update logic

    PHOENIX STREAMS:
    • Automatic subscription based on stream() calls
    • Declarative data dependencies
    • Automatic DOM updates when stream data changes
    • Built-in conflict resolution and ordering

    Benefits of Streams:
    • Less boilerplate code
    • Automatic memory management
    • Built-in pagination and limiting
    • Optimized DOM updates
    • Consistent ordering across clients
    """
  end

  def show_stream_lifecycle do
    steps = [
      "1. LiveView calls stream() to declare data dependency",
      "2. Phoenix subscribes to relevant PubSub topics automatically",
      "3. Data changes trigger stream updates via stream_insert/stream_delete",
      "4. Phoenix calculates minimal DOM changes needed",
      "5. Client receives optimized update instructions",
      "6. DOM updates happen automatically with animations"
    ]

    IO.puts("Stream lifecycle:")
    Enum.each(steps, fn step ->
      IO.puts("  #{step}")
    end)
  end
end

IO.puts("Stream concepts:")
IO.puts(DayTwo.StreamConcepts.explain_streams_vs_pubsub())
DayTwo.StreamConcepts.show_stream_lifecycle()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Basic stream setup and operations")

defmodule DayTwo.BasicStreams do
  @moduledoc """
  Basic stream setup and common operations.
  """

  def show_liveview_stream_setup do
    """
    # LiveView with streams:
    defmodule MyAppWeb.MessagesLive do
      use MyAppWeb, :live_view

      def mount(_params, _session, socket) do
        if connected?(socket) do
          # Subscribe to message updates
          Phoenix.PubSub.subscribe(MyApp.PubSub, "messages")
        end

        # Initialize stream with existing messages
        messages = Messages.list_recent_messages(50)

        socket = socket
                |> stream(:messages, messages)
                |> assign(:message_count, length(messages))

        {:ok, socket}
      end

      # Handle real-time message creation
      def handle_info({:message_created, message}, socket) do
        socket = socket
                |> stream_insert(:messages, message, at: 0)  # Insert at top
                |> update(:message_count, &(&1 + 1))

        {:noreply, socket}
      end

      # Handle message updates
      def handle_info({:message_updated, message}, socket) do
        socket = stream_insert(:messages, message)  # Replace existing
        {:noreply, socket}
      end

      # Handle message deletion
      def handle_info({:message_deleted, message}, socket) do
        socket = socket
                |> stream_delete(:messages, message)
                |> update(:message_count, &(&1 - 1))

        {:noreply, socket}
      end
    end
    """
  end

  def show_stream_template do
    """
    <!-- Template with stream rendering -->
    <div id="messages" phx-update="stream">
      <div :for={{dom_id, message} <- @streams.messages} id={dom_id}>
        <div class="message">
          <strong><%= message.author %></strong>
          <span class="timestamp"><%= message.inserted_at %></span>
          <p><%= message.content %></p>

          <button phx-click="delete_message" phx-value-id={message.id}>
            Delete
          </button>
        </div>
      </div>
    </div>

    <div class="message-count">
      Total: <%= @message_count %> messages
    </div>
    """
  end
end

IO.puts("Basic stream setup:")
IO.puts(DayTwo.BasicStreams.show_liveview_stream_setup())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Advanced stream features")

defmodule DayTwo.AdvancedStreams do
  @moduledoc """
  Advanced stream features and patterns.
  """

  def show_stream_options do
    """
    # Stream configuration options:
    defmodule MyAppWeb.ProductsLive do
      def mount(_params, _session, socket) do
        products = Products.list_products()

        socket = stream(socket, :products, products,
          limit: 50,          # Limit items in memory
          reset: true,        # Reset on reconnect
          at: 0              # Insert position for new items
        )

        {:ok, socket}
      end
    end

    # Conditional stream updates:
    def handle_info({:product_updated, product}, socket) do
      if product.featured do
        # Only stream featured products
        socket = stream_insert(:products, product)
        {:noreply, socket}
      else
        # Remove if no longer featured
        socket = stream_delete(:products, product)
        {:noreply, socket}
      end
    end

    # Batch stream operations:
    def handle_info({:bulk_update, products}, socket) do
      socket = Enum.reduce(products, socket, fn product, acc ->
        stream_insert(acc, :products, product)
      end)

      {:noreply, socket}
    end
    """
  end

  def show_stream_pagination do
    """
    # Infinite scroll with streams:
    defmodule MyAppWeb.PostsLive do
      def handle_event("load_more", _params, socket) do
        page = socket.assigns.current_page + 1
        posts = Posts.list_posts(page: page, per_page: 20)

        socket = socket
                |> stream(:posts, posts, at: -1)  # Append to end
                |> assign(:current_page, page)
                |> assign(:has_more, length(posts) == 20)

        {:noreply, socket}
      end
    end

    # Template with load more button:
    <!-- posts.html.heex -->
    <div id="posts" phx-update="stream">
      <article :for={{dom_id, post} <- @streams.posts} id={dom_id}>
        <!-- post content -->
      </article>
    </div>

    <button :if={@has_more}
            phx-click="load_more"
            class="load-more-btn">
      Load More Posts
    </button>
    """
  end
end

IO.puts("Advanced stream features:")
IO.puts(DayTwo.AdvancedStreams.show_stream_options())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Stream performance and optimization")

defmodule DayTwo.StreamOptimization do
  @moduledoc """
  Optimizing stream performance for large datasets.
  """

  def show_memory_management do
    """
    # Memory-efficient streams:
    defmodule MyAppWeb.AnalyticsLive do
      def mount(_params, _session, socket) do
        # Only load initial batch
        events = Analytics.recent_events(limit: 100)

        socket = socket
                |> stream(:events, events, limit: 1000)  # Keep max 1000 in memory
                |> assign(:total_events, Analytics.count_events())

        {:ok, socket}
      end

      # Efficient updates for high-frequency data
      def handle_info({:batch_events, events}, socket) do
        # Group multiple events into single update
        socket = stream(:events, events, at: 0, limit: 1000)
        {:noreply, socket}
      end
    end

    # Database-level optimizations:
    defmodule Analytics do
      def recent_events(opts \\ []) do
        limit = Keyword.get(opts, :limit, 50)

        from(e in Event,
          order_by: [desc: e.inserted_at],
          limit: ^limit,
          preload: [:user]  # Eager load associations
        )
        |> Repo.all()
      end
    end
    """
  end

  def show_debouncing_strategies do
    """
    # Debouncing rapid updates:
    defmodule MyAppWeb.LiveSearchLive do
      def mount(_params, _session, socket) do
        socket = socket
                |> assign(:search_query, "")
                |> assign(:debounce_timer, nil)
                |> stream(:results, [])

        {:ok, socket}
      end

      def handle_event("search", %{"query" => query}, socket) do
        # Cancel previous timer
        if socket.assigns.debounce_timer do
          Process.cancel_timer(socket.assigns.debounce_timer)
        end

        # Set new timer
        timer = Process.send_after(self(), {:perform_search, query}, 300)

        socket = socket
                |> assign(:search_query, query)
                |> assign(:debounce_timer, timer)

        {:noreply, socket}
      end

      def handle_info({:perform_search, query}, socket) do
        results = Search.search(query, limit: 50)

        socket = socket
                |> stream(:results, results, reset: true)
                |> assign(:debounce_timer, nil)

        {:noreply, socket}
      end
    end
    """
  end
end

IO.puts("Stream optimization:")
IO.puts(DayTwo.StreamOptimization.show_memory_management())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Live dashboard with streams")

defmodule DayTwo.DashboardDemo do
  @moduledoc """
  Real-world example: Live operations dashboard using streams.
  """

  def demonstrate_dashboard_flow do
    flow_steps = [
      "📊 Dashboard loads with multiple data streams",
      "📈 Metrics stream updates every 30 seconds",
      "🚨 Alert stream receives new incidents in real-time",
      "📝 Activity stream shows recent user actions",
      "🖥️  Server stream tracks infrastructure status",
      "🔄 Auto-refresh keeps data current",
      "📱 Mobile-optimized with pagination",
      "⚡ Optimized DOM updates maintain 60fps"
    ]

    IO.puts("\nLive dashboard flow:")
    Enum.each(flow_steps, fn step ->
      IO.puts("  #{step}")
    end)
  end

  def show_dashboard_features do
    features = [
      "Real-time metrics with automatic chart updates",
      "Live alert feed with severity-based filtering",
      "User activity stream with infinite scroll",
      "Server status grid with health indicators",
      "Auto-refreshing data with smart caching",
      "Responsive design for mobile and desktop",
      "Efficient memory usage for 24/7 operation"
    ]

    IO.puts("\nDashboard features powered by streams:")
    Enum.each(features, fn feature ->
      IO.puts("  • #{feature}")
    end)
  end
end

DayTwo.DashboardDemo.demonstrate_dashboard_flow()
DayTwo.DashboardDemo.show_dashboard_features()

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Create a live comment system with nested replies using streams,
#    including real-time updates and optimistic UI updates.
# 2. Build a live leaderboard that updates in real-time as user scores change,
#    with smooth animations and position transitions.
# 3. (Challenge) Design a live collaborative drawing canvas where multiple users
#    can draw simultaneously with streams handling the drawing operations.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. Live comment system
defmodule CommentsLive do
  def mount(%{"post_id" => post_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "post:#{post_id}:comments")
    end

    comments = Comments.list_with_replies(post_id)

    socket = socket
            |> assign(:post_id, post_id)
            |> stream(:comments, comments)

    {:ok, socket}
  end

  def handle_info({:comment_created, comment}, socket) do
    socket = stream_insert(:comments, comment, at: -1)
    {:noreply, socket}
  end

  def handle_event("add_comment", params, socket) do
    # Optimistic update
    temp_comment = %{id: "temp_#{System.unique_integer()}", content: params["content"]}
    socket = stream_insert(:comments, temp_comment)

    # Async save
    Task.start(fn -> Comments.create_comment(params) end)

    {:noreply, socket}
  end
end

# 2. Live leaderboard
defmodule LeaderboardLive do
  def handle_info({:score_updated, user_id, new_score}, socket) do
    # Find user in stream and update position
    updated_user = %{id: user_id, score: new_score, rank: calculate_rank(new_score)}

    socket = stream_insert(:leaderboard, updated_user)
    {:noreply, socket}
  end
end

# 3. Collaborative drawing canvas
defmodule DrawingLive do
  def handle_event("draw_stroke", stroke_data, socket) do
    stroke = %{id: generate_id(), data: stroke_data, user: socket.assigns.user}

    # Stream the drawing operation
    socket = stream_insert(:strokes, stroke)

    # Broadcast to other users
    broadcast_from(socket, "stroke_drawn", stroke)

    {:noreply, socket}
  end
end

# Benefits: Automatic updates, optimized rendering, consistent state management
"""
