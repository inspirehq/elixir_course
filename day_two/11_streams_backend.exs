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
    IO.puts("# LiveView with streams:")

    code =
      quote do
        defmodule MyAppWeb.MessagesLive do
          use MyAppWeb, :live_view

          def mount(_params, _session, socket) do
            if connected?(socket) do
              Phoenix.PubSub.subscribe(MyApp.PubSub, "messages")
            end

            messages = Messages.list_recent_messages(50)

            socket =
              socket
              |> stream(:messages, messages)
              |> assign(:message_count, length(messages))

            {:ok, socket}
          end

          def handle_info({:message_created, message}, socket) do
            socket =
              socket
              |> stream_insert(:messages, message, at: 0)
              |> update(:message_count, &(&1 + 1))

            {:noreply, socket}
          end

          def handle_info({:message_updated, message}, socket) do
            socket = stream_insert(:messages, message)
            {:noreply, socket}
          end

          def handle_info({:message_deleted, message}, socket) do
            socket =
              socket
              |> stream_delete(:messages, message)
              |> update(:message_count, &(&1 - 1))

            {:noreply, socket}
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_stream_template do
    IO.puts("<!-- Template with stream rendering -->")

    code = """
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

    IO.puts(code)
  end
end

IO.puts("Basic stream setup:")
DayTwo.BasicStreams.show_liveview_stream_setup()
DayTwo.BasicStreams.show_stream_template()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Advanced stream features")

defmodule DayTwo.AdvancedStreams do
  @moduledoc """
  Advanced stream features and patterns.
  """

  def show_stream_options do
    IO.puts("# Stream configuration options:")

    code =
      quote do
        defmodule MyAppWeb.ProductsLive do
          def mount(_params, _session, socket) do
            products = Products.list_products()

            socket =
              stream(socket, :products, products,
                limit: 50,
                reset: true,
                at: 0
              )

            {:ok, socket}
          end
        end
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Conditional stream updates:")

    code =
      quote do
        def handle_info({:product_updated, product}, socket) do
          if product.featured do
            socket = stream_insert(:products, product)
            {:noreply, socket}
          else
            socket = stream_delete(:products, product)
            {:noreply, socket}
          end
        end
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Batch stream operations:")

    code =
      quote do
        def handle_info({:bulk_update, products}, socket) do
          socket =
            Enum.reduce(products, socket, fn product, acc ->
              stream_insert(acc, :products, product)
            end)

          {:noreply, socket}
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_stream_pagination do
    IO.puts("# Infinite scroll with streams:")

    code =
      quote do
        defmodule MyAppWeb.PostsLive do
          def handle_event("load_more", _params, socket) do
            page = socket.assigns.current_page + 1
            posts = Posts.list_posts(page: page, per_page: 20)

            socket =
              socket
              |> stream(:posts, posts, at: -1)
              |> assign(:current_page, page)
              |> assign(:has_more, length(posts) == 20)

            {:noreply, socket}
          end
        end
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Template with load more button:")

    code = """
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

    IO.puts(code)
  end
end

IO.puts("Advanced stream features:")
DayTwo.AdvancedStreams.show_stream_options()
DayTwo.AdvancedStreams.show_stream_pagination()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Stream performance and optimization")

defmodule DayTwo.StreamOptimization do
  @moduledoc """
  Optimizing stream performance for large datasets.
  """

  def show_memory_management do
    IO.puts("# Memory-efficient streams:")

    code =
      quote do
        defmodule MyAppWeb.AnalyticsLive do
          def mount(_params, _session, socket) do
            events = Analytics.recent_events(limit: 100)

            socket =
              stream(socket, :events, events,
                limit: 200,
                reset: true
              )

            {:ok, socket}
          end

          def handle_info({:new_event, event}, socket) do
            {:noreply, stream_insert(socket, :events, event, at: 0)}
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_debouncing_strategies do
    IO.puts("# Debouncing rapid updates:")

    code =
      quote do
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
      end

    IO.puts(Macro.to_string(code))
  end

  def show_optimistic_updates do
    IO.puts("# Optimistic UI updates with streams:")

    code =
      quote do
        def handle_event("create_post", %{"post" => post_params}, socket) do
          temp_id = "temp-" <> Ecto.UUID.generate()
          current_user = socket.assigns.current_user

          temp_post = %{
            id: temp_id,
            author: current_user.name,
            content: post_params["content"],
            status: :saving
          }

          socket = stream_insert(socket, :posts, temp_post)

          Task.start(fn ->
            case Posts.create_post(current_user, post_params) do
              {:ok, new_post} ->
                Phoenix.PubSub.broadcast(
                  MyApp.PubSub,
                  "posts",
                  {:post_created, new_post, temp_id}
                )

              {:error, changeset} ->
                Phoenix.PubSub.broadcast(
                  MyApp.PubSub,
                  "posts",
                  {:post_error, changeset, temp_id}
                )
            end
          end)

          {:noreply, socket}
        end

        def handle_info({:post_created, new_post, temp_id}, socket) do
          socket = stream_delete(socket, :posts, %{id: temp_id})
          socket = stream_insert(socket, :posts, new_post)
          {:noreply, socket}
        end
      end

    IO.puts(Macro.to_string(code))
  end
end

DayTwo.StreamOptimization.show_memory_management()
DayTwo.StreamOptimization.show_debouncing_strategies()
DayTwo.StreamOptimization.show_optimistic_updates()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world Stream use cases")

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

defmodule DayTwo.StreamExercises do
  @moduledoc """
  Run the tests with: mix test day_two/11_streams_backend.exs
  or in IEx:
  iex -r day_two/11_streams_backend.exs
  DayTwo.StreamExercisesTest.test_design_live_comment_stream/0
  DayTwo.StreamExercisesTest.test_design_activity_feed_stream/0
  """

  @doc """
  Designs a stream for a live comment section on a blog post.

  **Goal:** Create a real-time comment feed where new comments appear at the
  top and deleted comments are removed.

  **Requirements:**
  - The stream should be named `:comments`.
  - New comments should be inserted at the beginning of the stream.
  - The `handle_info` for a new comment should be for a `{:new_comment, comment}` message.
  - The `handle_event` for deleting a comment should be for a `"delete_comment"`
    event with a `phx-value-id` containing the comment's ID.

  **Task:**
  Return a map describing the stream design, including:
  - `:stream_name`: The atom used to name the stream.
  - `:insert_at`: The position where new items are inserted (integer).
  - `:handle_info_tuple`: The tuple pattern for handling new comment messages.
  - `:handle_event_string`: The string for handling the delete event.
  """
  @spec design_live_comment_stream() :: map()
  def design_live_comment_stream do
    # Design a stream for a live comment section.
    # Return a map with :stream_name, :insert_at, :handle_info_tuple, and :handle_event_string.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a stream for a user's activity feed with "load more" pagination.

  **Goal:** Create an infinite-scrolling activity feed that loads older items
  on demand without replacing the existing items.

  **Requirements:**
  - The stream is named `:activities`.
  - A `handle_event` for `"load_more"` will fetch the next page of activities.
  - New (older) items must be appended to the **end** of the stream. This is
    done by inserting at index `-1`.
  - The socket should track the current page number.

  **Task:**
  Return a map describing the stream design for pagination, including:
  - `:stream_name`: The atom for the stream.
  - `:handle_event`: The event string for loading more items.
  - `:insert_at`: The position for appending new items.
  - `:socket_assigns`: A list of atoms that should be stored in the socket
    to manage the feed's state (e.g., page number).
  """
  @spec design_activity_feed_stream() :: map()
  def design_activity_feed_stream do
    # Design a stream for a paginated activity feed.
    # Return a map with :stream_name, :handle_event, :insert_at, and :socket_assigns.
    nil  # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.StreamExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.StreamExercises, as: EX

  test "design_live_comment_stream/0 returns a valid design" do
    design = EX.design_live_comment_stream()
    assert is_map(design)
    assert design.stream_name == :comments
    assert design.insert_at == 0
    assert design.handle_info_tuple == {:new_comment, :comment}
    assert design.handle_event_string == "delete_comment"
  end

  test "design_activity_feed_stream/0 returns a valid pagination design" do
    design = EX.design_activity_feed_stream()
    assert is_map(design)
    assert design.stream_name == :activities
    assert design.handle_event == "load_more"
    assert design.insert_at == -1
    assert :current_page in design.socket_assigns
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      %{
        stream_name: :comments,
        insert_at: 0,
        handle_info_tuple: {:new_comment, :comment},
        handle_event_string: "delete_comment"
      }
    end
  end

  def answer_two do
    quote do
      %{
        stream_name: :activities,
        handle_event: "load_more",
        insert_at: -1,
        socket_assigns: [:current_page, :has_more_items?]
      }
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. Live Comment Stream
#{Macro.to_string(DayTwo.Answers.answer_one())}
# This design covers the core operations of a real-time list. Using `at: 0`
# for `stream_insert` ensures new comments appear at the top, which is typical
# for feeds. The delete event uses `stream_delete` to efficiently remove the
# specific element from the DOM without affecting the others.

# 2. Activity Feed Stream with "Load More"
#{Macro.to_string(DayTwo.Answers.answer_two())}
# This is the standard pattern for infinite scrolling. Using `stream_insert` with
# `at: -1` appends the new page of items to the end of the list. The socket
# must maintain the state (`:current_page`) to know which page to fetch next.
# A `:has_more_items?` flag is used to know when to hide the "Load More" button.
""")
