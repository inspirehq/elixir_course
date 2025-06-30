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
    send(pubsub_pid, {:publish, "news", "Breaking: You received a pubsub msg!"})

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

    defp broadcast_simulation(topic, _message) do
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
  DayTwo.PubSubExercisesTest.test_create_chat_message_event/0
  """

  @doc """
  Creates a chat message event for PubSub broadcasting.

  **Requirements:**
  Return a map representing a chat message event with these keys:
  - `:event` - The atom `:new_message`
  - `:room_id` - The room ID (use "general")
  - `:user` - The username (use "alice")
  - `:message` - The message content (use "Hello everyone!")
  - `:timestamp` - Current datetime using `DateTime.utc_now()`

  """
  @spec create_chat_message_event() :: map()
  def create_chat_message_event do
    # Create a chat message event map
    nil # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.PubSubExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.PubSubExercises, as: EX

  test "create_chat_message_event/0 returns a valid chat event" do
    event = EX.create_chat_message_event()
    assert is_map(event)
    assert event.event == :new_message
    assert event.room_id == "general"
    assert event.user == "alice"
    assert event.message == "Hello everyone!"
    assert %DateTime{} = event.timestamp
  end
end

defmodule DayTwo.Answers do
  def chat_message_solution do
    quote do
      %{
        event: :new_message,
        room_id: "general",
        user: "alice",
        message: "Hello everyone!",
        timestamp: DateTime.utc_now()
      }
    end
  end
end

IO.puts("""
ANSWER & EXPLANATION

# Chat Message Event
#{Macro.to_string(DayTwo.Answers.chat_message_solution())}

# This chat message event demonstrates key PubSub patterns:
#
# 1. **Event Structure**: Clear event type (:new_message) and all necessary data
#    for subscribers to display the message properly.
#
# 2. **Real-World Usage**: In a Phoenix app, you'd broadcast this event:
#    Phoenix.PubSub.broadcast(MyApp.PubSub, "room:general", chat_event)
#
#    And chat participants would subscribe:
#    Phoenix.PubSub.subscribe(MyApp.PubSub, "room:general")
#
# 3. **Immediate Updates**: All users in the room receive the message instantly
#    without polling or refreshing the page.
""")
