# Day 1 – The `Enum` Standard Library
#
# This script can be run with:
#     mix run day_one/04_enum_library.exs
# or inside IEx with:
#     iex -r day_one/04_enum_library.exs
#
# `Enum` provides a rich set of functions for working with *enumerables* – data
# structures that implement the `Enumerable` protocol (lists, maps, ranges,
# streams…). Below are examples showcasing the most common patterns.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Enum.map/2 to transform a list")

IO.inspect(Enum.map([1, 2, 3], &(&1 * 10)))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Enum.filter/2 to keep even numbers")

IO.inspect(Enum.filter(1..10, &(rem(&1, 2) == 0)))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Enum.reduce/3 to compute a product")

product = Enum.reduce(1..5, 1, &*/2)
IO.inspect(product, label: "factorial-ish")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Enum.group_by/3 to categorize structs")

defmodule Pet do
  defstruct [:name, :type]

  def demo do
    pets = [
      %__MODULE__{name: "Milo",  type: :dog},
      %__MODULE__{name: "Luna",  type: :cat},
      %__MODULE__{name: "Otto",  type: :dog}
    ]

    IO.inspect(Enum.group_by(pets, & &1.type))
  end
end

# Run the demo
Pet.demo()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Enum.into/2 to convert a range into a map")

IO.inspect(Enum.into(1..3, %{}, fn n -> {n, n * n} end))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 6 – Real-world: aggregating orders")

orders = [
  %{id: 1, customer: "Ada",    total_cents: 4_500, status: :shipped},
  %{id: 2, customer: "Grace",  total_cents: 1_500, status: :processing},
  %{id: 3, customer: "Ada",    total_cents: 3_000, status: :shipped},
  %{id: 4, customer: "Linus",  total_cents: 2_000, status: :cancelled}
]

shipment_totals =
  orders
  |> Enum.filter(& &1.status == :shipped)
  |> Enum.group_by(& &1.customer)
  |> Enum.map(fn {customer, ords} ->
    total = Enum.reduce(ords, 0, fn o, acc -> acc + o.total_cents end)
    {customer, total / 100}
  end)
  |> Enum.into(%{})

IO.inspect(shipment_totals, label: "Shipped totals by customer ($)")

defmodule DayOne.EnumExercises do
  @moduledoc """
  Run the tests with: mix test day_one/04_enum_library.exs
  or in IEx:
  iex -r day_one/04_enum_library.exs
  DayOne.EnumExercisesTest.test_sum_of_squares/0
  DayOne.EnumExercisesTest.test_my_max/0
  DayOne.EnumExercisesTest.test_word_frequencies/0
  """

  @spec sum_of_squares(Range.t()) :: integer()
  def sum_of_squares(range) do
    #   Use Enum.reduce/3 to compute the sum of squares for the given range.
    #   Example: sum_of_squares(1..3) => 1² + 2² + 3² = 14
    #   Hint: The accumulator starts at 0, and each iteration adds n²
    0 # TODO: Implement sum of squares using Enum.reduce/3
  end

  @spec my_max([integer()]) :: integer() | nil
  def my_max(_list) do
    #   Implement Enum.max/1 using reduce (no Enum.max/1 allowed!).
    #   Return the maximum value in the list, or nil for empty list.
    #   Example: my_max([3, 7, 2]) => 7
    #   Example: my_max([]) => nil
    #   Hint: Pattern match [head | tail] and use head as initial accumulator
    nil  # TODO: Implement max finding using Enum.reduce/3
  end

  @spec word_frequencies(String.t()) :: map()
  def word_frequencies(_sentence) do
    #   Count word frequencies in the given sentence.
    #   Return a map like %{"hello" => 2, "world" => 1} using Enum functions only.
    #   Example: word_frequencies("hello world hello") => %{"hello" => 2, "world" => 1}
    #   Hint: Use String.split/1, then Enum.reduce/3 with Map.update/4
    %{}  # TODO: Implement word frequency counting using Enum.reduce/3
  end
end

ExUnit.start()

defmodule DayOne.EnumExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.EnumExercises, as: EX

  test "sum_of_squares/1 computes sum of squares correctly" do
    assert EX.sum_of_squares(1..3) == 14  # 1 + 4 + 9
    assert EX.sum_of_squares(1..10) == 385  # 1² + 2² + ... + 10²
    assert EX.sum_of_squares(1..1) == 1
    assert EX.sum_of_squares(0..0) == 0
  end

  test "my_max/1 finds maximum value without using Enum.max" do
    assert EX.my_max([3, 7, 2]) == 7
    assert EX.my_max([1]) == 1
    assert EX.my_max([-5, -1, -10]) == -1
    assert EX.my_max([]) == nil
  end

  test "word_frequencies/1 counts word occurrences" do
    assert EX.word_frequencies("hello world hello") == %{"hello" => 2, "world" => 1}
    assert EX.word_frequencies("the quick brown fox jumps over the lazy dog") ==
      %{"the" => 2, "quick" => 1, "brown" => 1, "fox" => 1, "jumps" => 1,
        "over" => 1, "lazy" => 1, "dog" => 1}
    assert EX.word_frequencies("") == %{}
    assert EX.word_frequencies("single") == %{"single" => 1}
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def sum_of_squares(range) do
        Enum.reduce(range, 0, fn n, acc -> acc + n * n end)
      end
    end
  end

  def answer_two do
    quote do
      def my_max([]), do: nil
      def my_max([head | tail]) do
        Enum.reduce(tail, head, fn x, acc ->
          if x > acc, do: x, else: acc
        end)
      end
    end
  end

  def answer_three do
    quote do
      def word_frequencies(sentence) do
        sentence
        |> String.split(" ", trim: true)
        |> Enum.reduce(%{}, fn
          "", acc -> acc
          word, acc -> Map.update(acc, word, 1, &(&1 + 1))
        end)
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. sum_of_squares/1
#{Macro.to_string(DayOne.Answers.answer_one())}
#  This is a classic use of `Enum.reduce/3`. The accumulator starts at `0`,
#  and for each number `n` in the range, we add `n * n` to the accumulator,
#  producing a final sum.

# 2. my_max/1
#{Macro.to_string(DayOne.Answers.answer_two())}
#  This shows how to implement a common `Enum` function from scratch. By using
#  the first element of the list as the initial accumulator, we can then reduce
#  over the rest of the list, comparing each element to the current max.

# 3. word_frequencies/1
#{Macro.to_string(DayOne.Answers.answer_three())}
#  This is a powerful pipeline that demonstrates multiple `Enum` concepts. It
#  splits the string into words, then uses `reduce` with a map as the accumulator.
#  `Map.update/4` is perfect here: it either inserts a key with a default value
#  (1) or applies a function to update the existing value.
""")
