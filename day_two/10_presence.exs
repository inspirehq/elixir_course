# Day 2 – Phoenix Presence
#
# This script can be run with:
#     mix run day_two/10_presence.exs
# or inside IEx with:
#     iex -r day_two/10_presence.exs
#
# Phoenix Presence provides distributed, fault-tolerant user presence tracking
# across a cluster of nodes using CRDTs (Conflict-free Replicated Data Types).
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Presence concepts and CRDT foundations")

defmodule DayTwo.PresenceConcepts do
  @moduledoc """
  Understanding Phoenix Presence and its CRDT foundations.
  """

  def explain_presence_architecture do
    """
    Phoenix Presence Architecture:

    • CRDT-based: Conflict-free Replicated Data Types
    • Eventually Consistent: All nodes converge to same state
    • Partition Tolerant: Handles network splits gracefully
    • Automatic Conflict Resolution: No manual intervention needed

    Core Components:
    • Tracker: Tracks presence state locally
    • Synchronizer: Syncs state across nodes
    • Broadcasts: Notifies about presence changes
    • Metadata: Arbitrary data attached to presences

    Benefits over traditional approaches:
    • No single point of failure
    • Works during network partitions
    • Automatic cleanup of stale presences
    • Rich metadata support
    """
  end

  def show_presence_lifecycle do
    steps = [
      "1. User connects → Presence.track() called",
      "2. Presence data replicated across cluster",
      "3. Other clients receive 'presence_state' event",
      "4. User updates status → Presence.update() called",
      "5. Changes broadcast as 'presence_diff' events",
      "6. User disconnects → Automatic cleanup after timeout"
    ]

    IO.puts("Presence lifecycle:")
    Enum.each(steps, fn step ->
      IO.puts("  #{step}")
    end)
  end
end

IO.puts("Presence concepts:")
IO.puts(DayTwo.PresenceConcepts.explain_presence_architecture())
DayTwo.PresenceConcepts.show_presence_lifecycle()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Setting up Phoenix Presence")

defmodule DayTwo.PresenceSetup do
  @moduledoc """
  Setting up Phoenix Presence in an application.
  """

  def show_presence_module_setup do
    """
    # Define Presence module:
    defmodule MyAppWeb.Presence do
      use Phoenix.Presence,
        otp_app: :my_app,
        pubsub_server: MyApp.PubSub
    end

    # Add to supervision tree:
    children = [
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Presence,  # Add presence here
      MyAppWeb.Endpoint
    ]

    # Use in channels:
    defmodule MyAppWeb.RoomChannel do
      use Phoenix.Channel
      alias MyAppWeb.Presence

      def join("room:" <> room_id, _params, socket) do
        send(self(), :after_join)
        {:ok, assign(socket, :room_id, room_id)}
      end

      def handle_info(:after_join, socket) do
        # Track user presence
        {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
          online_at: inspect(System.system_time(:second)),
          status: "available"
        })

        # Send current presence list
        push(socket, "presence_state", Presence.list(socket))
        {:noreply, socket}
      end
    end
    """
  end

  def demonstrate_basic_operations do
    operations = [
      "Track: Presence.track(socket, key, metadata)",
      "Update: Presence.update(socket, key, new_metadata)",
      "List: Presence.list(socket) → current presences",
      "Get: Presence.get_by_key(socket, key) → specific presence",
      "Untrack: Automatic on channel termination"
    ]

    IO.puts("\nBasic Presence operations:")
    Enum.each(operations, fn op ->
      IO.puts("  #{op}")
    end)
  end
end

IO.puts("Presence setup:")
IO.puts(DayTwo.PresenceSetup.show_presence_module_setup())
DayTwo.PresenceSetup.demonstrate_basic_operations()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Client-side presence handling")

defmodule DayTwo.ClientPresence do
  @moduledoc """
  Handling presence events on the client side.
  """

  def show_javascript_presence do
    """
    // JavaScript presence handling:
    import {Presence} from "phoenix"

    let channel = socket.channel("room:general", {})
    let presences = {}

    channel.on("presence_state", state => {
      presences = Presence.syncState(presences, state)
      displayUsers(presences)
    })

    channel.on("presence_diff", diff => {
      presences = Presence.syncDiff(presences, diff)
      displayUsers(presences)
    })

    function displayUsers(presences) {
      let users = Presence.list(presences, (id, {metas: [first, ...rest]}) => {
        return {
          id: id,
          status: first.status,
          online_at: first.online_at,
          count: rest.length + 1  // Multiple sessions
        }
      })

      renderUserList(users)
    }

    // Update your own status
    function updateStatus(status) {
      channel.push("update_status", {status: status})
    }
    """
  end

  def show_react_presence_hook do
    """
    // React presence hook:
    function usePresence(channel) {
      const [presences, setPresences] = useState({})

      useEffect(() => {
        if (!channel) return

        const handlePresenceState = (state) => {
          setPresences(Presence.syncState(presences, state))
        }

        const handlePresenceDiff = (diff) => {
          setPresences(prev => Presence.syncDiff(prev, diff))
        }

        channel.on('presence_state', handlePresenceState)
        channel.on('presence_diff', handlePresenceDiff)

        return () => {
          channel.off('presence_state', handlePresenceState)
          channel.off('presence_diff', handlePresenceDiff)
        }
      }, [channel])

      return Presence.list(presences)
    }
    """
  end
end

IO.puts("Client-side presence:")
IO.puts(DayTwo.ClientPresence.show_javascript_presence())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Advanced presence patterns")

defmodule DayTwo.AdvancedPresence do
  @moduledoc """
  Advanced patterns for using Phoenix Presence.
  """

  def show_multi_device_tracking do
    """
    # Multi-device presence tracking:
    defmodule MyAppWeb.UserChannel do
      use Phoenix.Channel
      alias MyAppWeb.Presence

      def join("user:" <> user_id, %{"device" => device}, socket) do
        if socket.assigns.user_id == user_id do
          socket = assign(socket, :device, device)
          send(self(), :track_presence)
          {:ok, socket}
        else
          {:error, %{reason: "unauthorized"}}
        end
      end

      def handle_info(:track_presence, socket) do
        # Track with device-specific key
        key = "#{socket.assigns.user_id}:#{socket.assigns.device}"

        {:ok, _} = Presence.track(socket, key, %{
          user_id: socket.assigns.user_id,
          device: socket.assigns.device,
          online_at: inspect(System.system_time(:second)),
          last_active: inspect(System.system_time(:second))
        })

        {:noreply, socket}
      end

      # Update activity timestamp
      def handle_in("activity", _params, socket) do
        key = "#{socket.assigns.user_id}:#{socket.assigns.device}"

        {:ok, _} = Presence.update(socket, key, fn meta ->
          Map.put(meta, :last_active, inspect(System.system_time(:second)))
        end)

        {:noreply, socket}
      end
    end
    """
  end

  def show_custom_presence_logic do
    """
    # Custom presence aggregation:
    defmodule MyAppWeb.TeamChannel do
      use Phoenix.Channel
      alias MyAppWeb.Presence

      def handle_info(:after_join, socket) do
        user_id = socket.assigns.user_id
        team_id = socket.assigns.team_id

        # Get user details for rich presence
        user = Users.get_user(user_id)

        {:ok, _} = Presence.track(socket, user_id, %{
          name: user.name,
          avatar: user.avatar_url,
          role: user.role,
          timezone: user.timezone,
          status: determine_status(user),
          joined_at: inspect(System.system_time(:second))
        })

        # Send aggregated team presence
        team_presence = aggregate_team_presence(team_id)
        push(socket, "team_presence", team_presence)

        {:noreply, socket}
      end

      defp aggregate_team_presence(team_id) do
        presences = Presence.list("team:#{team_id}")

        %{
          total_online: map_size(presences),
          by_role: group_by_role(presences),
          recent_joiners: get_recent_joiners(presences, 5)
        }
      end
    end
    """
  end
end

IO.puts("Advanced presence patterns:")
IO.puts(DayTwo.AdvancedPresence.show_multi_device_tracking())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Collaborative workspace presence")

defmodule DayTwo.WorkspacePresence do
  @moduledoc """
  Real-world example: Collaborative workspace with rich presence.
  """

  def demonstrate_workspace_flow do
    flow_steps = [
      "👤 User opens workspace → Track with current document/cursor",
      "📄 User switches documents → Update presence metadata",
      "✏️  User starts editing → Broadcast editing status",
      "⏸️  User goes idle → Auto-update to 'away' status",
      "💬 User opens chat → Show typing indicators",
      "🔄 User switches browser tabs → Update visibility status",
      "📱 User opens mobile app → Track multi-device presence",
      "🚪 User closes all apps → Automatic cleanup"
    ]

    IO.puts("\nWorkspace presence flow:")
    Enum.each(flow_steps, fn step ->
      IO.puts("  #{step}")
    end)
  end

  def show_presence_features do
    features = [
      "Live cursors showing user positions in documents",
      "User avatars with online/away/busy status indicators",
      "Activity feeds showing recent user actions",
      "Typing indicators in chat and comments",
      "Document collaboration awareness",
      "Meeting room occupancy tracking",
      "Timezone-aware presence information"
    ]

    IO.puts("\nWorkspace presence features:")
    Enum.each(features, fn feature ->
      IO.puts("  • #{feature}")
    end)
  end
end

DayTwo.WorkspacePresence.demonstrate_workspace_flow()
DayTwo.WorkspacePresence.show_presence_features()

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Create a gaming lobby presence system that tracks players waiting for matches,
#    their skill levels, and preferred game modes.
# 2. Build a customer support presence system showing agent availability,
#    current case load, and specialties.
# 3. (Challenge) Design a distributed team presence system that works across
#    multiple applications (Slack, email, calendar) and shows unified status.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. Gaming lobby presence
defmodule GameLobbyPresence do
  def track_player(socket, player_data) do
    Presence.track(socket, socket.assigns.user_id, %{
      skill_level: player_data.skill_level,
      preferred_modes: player_data.preferred_modes,
      looking_for_match: true,
      joined_lobby_at: System.system_time(:second)
    })
  end

  def find_matches(lobby_presences) do
    players = Presence.list(lobby_presences)
    # Match players by skill level and game mode preferences
    # Return potential matches
  end
end

# 2. Customer support presence
defmodule SupportPresence do
  def track_agent(socket, agent_data) do
    Presence.track(socket, socket.assigns.agent_id, %{
      status: "available",  # available, busy, away
      current_cases: agent_data.active_case_count,
      specialties: agent_data.specialties,
      max_concurrent_cases: agent_data.max_cases
    })
  end

  def find_available_agent(presences, case_category) do
    # Find agent with matching specialty and capacity
  end
end

# 3. Distributed team presence
defmodule UnifiedPresence do
  def aggregate_presence(user_id) do
    # Combine presence from multiple sources
    slack_status = SlackAPI.get_status(user_id)
    calendar_status = CalendarAPI.get_current_meeting(user_id)
    app_status = Presence.get_by_key("app:team", user_id)

    %{
      unified_status: determine_unified_status([slack_status, calendar_status, app_status]),
      sources: %{slack: slack_status, calendar: calendar_status, app: app_status}
    }
  end
end

# Benefits: Real-time awareness, distributed consistency, rich metadata
"""
