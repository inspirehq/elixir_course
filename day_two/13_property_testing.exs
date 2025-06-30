# Day 2 – Options for Property Testing
#
# This script can be run with:
#     mix run day_two/13_property_testing.exs
# or inside IEx with:
#     iex -r day_two/13_property_testing.exs
#
# Property testing generates hundreds of test cases automatically to find edge cases
# that traditional example-based testing might miss. We'll explore StreamData and PropCheck.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Property testing concepts and benefits")

defmodule DayTwo.PropertyTestingConcepts do
  @moduledoc """
  Understanding property testing vs example-based testing.
  """

  def explain_property_vs_example_testing do
    """
    Example-Based Testing:
    • Write specific inputs and expected outputs
    • Test known edge cases manually
    • Limited coverage of input space
    • Example: assert Calculator.add(2, 3) == 5

    Property-Based Testing:
    • Define properties that should always hold
    • Generate hundreds of random inputs automatically
    • Discovers unexpected edge cases
    • Example: For any integers a, b: add(a, b) == add(b, a)

    Key Benefits:
    • Finds edge cases you didn't think of
    • Tests large input spaces efficiently
    • Shrinks failing cases to minimal examples
    • Documents code behavior as properties
    • Complements example-based tests
    """
  end

  def show_property_examples do
    properties = [
      "Commutativity: add(a, b) == add(b, a)",
      "Associativity: add(add(a, b), c) == add(a, add(b, c))",
      "Identity: add(a, 0) == a",
      "Inverse: encode(decode(data)) == data",
      "Monotonicity: sort(list) is always sorted",
      "Idempotency: normalize(normalize(s)) == normalize(s)"
    ]

    IO.puts("Common property patterns:")
    Enum.each(properties, fn prop ->
      IO.puts("  • #{prop}")
    end)
  end
end

IO.puts("Property testing concepts:")
IO.puts(DayTwo.PropertyTestingConcepts.explain_property_vs_example_testing())
DayTwo.PropertyTestingConcepts.show_property_examples()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – StreamData generators and basic property tests")

defmodule DayTwo.MathOperations do
  @moduledoc """
  Simple math operations for testing properties.
  """

  def add(a, b), do: a + b
  def multiply(a, b), do: a * b
  def sort_list(list), do: Enum.sort(list)
  def reverse_list(list), do: Enum.reverse(list)
end

defmodule DayTwo.StringOperations do
  @moduledoc """
  String operations for property testing.
  """

  def encode_base64(string), do: Base.encode64(string)
  def decode_base64(encoded), do: Base.decode64(encoded)

  def normalize_whitespace(string) do
    string
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end
end

defmodule DayTwo.StreamDataExamples do
  @moduledoc """
  Demonstrates StreamData generator patterns.
  """

  def show_basic_generators do
    IO.puts("Basic StreamData generators:")
    generators = [
      "integer() - any integer",
      "integer(1..100) - integers from 1 to 100",
      "float() - any float",
      "boolean() - true or false",
      "string(:printable) - printable strings",
      "binary() - any binary data",
      "list_of(integer()) - lists of integers",
      "map_of(string(), integer()) - maps with string keys and integer values"
    ]

    Enum.each(generators, fn gen ->
      IO.puts("  • #{gen}")
    end)
  end

  def user_generator do
    # This shows how to build custom generators
    ExUnit.start()

    if Code.ensure_loaded?(StreamData) do
      # Return a sample generator description since we can't actually import at runtime
      %{
        description: "StreamData generator for users",
        example: %{name: "Alice", age: 30, email: "alice@example.com"},
        pattern: "gen all name <- string(:printable), age <- integer(18..120), email <- string(:alphanumeric) do ..."
      }
    else
      %{name: "Alice", age: 30, email: "alice@example.com"}
    end
  end
end

IO.puts("StreamData generator examples:")
DayTwo.StreamDataExamples.show_basic_generators()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Factory pattern for test data generation")

defmodule DayTwo.Factory do
  @moduledoc """
  Factory for generating test data consistently.
  """

  def build(:user) do
    %{
      id: System.unique_integer([:positive]),
      name: "User #{:rand.uniform(1000)}",
      email: "user#{:rand.uniform(1000)}@example.com",
      age: :rand.uniform(50) + 18,
      role: Enum.random([:user, :admin, :moderator]),
      active: true,
      inserted_at: DateTime.utc_now()
    }
  end

  def build(:post) do
    %{
      id: System.unique_integer([:positive]),
      title: "Post #{:rand.uniform(1000)}",
      content: "This is post content #{:rand.uniform(1000)}",
      author_id: :rand.uniform(100),
      published: true,
      tags: Enum.take_random(["elixir", "phoenix", "testing", "property"], :rand.uniform(3)),
      inserted_at: DateTime.utc_now()
    }
  end

  def build(:user, attrs) do
    build(:user) |> Map.merge(attrs)
  end

  def build(:post, attrs) do
    build(:post) |> Map.merge(attrs)
  end

  def build_list(factory_name, count, attrs \\ %{}) do
    Enum.map(1..count, fn _ -> build(factory_name, attrs) end)
  end
end

defmodule DayTwo.AdvancedFactory do
  @moduledoc """
  More sophisticated factory with relationships and sequences.
  """

  @counter_agent :factory_counter

  def start_sequences do
    if Process.whereis(@counter_agent) do
      :ok
    else
      {:ok, _pid} = Agent.start_link(fn -> %{} end, name: @counter_agent)
      :ok
    end
  end

  def sequence(name, start \\ 1) do
    start_sequences()
    Agent.get_and_update(@counter_agent, fn counters ->
      current = Map.get(counters, name, start)
      {current, Map.put(counters, name, current + 1)}
    end)
  end

  def build(:user_with_posts) do
    user = DayTwo.Factory.build(:user)
    posts = DayTwo.Factory.build_list(:post, :rand.uniform(5), %{author_id: user.id})

    %{user: user, posts: posts}
  end

  def build(:team) do
    %{
      id: System.unique_integer([:positive]),
      name: "Team #{sequence(:team)}",
      description: "A great team for testing",
      created_at: DateTime.utc_now()
    }
  end

  def build(:user_in_team, team_id) do
    DayTwo.Factory.build(:user, %{team_id: team_id})
  end
end

IO.puts("Factory examples:")
IO.puts("User: #{inspect(DayTwo.Factory.build(:user))}")
IO.puts("Post: #{inspect(DayTwo.Factory.build(:post))}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Stateful property testing patterns")

defmodule DayTwo.CounterServer do
  @moduledoc """
  A simple counter GenServer for testing stateful properties.
  """
  use GenServer

  def start_link(initial_value \\ 0) do
    GenServer.start_link(__MODULE__, initial_value)
  end

  def get_value(pid), do: GenServer.call(pid, :get)
  def increment(pid, amount \\ 1), do: GenServer.cast(pid, {:inc, amount})
  def decrement(pid, amount \\ 1), do: GenServer.cast(pid, {:dec, amount})
  def reset(pid), do: GenServer.cast(pid, :reset)

  def init(initial_value), do: {:ok, initial_value}

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_cast({:inc, amount}, state), do: {:noreply, state + amount}
  def handle_cast({:dec, amount}, state), do: {:noreply, state - amount}
  def handle_cast(:reset, _state), do: {:noreply, 0}
end

defmodule DayTwo.BankAccount do
  @moduledoc """
  Simple bank account for demonstrating property testing.
  """

  defstruct [:id, :balance, :transactions]

  def new(id, initial_balance \\ 0) do
    %__MODULE__{
      id: id,
      balance: initial_balance,
      transactions: []
    }
  end

  def deposit(%__MODULE__{} = account, amount) when amount > 0 do
    transaction = {:deposit, amount, DateTime.utc_now()}
    %{account |
      balance: account.balance + amount,
      transactions: [transaction | account.transactions]
    }
  end

  def withdraw(%__MODULE__{} = account, amount) when amount > 0 and amount <= account.balance do
    transaction = {:withdraw, amount, DateTime.utc_now()}
    %{account |
      balance: account.balance - amount,
      transactions: [transaction | account.transactions]
    }
  end

  def withdraw(%__MODULE__{} = account, amount) when amount > account.balance do
    {:error, :insufficient_funds}
  end

  def get_balance(%__MODULE__{balance: balance}), do: balance
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Testing JSON API serialization")

defmodule DayTwo.UserSerializer do
  @moduledoc """
  JSON serialization for users with property testing.
  """

  def serialize_user(user) do
    %{
      "id" => user.id,
      "name" => user.name,
      "email" => user.email,
      "profile" => %{
        "age" => user.age,
        "role" => to_string(user.role)
      }
    }
    |> Jason.encode()
  end

  def deserialize_user(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, data} -> deserialize_user(data)
      error -> error
    end
  end

  def deserialize_user(data) when is_map(data) do
    user = %{
      id: data["id"],
      name: data["name"],
      email: data["email"],
      age: get_in(data, ["profile", "age"]),
      role: String.to_atom(get_in(data, ["profile", "role"]))
    }
    {:ok, user}
  rescue
    _ -> {:error, :invalid_format}
  end
end

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# Run the tests with: mix test day_two/13_property_testing.exs
# ────────────────────────────────────────────────────────────────

defmodule DayTwo.PropertyTestExercises do
  @moduledoc """
  Exercises for learning property testing.
  """

  def design_sorting_properties do
    [
      "The output list has the same length as the input list",
      "Sorting is idempotent (sorting a sorted list doesn't change it)",
      "The sorted list contains the exact same elements as the original",
      "Every element in the output is less than or equal to the element that follows it"
    ]
  end

  def design_encoding_properties do
    %{
      property_name: "encode/decode functions are inverses (round-trip)",
      generator: "string(:printable)",
      assertion: "assert decode(encode(original)) == original"
    }
  end

  def design_custom_data_generator do
    """
    def user_generator do
      gen all id <- integer(1..100_000),
              email_local_part <- string(:alphanumeric, min_length: 3),
              age <- integer(18..99),
              role <- member_of([:guest, :member, :admin]) do
        %User{
          id: id,
          email: email_local_part <> "@example.com",
          age: age,
          role: role
        }
      end
    end
    """
  end
end

ExUnit.start()

# These are the actual exercises students will complete!

defmodule DayTwo.PropertyTestExercisesTest do
  use ExUnit.Case, async: true
  # Note: StreamData may not be available in all environments
  # These tests will check if it's available before running property tests

  alias DayTwo.{MathOperations, StringOperations, CounterServer, BankAccount, UserSerializer, Factory}

  describe "basic property testing" do
    test "addition is commutative" do
      # Exercise 1: Test that addition is commutative
      # If StreamData is available, write a property test
      # Otherwise, write a few example-based tests
      # Hint: a + b should equal b + a for any integers a and b

      if Code.ensure_loaded?(StreamData) do
        # TODO: Write property test using StreamData
        # import StreamData
        # check all a <- integer(), b <- integer() do
        #   assert MathOperations.add(a, b) == MathOperations.add(b, a)
        # end
        flunk "Implement property test for addition commutativity"
      else
        # Fall back to example-based tests
        assert MathOperations.add(2, 3) == MathOperations.add(3, 2)
        assert MathOperations.add(-5, 10) == MathOperations.add(10, -5)
        assert MathOperations.add(0, 42) == MathOperations.add(42, 0)
      end
    end

    test "sorting preserves list length" do
      # Exercise 2: Test that sorting preserves list length
      # Hint: length(sort(list)) should equal length(list)

      if Code.ensure_loaded?(StreamData) do
        # TODO: Write property test
        flunk "Implement property test for sort length preservation"
      else
        lists = [
          [],
          [1],
          [3, 1, 4, 1, 5],
          [1, 1, 1, 1],
          [-5, -10, 0, 15]
        ]

        Enum.each(lists, fn list ->
          sorted = MathOperations.sort_list(list)
          assert length(sorted) == length(list)
        end)
      end
    end

    test "double reverse returns original list" do
      # Exercise 3: Test that reversing twice returns the original
      # Hint: reverse(reverse(list)) should equal list

      if Code.ensure_loaded?(StreamData) do
        # TODO: Write property test
        flunk "Implement property test for double reverse"
      else
        lists = [
          [],
          [1],
          [1, 2, 3],
          [:a, :b, :c, :d]
        ]

        Enum.each(lists, fn list ->
          double_reversed = list |> MathOperations.reverse_list() |> MathOperations.reverse_list()
          assert double_reversed == list
        end)
      end
    end
  end

  describe "string encoding properties" do
    test "base64 encode/decode roundtrip" do
      # Exercise 4: Test that base64 encoding and decoding are inverses
      # Hint: decode(encode(string)) should equal string (when successful)

      if Code.ensure_loaded?(StreamData) do
        # TODO: Write property test for base64 roundtrip
        flunk "Implement property test for base64 roundtrip"
      else
        strings = [
          "",
          "hello",
          "Hello, World!",
          "🚀 Elixir rocks! 🎉",
          String.duplicate("a", 1000)
        ]

        Enum.each(strings, fn original ->
          encoded = StringOperations.encode_base64(original)
          assert {:ok, decoded} = StringOperations.decode_base64(encoded)
          assert decoded == original
        end)
      end
    end

    test "whitespace normalization is idempotent" do
      # Exercise 5: Test that normalizing whitespace twice gives same result
      # Hint: normalize(normalize(string)) should equal normalize(string)

      strings = [
        "  hello   world  ",
        "no  extra   spaces",
        "\t\nspacing\r\n  issues\t",
        "already normalized"
      ]

      Enum.each(strings, fn string ->
        normalized_once = StringOperations.normalize_whitespace(string)
        normalized_twice = StringOperations.normalize_whitespace(normalized_once)
        assert normalized_once == normalized_twice
      end)
    end
  end

  describe "factory testing" do
    test "factory produces valid users" do
      # Exercise 6: Test that the factory produces valid user data
      user = Factory.build(:user)

      # TODO: Add assertions to verify the user has required fields
      # Hint: Check that user has id, name, email, age, role, active, inserted_at
      assert user.id != nil
      # Add more assertions here
    end

    test "factory with custom attributes" do
      # Exercise 7: Test that factory respects custom attributes
      custom_name = "Custom User"
      user = Factory.build(:user, %{name: custom_name, age: 25})

      # TODO: Assert that custom attributes are applied
      # Hint: user.name should equal custom_name, user.age should equal 25
      _ = user  # Prevent unused variable warning until TODO is implemented
    end

    test "factory builds lists of items" do
      # Exercise 8: Test that build_list creates the correct number of items
      users = Factory.build_list(:user, 5)

      # TODO: Add assertions about the list
      # Hint: Check length, that all items are users, that they have unique IDs
      _ = users  # Prevent unused variable warning until TODO is implemented
    end
  end

  describe "stateful property testing" do
    test "counter operations are consistent" do
      # Exercise 9: Test counter GenServer properties
      {:ok, counter} = CounterServer.start_link(0)

      # Test basic operations
      assert CounterServer.get_value(counter) == 0

      CounterServer.increment(counter, 5)
      CounterServer.increment(counter, 3)
      assert CounterServer.get_value(counter) == 8

      CounterServer.decrement(counter, 2)
      assert CounterServer.get_value(counter) == 6

      CounterServer.reset(counter)
      assert CounterServer.get_value(counter) == 0

      # TODO: Add property-based test here
      # Test multiple operations and verify final state matches expectations
    end

    test "bank account maintains balance invariants" do
      # Exercise 10: Test bank account properties
      account = BankAccount.new("acc123", 100)

      # TODO: Test deposit/withdraw operations
      # Properties to test:
      # - Balance should never go negative
      # - Total of all transactions should equal balance change
      # - Withdrawing more than balance should fail

      # Test successful operations
      account = BankAccount.deposit(account, 50)
      assert BankAccount.get_balance(account) == 150

      account = BankAccount.withdraw(account, 25)
      assert BankAccount.get_balance(account) == 125

      # Test overdraft protection
      result = BankAccount.withdraw(account, 200)
      assert result == {:error, :insufficient_funds}
    end
  end

  describe "json serialization properties" do
    test "user serialization roundtrip" do
      # Exercise 11: Test JSON serialization/deserialization
      original_user = Factory.build(:user)

      # TODO: Test the roundtrip property
      # Hint: deserialize(serialize(user)) should equal user
      # Note: You may need to handle the case where Jason is not available

      if Code.ensure_loaded?(Jason) do
        case UserSerializer.serialize_user(original_user) do
          {:ok, json} ->
            assert {:ok, deserialized} = UserSerializer.deserialize_user(json)
            # Check that key fields match (some fields might be transformed)
            assert deserialized.id == original_user.id
            assert deserialized.name == original_user.name
            assert deserialized.email == original_user.email

          {:error, _} ->
            flunk "Serialization failed"
        end
      else
        # Skip if Jason not available
        :ok
      end
    end
  end

  describe "custom factory exercise" do
    # Exercise 12: Build your own factory!
    # TODO: Create a factory for a Product struct
    # The product should have: id, name, price, category, in_stock, created_at

    defmodule ProductFactory do
      def build(:product) do
        # TODO: Implement product factory
        # Should return a map with all required fields
        %{}
      end

      def build(:product, attrs) do
        # TODO: Allow custom attributes to override defaults
        build(:product) |> Map.merge(attrs)
      end
    end

    test "product factory creates valid products" do
      # TODO: Test your product factory
      # product = ProductFactory.build(:product)
      # Add assertions to verify all fields are present and valid
      flunk "Implement product factory and tests"
    end

    test "product factory with custom attributes" do
      # TODO: Test custom attributes work
      # custom_product = ProductFactory.build(:product, %{name: "Custom Product", price: 99.99})
      # Add assertions
      flunk "Implement custom product factory test"
    end
  end
end

IO.puts("""


PROPERTY TESTING CONCEPTS SUMMARY
==================================

Key Patterns:
• Commutativity: f(a, b) == f(b, a)
• Associativity: f(f(a, b), c) == f(a, f(b, c))
• Identity: f(a, identity) == a
• Inverse/Roundtrip: decode(encode(x)) == x
• Idempotency: f(f(x)) == f(x)
• Monotonicity: f preserves ordering
• Invariants: Properties that never change

Factory Benefits:
• Consistent test data generation
• Easy customization with attributes
• Relationship management
• Reduces test setup boilerplate
• Enables property testing with realistic data

When to Use Property Testing:
• Data transformation functions
• Serialization/parsing code
• Mathematical operations
• Algorithm implementations
• API contract validation
• State machine behavior

Property testing finds edge cases that example-based testing misses,
making your code more robust and reliable.
""")

# ────────────────────────────────────────────────────────────────
# 📚 EXERCISE ANSWERS
# ────────────────────────────────────────────────────────────────

defmodule DayTwo.PropertyTestingAnswers do
  @moduledoc """
  Complete solutions for the property testing exercises.
  """

  def answer_one do
    """
    # Exercise 1: Addition is commutative property test

    test "addition is commutative" do
      if Code.ensure_loaded?(StreamData) do
        import StreamData
        check all a <- integer(), b <- integer() do
          assert MathOperations.add(a, b) == MathOperations.add(b, a)
        end
      else
        # Example-based fallback tests
        assert MathOperations.add(2, 3) == MathOperations.add(3, 2)
        assert MathOperations.add(-5, 10) == MathOperations.add(10, -5)
        assert MathOperations.add(0, 42) == MathOperations.add(42, 0)
        assert MathOperations.add(-10, -20) == MathOperations.add(-20, -10)
      end
    end
    """
  end

  def answer_two do
    """
    # Exercise 2: Sorting preserves list length property test

    test "sorting preserves list length" do
      if Code.ensure_loaded?(StreamData) do
        import StreamData
        check all list <- list_of(integer()) do
          sorted = MathOperations.sort_list(list)
          assert length(sorted) == length(list)
        end
      else
        lists = [
          [],
          [1],
          [3, 1, 4, 1, 5],
          [1, 1, 1, 1],
          [-5, -10, 0, 15],
          [100, -100, 0, 50, -25]
        ]

        Enum.each(lists, fn list ->
          sorted = MathOperations.sort_list(list)
          assert length(sorted) == length(list)
        end)
      end
    end
    """
  end

  def answer_three do
    """
    # Exercise 3: Double reverse returns original list property test

    test "double reverse returns original list" do
      if Code.ensure_loaded?(StreamData) do
        import StreamData
        check all list <- list_of(term()) do
          double_reversed = list |> MathOperations.reverse_list() |> MathOperations.reverse_list()
          assert double_reversed == list
        end
      else
        lists = [
          [],
          [1],
          [1, 2, 3],
          [:a, :b, :c, :d],
          ["hello", "world"],
          [1, :atom, "string", %{key: "value"}]
        ]

        Enum.each(lists, fn list ->
          double_reversed = list |> MathOperations.reverse_list() |> MathOperations.reverse_list()
          assert double_reversed == list
        end)
      end
    end
    """
  end

  def answer_four do
    """
    # Exercise 4: Base64 encode/decode roundtrip property test

    test "base64 encode/decode roundtrip" do
      if Code.ensure_loaded?(StreamData) do
        import StreamData
        check all string <- string(:printable) do
          encoded = StringOperations.encode_base64(string)
          assert {:ok, decoded} = StringOperations.decode_base64(encoded)
          assert decoded == string
        end
      else
        strings = [
          "",
          "hello",
          "Hello, World!",
          "🚀 Elixir rocks! 🎉",
          String.duplicate("a", 1000),
          "Special chars: !@#$%^&*()",
          "Newlines\\nand\\ttabs"
        ]

        Enum.each(strings, fn original ->
          encoded = StringOperations.encode_base64(original)
          assert {:ok, decoded} = StringOperations.decode_base64(encoded)
          assert decoded == original
        end)
      end
    end
    """
  end

  def answer_five do
    """
    # Exercise 5: Whitespace normalization is idempotent

    test "whitespace normalization is idempotent" do
      # This works without StreamData since it uses fixed examples
      strings = [
        "  hello   world  ",
        "no  extra   spaces",
        "\\t\\nspacing\\r\\n  issues\\t",
        "already normalized",
        "   multiple    spaces    everywhere   ",
        "",
        "   ",
        "single"
      ]

      Enum.each(strings, fn string ->
        normalized_once = StringOperations.normalize_whitespace(string)
        normalized_twice = StringOperations.normalize_whitespace(normalized_once)
                 assert normalized_once == normalized_twice,
                "Normalization should be idempotent for: \#{inspect(string)}"
      end)
    end
    """
  end

  def answer_six do
    """
    # Exercise 6: Factory produces valid users

    test "factory produces valid users" do
      user = Factory.build(:user)

      # Verify all required fields are present
      assert user.id != nil
      assert is_binary(user.name) and String.length(user.name) > 0
      assert is_binary(user.email) and String.contains?(user.email, "@")
      assert is_integer(user.age) and user.age >= 18
      assert user.role in [:user, :admin, :moderator]
      assert is_boolean(user.active)
      assert %DateTime{} = user.inserted_at
    end
    """
  end

  def answer_seven do
    """
    # Exercise 7: Factory with custom attributes

    test "factory with custom attributes" do
      custom_name = "Custom User"
      custom_age = 25
      user = Factory.build(:user, %{name: custom_name, age: custom_age})

      # Assert that custom attributes are applied
      assert user.name == custom_name
      assert user.age == custom_age

      # Assert other fields still have default values
      assert user.id != nil
      assert String.contains?(user.email, "@")
      assert user.role in [:user, :admin, :moderator]
      assert is_boolean(user.active)
    end
    """
  end

  def answer_eight do
    """
    # Exercise 8: Factory builds lists of items

    test "factory builds lists of items" do
      count = 5
      users = Factory.build_list(:user, count)

      # Check length
      assert length(users) == count

      # Check that all items are valid users
      Enum.each(users, fn user ->
        assert user.id != nil
        assert is_binary(user.name)
        assert String.contains?(user.email, "@")
        assert is_integer(user.age)
      end)

      # Check that they have unique IDs
      ids = Enum.map(users, & &1.id)
      unique_ids = Enum.uniq(ids)
      assert length(ids) == length(unique_ids), "All users should have unique IDs"
    end
    """
  end

  def answer_nine do
    """
    # Exercise 9: Counter operations are consistent

    test "counter operations are consistent" do
      {:ok, counter} = CounterServer.start_link(0)

      # Test basic operations
      assert CounterServer.get_value(counter) == 0

      CounterServer.increment(counter, 5)
      CounterServer.increment(counter, 3)
      # Give time for async operations
      Process.sleep(10)
      assert CounterServer.get_value(counter) == 8

      CounterServer.decrement(counter, 2)
      Process.sleep(10)
      assert CounterServer.get_value(counter) == 6

      CounterServer.reset(counter)
      Process.sleep(10)
      assert CounterServer.get_value(counter) == 0

      # Test sequence of operations
      operations = [
        {:inc, 10},
        {:inc, 5},
        {:dec, 3},
        {:inc, 2},
        {:dec, 4}
      ]

      expected_total = 10 + 5 - 3 + 2 - 4  # = 10

      Enum.each(operations, fn
        {:inc, amount} -> CounterServer.increment(counter, amount)
        {:dec, amount} -> CounterServer.decrement(counter, amount)
      end)

      Process.sleep(50)  # Wait for all operations
      assert CounterServer.get_value(counter) == expected_total
    end
    """
  end

  def answer_ten do
    """
    # Exercise 10: Bank account maintains balance invariants

    test "bank account maintains balance invariants" do
      account = BankAccount.new("acc123", 100)

      # Test successful operations
      account = BankAccount.deposit(account, 50)
      assert BankAccount.get_balance(account) == 150

      account = BankAccount.withdraw(account, 25)
      assert BankAccount.get_balance(account) == 125

      # Test overdraft protection
      result = BankAccount.withdraw(account, 200)
      assert result == {:error, :insufficient_funds}
      # Original account should be unchanged
      assert BankAccount.get_balance(account) == 125

      # Test transaction history consistency
      account = BankAccount.new("acc456", 0)
      transactions = [
        {:deposit, 100},
        {:deposit, 50},
        {:withdraw, 30},
        {:deposit, 25},
        {:withdraw, 45}
      ]

      final_account = Enum.reduce(transactions, account, fn
        {:deposit, amount}, acc -> BankAccount.deposit(acc, amount)
        {:withdraw, amount}, acc ->
          case BankAccount.withdraw(acc, amount) do
            %BankAccount{} = new_acc -> new_acc
            {:error, _} -> acc  # Keep original if withdrawal fails
          end
      end)

      expected_balance = 100 + 50 - 30 + 25 - 45  # = 100
      assert BankAccount.get_balance(final_account) == expected_balance

      # Verify transactions were recorded
      assert length(final_account.transactions) == 5
    end
    """
  end

  def answer_eleven do
    """
    # Exercise 11: User serialization roundtrip

    test "user serialization roundtrip" do
      original_user = Factory.build(:user)

      if Code.ensure_loaded?(Jason) do
        case UserSerializer.serialize_user(original_user) do
          {:ok, json} ->
            assert {:ok, deserialized} = UserSerializer.deserialize_user(json)

            # Check that key fields match (some fields might be transformed)
            assert deserialized.id == original_user.id
            assert deserialized.name == original_user.name
            assert deserialized.email == original_user.email
            assert deserialized.age == original_user.age
            assert deserialized.role == original_user.role

          {:error, reason} ->
            flunk "Serialization failed: \#{inspect(reason)}"
        end
      else
        # Skip if Jason not available
        assert true, "Skipping serialization test - Jason not available"
      end
    end
    """
  end

  def answer_twelve do
    """
    # Exercise 12: Build your own Product factory

    defmodule ProductFactory do
      def build(:product) do
        %{
          id: System.unique_integer([:positive]),
          name: "Product \#{:rand.uniform(1000)}",
          price: (:rand.uniform(10000) / 100) |> Float.round(2),  # $0.01 to $100.00
          category: Enum.random([:electronics, :clothing, :books, :home, :sports]),
          in_stock: :rand.uniform() > 0.2,  # 80% chance of being in stock
          created_at: DateTime.utc_now()
        }
      end

      def build(:product, attrs) do
        build(:product) |> Map.merge(attrs)
      end
    end

    test "product factory creates valid products" do
      product = ProductFactory.build(:product)

      assert product.id != nil
      assert is_binary(product.name) and String.length(product.name) > 0
      assert is_float(product.price) and product.price > 0
      assert product.category in [:electronics, :clothing, :books, :home, :sports]
      assert is_boolean(product.in_stock)
      assert %DateTime{} = product.created_at
    end

    test "product factory with custom attributes" do
      custom_product = ProductFactory.build(:product, %{
        name: "Custom Product",
        price: 99.99,
        category: :electronics,
        in_stock: false
      })

      assert custom_product.name == "Custom Product"
      assert custom_product.price == 99.99
      assert custom_product.category == :electronics
      assert custom_product.in_stock == false

      # Other fields should still have defaults
      assert custom_product.id != nil
      assert %DateTime{} = custom_product.created_at
    end
    """
  end
end
