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
IO.puts("\n📌 Example 2 – StreamData for property testing")

defmodule DayTwo.StreamDataExamples do
  @moduledoc """
  Using StreamData for property-based testing in Elixir.
  """

  def show_streamdata_setup do
    IO.puts("# Add to mix.exs dependencies:")
    IO.puts(~S'{:stream_data, "~> 0.5", only: :test}')
    IO.puts("\n# Basic StreamData test:")

    code =
      quote do
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
      end

    IO.puts(Macro.to_string(code))
  end

  def show_generators do
    IO.puts("# Common StreamData generators:")
    IO.puts("\n# Basic types")

    code =
      quote do
        integer()
        integer(1..100)
        float()
        boolean()
        string(:printable)
        binary()
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Collections")

    code =
      quote do
        list_of(integer())
        list_of(string(), length: 1..10)
        map_of(string(), integer())
        tuple({integer(), string()})
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Custom generators")

    code =
      quote do
        user_generator =
          gen all name <- string(:printable, min_length: 1),
                  age <- integer(1..120),
                  email <- string(:alphanumeric) do
            %{name: name, age: age, email: email <> "@example.com"}
          end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_practical_examples do
    IO.puts("# Practical property tests:")

    code =
      quote do
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
              assert Enum.all?(result1, &(&1 > 0))
              assert Enum.all?(result2, &(&1 > 0))
            end
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end
end

IO.puts("StreamData usage:")
DayTwo.StreamDataExamples.show_streamdata_setup()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Advanced property testing patterns")

defmodule DayTwo.AdvancedPropertyTesting do
  @moduledoc """
  Advanced patterns and techniques for property testing.
  """

  def show_shrinking_and_debugging do
    IO.puts("# Shrinking helps find minimal failing cases:")

    code =
      quote do
        property "string processing maintains certain properties" do
          check all original <- string(:printable, min_length: 1),
                    max_runs: 1000 do
            processed = MyModule.process_string(original)
            assert String.length(processed) <= String.length(original)
            assert String.valid?(processed)
          end
        end
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Custom generators for domain objects:")

    code =
      quote do
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
      end

    IO.puts(Macro.to_string(code))
  end

  def show_stateful_testing do
    IO.puts("# Stateful property testing for GenServers:")

    code =
      quote do
        defmodule CounterStatefulTest do
          use ExUnit.Case
          use ExUnitProperties

          property "counter operations maintain consistency" do
            check all operations <-
                    list_of(
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
      end

    IO.puts(Macro.to_string(code))
  end
end

DayTwo.AdvancedPropertyTesting.show_shrinking_and_debugging()
DayTwo.AdvancedPropertyTesting.show_stateful_testing()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – PropCheck for property testing")

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

defmodule DayTwo.PropertyTestExercises do
  @moduledoc """
  Run the tests with: mix test day_two/13_property_testing.exs
  or in IEx:
  iex -r day_two/13_property_testing.exs
  DayTwo.PropertyTestExercisesTest.test_design_sorting_properties/0
  DayTwo.PropertyTestExercisesTest.test_design_encoding_properties/0
  DayTwo.PropertyTestExercisesTest.test_design_custom_data_generator/0
  """

  @doc """
  Designs property tests for a custom sorting function.

  **Goal:** Instead of testing with a few example lists, define the essential
  properties that any correct sorting algorithm must have.

  **Function to Test:**
  `MySorter.sort(list)`

  **Task:**
  Return a list of strings, where each string is a key property of a
  correct sorting function. Examples include:
  - "The output list has the same length as the input list."
  - "Sorting a sorted list produces the same list (idempotency)."
  - "All elements from the input list are present in the output list."
  """
  @spec design_sorting_properties() :: [binary()]
  def design_sorting_properties do
    # List the key properties that a sorting function must always satisfy.
    # Return a list of strings describing these properties.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs property tests for a simple encoding/decoding module.

  **Goal:** Verify that a pair of `encode/1` and `decode/1` functions are
  inverses of each other. This is a classic "round-trip" property.

  **Functions to Test:**
  `Codec.encode(string)` and `Codec.decode(encoded_string)`

  **Task:**
  Return a map that describes the property test:
  - `:property_name`: A string naming the property (e.g., "encode/decode roundtrip").
  - `:generator`: A string representing the `StreamData` generator for a
    printable string (e.g., `string(:printable)`).
  - `:assertion`: A string showing the core assertion of the test, which
    checks that `decode(encode(original_string))` equals `original_string`.
  """
  @spec design_encoding_properties() :: map()
  def design_encoding_properties do
    # Design a round-trip property test for an encoder/decoder.
    # Return a map with :property_name, :generator, and :assertion.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a custom `StreamData` generator for a domain-specific struct.

  **Goal:** Learn to create complex data generators that produce valid
  structs for your application's domain models.

  **Struct to Generate:**
  ```elixir
  defmodule User do
    defstruct [:id, :email, :age, :role]
  end
  ```

  **Requirements:**
  - `id` should be a positive integer.
  - `email` should be a string that looks like a valid email.
  - `age` should be an integer between 18 and 99.
  - `role` should be one of the atoms `:guest`, `:member`, or `:admin`.

  **Task:**
  Return a string containing the complete definition of a `StreamData`
  generator function named `user_generator/0` that produces valid `User` structs.
  """
  @spec design_custom_data_generator() :: binary()
  def design_custom_data_generator do
    # Write a custom StreamData generator for a User struct.
    # Return the generator definition as a string.
    nil  # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.PropertyTestExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.PropertyTestExercises, as: EX

  test "design_sorting_properties/0 returns key sorting properties" do
    properties = EX.design_sorting_properties()
    assert is_list(properties)
    assert Enum.any?(properties, &String.contains?(&1, "length"))
    assert Enum.any?(properties, &String.contains?(&1, "idempotent"))
    assert Enum.any?(properties, &String.contains?(&1, "elements"))
  end

  test "design_encoding_properties/0 describes a round-trip test" do
    design = EX.design_encoding_properties()
    assert is_map(design)
    assert Map.has_key?(design, :property_name)
    assert Map.has_key?(design, :generator)
    assert Map.has_key?(design, :assertion)
    assert String.contains?(design.assertion, "decode(encode(")
  end

  test "design_custom_data_generator/0 returns a valid generator string" do
    generator_string = EX.design_custom_data_generator()
    assert is_binary(generator_string)
    assert String.contains?(generator_string, "def user_generator")
    assert String.contains?(generator_string, "gen all")
    assert String.contains?(generator_string, "integer(1..")
    assert String.contains?(generator_string, "member_of([:guest, :member, :admin])")
    assert String.contains?(generator_string, "%User{")
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      [
        "The output list has the same length as the input list.",
        "Sorting is idempotent (sorting a sorted list doesn't change it).",
        "The sorted list contains the exact same elements as the original.",
        "Every element in the output is less than or equal to the element that follows it."
      ]
    end
  end

  def answer_two do
    quote do
      %{
        property_name: "encode/decode functions are inverses (round-trip)",
        generator: "string(:printable)",
        assertion: "assert Codec.decode(Codec.encode(original)) == original"
      }
    end
  end

  def answer_three do
    quote do
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
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. Properties of Sorting
#{Macro.to_string(DayTwo.Answers.answer_one())}
# This approach forces you to think about the definition of "sorted" rather
# than just a few examples. A property-based test would check these invariants
# against hundreds of randomly generated lists (empty, long, reversed, with
# duplicates, etc.), providing much higher confidence than a simple example.

# 2. Round-trip Property for Encoding
#{Macro.to_string(DayTwo.Answers.answer_two())}
# This is one of the most common and powerful uses of property testing. It's
# perfect for testing serialization (JSON, binary, etc.), data conversion, or
# any pair of functions that are supposed to be inverses of each other. The
# test ensures that no data is lost or malformed during the two-way process.

# 3. Custom Data Generator
#{Macro.to_string(DayTwo.Answers.answer_three())}
# As your application grows, you'll need to test functions that take your own
# custom structs. Building generators for them is key. This composed generator
# combines simpler generators (`integer`, `string`, `member_of`) to build a
# complex, valid `User` struct every time, making your property tests clean
# and focused on the logic, not on data setup.
""")
