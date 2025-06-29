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
    IO.puts(~S"""
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

    IO.puts(~S"""

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
          use ExUnit.Case

          test "basic arithmetic" do
            assert Calculator.add(2, 3) == 5
            refute Calculator.add(2, 3) == 6
            assert Calculator.divide(10, 2) == 5.0
            assert_in_delta(Calculator.divide(1, 3), 0.333, 0.001)
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
      end

    IO.puts(Macro.to_string(code))
  end

  def show_pattern_matching_tests do
    IO.puts("# Pattern matching in tests:")

    code =
      quote do
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
      end

    IO.puts(Macro.to_string(code))
  end

  def show_async_and_tagging do
    IO.puts("# Async tests and tagging:")

    code =
      quote do
        defmodule FastMathTest do
          use ExUnit.Case, async: true

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
      end

    IO.puts(Macro.to_string(code))

    IO.puts(~S"""

    # Run specific tags:
    # mix test --only unit
    # mix test --exclude slow
    # mix test --include skip
    """)
  end
end

IO.puts("Assertion patterns:")
DayTwo.AssertionExamples.show_basic_assertions()

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
          use ExUnit.Case

          setup_all do
            :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo)
            Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()})
            admin = insert(:user, role: "admin")

            on_exit(fn ->
              Ecto.Adapters.SQL.Sandbox.checkin(MyApp.Repo)
            end)

            %{admin: admin}
          end

          setup %{admin: admin} do
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
      end

    IO.puts(Macro.to_string(code))
  end

  def show_conditional_setup do
    IO.puts("# Conditional setup based on tags:")

    code =
      quote do
        defmodule APITest do
          use ExUnit.Case

          setup tags do
            if tags[:integration] do
              start_supervised!(MockHTTPServer)
              %{server_url: "http://localhost:4002"}
            else
              %{server_url: nil}
            end
          end

          @tag :integration
          test "external API call", %{server_url: url} do
            assert {:ok, response} = HTTPClient.get("#{url}/users")
            assert response.status == 200
          end

          test "pure function test", %{server_url: url} do
            assert url == nil
            assert Parser.parse_json("{}") == %{}
          end
        end
      end

    IO.puts(Macro.to_string(code))
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

DayTwo.TestSetupExamples.show_setup_patterns()
DayTwo.TestSetupExamples.show_conditional_setup()

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

defmodule DayTwo.ExUnitExercises do
  @moduledoc """
  Run the tests with: mix test day_two/12_intro_to_exunit.exs
  or in IEx:
  iex -r day_two/12_intro_to_exunit.exs
  DayTwo.ExUnitExercisesTest.test_write_basic_assertions/0
  DayTwo.ExUnitExercisesTest.test_write_setup_with_context/0
  DayTwo.ExUnitExercisesTest.test_design_test_for_complex_logic/0
  """

  @doc """
  Writes basic assertions for a simple utility module.

  **Goal:** Learn to use the most common assertions in ExUnit to test a
  pure function.

  **Module to Test:**
  ```elixir
  defmodule StringHelper do
    def truncate(str, len) when is_binary(str) and is_integer(len) do
      if String.length(str) > len do
        String.slice(str, 0, len) <> "..."
      else
        str
      end
    end
  end
  ```

  **Task:**
  Return a string containing a complete `ExUnit.Case` module that:
  1.  Tests the `truncate/2` function when the string is shorter than the limit.
  2.  Tests the `truncate/2` function when the string is longer than the limit.
  3.  Uses `assert` to check for the correct return value.
  """
  @spec write_basic_assertions() :: binary()
  def write_basic_assertions do
    # Write a test module as a string for the StringHelper.truncate/2 function.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Writes a test that uses a `setup` block to prepare context.

  **Goal:** Learn how to use `setup` to create data that can be shared
  across multiple tests in a module.

  **Scenario:**
  You have a `ShoppingCart` module. You need to test adding items and
  calculating the total. The cart should be created once for each test.

  ```elixir
  defmodule ShoppingCart do
    def new(), do: %{items: [], total: 0}
    def add_item(cart, item), do: # ...
    def total(cart), do: # ...
  end
  ```

  **Task:**
  Return a map describing the test design:
  - `:setup_block`: A string containing the `setup` block that creates a new
    shopping cart and puts it in the context as `:cart`.
  - `:test_one`: A string for a test named `"adds an item correctly"` that uses
    the cart from context, adds an item, and asserts the item is in the cart.
  - `:test_two`: A string for a test named `"calculates total correctly"` that
    uses the cart, adds a couple of items, and asserts the total is correct.
  """
  @spec write_setup_with_context() :: map()
  def write_setup_with_context do
    # Design a test for a ShoppingCart that uses a setup block.
    # Return a map with :setup_block, :test_one, and :test_two.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a test for a function with complex logic and potential errors.

  **Goal:** Learn how to test different return patterns (`:ok`/`:error` tuples)
  and how to assert on raised errors.

  **Module to Test:**
  ```elixir
  defmodule UserCreator do
    def create_user(params) do
      with {:ok, email} <- Map.fetch(params, :email),
           {:ok, password} <- Map.fetch(params, :password) do
        if String.length(password) < 8 do
          {:error, :password_too_short}
        else
          # DB insert logic...
          {:ok, %{email: email, id: 123}}
        end
      else
        :error -> {:error, :missing_params}
        # Special case for a specific library error
        {:error, :enoent} -> raise "Database not available"
      end
    end
  end
  ```

  **Task:**
  Return a string describing the testing strategy. It should cover how you would test:
  1.  The success case (`{:ok, user}`).
  2.  The invalid password case (`{:error, :password_too_short}`).
  3.  The missing parameters case (`{:error, :missing_params}`).
  4.  The case where an exception is raised, using `assert_raise/2`.
  """
  @spec design_test_for_complex_logic() :: binary()
  def design_test_for_complex_logic do
    # Describe a testing strategy for the UserCreator.create_user/1 function.
    # Cover success, error tuples, and exceptions.
    nil  # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.ExUnitExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.ExUnitExercises, as: EX

  test "write_basic_assertions/0 returns a valid test module string" do
    test_module_string = EX.write_basic_assertions()
    assert is_binary(test_module_string)
    assert String.contains?(test_module_string, "defmodule StringHelperTest")
    assert String.contains?(test_module_string, "use ExUnit.Case")
    assert String.contains?(test_module_string, "assert StringHelper.truncate")
  end

  test "write_setup_with_context/0 returns a valid test design" do
    design = EX.write_setup_with_context()
    assert is_map(design)
    assert String.contains?(design.setup_block, "setup do")
    assert String.contains?(design.test_one, "test \"adds an item correctly\"")
    assert String.contains?(design.test_two, "test \"calculates total correctly\"")
  end

  test "design_test_for_complex_logic/0 describes a comprehensive strategy" do
    strategy = EX.design_test_for_complex_logic()
    assert is_binary(strategy)
    assert String.contains?(strategy, "assert {:ok, user}")
    assert String.contains?(strategy, "assert {:error, :password_too_short}")
    assert String.contains?(strategy, "assert_raise")
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      """
      defmodule StringHelperTest do
        use ExUnit.Case, async: true

        test "does not truncate short strings" do
          assert StringHelper.truncate("hello", 10) == "hello"
        end

        test "truncates long strings and adds ellipsis" do
          assert StringHelper.truncate("hello world", 5) == "hello..."
        end
      end
      """
    end
  end

  def answer_two do
    quote do
      %{
        setup_block: """
        setup do
          cart = ShoppingCart.new()
          %{cart: cart}
        end
        """,
        test_one: """
        test "adds an item correctly", %{cart: cart} do
          cart = ShoppingCart.add_item(cart, %{name: "milk", price: 3})
          assert Enum.any?(cart.items, &(&1.name == "milk"))
        end
        """,
        test_two: """
        test "calculates total correctly", %{cart: cart} do
          cart = ShoppingCart.add_item(cart, %{name: "milk", price: 3})
          cart = ShoppingCart.add_item(cart, %{name: "bread", price: 2})
          assert ShoppingCart.total(cart) == 5
        end
        """
      }
    end
  end

  def answer_three do
    quote do
      """
      Testing Strategy for `UserCreator.create_user/1`:

      1.  **Success Case**: Write a test that provides valid params (email and a
          long password). Use pattern matching to assert on the successful
          `{:ok, user}` tuple and the structure of the `user` map.
          `assert {:ok, %{email: "a@b.c"}} = UserCreator.create_user(valid_params)`

      2.  **Invalid Data Case**: Write a test that provides a password that is
          too short. Assert that the function returns the specific error tuple.
          `assert UserCreator.create_user(short_pass_params) == {:error, :password_too_short}`

      3.  **Missing Data Case**: Write a test where the `:password` key is
          missing from the params map. Assert the function returns `{:error, :missing_params}`.
          This tests the `with` clause's `else` block.

      4.  **Exception Case**: To test the `raise`, we need to mock the condition
          that causes it. We can use a testing utility like `Mox` to make `Map.fetch`
          return `{:error, :enoent}` for a specific test. Then, we wrap the
          function call in `assert_raise/2` to verify the correct exception is raised.
          `assert_raise RuntimeError, "Database not available", fn -> ... end`
      """
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. Basic Assertions
#{Macro.to_string(DayTwo.Answers.answer_one())}
# This demonstrates the simplest form of testing: asserting that a pure function
# returns the expected output for a given input. Separating the "happy path"
# from the other cases into different test functions is a good practice.

# 2. Setup with Context
#{Macro.to_string(DayTwo.Answers.answer_two())}
# The `setup` block is essential for keeping tests clean and free of repetitive
# setup code. It runs before each test, providing a fresh context map. This
# ensures that tests are isolated and don't interfere with each other.

# 3. Testing Complex Logic
#{Macro.to_string(DayTwo.Answers.answer_three())}
# This strategy shows how to handle functions with multiple success and failure
# paths. Using pattern matching in assertions (`assert {:ok, user} = ...`) is a
# powerful Elixir feature. `assert_raise` is the standard way to confirm that
# your code correctly handles and raises exceptions under exceptional conditions.
""")
