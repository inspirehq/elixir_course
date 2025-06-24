# Day 2 – Intro to ExUnit
#
# Run with `mix test elixir_course/day_two/12_intro_to_exunit.exs`
# or inside IEx with:
#     iex -S mix
#     c "elixir_course/day_two/12_intro_to_exunit.exs"
#
# ExUnit is Elixir's built-in testing framework providing a rich set of assertions,
# test organization features, and integration with Mix for comprehensive testing.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – ExUnit fundamentals and test structure")

defmodule DayTwo.ExUnitBasics do
  @moduledoc """
  Understanding ExUnit structure and basic testing concepts.
  """

  def explain_exunit_architecture do
    """
    ExUnit Architecture:

    • Test Modules: Define test cases using ExUnit.Case
    • Test Functions: Functions starting with 'test' prefix
    • Assertions: assert, refute, assert_in_delta, etc.
    • Setup/Teardown: setup, setup_all for test preparation
    • Tags: @tag for organizing and filtering tests
    • Async Testing: async: true for parallel test execution

    Basic Test Structure:

    defmodule MyModuleTest do
      use ExUnit.Case, async: true

      setup do
        %{user: %{name: "Alice", age: 30}}
      end

      test "user has valid name", %{user: user} do
        assert user.name == "Alice"
        refute user.name == ""
      end
    end

    Benefits:
    • Built into Elixir core
    • Excellent test organization
    • Parallel test execution
    • Rich assertion library
    • Great error reporting
    """
  end

  def show_test_lifecycle do
    steps = [
      "1. ExUnit.start() - Initialize test framework",
      "2. setup_all - Run once before all tests in module",
      "3. setup - Run before each test",
      "4. test function - Execute test logic",
      "5. on_exit - Cleanup after test (if defined)",
      "6. Repeat steps 3-5 for each test",
      "7. Generate test report with results"
    ]

    IO.puts("ExUnit test lifecycle:")
    Enum.each(steps, fn step ->
      IO.puts("  #{step}")
    end)
  end
end

IO.puts("ExUnit fundamentals:")
IO.puts(DayTwo.ExUnitBasics.explain_exunit_architecture())
DayTwo.ExUnitBasics.show_test_lifecycle()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Assertions and test patterns")

# Note: These are example test patterns, not actual running tests
defmodule DayTwo.AssertionExamples do
  @moduledoc """
  Common ExUnit assertion patterns and techniques.
  """

  def show_basic_assertions do
    """
    # Basic assertions:
    defmodule CalculatorTest do
      use ExUnit.Case

      test "basic arithmetic" do
        assert Calculator.add(2, 3) == 5
        refute Calculator.add(2, 3) == 6

        assert Calculator.divide(10, 2) == 5.0
        assert_in_delta Calculator.divide(1, 3), 0.333, 0.001
      end

      test "error conditions" do
        assert_raise ArithmeticError, fn ->
          Calculator.divide(10, 0)
        end

        assert_raise ArgumentError, "invalid input", fn ->
          Calculator.add("a", "b")
        end
      end
    end
    """
  end

  def show_pattern_matching_tests do
    """
    # Pattern matching in tests:
    defmodule UserServiceTest do
      use ExUnit.Case

      test "user creation returns expected structure" do
        assert {:ok, user} = UserService.create_user(%{name: "Alice"})
        assert %User{name: "Alice", id: id} = user when is_integer(id)
        assert user.inserted_at != nil
      end

      test "validation errors" do
        assert {:error, changeset} = UserService.create_user(%{name: ""})
        assert %{name: ["can't be blank"]} = errors_on(changeset)
      end

      test "list operations" do
        users = UserService.list_users()
        assert is_list(users)
        assert length(users) > 0
        assert Enum.all?(users, &match?(%User{}, &1))
      end
    end
    """
  end

  def show_async_and_tagging do
    """
    # Async tests and tagging:
    defmodule FastMathTest do
      use ExUnit.Case, async: true  # Safe to run in parallel

      @tag :unit
      test "pure functions are fast" do
        assert Math.factorial(5) == 120
      end

      @tag :slow
      test "complex calculation" do
        result = Math.complex_operation(1000)
        assert result > 0
      end

      @tag skip: "not implemented yet"
      test "future feature" do
        assert false
      end
    end

    # Run specific tags:
    # mix test --only unit
    # mix test --exclude slow
    # mix test --include skip
    """
  end
end

IO.puts("Assertion patterns:")
IO.puts(DayTwo.AssertionExamples.show_basic_assertions())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Setup, teardown, and test context")

defmodule DayTwo.TestSetupExamples do
  @moduledoc """
  Test setup and context management patterns.
  """

  def show_setup_patterns do
    """
    # Setup and context patterns:
    defmodule DatabaseTest do
      use ExUnit.Case

      # Runs once before all tests in this module
      setup_all do
        # Start test database
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo)
        Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()})

        # Seed test data
        admin = insert(:user, role: "admin")

        on_exit(fn ->
          # Cleanup after all tests
          Ecto.Adapters.SQL.Sandbox.checkin(MyApp.Repo)
        end)

        %{admin: admin}
      end

      # Runs before each test
      setup %{admin: admin} do
        # Create test-specific data
        user = insert(:user)
        post = insert(:post, author: user)

        %{user: user, post: post, admin: admin}
      end

      test "user can view own post", %{user: user, post: post} do
        assert Posts.can_view?(user, post)
      end

      test "admin can view all posts", %{admin: admin, post: post} do
        assert Posts.can_view?(admin, post)
      end
    end
    """
  end

  def show_conditional_setup do
    """
    # Conditional setup based on tags:
    defmodule APITest do
      use ExUnit.Case

      setup tags do
        if tags[:integration] do
          # Setup for integration tests
          start_supervised!(MockHTTPServer)
          %{server_url: "http://localhost:4002"}
        else
          # Setup for unit tests
          %{server_url: nil}
        end
      end

      @tag :integration
      test "external API call", %{server_url: url} do
        assert {:ok, response} = HTTPClient.get("#{url}/users")
        assert response.status == 200
      end

      test "pure function test", %{server_url: url} do
        assert url == nil  # Unit test, no server needed
        assert Parser.parse_json("{}") == %{}
      end
    end
    """
  end

  def show_shared_setup do
    """
    # Shared setup across test files:
    defmodule MyApp.TestCase do
      use ExUnit.CaseTemplate

      using do
        quote do
          use ExUnit.Case, async: true
          import MyApp.TestHelpers
          import MyApp.Factory
        end
      end

      setup tags do
        # Common setup for all tests
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()})
        end

        :ok
      end
    end

    # Usage in test files:
    defmodule UserTest do
      use MyApp.TestCase  # Gets common setup automatically

      test "user creation" do
        user = insert(:user)
        assert user.id != nil
      end
    end
    """
  end
end

IO.puts("Setup patterns:")
IO.puts(DayTwo.TestSetupExamples.show_setup_patterns())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Testing GenServers and OTP processes")

defmodule DayTwo.OTPTestingExamples do
  @moduledoc """
  Patterns for testing GenServers and other OTP processes.
  """

  def show_genserver_testing do
    """
    # Testing GenServers:
    defmodule CounterServerTest do
      use ExUnit.Case

      setup do
        # Start supervised GenServer for each test
        {:ok, pid} = start_supervised(CounterServer)
        %{counter: pid}
      end

      test "initial state", %{counter: counter} do
        assert CounterServer.value(counter) == 0
      end

      test "increment operation", %{counter: counter} do
        CounterServer.inc(counter)
        CounterServer.inc(counter)
        assert CounterServer.value(counter) == 2
      end

      test "concurrent operations", %{counter: counter} do
        # Test concurrent access
        tasks = for _ <- 1..10 do
          Task.async(fn -> CounterServer.inc(counter) end)
        end

        Enum.each(tasks, &Task.await/1)
        assert CounterServer.value(counter) == 10
      end

      test "server crash and restart" do
        {:ok, pid} = start_supervised(CounterServer)
        CounterServer.inc(pid)

        # Kill the process
        Process.exit(pid, :kill)

        # Supervisor should restart it
        Process.sleep(10)
        {:ok, new_pid} = start_supervised(CounterServer)
        assert CounterServer.value(new_pid) == 0  # Fresh state
      end
    end
    """
  end

  def show_message_testing do
    """
    # Testing process messaging:
    defmodule ProcessTest do
      use ExUnit.Case

      test "process receives messages" do
        parent = self()

        pid = spawn(fn ->
          receive do
            {:ping, from} -> send(from, :pong)
          end
        end)

        send(pid, {:ping, parent})

        assert_receive :pong, 1000
      end

      test "process sends messages periodically" do
        {:ok, _pid} = PeriodicWorker.start_link(interval: 100)

        # Should receive multiple ticks
        assert_receive :tick, 150
        assert_receive :tick, 150
        assert_receive :tick, 150
      end

      test "no unwanted messages" do
        QuietWorker.start_link()

        refute_receive _, 100  # Should not receive anything
      end
    end
    """
  end

  def show_supervision_testing do
    """
    # Testing supervision trees:
    defmodule SupervisorTest do
      use ExUnit.Case

      test "supervisor starts children" do
        {:ok, sup_pid} = MyApp.Supervisor.start_link()

        children = Supervisor.which_children(sup_pid)
        assert length(children) == 3

        # Verify specific children are running
        assert {:worker1, worker_pid, :worker, [Worker]} =
          List.keyfind(children, :worker1, 0)
        assert Process.alive?(worker_pid)
      end

      test "supervisor restarts crashed children" do
        {:ok, sup_pid} = MyApp.Supervisor.start_link()

        [{:worker1, pid, :worker, [Worker]}] =
          Supervisor.which_children(sup_pid)

        # Kill the worker
        Process.exit(pid, :kill)

        # Wait for restart
        Process.sleep(100)

        # Verify new worker is running
        [{:worker1, new_pid, :worker, [Worker]}] =
          Supervisor.which_children(sup_pid)

        assert new_pid != pid
        assert Process.alive?(new_pid)
      end
    end
    """
  end
end

IO.puts("OTP testing patterns:")
IO.puts(DayTwo.OTPTestingExamples.show_genserver_testing())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Testing a chat system")

defmodule DayTwo.ChatSystemTest do
  @moduledoc """
  Real-world example: Comprehensive testing of a chat system.
  """

  def demonstrate_test_strategy do
    """
    Chat System Test Strategy:

    • Unit Tests: Pure functions and business logic
    • Integration Tests: Database operations and external APIs
    • Process Tests: GenServer behavior and message passing
    • End-to-End Tests: Full user workflows
    • Performance Tests: Load and concurrency testing
    """
  end

  def show_comprehensive_test_suite do
    """
    # Complete test suite for chat system:
    defmodule ChatSystemTest do
      use MyApp.TestCase, async: false  # Database operations

      describe "message validation" do
        test "valid message passes validation" do
          changeset = Message.changeset(%Message{}, %{
            content: "Hello world",
            user_id: 1,
            room_id: 1
          })

          assert changeset.valid?
        end

        test "empty content fails validation" do
          changeset = Message.changeset(%Message{}, %{
            content: "",
            user_id: 1,
            room_id: 1
          })

          refute changeset.valid?
          assert "can't be blank" in errors_on(changeset).content
        end
      end

      describe "room management" do
        setup do
          user = insert(:user)
          room = insert(:room, owner: user)
          %{user: user, room: room}
        end

        test "user can join room", %{user: user, room: room} do
          assert {:ok, membership} = Rooms.join(room, user)
          assert membership.user_id == user.id
          assert membership.room_id == room.id
        end

        test "user receives messages after joining", %{user: user, room: room} do
          {:ok, _} = Rooms.join(room, user)

          message = insert(:message, room: room)

          # Simulate real-time notification
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "room:#{room.id}",
            {:new_message, message}
          )

          # User process should receive the message
          assert_receive {:new_message, ^message}, 1000
        end
      end

      describe "real-time messaging" do
        test "message broadcasts to room members" do
          room = insert(:room)
          user1 = insert(:user)
          user2 = insert(:user)

          # Both users join room
          {:ok, _} = Rooms.join(room, user1)
          {:ok, _} = Rooms.join(room, user2)

          # User1 sends message
          message_data = %{content: "Hello!", user_id: user1.id, room_id: room.id}
          {:ok, message} = Messages.create_and_broadcast(message_data)

          # Both users should receive the message
          assert_receive {:new_message, ^message}
          assert_receive {:new_message, ^message}
        end

        test "typing indicators work" do
          room = insert(:room)
          user = insert(:user)

          TypingIndicator.start_typing(room.id, user.id)

          assert_receive {:typing_started, %{room_id: room_id, user_id: user_id}}
          assert room_id == room.id
          assert user_id == user.id
        end
      end

      describe "performance and load" do
        @tag :slow
        test "handles concurrent message creation" do
          room = insert(:room)
          user = insert(:user)

          # Create 100 messages concurrently
          tasks = for i <- 1..100 do
            Task.async(fn ->
              Messages.create_message(%{
                content: "Message #{i}",
                user_id: user.id,
                room_id: room.id
              })
            end)
          end

          results = Enum.map(tasks, &Task.await(&1, 5000))

          # All should succeed
          assert Enum.all?(results, &match?({:ok, _}, &1))

          # Verify count in database
          count = Messages.count_for_room(room.id)
          assert count == 100
        end
      end
    end
    """
  end

  def show_test_organization do
    categories = [
      "Unit Tests → message_test.exs, user_test.exs, room_test.exs",
      "Integration Tests → chat_integration_test.exs",
      "Channel Tests → room_channel_test.exs",
      "LiveView Tests → chat_live_test.exs",
      "Performance Tests → load_test.exs",
      "Feature Tests → chat_feature_test.exs"
    ]

    IO.puts("\nTest file organization:")
    Enum.each(categories, fn category ->
      IO.puts("  #{category}")
    end)
  end
end

IO.puts("Chat system testing:")
IO.puts(DayTwo.ChatSystemTest.demonstrate_test_strategy())
DayTwo.ChatSystemTest.show_test_organization()

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Create a comprehensive test suite for a shopping cart GenServer that handles
#    adding items, removing items, calculating totals, and applying discounts.
# 2. Build tests for a user authentication system including password validation,
#    JWT token generation, and session management with proper setup/teardown.
# 3. (Challenge) Design a test suite for a real-time notification system that
#    tests delivery, retries, batching, and different notification channels.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. Shopping cart test suite
defmodule ShoppingCartTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = start_supervised(ShoppingCart)
    %{cart: pid}
  end

  describe "item management" do
    test "adding items increases quantity", %{cart: cart} do
      ShoppingCart.add_item(cart, %{id: 1, name: "Widget", price: 10.00})
      ShoppingCart.add_item(cart, %{id: 1, name: "Widget", price: 10.00})

      items = ShoppingCart.get_items(cart)
      assert items[1].quantity == 2
    end

    test "removing items decreases quantity", %{cart: cart} do
      ShoppingCart.add_item(cart, %{id: 1, name: "Widget", price: 10.00})
      ShoppingCart.remove_item(cart, 1)

      items = ShoppingCart.get_items(cart)
      assert items == %{}
    end
  end

  describe "calculations" do
    test "calculates total correctly", %{cart: cart} do
      ShoppingCart.add_item(cart, %{id: 1, name: "Widget", price: 10.00})
      ShoppingCart.add_item(cart, %{id: 2, name: "Gadget", price: 15.00})

      total = ShoppingCart.get_total(cart)
      assert_in_delta total, 25.00, 0.01
    end

    test "applies discount correctly", %{cart: cart} do
      ShoppingCart.add_item(cart, %{id: 1, name: "Widget", price: 100.00})
      ShoppingCart.apply_discount(cart, 0.10)  # 10% discount

      total = ShoppingCart.get_total(cart)
      assert_in_delta total, 90.00, 0.01
    end
  end
end

# 2. Authentication system tests
defmodule AuthTest do
  use MyApp.TestCase

  describe "password validation" do
    test "validates strong password" do
      changeset = User.registration_changeset(%User{}, %{
        email: "user@example.com",
        password: "SecurePass123!"
      })

      assert changeset.valid?
    end

    test "rejects weak password" do
      changeset = User.registration_changeset(%User{}, %{
        email: "user@example.com",
        password: "123"
      })

      refute changeset.valid?
      assert "password too weak" in errors_on(changeset).password
    end
  end

  describe "JWT tokens" do
    setup do
      user = insert(:user)
      %{user: user}
    end

    test "generates valid JWT token", %{user: user} do
      {:ok, token} = Auth.generate_token(user)
      assert is_binary(token)

      {:ok, claims} = Auth.verify_token(token)
      assert claims["user_id"] == user.id
    end

    test "rejects expired token", %{user: user} do
      {:ok, token} = Auth.generate_token(user, ttl: -1)

      assert {:error, :expired} = Auth.verify_token(token)
    end
  end
end

# 3. Notification system tests
defmodule NotificationSystemTest do
  use ExUnit.Case, async: false

  setup do
    start_supervised!(NotificationQueue)
    start_supervised!(EmailSender)
    start_supervised!(SMSSender)
    :ok
  end

  describe "delivery" do
    test "delivers email notification" do
      notification = %{
        type: :email,
        recipient: "user@example.com",
        subject: "Test",
        body: "Hello"
      }

      NotificationSystem.send(notification)

      assert_receive {:email_sent, %{to: "user@example.com"}}, 1000
    end

    test "retries failed deliveries" do
      # Mock a failing service
      MockEmailService.set_failure_rate(0.5)

      notification = %{type: :email, recipient: "user@example.com"}
      NotificationSystem.send(notification)

      # Should eventually succeed after retries
      assert_receive {:email_sent, _}, 5000
    end
  end

  describe "batching" do
    test "batches multiple notifications" do
      notifications = for i <- 1..10 do
        %{type: :email, recipient: "user#{i}@example.com"}
      end

      Enum.each(notifications, &NotificationSystem.send/1)

      # Should batch into fewer actual sends
      Process.sleep(1000)
      sent_count = MockEmailService.get_send_count()
      assert sent_count < 10  # Batched
      assert sent_count > 0   # But some sent
    end
  end
end

# Benefits: Comprehensive coverage, realistic scenarios, proper isolation
"""
