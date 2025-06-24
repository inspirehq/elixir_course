# Day 2 – Options for Property Testing
#
# Run with `mix run elixir_course/day_two/13_property_testing.exs`
# or inside IEx with:
#     iex -S mix
#     c "elixir_course/day_two/13_property_testing.exs"
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
IO.puts("\n📌 Example 2 – StreamData for property testing")

defmodule DayTwo.StreamDataExamples do
  @moduledoc """
  Using StreamData for property-based testing in Elixir.
  """

  def show_streamdata_setup do
    """
    # Add to mix.exs dependencies:
    {:stream_data, "~> 0.5", only: :test}

    # Basic StreamData test:
    defmodule MathTest do
      use ExUnit.Case
      use ExUnitProperties

      property "addition is commutative" do
        check all a <- integer(),
                  b <- integer() do
          assert Math.add(a, b) == Math.add(b, a)
        end
      end

      property "string reverse is involutive" do
        check all s <- string(:printable) do
          assert s |> String.reverse() |> String.reverse() == s
        end
      end
    end
    """
  end

  def show_generators do
    """
    # Common StreamData generators:

    # Basic types
    integer()                    # Any integer
    integer(1..100)              # Integer in range
    float()                      # Any float
    boolean()                    # true or false
    string(:printable)           # Printable strings
    binary()                     # Random binary data

    # Collections
    list_of(integer())           # List of integers
    list_of(string(), length: 1..10)  # Constrained list
    map_of(string(), integer())  # Map with string keys, int values
    tuple({integer(), string()}) # Fixed-size tuple

    # Custom generators
    user_generator =
      gen all name <- string(:printable, min_length: 1),
              age <- integer(1..120),
              email <- string(:alphanumeric) do
        %{name: name, age: age, email: email <> "@example.com"}
      end
    """
  end

  def show_practical_examples do
    """
    # Practical property tests:
    defmodule ListPropertiesTest do
      use ExUnit.Case
      use ExUnitProperties

      property "sorting preserves length" do
        check all list <- list_of(integer()) do
          sorted = Enum.sort(list)
          assert length(sorted) == length(list)
        end
      end

      property "sorting is idempotent" do
        check all list <- list_of(integer()) do
          sorted_once = Enum.sort(list)
          sorted_twice = Enum.sort(sorted_once)
          assert sorted_once == sorted_twice
        end
      end

      property "map then filter vs filter then map" do
        check all list <- list_of(integer()),
                  fun <- member_of([&(&1 * 2), &(&1 + 1), &abs/1]) do

          result1 = list |> Enum.map(fun) |> Enum.filter(&(&1 > 0))
          result2 = list |> Enum.filter(&(fun.(&1) > 0)) |> Enum.map(fun)

          # They might not be equal, but should have same positive elements
          assert Enum.all?(result1, &(&1 > 0))
          assert Enum.all?(result2, &(&1 > 0))
        end
      end
    end
    """
  end
end

IO.puts("StreamData usage:")
IO.puts(DayTwo.StreamDataExamples.show_streamdata_setup())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Advanced property testing patterns")

defmodule DayTwo.AdvancedPropertyTesting do
  @moduledoc """
  Advanced patterns and techniques for property testing.
  """

  def show_shrinking_and_debugging do
    """
    # Shrinking helps find minimal failing cases:
    property "string processing maintains certain properties" do
      check all original <- string(:printable, min_length: 1),
                max_runs: 1000 do  # Run more tests

        processed = MyModule.process_string(original)

        # If this fails, StreamData will shrink to smallest failing input
        assert String.length(processed) <= String.length(original)
        assert String.valid?(processed)
      end
    end

    # Custom generators for domain objects:
    def valid_email_generator do
      gen all local <- string(:alphanumeric, min_length: 1),
              domain <- string(:alphanumeric, min_length: 1),
              tld <- member_of(["com", "org", "net", "edu"]) do
        "#{local}@#{domain}.#{tld}"
      end
    end

    property "email validation works correctly" do
      check all email <- valid_email_generator() do
        assert EmailValidator.valid?(email) == true
      end
    end
    """
  end

  def show_stateful_testing do
    """
    # Stateful property testing for GenServers:
    defmodule CounterStatefulTest do
      use ExUnit.Case
      use ExUnitProperties

      property "counter operations maintain consistency" do
        check all operations <- list_of(
                    one_of([
                      {:inc, integer(1..10)},
                      {:dec, integer(1..10)},
                      :reset
                    ]),
                    max_length: 50
                  ) do

          {:ok, counter} = Counter.start_link(0)

          expected_value = simulate_operations(operations, 0)
          actual_value = apply_operations(counter, operations)

          assert actual_value == expected_value
        end
      end

      defp simulate_operations([], acc), do: acc
      defp simulate_operations([{:inc, n} | rest], acc), do: simulate_operations(rest, acc + n)
      defp simulate_operations([{:dec, n} | rest], acc), do: simulate_operations(rest, acc - n)
      defp simulate_operations([:reset | rest], _acc), do: simulate_operations(rest, 0)

      defp apply_operations(counter, operations) do
        Enum.each(operations, fn
          {:inc, n} -> Counter.increment(counter, n)
          {:dec, n} -> Counter.decrement(counter, n)
          :reset -> Counter.reset(counter)
        end)

        Counter.value(counter)
      end
    end
    """
  end
end

IO.puts("Advanced patterns:")
IO.puts(DayTwo.AdvancedPropertyTesting.show_shrinking_and_debugging())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – PropCheck and QuickCheck integration")

defmodule DayTwo.PropCheckExamples do
  @moduledoc """
  Using PropCheck for more advanced property testing features.
  """

  def show_propcheck_setup do
    """
    # Add to mix.exs (requires Erlang/OTP QuickCheck):
    {:propcheck, "~> 1.4", only: :test}

    # PropCheck offers more features than StreamData:
    defmodule AdvancedPropertyTest do
      use ExUnit.Case
      use PropCheck

      property "complex data structure properties" do
        forall data <- complex_data_generator() do
          result = process_data(data)

          # Multiple assertions with better error reporting
          aggregate(classify_data(data),
            conjunction([
              {:length_preserved, length(result) == length(data)},
              {:type_consistency, all_same_type?(result)},
              {:ordering_maintained, is_sorted?(result)}
            ])
          )
        end
      end

      # Targeted testing with preconditions
      property "division properties" do
        forall {a, b} <- {number(), non_zero_number()} do
          implies(b != 0,
            begin
              result = a / b
              abs(result * b - a) < 0.0001
            end
          )
        end
      end
    end
    """
  end

  def show_model_based_testing do
    """
    # Model-based testing with PropCheck:
    defmodule BankAccountModelTest do
      use PropCheck
      use PropCheck.StateM

      # Define the model state
      def initial_state, do: %{balance: 0, transactions: []}

      # Define commands
      def command(_state) do
        oneof([
          {:call, BankAccount, :deposit, [pos_integer()]},
          {:call, BankAccount, :withdraw, [pos_integer()]},
          {:call, BankAccount, :get_balance, []}
        ])
      end

      # Define state transitions
      def next_state(state, _result, {:call, BankAccount, :deposit, [amount]}) do
        %{state |
          balance: state.balance + amount,
          transactions: [{:deposit, amount} | state.transactions]
        }
      end

      def next_state(state, _result, {:call, BankAccount, :withdraw, [amount]}) do
        new_balance = max(0, state.balance - amount)
        %{state |
          balance: new_balance,
          transactions: [{:withdraw, amount} | state.transactions]
        }
      end

      # Define postconditions
      def postcondition(state, {:call, BankAccount, :get_balance, []}, result) do
        result == state.balance
      end

      # Run the model test
      property "bank account model correctness" do
        forall commands <- commands(__MODULE__) do
          {history, state, result} = run_commands(__MODULE__, commands)

          aggregate(command_names(commands),
            result == :ok
          )
        end
      end
    end
    """
  end
end

IO.puts("PropCheck features:")
IO.puts(DayTwo.PropCheckExamples.show_propcheck_setup())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Testing a JSON API with properties")

defmodule DayTwo.APIPropertyTesting do
  @moduledoc """
  Real-world example: Property testing a JSON API for data consistency.
  """

  def demonstrate_api_testing_flow do
    flow_steps = [
      "🔧 Generate valid API payloads automatically",
      "📡 Send requests with property-based data",
      "✅ Verify response structure and constraints",
      "🔄 Test round-trip serialization properties",
      "🚫 Validate error handling with invalid data",
      "📊 Collect statistics on test coverage",
      "🐛 Shrink failing cases to minimal examples"
    ]

    IO.puts("\nAPI property testing flow:")
    Enum.each(flow_steps, fn step ->
      IO.puts("  #{step}")
    end)
  end

  def show_api_property_benefits do
    benefits = [
      "Discovers edge cases in JSON parsing",
      "Validates API contracts automatically",
      "Tests data type constraints thoroughly",
      "Ensures consistent error responses",
      "Verifies serialization round-trips",
      "Checks field validation rules",
      "Finds boundary condition bugs"
    ]

    IO.puts("\nProperty testing benefits for APIs:")
    Enum.each(benefits, fn benefit ->
      IO.puts("  • #{benefit}")
    end)
  end
end

DayTwo.APIPropertyTesting.demonstrate_api_testing_flow()
DayTwo.APIPropertyTesting.show_api_property_benefits()

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Create property tests for a URL parsing/encoding library that verify
#    round-trip consistency and handle edge cases in URLs.
# 2. Build property tests for a shopping cart that verify invariants like
#    "total price equals sum of item prices" under various operations.
# 3. (Challenge) Design a stateful property test for a chat room GenServer
#    that verifies message ordering and user state consistency.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. URL parsing property tests
defmodule URLPropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  property "URL encoding/decoding round trip" do
    check all url_string <- string(:printable) do
      encoded = URL.encode(url_string)
      decoded = URL.decode(encoded)
      assert decoded == url_string
    end
  end

  property "valid URLs parse successfully" do
    check all url <- valid_url_generator() do
      assert {:ok, parsed} = URL.parse(url)
      assert is_map(parsed)
      assert Map.has_key?(parsed, :scheme)
      assert Map.has_key?(parsed, :host)
    end
  end

  def valid_url_generator do
    gen all scheme <- member_of(["http", "https", "ftp"]),
            host <- string(:alphanumeric, min_length: 1),
            path <- string(:printable) do
      "#{scheme}://#{host}.com/#{path}"
    end
  end
end

# 2. Shopping cart property tests
defmodule CartPropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  property "cart total equals sum of item prices" do
    check all items <- list_of(item_generator(), max_length: 20) do
      cart = Cart.new()
      final_cart = Enum.reduce(items, cart, &Cart.add_item(&2, &1))

      expected_total = items |> Enum.map(&(&1.price * &1.quantity)) |> Enum.sum()
      actual_total = Cart.total(final_cart)

      assert_in_delta actual_total, expected_total, 0.01
    end
  end

  def item_generator do
    gen all name <- string(:alphanumeric, min_length: 1),
            price <- float(min: 0.01, max: 1000.0),
            quantity <- integer(1..10) do
      %{name: name, price: price, quantity: quantity}
    end
  end
end

# 3. Chat room stateful testing
defmodule ChatRoomStatefulTest do
  use ExUnit.Case
  use ExUnitProperties

  property "chat room maintains message ordering" do
    check all commands <- list_of(chat_command_generator(), max_length: 30) do
      {:ok, room} = ChatRoom.start_link()

      {messages, users} = execute_commands(room, commands)

      # Messages should be in chronological order
      timestamps = Enum.map(messages, & &1.timestamp)
      assert timestamps == Enum.sort(timestamps)

      # All users should be tracked correctly
      assert MapSet.size(users) <= 10  # Max concurrent users
    end
  end

  def chat_command_generator do
    user_id = integer(1..5)

    one_of([
      {:join, user_id},
      {:leave, user_id},
      {:send_message, user_id, string(:printable, min_length: 1)}
    ])
  end
end

# Benefits: Comprehensive coverage, automatic edge case discovery, regression prevention
"""
