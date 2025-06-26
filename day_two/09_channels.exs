# Day 2 – Phoenix Channels
#
# This script can be run with:
#     mix run day_two/09_channels.exs
# or inside IEx with:
#     iex -r day_two/09_channels.exs
#
# Phoenix Channels provide real-time bidirectional communication between clients
# and the server using WebSockets, with automatic fallbacks to long-polling.
# Built on top of Phoenix PubSub for distributed messaging.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Channel concepts and architecture")

defmodule DayTwo.ChannelConcepts do
  @moduledoc """
  Understanding Phoenix Channels architecture and concepts.
  """

  def explain_channel_architecture do
    """
    Phoenix Channels Architecture:

    Client (JavaScript)     →     Phoenix Server
    ┌─────────────────┐          ┌─────────────────┐
    │   Phoenix.js    │ ←─────→  │   UserSocket    │
    │   - Connect     │          │   - Auth        │
    │   - Join topic  │          │   - Route       │
    │   - Send/receive│          └─────────────────┘
    └─────────────────┘                    │
                                          │
                                  ┌─────────────────┐
                                  │   Channel       │
                                  │   - join/3      │
                                  │   - handle_in/3 │
                                  │   - handle_info/2│
                                  └─────────────────┘
                                          │
                                  ┌─────────────────┐
                                  │   PubSub        │
                                  │   - Broadcast   │
                                  │   - Subscribe   │
                                  └─────────────────┘

    Key Components:
    • Socket: Connection endpoint, handles auth & routing
    • Channel: GenServer-like process for topic messaging
    • Topic: String identifier for channel instances
    • Transport: WebSocket, Long Polling fallback
    """
  end

  def show_channel_lifecycle do
    steps = [
      "1. Client connects to socket endpoint",
      "2. Client joins a topic (creates channel process)",
      "3. Channel.join/3 callback handles authorization",
      "4. Client and server exchange messages bidirectionally",
      "5. Channel subscribes to PubSub topics for broadcasts",
      "6. Client leaves topic (terminates channel process)"
    ]

    IO.puts("Channel lifecycle:")
    Enum.each(steps, fn step ->
      IO.puts("  #{step}")
    end)
  end

  def show_message_flow do
    """
    Message Flow Patterns:

    Client → Server (handle_in):
    client.channel.push("new_message", {content: "Hello"})
    ↓
    def handle_in("new_message", payload, socket)

    Server → Client (push):
    push(socket, "message_sent", %{id: 123})
    ↓
    channel.on("message_sent", payload => { ... })

    Server → All Clients (broadcast):
    broadcast(socket, "user_joined", %{user: "Alice"})
    ↓
    All clients on topic receive "user_joined"
    """
  end
end

IO.puts("Channel architecture:")
IO.puts(DayTwo.ChannelConcepts.explain_channel_architecture())
DayTwo.ChannelConcepts.show_channel_lifecycle()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Socket and Channel implementation patterns")

defmodule DayTwo.ChannelPatterns do
  @moduledoc """
  Common patterns for implementing sockets and channels.
  """

  def show_socket_implementation do
    """
    # Phoenix Socket implementation:
    defmodule MyAppWeb.UserSocket do
      use Phoenix.Socket

      # Channel routing
      channel "room:*", MyAppWeb.RoomChannel
      channel "user:*", MyAppWeb.UserChannel
      channel "presence:*", MyAppWeb.PresenceChannel

      # Authentication
      def connect(%{"token" => token}, socket, _connect_info) do
        case MyApp.Guardian.decode_token(token) do
          {:ok, user_id} ->
            socket = assign(socket, :user_id, user_id)
            {:ok, socket}
          {:error, _} ->
            :error
        end
      end

      def connect(_params, _socket, _connect_info) do
        :error
      end

      # Socket ID for disconnection
      def id(socket), do: "user_socket:#{socket.assigns.user_id}"
    end
    """
  end

  def show_basic_channel_implementation do
    """
    # Basic Channel implementation:
    defmodule MyAppWeb.RoomChannel do
      use Phoenix.Channel

      # Join authorization
      def join("room:" <> room_id, params, socket) do
        if authorized?(socket.assigns.user_id, room_id) do
          send(self(), :after_join)
          {:ok, assign(socket, :room_id, room_id)}
        else
          {:error, %{reason: "unauthorized"}}
        end
      end

      # Handle client messages
      def handle_in("new_message", %{"content" => content}, socket) do
        user_id = socket.assigns.user_id
        room_id = socket.assigns.room_id

        message = %{
          id: generate_id(),
          user_id: user_id,
          content: content,
          timestamp: DateTime.utc_now()
        }

        # Save to database
        {:ok, _} = Messages.create_message(message)

        # Broadcast to all room members
        broadcast!(socket, "new_message", message)

        {:reply, {:ok, message}, socket}
      end

      # Handle PubSub messages
      def handle_info(:after_join, socket) do
        room_id = socket.assigns.room_id
        user_id = socket.assigns.user_id

        # Subscribe to room-specific events
        Phoenix.PubSub.subscribe(MyApp.PubSub, "room_events:#{room_id}")

        # Announce user joined
        broadcast!(socket, "user_joined", %{user_id: user_id})

        {:noreply, socket}
      end
    end
    """
  end
end

IO.puts("Socket implementation:")
IO.puts(DayTwo.ChannelPatterns.show_socket_implementation())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Client-side Channel integration")

defmodule DayTwo.ClientPatterns do
  @moduledoc """
  JavaScript client patterns for Phoenix Channels.
  """

  def show_javascript_setup do
    """
    // JavaScript client setup:
    import {Socket} from "phoenix"

    // Create socket connection
    let socket = new Socket("/socket", {
      params: {token: userToken},
      logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data) }
    })

    socket.connect()

    // Join a channel
    let channel = socket.channel("room:general", {})

    channel.join()
      .receive("ok", resp => {
        console.log("Joined successfully", resp)
      })
      .receive("error", resp => {
        console.log("Unable to join", resp)
      })

    // Listen for messages
    channel.on("new_message", payload => {
      console.log("New message:", payload)
      displayMessage(payload)
    })

    // Send messages
    channel.push("new_message", {content: "Hello, world!"})
      .receive("ok", resp => console.log("Message sent", resp))
      .receive("error", resp => console.log("Failed to send", resp))
    """
  end

  def show_react_integration do
    """
    // React hook for channels:
    import {useEffect, useState} from 'react'
    import {Socket} from 'phoenix'

    function useChannel(topic, params = {}) {
      const [channel, setChannel] = useState(null)
      const [messages, setMessages] = useState([])

      useEffect(() => {
        const socket = new Socket('/socket', {params: {token: userToken}})
        socket.connect()

        const newChannel = socket.channel(topic, params)

        newChannel.on('new_message', message => {
          setMessages(prev => [...prev, message])
        })

        newChannel.join()
        setChannel(newChannel)

        return () => {
          newChannel.leave()
          socket.disconnect()
        }
      }, [topic])

      const sendMessage = (event, payload) => {
        if (channel) {
          channel.push(event, payload)
        }
      }

      return {messages, sendMessage}
    }

    // Usage in component:
    function ChatRoom({roomId}) {
      const {messages, sendMessage} = useChannel(`room:${roomId}`)

      const handleSend = (content) => {
        sendMessage('new_message', {content})
      }

      return (
        <div>
          {messages.map(msg => <Message key={msg.id} {...msg} />)}
          <MessageForm onSend={handleSend} />
        </div>
      )
    }
    """
  end
end

IO.puts("JavaScript client patterns:")
IO.puts(DayTwo.ClientPatterns.show_javascript_setup())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Advanced Channel features")

defmodule DayTwo.AdvancedChannels do
  @moduledoc """
  Advanced Phoenix Channel features and patterns.
  """

  def show_channel_interceptors do
    """
    # Channel interceptors for cross-cutting concerns:
    defmodule MyAppWeb.RoomChannel do
      use Phoenix.Channel

      intercept ["new_message", "user_joined"]

      # Intercept outgoing messages
      def handle_out("new_message", payload, socket) do
        user_id = socket.assigns.user_id

        # Add user-specific data
        enhanced_payload = Map.put(payload, :is_own_message, payload.user_id == user_id)

        push(socket, "new_message", enhanced_payload)
        {:noreply, socket}
      end

      def handle_out("user_joined", payload, socket) do
        # Filter sensitive data based on user permissions
        if can_see_user_details?(socket.assigns.user_id, payload.user_id) do
          push(socket, "user_joined", payload)
        else
          filtered = Map.take(payload, [:user_id, :timestamp])
          push(socket, "user_joined", filtered)
        end

        {:noreply, socket}
      end
    end
    """
  end

  def show_channel_state_management do
    """
    # Channel state management:
    defmodule MyAppWeb.GameChannel do
      use Phoenix.Channel

      def join("game:" <> game_id, _params, socket) do
        game_state = GameEngine.get_state(game_id)

        socket = socket
                |> assign(:game_id, game_id)
                |> assign(:player_id, socket.assigns.user_id)
                |> assign(:game_state, game_state)

        {:ok, game_state, socket}
      end

      def handle_in("make_move", %{"move" => move}, socket) do
        game_id = socket.assigns.game_id
        player_id = socket.assigns.player_id

        case GameEngine.make_move(game_id, player_id, move) do
          {:ok, new_state} ->
            # Update local state
            socket = assign(socket, :game_state, new_state)

            # Broadcast to all players
            broadcast!(socket, "game_updated", new_state)

            {:reply, {:ok, new_state}, socket}

          {:error, reason} ->
            {:reply, {:error, %{reason: reason}}, socket}
        end
      end

      def handle_info({:game_ended, winner}, socket) do
        game_state = %{status: :ended, winner: winner}

        broadcast!(socket, "game_ended", game_state)
        {:noreply, assign(socket, :game_state, game_state)}
      end
    end
    """
  end

  def show_presence_integration do
    """
    # Integrating Phoenix Presence:
    defmodule MyAppWeb.RoomChannel do
      use Phoenix.Channel
      alias MyAppWeb.Presence

      def join("room:" <> room_id, _params, socket) do
        send(self(), :after_join)
        {:ok, assign(socket, :room_id, room_id)}
      end

      def handle_info(:after_join, socket) do
        room_id = socket.assigns.room_id
        user_id = socket.assigns.user_id

        # Track user presence
        {:ok, _} = Presence.track(socket, user_id, %{
          online_at: inspect(System.system_time(:second)),
          status: "online"
        })

        # Send current presence state to joining user
        push(socket, "presence_state", Presence.list(socket))

        {:noreply, socket}
      end

      def handle_in("update_status", %{"status" => status}, socket) do
        user_id = socket.assigns.user_id

        {:ok, _} = Presence.update(socket, user_id, %{
          status: status,
          updated_at: inspect(System.system_time(:second))
        })

        {:noreply, socket}
      end
    end
    """
  end
end

IO.puts("Advanced channel features:")
IO.puts(DayTwo.AdvancedChannels.show_channel_interceptors())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Live collaboration system")

defmodule DayTwo.CollaborationDemo do
  @moduledoc """
  Real-world example: Live document collaboration system with channels.
  """

  def show_collaboration_channel do
    """
    # Live document collaboration channel:
    defmodule MyAppWeb.DocumentChannel do
      use Phoenix.Channel
      alias MyApp.Documents
      alias MyAppWeb.Presence

      def join("document:" <> doc_id, _params, socket) do
        case Documents.get_document_with_permissions(doc_id, socket.assigns.user_id) do
          {:ok, document, permissions} ->
            socket = socket
                    |> assign(:document_id, doc_id)
                    |> assign(:permissions, permissions)

            send(self(), :after_join)
            {:ok, %{document: document}, socket}

          {:error, :not_found} ->
            {:error, %{reason: "Document not found"}}

          {:error, :unauthorized} ->
            {:error, %{reason: "Access denied"}}
        end
      end

      # Real-time text editing
      def handle_in("text_operation", payload, socket) do
        if can_edit?(socket.assigns.permissions) do
          doc_id = socket.assigns.document_id
          user_id = socket.assigns.user_id

          operation = %{
            type: :text_operation,
            user_id: user_id,
            operation: payload["operation"],
            timestamp: System.system_time(:millisecond)
          }

          # Apply operation to document
          {:ok, updated_doc} = Documents.apply_operation(doc_id, operation)

          # Broadcast to all collaborators except sender
          broadcast_from!(socket, "operation_applied", %{
            operation: operation,
            document_version: updated_doc.version
          })

          {:reply, {:ok, %{version: updated_doc.version}}, socket}
        else
          {:reply, {:error, %{reason: "No edit permission"}}, socket}
        end
      end

      # Cursor position tracking
      def handle_in("cursor_update", %{"position" => position}, socket) do
        user_id = socket.assigns.user_id

        broadcast_from!(socket, "cursor_moved", %{
          user_id: user_id,
          position: position
        })

        {:noreply, socket}
      end

      # Comment system
      def handle_in("add_comment", comment_data, socket) do
        if can_comment?(socket.assigns.permissions) do
          doc_id = socket.assigns.document_id
          user_id = socket.assigns.user_id

          comment = Map.merge(comment_data, %{
            "document_id" => doc_id,
            "user_id" => user_id
          })

          {:ok, created_comment} = Documents.create_comment(comment)

          broadcast!(socket, "comment_added", created_comment)

          {:reply, {:ok, created_comment}, socket}
        else
          {:reply, {:error, %{reason: "No comment permission"}}, socket}
        end
      end

      def handle_info(:after_join, socket) do
        doc_id = socket.assigns.document_id
        user_id = socket.assigns.user_id

        # Track user presence in document
        {:ok, _} = Presence.track(socket, user_id, %{
          name: Users.get_name(user_id),
          joined_at: inspect(System.system_time(:second)),
          cursor_position: nil
        })

        # Send current collaborators to joining user
        push(socket, "presence_state", Presence.list(socket))

        # Subscribe to document-level events
        Phoenix.PubSub.subscribe(MyApp.PubSub, "document_events:#{doc_id}")

        {:noreply, socket}
      end

      # Handle external document events
      def handle_info({:document_shared, user_data}, socket) do
        broadcast!(socket, "document_shared", user_data)
        {:noreply, socket}
      end

      def handle_info({:document_permissions_changed, permissions}, socket) do
        push(socket, "permissions_updated", permissions)
        {:noreply, assign(socket, :permissions, permissions)}
      end
    end
    """
  end

  def demonstrate_collaboration_flow do
    flow_steps = [
      "👤 User A joins document channel with edit permissions",
      "👤 User B joins same document with view permissions",
      "📝 User A makes text edit → operation broadcast to User B",
      "🖱️  User A moves cursor → position update sent to User B",
      "💬 User B adds comment → notification sent to User A",
      "🔄 Document permissions updated → both users notified",
      "📤 User A shares document → external event triggers broadcast",
      "🚪 User A leaves → presence update sent to remaining users"
    ]

    IO.puts("\nLive collaboration flow:")
    Enum.each(flow_steps, fn step ->
      IO.puts("  #{step}")
    end)
  end

  def show_conflict_resolution do
    """
    Conflict Resolution Strategies:

    • Operational Transformation (OT):
      - Transform operations based on concurrent changes
      - Ensures consistent final state across all clients
      - Complex but handles all edge cases

    • Last Writer Wins:
      - Simple timestamp-based conflict resolution
      - Good for non-critical collaborative features
      - Risk of data loss in high-concurrency scenarios

    • Version Vectors:
      - Track causality between operations
      - Detect conflicts and allow manual resolution
      - Good balance of complexity and correctness

    • Locking Mechanisms:
      - Prevent conflicts by locking document sections
      - Simple to implement but reduces collaboration
      - Good for critical data that must not conflict
    """
  end
end

IO.puts("Collaboration channel:")
IO.puts(DayTwo.CollaborationDemo.show_collaboration_channel())
DayTwo.CollaborationDemo.demonstrate_collaboration_flow()

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Create a simple chat channel that supports rooms, user authentication,
#    and message history. Include join/leave announcements and typing indicators.
# 2. Build a real-time notifications channel that delivers different types of
#    notifications (mentions, likes, comments) to users based on their preferences.
# 3. (Challenge) Design a live gaming channel for a turn-based game with
#    real-time moves, spectator mode, and reconnection handling for dropped connections.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. Chat channel with features
defmodule MyAppWeb.ChatChannel do
  use Phoenix.Channel

  def join("chat:" <> room_id, _params, socket) do
    # Load recent message history
    messages = Messages.get_recent(room_id, 50)

    socket = assign(socket, :room_id, room_id)
    send(self(), :after_join)

    {:ok, %{messages: messages}, socket}
  end

  def handle_in("new_message", %{"content" => content}, socket) do
    message = Messages.create_message(socket.assigns.user_id, content)
    broadcast!(socket, "new_message", message)
    {:reply, {:ok, message}, socket}
  end

  def handle_in("typing", %{"typing" => typing}, socket) do
    broadcast_from!(socket, "user_typing", %{
      user_id: socket.assigns.user_id,
      typing: typing
    })
    {:noreply, socket}
  end
end

# 2. Notifications channel with preferences
defmodule MyAppWeb.NotificationsChannel do
  use Phoenix.Channel

  def join("notifications:" <> user_id, _params, socket) do
    if socket.assigns.user_id == user_id do
      preferences = Users.get_notification_preferences(user_id)
      {:ok, %{preferences: preferences}, assign(socket, :preferences, preferences)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:notification, type, data}, socket) do
    if notification_enabled?(socket.assigns.preferences, type) do
      push(socket, "notification", %{type: type, data: data})
    end
    {:noreply, socket}
  end
end

# 3. Gaming channel with reconnection
defmodule MyAppWeb.GameChannel do
  use Phoenix.Channel

  def join("game:" <> game_id, %{"player_token" => token}, socket) do
    case Games.authenticate_player(game_id, token) do
      {:ok, player, game_state} ->
        socket = assign(socket, :game_id, game_id, :player_id, player.id)
        {:ok, game_state, socket}
      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  def handle_in("make_move", move_data, socket) do
    case Games.make_move(socket.assigns.game_id, socket.assigns.player_id, move_data) do
      {:ok, new_state} ->
        broadcast!(socket, "game_updated", new_state)
        {:reply, {:ok, new_state}, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  # Reconnection handling
  def handle_in("reconnect", _params, socket) do
    game_state = Games.get_current_state(socket.assigns.game_id)
    {:reply, {:ok, game_state}, socket}
  end
end

# Benefits: Real-time communication, scalable architecture, fault tolerance
"""
