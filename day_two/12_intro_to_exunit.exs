# Day 2 – Intro to ExUnit
#
# This script can be run with:
#     mix run day_two/12_intro_to_exunit.exs
# or inside IEx with:
#     iex -r day_two/12_intro_to_exunit.exs
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
    IO.puts("""
    ExUnit Architecture:

    • Test Modules: Define test cases using ExUnit.Case
    • Test Functions: Functions starting with 'test' prefix
    • Assertions: assert, refute, assert_in_delta, etc.
    • Setup/Teardown: setup, setup_all for test preparation
    • Tags: @tag for organizing and filtering tests
    • Async Testing: async: true for parallel test execution

    Basic Test Structure:
    """)

    code =
      quote do
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
      end

    IO.puts(Macro.to_string(code))

    IO.puts("""

    Benefits:
    • Built into Elixir core
    • Excellent test organization
    • Parallel test execution
    • Rich assertion library
    • Great error reporting
    """)
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
DayTwo.ExUnitBasics.explain_exunit_architecture()
DayTwo.ExUnitBasics.show_test_lifecycle()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Assertions and test patterns")

# Note: These are example test patterns, not actual running tests
defmodule DayTwo.AssertionExamples do
  @moduledoc """
  Common ExUnit assertion patterns and techniques.
  """

  def show_basic_assertions do
    IO.puts("# Basic assertions:")

    code =
      quote do
        defmodule CalculatorTest do
          use ExUnit.Case # Defines a test module for Calculator

          test "basic arithmetic" do
            assert Calculator.add(2, 3) == 5 # Check that addition works as expected
            refute Calculator.add(2, 3) == 6 # Ensure incorrect results are not returned
            assert Calculator.divide(10, 2) == 5.0 # Check division result
            assert_in_delta(Calculator.divide(1, 3), 0.333, 0.001) # Allow for floating point rounding errors
          end

          test "error conditions" do
            assert_raise ArithmeticError, fn ->
              Calculator.divide(10, 0) # Ensure dividing by zero raises an error
            end

            assert_raise ArgumentError, "invalid input", fn ->
              Calculator.add("a", "b") # Ensure invalid input raises the correct error
            end
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_pattern_matching_tests do
    IO.puts("# Pattern matching in tests:")

    code =
      quote do
        defmodule UserServiceTest do
          use ExUnit.Case # Defines a test module for UserService

          test "user creation returns expected structure" do
            assert {:ok, user} = UserService.create_user(%{name: "Alice"}) # Pattern match to check for success tuple
            assert %User{name: "Alice", id: id} = user when is_integer(id) # Ensure user struct has correct fields and id is an integer
            assert user.inserted_at != nil # Check that a timestamp was set
          end

          test "validation errors" do
            assert {:error, changeset} = UserService.create_user(%{name: ""}) # Pattern match to check for error tuple
            assert %{name: ["can't be blank"]} = errors_on(changeset) # Ensure the error message is correct
          end

          test "list operations" do
            users = UserService.list_users() # Get the list of users
            assert is_list(users) # Ensure the result is a list
            assert length(users) > 0 # List should not be empty
            assert Enum.all?(users, &match?(%User{}, &1)) # Every element should be a User struct
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_async_and_tagging do
    IO.puts("# Async tests and tagging:")

    code =
      quote do
        defmodule FastMathTest do
          use ExUnit.Case, async: true # Run tests in parallel for speed

          @tag :unit
          test "pure functions are fast" do
            assert Math.factorial(5) == 120 # Check that factorial works for a small input
          end

          @tag :slow
          test "complex calculation" do
            result = Math.complex_operation(1000) # Run a slow operation
            assert result > 0 # Ensure the result is positive
          end

          @tag skip: "not implemented yet"
          test "future feature" do
            assert false # This test is marked as skipped and will not run
          end
        end
      end

    IO.puts(Macro.to_string(code))

    IO.puts("""

    # Run specific tags:
    # mix test --only unit
    # mix test --exclude slow
    # mix test --include skip
    """)
  end
end

IO.puts("Assertion patterns:")
DayTwo.AssertionExamples.show_basic_assertions()
DayTwo.AssertionExamples.show_pattern_matching_tests()
DayTwo.AssertionExamples.show_async_and_tagging()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Setup, teardown, and test context")

defmodule DayTwo.TestSetupExamples do
  @moduledoc """
  Test setup and context management patterns.
  """

  def show_setup_patterns do
    IO.puts("# Setup and context patterns:")

    code =
      quote do
        defmodule DatabaseTest do
          use ExUnit.Case # Defines a test module for database-related tests

          setup_all do
            :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo) # Checkout a DB connection for all tests in this module
            Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()}) # Set sandbox mode to shared for concurrent tests
            admin = insert(:user, role: "admin") # Insert an admin user for use in tests

            on_exit(fn ->
              Ecto.Adapters.SQL.Sandbox.checkin(MyApp.Repo) # Clean up DB connection after all tests
            end)

            %{admin: admin} # Make admin available to all tests
          end

          setup %{admin: admin} do
            user = insert(:user) # Insert a regular user
            post = insert(:post, author: user) # Insert a post for that user
            %{user: user, post: post, admin: admin} # Provide all test data in the context
          end

          test "user can view own post", %{user: user, post: post} do
            assert Posts.can_view?(user, post) # User should be able to view their own post
          end

          test "admin can view all posts", %{admin: admin, post: post} do
            assert Posts.can_view?(admin, post) # Admin should be able to view any post
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_conditional_setup do
    IO.puts("# Conditional setup based on tags:")

    code =
      quote do
        defmodule APITest do
          use ExUnit.Case # Defines a test module for API-related tests

          setup tags do
            if tags[:integration] do
              start_supervised!(MockHTTPServer) # Start a mock HTTP server for integration tests
              %{server_url: "http://localhost:4002"} # Provide the server URL in the test context
            else
              %{server_url: nil} # For non-integration tests, no server is started
            end
          end

          @tag :integration
          test "external API call", %{server_url: url} do
            assert {:ok, response} = HTTPClient.get("#{url}/users") # Make an HTTP call and check for success
            assert response.status == 200 # Ensure the response status is 200 OK
          end

          test "pure function test", %{server_url: url} do
            assert url == nil # No server URL should be set for this test
            assert Parser.parse_json("{}") == %{} # Check that JSON parsing works
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_shared_setup do
    IO.puts("# Shared setup across test files:")
    code =
      quote do
        defmodule MyApp.TestCase do
          use ExUnit.CaseTemplate # Defines a reusable template for test modules

          using do
            quote do
              use ExUnit.Case, async: true # All tests using this template will run in parallel by default
              import MyApp.TestHelpers    # Bring in custom helper functions for use in tests
              import MyApp.Factory        # Bring in test data factory functions for easy test data creation
            end
          end

          setup tags do
            # This setup block runs before each test using this template
            :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo) # Checkout a database connection for test isolation
            unless tags[:async] do
              # If the test is not async, set the sandbox mode to shared so multiple processes can use the same connection
              Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()})
            end
            :ok # Return :ok to indicate setup succeeded
          end
        end
        # Example usage of the test case template:
        defmodule UserTest do
          use MyApp.TestCase # Inherit all setup and imports from MyApp.TestCase
          test "user creation" do
            user = insert(:user) # Use the imported factory to create a user
            assert user.id != nil # Assert that the user was created and has an id
          end
        end
      end
    IO.puts(Macro.to_string(code))
  end
end

DayTwo.TestSetupExamples.show_setup_patterns()
DayTwo.TestSetupExamples.show_conditional_setup()
DayTwo.TestSetupExamples.show_shared_setup()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Testing GenServers and OTP processes")

defmodule DayTwo.OTPTestingExamples do
  @moduledoc """
  Patterns for testing GenServers and other OTP processes.
  """

  def show_genserver_testing do
    IO.puts("# Testing GenServers:")
    code =
      quote do
        defmodule CounterServerTest do
          use ExUnit.Case # Defines a test module for the CounterServer GenServer
          setup do
            # Start a supervised CounterServer for each test to ensure isolation
            {:ok, pid} = start_supervised(CounterServer)
            %{counter: pid} # Provide the GenServer pid in the test context
          end
          test "initial state", %{counter: counter} do
            assert CounterServer.value(counter) == 0 # Counter should start at 0
          end
          test "increment operation", %{counter: counter} do
            CounterServer.inc(counter) # Increment the counter
            CounterServer.inc(counter) # Increment again
            assert CounterServer.value(counter) == 2 # Counter should now be 2
          end
          test "concurrent operations", %{counter: counter} do
            # Test concurrent increments using tasks
            tasks = for _ <- 1..10 do
              Task.async(fn -> CounterServer.inc(counter) end)
            end
            Enum.each(tasks, &Task.await/1) # Wait for all tasks to finish
            assert CounterServer.value(counter) == 10 # Counter should reflect all increments
          end
          test "server crash and restart" do
            {:ok, pid} = start_supervised(CounterServer) # Start a new server
            CounterServer.inc(pid) # Increment once
            Process.exit(pid, :kill) # Simulate a crash
            Process.sleep(10) # Give supervisor time to restart
            {:ok, new_pid} = start_supervised(CounterServer) # Start again
            assert CounterServer.value(new_pid) == 0 # New server should start fresh
          end
        end
      end
    IO.puts(Macro.to_string(code))
  end

  def show_message_testing do
    IO.puts("# Testing process messaging:")
    code =
      quote do
        defmodule ProcessTest do
          use ExUnit.Case # Defines a test module for process messaging
          test "process receives messages" do
            parent = self() # Get the current process pid
            pid = spawn(fn ->
              receive do
                {:ping, from} -> send(from, :pong) # Reply with :pong when pinged
              end
            end)
            send(pid, {:ping, parent}) # Send a ping message
            assert_receive :pong, 1000 # Assert that we receive :pong within 1 second
          end
          test "process sends messages periodically" do
            {:ok, _pid} = PeriodicWorker.start_link(interval: 100) # Start a worker that sends :tick
            assert_receive :tick, 150 # Should receive a tick soon
            assert_receive :tick, 150 # And another
            assert_receive :tick, 150 # And another
          end
          test "no unwanted messages" do
            QuietWorker.start_link() # Start a worker that should not send messages
            refute_receive _, 100 # Assert that no messages are received within 100ms
          end
        end
      end
    IO.puts(Macro.to_string(code))
  end

  def show_supervision_testing do
    IO.puts("# Testing supervision trees:")
    code =
      quote do
        defmodule SupervisorTest do
          use ExUnit.Case # Defines a test module for supervisor behavior
          test "supervisor starts children" do
            {:ok, sup_pid} = MyApp.Supervisor.start_link() # Start the supervisor
            children = Supervisor.which_children(sup_pid) # Get the list of children
            assert length(children) == 3 # There should be three children
            # Check that a specific worker is running
            assert {:worker1, worker_pid, :worker, [Worker]} =
                     List.keyfind(children, :worker1, 0)
            assert Process.alive?(worker_pid) # The worker process should be alive
          end
          test "supervisor restarts crashed children" do
            {:ok, sup_pid} = MyApp.Supervisor.start_link() # Start the supervisor
            [{:worker1, pid, :worker, [Worker]}] = Supervisor.which_children(sup_pid) # Get the worker
            Process.exit(pid, :kill) # Simulate a crash
            Process.sleep(100) # Wait for restart
            [{:worker1, new_pid, :worker, [Worker]}] = Supervisor.which_children(sup_pid) # Get the new worker
            assert new_pid != pid # The pid should be different (new process)
            assert Process.alive?(new_pid) # The new worker should be alive
          end
        end
      end
    IO.puts(Macro.to_string(code))
  end
end

IO.puts("OTP testing patterns:")
DayTwo.OTPTestingExamples.show_genserver_testing()
DayTwo.OTPTestingExamples.show_message_testing()
DayTwo.OTPTestingExamples.show_supervision_testing()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Testing a chat system")

defmodule DayTwo.ChatSystemTest do
  @moduledoc """
  Real-world example: Comprehensive testing of a chat system.
  """

  def demonstrate_test_strategy do
    IO.puts("Chat System Test Strategy:")
    IO.puts("""
    • Unit Tests: Pure functions and business logic
    • Integration Tests: Database operations and external APIs
    • Process Tests: GenServer behavior and message passing
    • End-to-End Tests: Full user workflows
    • Performance Tests: Load and concurrency testing
    """)
  end

  def show_comprehensive_test_suite do
    IO.puts("# Complete test suite for chat system:")
    code =
      quote do
        defmodule ChatSystemTest do
          use MyApp.TestCase, async: false # Use the shared test case template, run tests synchronously (DB ops)
          describe "message validation" do
            test "valid message passes validation" do
              changeset =
                Message.changeset(%Message{}, %{
                  content: "Hello world",
                  user_id: 1,
                  room_id: 1
                }) # Build a changeset for a valid message
              assert changeset.valid? # The changeset should be valid
            end
            test "empty content fails validation" do
              changeset =
                Message.changeset(%Message{}, %{
                  content: "",
                  user_id: 1,
                  room_id: 1
                }) # Build a changeset with empty content
              refute changeset.valid? # The changeset should be invalid
              assert "can't be blank" in errors_on(changeset).content # Error message should be present
            end
          end
          describe "room management" do
            setup do
              user = insert(:user) # Create a user
              room = insert(:room, owner: user) # Create a room owned by the user
              %{user: user, room: room} # Provide both in the test context
            end
            test "user can join room", %{user: user, room: room} do
              assert {:ok, membership} = Rooms.join(room, user) # User should be able to join the room
              assert membership.user_id == user.id # Membership should reference the correct user
              assert membership.room_id == room.id # Membership should reference the correct room
            end
            test "user receives messages after joining", %{user: user, room: room} do
              {:ok, _} = Rooms.join(room, user) # User joins the room
              message = insert(:message, room: room) # Insert a message into the room
              Phoenix.PubSub.broadcast(
                MyApp.PubSub,
                "room:#{room.id}",
                {:new_message, message}
              ) # Simulate a real-time message broadcast
              assert_receive {:new_message, ^message}, 1000 # User process should receive the message
            end
          end
          describe "real-time messaging" do
            test "message broadcasts to room members" do
              room = insert(:room) # Create a room
              user1 = insert(:user) # Create user 1
              user2 = insert(:user) # Create user 2
              {:ok, _} = Rooms.join(room, user1) # Both users join the room
              {:ok, _} = Rooms.join(room, user2)
              message_data = %{content: "Hello!", user_id: user1.id, room_id: room.id}
              {:ok, message} = Messages.create_and_broadcast(message_data) # User1 sends a message
              assert_receive {:new_message, ^message} # Both users should receive the message
              assert_receive {:new_message, ^message}
            end
            test "typing indicators work" do
              room = insert(:room) # Create a room
              user = insert(:user) # Create a user
              TypingIndicator.start_typing(room.id, user.id) # Simulate typing
              assert_receive {:typing_started, %{room_id: room_id, user_id: user_id}} # Should receive typing event
              assert room_id == room.id # Room id should match
              assert user_id == user.id # User id should match
            end
          end
          describe "performance and load" do
            @tag :slow
            test "handles concurrent message creation" do
              room = insert(:room) # Create a room
              user = insert(:user) # Create a user
              tasks =
                for i <- 1..100 do
                  Task.async(fn ->
                    Messages.create_message(%{
                      content: "Message #{i}",
                      user_id: user.id,
                      room_id: room.id
                    }) # Create messages concurrently
                  end)
                end
              results = Enum.map(tasks, &Task.await(&1, 5000)) # Wait for all tasks
              assert Enum.all?(results, &match?({:ok, _}, &1)) # All should succeed
              count = Messages.count_for_room(room.id) # Check message count in DB
              assert count == 100 # Should be 100 messages
            end
          end
        end
      end
    IO.puts(Macro.to_string(code))
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
DayTwo.ChatSystemTest.demonstrate_test_strategy()
DayTwo.ChatSystemTest.show_comprehensive_test_suite()
DayTwo.ChatSystemTest.show_test_organization()

# ────────────────────────────────────────────────────────────────
# 🚀 EXERCISES
#
# The modules below contain simple problems for you to solve by writing
# tests. The test shells are provided; you just need to fill in the assertions.
#
# To run the tests: mix test day_two/12_intro_to_exunit.exs
# ────────────────────────────────────────────────────────────────

defmodule DayTwo.ExUnitExercises do
  # Module for Exercise 1
  defmodule Calculator do
    def add(a, b), do: a + b
    def divide(_a, 0), do: raise(ArithmeticError, "division by zero")
    def divide(a, b), do: a / b
  end

  # Module for Exercise 2
  defmodule KeyValueStore do
    use GenServer

    def start_link(_opts), do: GenServer.start_link(__MODULE__, %{})
    def init(state), do: {:ok, state}
    def put(pid, key, value), do: GenServer.cast(pid, {:put, key, value})
    def get(pid, key), do: GenServer.call(pid, {:get, key})
    def handle_cast({:put, key, value}, state), do: {:noreply, Map.put(state, key, value)}
    def handle_call({:get, key}, _from, state), do: {:reply, Map.get(state, key), state}
  end

  # Modules for Exercise 3
  defmodule User do
    defstruct [:id, :email, :name]
    def changeset(struct, params) do
      if Map.get(params, :email) do
        {:ok, struct |> struct(params)}
      else
        {:error, %{email: ["can't be blank"]}}
      end
    end
  end

  defmodule UserContext do
    alias DayTwo.ExUnitExercises.User
    def create_user(params) do
      case User.changeset(%User{}, params) do
        {:ok, user_struct} -> {:ok, Map.put(user_struct, :id, System.unique_integer())}
        {:error, errors} -> {:error, errors}
      end
    end
  end
end

ExUnit.start()

# Fill out the tests below!

defmodule DayTwo.CalculatorTest do
  use ExUnit.Case, async: true
  alias DayTwo.ExUnitExercises.Calculator

  # Exercise 1: Basic Assertions
  # Goal: Test the Calculator module.

  test "adds two numbers" do
    # Hint: Use `assert` to check if Calculator.add(2, 3) equals 5.
  end

  test "divides two numbers" do
    # Hint: Use `assert` to check if Calculator.divide(10, 2) equals 5.0.
  end

  test "division by zero raises an error" do
    # Hint: Use `assert_raise` to check for an ArithmeticError.
  end
end

defmodule DayTwo.KeyValueStoreTest do
  use ExUnit.Case, async: true
  alias DayTwo.ExUnitExercises.KeyValueStore

  # Exercise 2: Testing with Context (`setup`)
  # Goal: Test the KeyValueStore GenServer.

  setup do
    # Hint: Use `start_supervised` to start the KeyValueStore
    # and return it in the context map, e.g., `{:ok, store: pid}`.
    :ok
  end

  test "can put and get a value", context do
    # Hint: Get the store's pid from the context.
    # Put a value, then get it back and assert it's correct.
  end

  test "returns nil for a non-existent key", context do
    # Hint: Get the store's pid from the context.
    # Get a key that hasn't been set and assert the result is `nil`.
  end
end

defmodule DayTwo.UserContextTest do
  use ExUnit.Case, async: true
  alias DayTwo.ExUnitExercises.UserContext

  # Exercise 3: Testing with Pattern Matching
  # Goal: Test a function that returns ok/error tuples.

  test "create_user with valid data returns an ok tuple" do
    valid_attrs = %{email: "test@example.com", name: "Test User"}
    # Hint: Use `assert` with pattern matching for `{:ok, user}`.
    # Also assert that the returned `user` has the correct email.
  end

  test "create_user with missing email returns an error tuple" do
    invalid_attrs = %{name: "Test User"}
    # Hint: Use `assert` with pattern matching for `{:error, errors}`.
    # Also assert the `errors` map contains the expected validation message.
  end
end

defmodule DayTwo.Answers do
  def print_answer_one do
    IO.puts("\n# 1. Basic Assertions")
    code =
      quote do
        defmodule DayTwo.CalculatorTest do
          use ExUnit.Case, async: true
          alias DayTwo.ExUnitExercises.Calculator
          test "adds two numbers" do
            assert Calculator.add(2, 3) == 5
          end
          test "divides two numbers" do
            assert Calculator.divide(10, 2) == 5.0
          end
          test "division by zero raises an error" do
            assert_raise ArithmeticError, "division by zero", fn ->
              Calculator.divide(10, 0)
            end
          end
        end
      end
    IO.puts(Macro.to_string(code))
    IO.puts(
      """
      # This test suite covers the basic functionality of a pure module. It uses `assert`
      # for happy paths and `assert_raise` to ensure errors are handled correctly.
      """
    )
  end

  def print_answer_two do
    IO.puts("\n# 2. Testing with Context (`setup`)")
    code =
      quote do
        defmodule DayTwo.KeyValueStoreTest do
          use ExUnit.Case, async: true
          alias DayTwo.ExUnitExercises.KeyValueStore
          setup do
            {:ok, pid} = start_supervised(KeyValueStore)
            {:ok, store: pid}
          end
          test "can put and get a value", %{store: store} do
            KeyValueStore.put(store, :name, "Alice")
            assert KeyValueStore.get(store, :name) == "Alice"
          end
          test "returns nil for a non-existent key", %{store: store} do
            assert KeyValueStore.get(store, :non_existent) == nil
          end
        end
      end
    IO.puts(Macro.to_string(code))
    IO.puts(
      """
      # The `setup` block is essential for testing stateful processes like GenServers.
      # It runs before each test, providing a clean, supervised process. This ensures
      # that tests are isolated and don't interfere with each other.
      """
    )
  end

  def print_answer_three do
    IO.puts("\n# 3. Testing with Pattern Matching")
    code =
      quote do
        defmodule DayTwo.UserContextTest do
          use ExUnit.Case, async: true
          alias DayTwo.ExUnitExercises.UserContext
          test "create_user with valid data returns an ok tuple" do
            valid_attrs = %{email: "test@example.com", name: "Test User"}
            assert {:ok, user} = UserContext.create_user(valid_attrs)
            assert user.email == "test@example.com"
          end
          test "create_user with missing email returns an error tuple" do
            invalid_attrs = %{name: "Test User"}
            assert {:error, errors} = UserContext.create_user(invalid_attrs)
            assert errors == %{email: ["can't be blank"]}
          end
        end
      end
    IO.puts(Macro.to_string(code))
    IO.puts(
      """
      # This strategy shows how to handle functions with multiple success and failure
      # paths. Using pattern matching in assertions (`assert {:ok, user} = ...`) is a
      # powerful and idiomatic Elixir feature for writing clear, concise tests.
      """
    )
  end
end

IO.puts("""


ANSWERS & EXPLANATIONS
========================
""")
DayTwo.Answers.print_answer_one()
DayTwo.Answers.print_answer_two()
DayTwo.Answers.print_answer_three()
