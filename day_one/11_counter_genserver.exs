# Day 1 – Guided Exercise: Building a Simple Counter GenServer
#
# This script can be run with:
#     mix run day_one/11_counter_genserver.exs
# or inside IEx with:
#     iex -r day_one/11_counter_genserver.exs
#
#
# Instructions:
#   1. Review the implemented code to understand GenServer patterns
#   2. Modify the functions to experiment with different approaches
#   3. Run the tests to verify your understanding
# ────────────────────────────────────────────────────────────────

IO.puts("\n🎯 Exercise Prompt – Review and understand the GenServer patterns!")

defmodule CounterExercise do
  @moduledoc """
  A GenServer that keeps an integer count in its state.

  Public API requirements:
  • start_link/1 – initial count (default 0)
  • inc/1 – increment by n (default 1)
  • value/0 – synchronous call returning the current count.
  """

  use GenServer

  # ── Public API ───────────────────────────────────────────────
  def start_link(initial \\ 0) do
    GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def inc(n \\ 1) do
    GenServer.cast(__MODULE__, {:inc, n})
  end

  def value, do: GenServer.call(__MODULE__, :value)

  # ── Callbacks ────────────────────────────────────────────────
  @impl true
  def init(initial), do: {:ok, initial}

  @impl true
  def handle_cast({:inc, n}, state) do
    {:noreply, state + n}
  end

  @impl true
  def handle_call(:value, _from, state), do: {:reply, state, state}

  # ── Convenience for manual demo ─────────────────────────────
  def manual_demo do
    {:ok, _} = start_link(10)
    inc()
    inc(5)
    IO.inspect(value(), label: "counter value")
  end
end

# Quick assertion-style tests so students know the implementation works
{:ok, _} = CounterExercise.start_link(2)
CounterExercise.inc()
CounterExercise.inc(3)

expected = 6
actual   = CounterExercise.value()
if expected == actual do
  IO.puts("✅  All good! Counter is #{actual} as expected.")
else
  IO.puts("❌  Expected #{expected}, got #{actual}")
end

defmodule DayOne.CounterExercises do
  @moduledoc """
  Run the tests with: mix test day_one/11_counter_genserver.exs
  or in IEx:
  iex -r day_one/11_counter_genserver.exs
  DayOne.CounterExercisesTest.test_basic_counter/0
  DayOne.CounterExercisesTest.test_counter_with_reset/0
  DayOne.CounterExercisesTest.test_counter_boundaries/0
  """

  @spec build_basic_counter(integer()) :: integer()
  def build_basic_counter(initial) do
    #   Build a counter that starts at the given initial value,
    #   increment it by 1 three times, then return the final value.
    #   Use the CounterExercise module above.
    #   Example: build_basic_counter(5) should return 8
    #   Hint: Use a unique name to avoid conflicts in tests (provided below)
    _name = :"counter_#{:rand.uniform(10000)}"
    initial + 3  # TODO: Implement using CounterExercise GenServer
  end

  @spec build_counter_with_reset() :: :ok
  def build_counter_with_reset do
    #   Extend the CounterExercise to support a reset/0 function that sets
    #   the counter back to 0. Demonstrate by incrementing, resetting,
    #   and verifying the counter is 0. Return :ok when complete. Use the
    #   CounterWithReset module provided.
    :ok  # TODO: Implement counter with reset functionality
  end

  @spec test_counter_boundaries() :: :ok
  def test_counter_boundaries do
    #   Test edge cases: increment by 0, increment by negative numbers,
    #   and very large increments. Return :ok if all behave as expected.
    :ok  # TODO: Implement boundary testing for counter
  end
end

# Extended counter with reset functionality for exercises
defmodule CounterWithReset do
  use GenServer

  # Public API
  def start_link(initial \\ 0), do: GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  def inc(n \\ 1), do: GenServer.cast(__MODULE__, {:inc, n})
  def reset(), do: GenServer.cast(__MODULE__, :reset)
  def value(), do: GenServer.call(__MODULE__, :value)

  # Callbacks
  @impl true
  def init(initial), do: {:ok, initial}

  @impl true
  def handle_cast({:inc, n}, state), do: {:noreply, state + n}

  @impl true
  def handle_cast(:reset, _state), do: {:noreply, 0}

  @impl true
  def handle_call(:value, _from, state), do: {:reply, state, state}
end

ExUnit.start()

defmodule DayOne.CounterExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.CounterExercises, as: EX

  test "build_basic_counter/1 increments counter from initial value" do
    assert EX.build_basic_counter(5) == 8
    assert EX.build_basic_counter(0) == 3
    assert EX.build_basic_counter(-2) == 1
  end

  test "build_counter_with_reset/0 demonstrates reset functionality" do
    assert EX.build_counter_with_reset() == :ok
  end

  test "test_counter_boundaries/0 handles edge cases properly" do
    assert EX.test_counter_boundaries() == :ok
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def build_basic_counter(initial) do
        name = :"counter_#{System.unique_integer()}"
        {:ok, _pid} = GenServer.start_link(CounterExercise, initial, name: name)
        GenServer.cast(name, {:inc, 1})
        GenServer.cast(name, {:inc, 1})
        GenServer.cast(name, {:inc, 1})
        GenServer.call(name, :value)
      end
    end
  end

  def answer_two do
    quote do
      # The implementation is in the `CounterWithReset` module provided.
      # This function demonstrates its use.
      def build_counter_with_reset do
        {:ok, _pid} = CounterWithReset.start_link()
        CounterWithReset.inc(10)
        assert CounterWithReset.value() == 10
        CounterWithReset.reset()
        assert CounterWithReset.value() == 0
        :ok
      end
    end
  end

  def answer_three do
    quote do
      def test_counter_boundaries do
        name = :"boundary_counter_#{System.unique_integer()}"
        {:ok, _pid} = GenServer.start_link(CounterExercise, 100, name: name)

        # Test increment by 0
        CounterExercise.inc(0) # Using the public API
        assert GenServer.call(name, :value) == 100

        # Test negative increment
        CounterExercise.inc(-20)
        assert GenServer.call(name, :value) == 80

        # Test large increment
        CounterExercise.inc(1_000_000)
        assert GenServer.call(name, :value) == 1_000_080
        :ok
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. build_basic_counter/1
#{Macro.to_string(DayOne.Answers.answer_one())}
#  This solution correctly uses a unique name for each GenServer instance to
#  prevent conflicts during concurrent tests. It then follows the standard
#  lifecycle: start the server, send messages to it, and then query the final
#  state.

# 2. build_counter_with_reset/0
#{Macro.to_string(DayOne.Answers.answer_two())}
#  The key part of this exercise is implementing the `:reset` `handle_cast`
#  callback in the `CounterWithReset` module. It simply ignores the current
#  state and returns `{:noreply, 0}`, effectively resetting the counter. This
#  demonstrates how a GenServer can completely replace its state.

# 3. test_counter_boundaries/0
#{Macro.to_string(DayOne.Answers.answer_three())}
#  This shows that the logic inside a GenServer is just standard Elixir code.
#  The `+` operator in the `handle_cast` callback handles positive, negative,
#  and zero values correctly, so the GenServer's state transitions are always
#  predictable.
""")
