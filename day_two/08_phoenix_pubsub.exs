# Day 2 – Phoenix PubSub
#
# This script can be run with:
#     mix run day_two/08_phoenix_pubsub.exs
# or inside IEx with:
#     iex -r day_two/08_phoenix_pubsub.exs
#
# Phoenix PubSub provides distributed publish-subscribe messaging. It enables
# processes to subscribe to topics and receive messages published to those topics,
# even across multiple nodes in a cluster.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic PubSub concepts and local messaging")

defmodule DayTwo.PubSubBasics do
  @moduledoc """
  Understanding the core concepts of publish-subscribe messaging.
  """

  def explain_pubsub_pattern do
    """
    Publish-Subscribe (PubSub) pattern:

    • Publishers: Send messages to topics (don't know who receives)
    • Subscribers: Listen to topics (don't know who sends)
    • Topics: Named channels for message routing
    • Decoupling: Publishers and subscribers are independent

    Benefits:
    • Loose coupling between components
    • Multiple subscribers can listen to same topic
    • Dynamic subscription/unsubscription
    • Distributed messaging across nodes
    """
  end

  def simulate_local_pubsub do
    # Simulate how PubSub works with process messaging
    pubsub_pid = spawn(fn -> pubsub_loop(%{}) end)

    # Subscriber 1
    subscriber1 = spawn(fn ->
      send(pubsub_pid, {:subscribe, "news", self()})
      receive do
        {:message, topic, data} ->
          IO.puts("Subscriber 1 received on #{topic}: #{data}")
      end
    end)

    # Subscriber 2
    subscriber2 = spawn(fn ->
      send(pubsub_pid, {:subscribe, "news", self()})
      receive do
        {:message, topic, data} ->
          IO.puts("Subscriber 2 received on #{topic}: #{data}")
      end
    end)

    # Give time for subscriptions
    Process.sleep(100)

    # Publisher
    send(pubsub_pid, {:publish, "news", "Breaking: Elixir is awesome!"})

    # Wait for delivery
    Process.sleep(100)

    :ok
  end

  defp pubsub_loop(subscribers) do
    receive do
      {:subscribe, topic, pid} ->
        updated = Map.update(subscribers, topic, [pid], &[pid | &1])
        pubsub_loop(updated)

      {:publish, topic, message} ->
        case Map.get(subscribers, topic, []) do
          [] -> :ok
          pids ->
            Enum.each(pids, fn pid ->
              send(pid, {:message, topic, message})
            end)
        end
        pubsub_loop(subscribers)
    end
  end
end

IO.puts("PubSub pattern explanation:")
IO.puts(DayTwo.PubSubBasics.explain_pubsub_pattern())
IO.puts("\nSimulating local PubSub:")
DayTwo.PubSubBasics.simulate_local_pubsub()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Phoenix.PubSub setup and basic usage")

defmodule DayTwo.PhoenixPubSubDemo do
  @moduledoc """
  Demonstrating Phoenix.PubSub in a standalone context.
  """

  def show_pubsub_setup do
    """
    Setting up Phoenix.PubSub:

    # In your application's supervision tree:
    children = [
      {Phoenix.PubSub, name: MyApp.PubSub}
    ]

    # Basic operations:

    # Subscribe to a topic:
    Phoenix.PubSub.subscribe(MyApp.PubSub, "topic_name")

    # Publish a message:
    Phoenix.PubSub.broadcast(MyApp.PubSub, "topic_name", {:event, "data"})

    # Unsubscribe:
    Phoenix.PubSub.unsubscribe(MyApp.PubSub, "topic_name")

    # The subscribing process will receive messages via handle_info/2
    # or in receive blocks.
    """
  end

  def demonstrate_simulated_usage do
    # Since we don't have Phoenix.PubSub in this environment,
    # we'll demonstrate the API patterns

    operations = [
      "1. Start PubSub: {:ok, _pid} = start_pubsub()",
      "2. Subscribe: :ok = subscribe('user:123')",
      "3. Publish: :ok = broadcast('user:123', {:user_updated, %{name: 'Alice'}})",
      "4. Receive: handle_info({:user_updated, data}, state)",
      "5. Unsubscribe: :ok = unsubscribe('user:123')"
    ]

    IO.puts("Phoenix.PubSub operation flow:")
    Enum.each(operations, fn op ->
      IO.puts("  #{op}")
    end)
  end

  def show_topic_patterns do
    patterns = [
      {"user:123", "User-specific updates"},
      {"room:lobby", "Chat room messages"},
      {"orders:processing", "Order status changes"},
      {"notifications:admin", "Admin notifications"},
      {"game:match:456", "Game match events"},
      {"presence:users", "User presence updates"}
    ]

    IO.puts("\nCommon topic naming patterns:")
    Enum.each(patterns, fn {pattern, description} ->
      IO.puts("  #{pattern} - #{description}")
    end)
  end
end

IO.puts("Phoenix.PubSub setup:")
IO.puts(DayTwo.PhoenixPubSubDemo.show_pubsub_setup())
DayTwo.PhoenixPubSubDemo.demonstrate_simulated_usage()
DayTwo.PhoenixPubSubDemo.show_topic_patterns()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Event-driven architecture with PubSub")

defmodule DayTwo.EventDrivenDemo do
  @moduledoc """
  Demonstrating event-driven patterns using PubSub concepts.
  """

  # Simulate different service modules that communicate via events

  defmodule UserService do
    def simulate_user_creation(user_data) do
      # Create user logic...
      user = %{id: 1, name: user_data[:name], email: user_data[:email]}

      # Publish event
      IO.puts("UserService: Created user #{user.name}")
      broadcast_event("user:created", user)

      {:ok, user}
    end

    defp broadcast_event(topic, data) do
      IO.puts("  📡 Broadcasting to '#{topic}': #{inspect(data)}")
    end
  end

  defmodule EmailService do
    def handle_user_created(user) do
      IO.puts("EmailService: Sending welcome email to #{user.name} (#{user.email})")
      # Send welcome email logic...
      :ok
    end
  end

  defmodule AnalyticsService do
    def handle_user_created(user) do
      IO.puts("AnalyticsService: Recording user signup event for #{user.name}")
      # Track analytics event...
      :ok
    end
  end

  defmodule AuditService do
    def handle_user_created(user) do
      IO.puts("AuditService: Logging user creation - ID: #{user.id}")
      # Create audit log...
      :ok
    end
  end

  def demonstrate_event_flow do
    IO.puts("\n🎯 Event-driven user creation flow:")

    # Simulate the event flow
    user_data = [name: "Alice Johnson", email: "alice@example.com"]

    # User creation triggers event
    {:ok, user} = UserService.simulate_user_creation(user_data)

    # Simulate subscribers handling the event
    IO.puts("\n📨 Event subscribers processing 'user:created':")
    EmailService.handle_user_created(user)
    AnalyticsService.handle_user_created(user)
    AuditService.handle_user_created(user)

    IO.puts("\n✅ All services processed the event independently")
  end

  def show_event_patterns do
    """
    Common event-driven patterns:

    • Domain Events: user:created, order:shipped, payment:processed
    • System Events: cache:expired, health:check, deploy:finished
    • Integration Events: webhook:received, api:rate_limited
    • UI Events: page:viewed, button:clicked, form:submitted

    Benefits:
    • Services stay decoupled
    • Easy to add new subscribers
    • Natural audit trail
    • Scalable architecture
    """
  end
end

DayTwo.EventDrivenDemo.demonstrate_event_flow()
IO.puts("\nEvent patterns:")
IO.puts(DayTwo.EventDrivenDemo.show_event_patterns())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Distributed PubSub across nodes")

defmodule DayTwo.DistributedPubSub do
  @moduledoc """
  Understanding how PubSub works across multiple nodes in a cluster.
  """

  def explain_distributed_messaging do
    """
    Phoenix.PubSub automatically handles distribution:

    • Cluster Formation: Nodes connect via Node.connect/1
    • Message Propagation: Messages broadcast across all nodes
    • Subscription Sync: Subscriptions work regardless of node
    • Fault Tolerance: Node failures don't break other nodes

    Example topology:

    Node A (web-1)        Node B (web-2)        Node C (worker-1)
    ┌─────────────┐      ┌─────────────┐       ┌─────────────┐
    │ User Socket │      │ User Socket │       │ Job Processor│
    │ subscribes  │      │ subscribes  │       │ publishes   │
    │ to "notifications"│ │ to "notifications"│ │ "job:complete"│
    └─────────────┘      └─────────────┘       └─────────────┘
           │                      │                     │
           └──────────────────────┼─────────────────────┘
                                  │
                            PubSub Network
                        (automatic distribution)
    """
  end

  def show_clustering_setup do
    """
    Setting up a clustered PubSub:

    # Start nodes with same cookie:
    # Terminal 1: iex --name node1@127.0.0.1 --cookie secret
    # Terminal 2: iex --name node2@127.0.0.1 --cookie secret

    # Connect nodes:
    Node.connect(:"node1@127.0.0.1")

    # Same PubSub code works across nodes:
    Phoenix.PubSub.subscribe(MyApp.PubSub, "global_events")
    Phoenix.PubSub.broadcast(MyApp.PubSub, "global_events", {:ping, Node.self()})

    # All subscribed processes across the cluster receive the message
    """
  end

  def simulate_distributed_scenario do
    scenarios = [
      "📱 Mobile app connects to Node A, subscribes to user:123",
      "💻 Web app connects to Node B, also subscribes to user:123",
      "🔄 Background job on Node C publishes user:123 profile update",
      "📨 Both mobile and web apps receive the update instantly",
      "🌐 No configuration needed - PubSub handles distribution"
    ]

    IO.puts("\nDistributed messaging scenario:")
    Enum.each(scenarios, fn scenario ->
      IO.puts("  #{scenario}")
    end)
  end
end

IO.puts("Distributed PubSub:")
IO.puts(DayTwo.DistributedPubSub.explain_distributed_messaging())
DayTwo.DistributedPubSub.simulate_distributed_scenario()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Chat application with PubSub")

defmodule DayTwo.ChatDemo do
  @moduledoc """
  Real-world example: Chat application using PubSub patterns.
  """

  defmodule ChatRoom do
    def join_room(user_id, room_id) do
      topic = "room:#{room_id}"

      # Subscribe to room messages
      IO.puts("User #{user_id} joining room #{room_id}")
      subscribe_simulation(topic)

      # Announce user joined
      message = %{
        type: :user_joined,
        user_id: user_id,
        room_id: room_id,
        timestamp: DateTime.utc_now()
      }

      broadcast_simulation(topic, message)

      {:ok, topic}
    end

    def send_message(user_id, room_id, content) do
      topic = "room:#{room_id}"

      message = %{
        type: :message,
        user_id: user_id,
        room_id: room_id,
        content: content,
        timestamp: DateTime.utc_now()
      }

      IO.puts("User #{user_id} sends: #{content}")
      broadcast_simulation(topic, message)

      :ok
    end

    def leave_room(user_id, room_id) do
      topic = "room:#{room_id}"

      # Unsubscribe from room
      unsubscribe_simulation(topic)

      # Announce user left
      message = %{
        type: :user_left,
        user_id: user_id,
        room_id: room_id,
        timestamp: DateTime.utc_now()
      }

      broadcast_simulation(topic, message)

      :ok
    end

    defp subscribe_simulation(topic) do
      IO.puts("  📡 Subscribed to #{topic}")
    end

    defp broadcast_simulation(topic, message) do
      IO.puts("  📨 Broadcasting to #{topic}: #{message.type}")
    end

    defp unsubscribe_simulation(topic) do
      IO.puts("  🚫 Unsubscribed from #{topic}")
    end
  end

  defmodule PresenceTracker do
    def track_user_online(user_id) do
      topic = "presence:users"

      presence_data = %{
        user_id: user_id,
        status: :online,
        joined_at: DateTime.utc_now()
      }

      IO.puts("PresenceTracker: User #{user_id} is now online")
      broadcast_simulation(topic, {:user_online, presence_data})
    end

    def track_user_offline(user_id) do
      topic = "presence:users"

      presence_data = %{
        user_id: user_id,
        status: :offline,
        left_at: DateTime.utc_now()
      }

      IO.puts("PresenceTracker: User #{user_id} is now offline")
      broadcast_simulation(topic, {:user_offline, presence_data})
    end

    defp broadcast_simulation(topic, message) do
      IO.puts("  📡 Presence update on #{topic}")
    end
  end

  def demonstrate_chat_flow do
    IO.puts("\n💬 Chat application flow:")

    # Users join
    ChatRoom.join_room("alice", "general")
    ChatRoom.join_room("bob", "general")

    # Track presence
    PresenceTracker.track_user_online("alice")
    PresenceTracker.track_user_online("bob")

    # Send messages
    ChatRoom.send_message("alice", "general", "Hello everyone!")
    ChatRoom.send_message("bob", "general", "Hey Alice! 👋")
    ChatRoom.send_message("alice", "general", "How's the Elixir learning going?")

    # User leaves
    ChatRoom.leave_room("bob", "general")
    PresenceTracker.track_user_offline("bob")

    IO.puts("\n✅ Chat flow complete - all events distributed via PubSub")
  end

  def show_chat_topics do
    topics = [
      {"room:general", "General chat room messages"},
      {"room:random", "Random chat room messages"},
      {"presence:users", "User online/offline status"},
      {"notifications:alice", "Private notifications for Alice"},
      {"typing:room:general", "Typing indicators for general room"},
      {"moderation:reports", "Content moderation events"}
    ]

    IO.puts("\nChat application topics:")
    Enum.each(topics, fn {topic, description} ->
      IO.puts("  #{topic} - #{description}")
    end)
  end
end

DayTwo.ChatDemo.demonstrate_chat_flow()
DayTwo.ChatDemo.show_chat_topics()

defmodule DayTwo.PubSubExercises do
  @moduledoc """
  Run the tests with: mix test day_two/08_phoenix_pubsub.exs
  or in IEx:
  iex -r day_two/08_phoenix_pubsub.exs
  DayTwo.PubSubExercisesTest.test_design_notification_system_topics/0
  DayTwo.PubSubExercisesTest.test_design_dashboard_widget_subscriptions/0
  DayTwo.PubSubExercisesTest.test_design_task_processing_architecture/0
  """

  @doc """
  Designs the PubSub topics for a multi-channel notification system.

  **Goal:** Create a topic structure that can route notifications for different
  events (e.g., new comment, friend request) to various delivery channels
  (e.g., email, push notification) for a specific user.

  **Requirements:**
  - Return a map describing the topic design.
  - The map should have a key `:user_notifications` with a value that is an
    example topic string for a specific user and channel. The topic should
    include placeholders. E.g., "users:USER_ID:notifications:CHANNEL".
  - It should also have a key `:event_triggers` with a list of example
    event messages (the payload) that would be broadcast.

  **Example `event` payload:**
  `%{event: "new_comment", post_id: 123, user_id: 456}`

  **Task:**
  Return a map matching the requirements.
  """
  @spec design_notification_system_topics() :: map()
  def design_notification_system_topics do
    # Design a topic structure for a notification system.
    # Return a map with keys :user_notifications and :event_triggers.
    nil # TODO: Implement this exercise
  end

  @doc """
  Maps real-time dashboard widgets to their PubSub topics.

  **Goal:** Create a subscription map for a live dashboard where different
  UI components (widgets) get updates from different data sources.

  **Requirements:**
  - Return a map where keys are widget names (atoms) and values are the
    topic strings they should subscribe to.
  - Include at least three widgets:
    - `:sales_ticker`: Subscribes to new sales events.
    - `:user_activity_feed`: Subscribes to user signups.
    - `:error_monitor`: Subscribes to critical system errors.

  **Task:**
  Return a map matching the widget-to-topic structure.
  """
  @spec design_dashboard_widget_subscriptions() :: map()
  def design_dashboard_widget_subscriptions do
    # Build a map where keys are widget names (e.g., :sales_ticker) and
    # values are the PubSub topics they subscribe to (e.g., "sales:new").
    nil # TODO: Implement this exercise
  end

  @doc """
  Designs the architecture for a distributed task processing system.

  **Goal:** Architect a system where tasks can be published from anywhere
  and picked up by available workers that are specialized for certain tasks.

  **Scenario:**
  You have workers for `image_processing`, `video_encoding`, and `report_generation`.
  A web server needs to publish jobs for these workers to consume.

  **Task:**
  Return a string describing the architecture. It should cover:
  1.  The **topic naming convention** for different job types.
  2.  How a **dispatcher** would publish a job.
  3.  How a **worker** would subscribe to receive jobs.
  4.  The benefits of this approach (e.g., scalability, decoupling).
  """
  @spec design_task_processing_architecture() :: binary()
  def design_task_processing_architecture do
    # Describe a distributed task processing system using PubSub.
    # The description should include topic design, and the roles of
    # dispatchers and workers.
    nil # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.PubSubExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.PubSubExercises, as: EX

  test "design_notification_system_topics/0 returns a valid topic map" do
    design = EX.design_notification_system_topics()
    assert is_map(design)
    assert Map.has_key?(design, :user_notifications)
    assert Map.has_key?(design, :event_triggers)
    assert is_binary(design.user_notifications)
    assert is_list(design.event_triggers)
  end

  test "design_dashboard_widget_subscriptions/0 maps widgets to topics" do
    subscriptions = EX.design_dashboard_widget_subscriptions()
    assert is_map(subscriptions)
    assert Map.has_key?(subscriptions, :sales_ticker)
    assert Map.has_key?(subscriptions, :user_activity_feed)
    assert Map.has_key?(subscriptions, :error_monitor)
    assert is_binary(subscriptions[:sales_ticker])
  end

  test "design_task_processing_architecture/0 describes a valid architecture" do
    description = EX.design_task_processing_architecture()
    assert is_binary(description)
    assert String.contains?(description, "topic")
    assert String.contains?(description, "worker")
    assert String.contains?(description, "dispatcher")
    assert String.length(description) > 100
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      %{
        user_notifications: "users:USER_ID:notifications:CHANNEL",
        event_triggers: [
          %{event: "new_comment", user_id: 456, post_id: 123},
          %{event: "friend_request", user_id: 789, from_user_id: 101}
        ]
      }
    end
  end

  def answer_two do
    quote do
      %{
        sales_ticker: "sales:new",
        user_activity_feed: "users:new",
        error_monitor: "errors:critical"
      }
    end
  end

  def answer_three do
    quote do
      """
      Architecture: Distributed Task Processing via PubSub

      1. Topic Naming Convention:
      Jobs are categorized by topic. The convention is `jobs:TYPE`.
      Examples: `jobs:image_processing`, `jobs:video_encoding`, `jobs:report_generation`.

      2. Dispatcher (Publisher):
      A dispatcher (e.g., a web server controller) publishes a job by broadcasting
      a message to the relevant topic. The message contains the job payload.
      `Phoenix.PubSub.broadcast(MyApp.PubSub, "jobs:image_processing", {:process, job_data})`

      3. Worker (Subscriber):
      Worker processes subscribe to the topics they are equipped to handle. A pool of
      image processing workers would all subscribe to `"jobs:image_processing"`.
      `Phoenix.PubSub.subscribe(MyApp.PubSub, "jobs:image_processing")`

      4. Benefits:
      - Decoupling: The web server doesn't need to know about specific workers.
      - Scalability: To handle more image processing jobs, just add more worker nodes.
        They will automatically subscribe and start receiving work.
      - Resilience: If a worker crashes, the job wasn't sent to it directly, so it can
        be picked up by another worker (with appropriate logic).
      """
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. Design Notification System Topics
#{Macro.to_string(DayTwo.Answers.answer_one())}
# This structure separates the *triggering event* from the *delivery mechanism*. An
# event like a new comment is published once. A separate listener process receives
# this event, looks up the user's notification preferences, and then publishes a
# targeted message to the correct channel topic (e.g., "users:456:notifications:email").

# 2. Design Dashboard Widget Subscriptions
#{Macro.to_string(DayTwo.Answers.answer_two())}
# This mapping provides a clean separation of concerns. The backend system that
# processes sales only needs to know to broadcast on "sales:new". It doesn't
# care about which UI components are listening. This makes it easy to add or
# change dashboard widgets without touching the backend logic.

# 3. Design Task Processing Architecture
#{Macro.to_string(DayTwo.Answers.answer_three())}
# This is a classic "work queue" pattern implemented with PubSub. It's highly
# scalable and resilient. Dispatchers fire and forget jobs, and a dynamic pool
# of workers consumes them. This allows different parts of the system to be
# scaled independently based on load.
""")
