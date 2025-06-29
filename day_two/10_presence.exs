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
    IO.puts("# Define Presence module:")

    code =
      quote do
        defmodule MyAppWeb.Presence do
          use Phoenix.Presence,
            otp_app: :my_app,
            pubsub_server: MyApp.PubSub
        end
      end

    IO.puts(Macro.to_string(code))

    IO.puts("\n# Add to supervision tree:")

    code =
      quote do
        children = [
          MyApp.Repo,
          {Phoenix.PubSub, name: MyApp.PubSub},
          MyAppWeb.Presence,
          MyAppWeb.Endpoint
        ]
      end

    IO.puts(Macro.to_string(code))

    IO.puts("\n# Use in channels:")

    code =
      quote do
        defmodule MyAppWeb.RoomChannel do
          use Phoenix.Channel
          alias MyAppWeb.Presence

          def join("room:" <> room_id, _params, socket) do
            send(self(), :after_join)
            {:ok, assign(socket, :room_id, room_id)}
          end

          def handle_info(:after_join, socket) do
            {:ok, _} =
              Presence.track(socket, socket.assigns.user_id, %{
                online_at: inspect(System.system_time(:second)),
                status: "available"
              })

            push(socket, "presence_state", Presence.list(socket))
            {:noreply, socket}
          end
        end
      end

    IO.puts(Macro.to_string(code))
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
DayTwo.PresenceSetup.show_presence_module_setup()
DayTwo.PresenceSetup.demonstrate_basic_operations()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Client-side presence handling")

defmodule DayTwo.ClientPresence do
  @moduledoc """
  Handling presence events on the client side.
  """

  def show_javascript_presence do
    IO.puts("// JavaScript presence handling:")

    code =
      ~S"""
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

    IO.puts(code)
  end

  def show_react_presence_hook do
    IO.puts("// React presence hook:")

    code =
      ~S"""
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

    IO.puts(code)
  end
end

IO.puts("Client-side presence:")
DayTwo.ClientPresence.show_javascript_presence()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Advanced presence patterns")

defmodule DayTwo.AdvancedPresence do
  @moduledoc """
  Advanced patterns for using Phoenix Presence.
  """

  def show_multi_device_tracking do
    IO.puts("# Multi-device presence tracking:")

    code =
      quote do
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
            key = "#{socket.assigns.user_id}:#{socket.assigns.device}"

            {:ok, _} =
              Presence.track(socket, key, %{
                user_id: socket.assigns.user_id,
                device: socket.assigns.device,
                online_at: inspect(System.system_time(:second)),
                last_active: inspect(System.system_time(:second))
              })

            {:noreply, socket}
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_presence_in_liveview do
    IO.puts("# Using Presence data in LiveView:")

    code =
      quote do
        defmodule MyAppWeb.RoomLive do
          use MyAppWeb, :live_view
          alias MyAppWeb.Presence

          def mount(_params, _session, socket) do
            if connected?(socket), do: Presence.subscribe("room:live")

            users = Presence.list("room:live") |> Enum.map(&elem(&1, 1))

            {:ok, assign(socket, :users, users)}
          end

          def handle_info(%{event: "presence_diff", payload: _}, socket) do
            users = Presence.list("room:live") |> Enum.map(&elem(&1, 1))
            {:noreply, assign(socket, :users, users)}
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end
end

DayTwo.AdvancedPresence.show_multi_device_tracking()
DayTwo.AdvancedPresence.show_presence_in_liveview()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world Presence use cases")

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

defmodule DayTwo.PresenceExercises do
  @moduledoc """
  Run the tests with: mix test day_two/10_presence.exs
  or in IEx:
  iex -r day_two/10_presence.exs
  DayTwo.PresenceExercisesTest.test_design_document_collaboration_presence/0
  DayTwo.PresenceExercisesTest.test_design_game_lobby_presence/0
  DayTwo.PresenceExercisesTest.test_design_e_learning_platform_presence/0
  """

  @doc """
  Designs a presence system for a collaborative document editor.

  **Goal:** Track which users are currently viewing or editing a specific document.

  **Requirements:**
  - The presence topic should be unique per document (e.g., `"document:DOC_ID"`).
  - The metadata for each user must include their `status`, which can be
    `"viewing"` or `"editing"`.
  - The system must handle users changing their status (e.g., from viewing to editing).

  **Task:**
  Return a map describing the presence design, including:
  - `:topic`: An example topic string for a specific document.
  - `:track_payload`: An example map of the metadata to be sent when a user joins.
  - `:update_payload`: An example map for updating a user's status.
  """
  @spec design_document_collaboration_presence() :: map()
  def design_document_collaboration_presence do
    # Design a presence system for a collaborative document editor.
    # Return a map with :topic, :track_payload, and :update_payload.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a presence system for a game lobby.

  **Goal:** Track players in a game lobby, their ready status, and their team.

  **Requirements:**
  - The presence topic should be unique for each lobby (e.g., `"lobby:LOBBY_ID"`).
  - The metadata must include the player's `username`, `team` (`"blue"` or `"red"`),
    and `is_ready` (a boolean).
  - The system should allow players to update their team and ready status.

  **Task:**
  Return a map describing the presence design, including:
  - `:topic`: An example topic string for a lobby.
  - `:track_payload`: An example map of metadata for a player joining the lobby.
  - `:list_by_function`: A string containing a function signature and body for
    the `list/2` function that would group players by team. The function
    should take `presences` and a `mapper_fun` as arguments.
  """
  @spec design_game_lobby_presence() :: map()
  def design_game_lobby_presence do
    # Design a presence system for a game lobby.
    # Return a map with :topic, :track_payload, and :list_by_function.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a presence system for an e-learning platform.

  **Goal:** Track students and instructors in a live virtual classroom,
  including who is the current "presenter" and if a student has their
  "hand raised".

  **Requirements:**
  - The presence topic is unique per classroom (e.g., `"classroom:CLASS_ID"`).
  - The metadata must include the user's `role` (`:student` or `:instructor`)
    and other role-specific state (e.g., `:hand_raised` for students,
    `:is_presenting` for instructors).

  **Task:**
  Return a string describing the architecture. The description should cover:
  1.  How an instructor can be designated the presenter.
  2.  How a student can raise their hand.
  3.  How presence events (`presence_diff`) would be used by the client UI
      to reflect these state changes for all participants.
  """
  @spec design_e_learning_platform_presence() :: binary()
  def design_e_learning_platform_presence do
    # Describe the presence architecture for a virtual classroom, covering
    # presenter status and students raising their hands.
    nil  # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.PresenceExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.PresenceExercises, as: EX

  test "design_document_collaboration_presence/0 returns a valid design map" do
    design = EX.design_document_collaboration_presence()
    assert is_map(design)
    assert Map.has_key?(design, :topic)
    assert Map.has_key?(design, :track_payload)
    assert Map.has_key?(design, :update_payload)
    assert design.track_payload.status == "viewing"
    assert design.update_payload.status == "editing"
  end

  test "design_game_lobby_presence/0 returns a valid game lobby design" do
    design = EX.design_game_lobby_presence()
    assert is_map(design)
    assert Map.has_key?(design, :topic)
    assert Map.has_key?(design, :track_payload)
    assert Map.has_key?(design, :list_by_function)
    assert is_binary(design.list_by_function)
    assert String.contains?(design.list_by_function, "group_by")
  end

  test "design_e_learning_platform_presence/0 describes the classroom architecture" do
    description = EX.design_e_learning_platform_presence()
    assert is_binary(description)
    assert String.contains?(description, "presenter")
    assert String.contains?(description, "hand_raised")
    assert String.contains?(description, "presence_diff")
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      %{
        topic: "document:123-abc-789",
        track_payload: %{status: "viewing", user_avatar: "url_to_image"},
        update_payload: %{status: "editing"}
      }
    end
  end

  def answer_two do
    quote do
      %{
        topic: "lobby:g-456",
        track_payload: %{username: "player1", team: "blue", is_ready: false},
        list_by_function: """
        def list_by_team(presences) do
          Presence.list(presences)
          |> Enum.group_by(fn {_user_id, meta} -> meta.metas |> List.first() |> Map.get(:team) end)
        end
        """
      }
    end
  end

  def answer_three do
    quote do
      """
      Architecture: E-Learning Classroom Presence

      1. Designating a Presenter:
      An instructor client sends a `claim_presenter` event. The channel's
      `handle_in` callback for this event calls `Presence.update/3` to change
      that instructor's metadata to `is_presenting: true`. It may also update
      any previous presenter's metadata to set `is_presenting: false`.

      2. Raising a Hand:
      A student client sends a `raise_hand` event. The channel's `handle_in`
      callback calls `Presence.update/3` on that student's presence, setting
      their `hand_raised` metadata to `true`. A corresponding `lower_hand`
      event would set it to `false`.

      3. Client UI Updates via `presence_diff`:
      When any of these metadata changes occur, Phoenix Presence sends a
      `presence_diff` event to all clients. The client-side JavaScript uses
      `Presence.syncDiff` to update its local state. The UI is bound to this
      state, so it automatically re-renders to:
      - Highlight the new presenter's video feed.
      - Show a "hand raised" icon next to the student's name.
      """
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. Collaborative Document Presence
#{Macro.to_string(DayTwo.Answers.answer_one())}
# This design uses the metadata to track the state of each user within the
# context of the document. When a user starts typing, they push an event, and
# the channel updates their status to "editing". The resulting `presence_diff`
# notifies all other clients, who can then show a "User is typing..." indicator
# and lock the corresponding section of the document.

# 2. Game Lobby Presence
#{Macro.to_string(DayTwo.Answers.answer_two())}
# This is a great example of using Presence not just for who is online, but for
# managing shared lobby state. The custom `list_by_team` function shows how you can
# use `Presence.list/2` with a custom mapping function on the server to easily
# query and shape the presence data before sending it to clients.

# 3. E-Learning Platform Presence
#{Macro.to_string(DayTwo.Answers.answer_three())}
# This architecture shows how presence can be the single source of truth for
# real-time classroom state. Instead of custom events for everything, actions
# like raising a hand simply update the user's metadata. The `presence_diff`
# becomes the unified stream of all state changes, which greatly simplifies
# client-side logic.
""")
