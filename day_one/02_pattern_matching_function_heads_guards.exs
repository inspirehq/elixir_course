# Day 1 – Pattern Matching in Function Heads & Guards
#
# Run with:
#     mix run day_one/02_pattern_matching_function_heads_guards.exs
#
# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 1 – Multiple heads for tuple shapes")

defmodule Shape do
  # Matches a two-element tuple representing the sides of a rectangle.
  def area({w, h}) when is_number(w) and is_number(h), do: w * h

  # Matches a single number (radius) for a circle.
  def area(r) when is_number(r), do: :math.pi() * r * r
end

IO.inspect(Shape.area({3, 4}), label: "rectangle area")
IO.inspect(Shape.area(3),      label: "circle area")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Guards for even/odd")

defmodule Parity do
  def classify(n) when is_integer(n) and rem(n, 2) == 0, do: :even
  def classify(n) when is_integer(n) and rem(n, 2) == 1, do: :odd
end

for n <- 1..4, do: IO.puts("#{n} → #{Parity.classify(n)}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Fallback clause using _ pattern")

defmodule Greeting do
  def hello("es"), do: "¡Hola!"
  def hello("fr"), do: "Bonjour!"
  def hello(_),    do: "Hello!"   # fallback
end

IO.inspect(Greeting.hello("es"))
IO.inspect(Greeting.hello("de"))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Pattern matching on maps with required keys")

defmodule Accounts do
  # Accept only maps that *at least* contain :id and :email.
  def extract_email(%{id: id, email: email}) when is_integer(id), do: {:ok, email}
  def extract_email(_), do: {:error, :invalid}
end

IO.inspect(Accounts.extract_email(%{id: 1, email: "a@b.com"}))
IO.inspect(Accounts.extract_email(%{email: "a@b.com"}))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world example: parsing HTTP status")

# Imagine we receive HTTP responses as `%HTTPoison.Response{}` structs.
# We want to convert them into one of three atoms: :ok, :client_error, :server_error.

defmodule HttpHelpers do
  def classify(%{status_code: code}) when code in 200..299, do: :ok
  def classify(%{status_code: code}) when code in 400..499, do: :client_error
  def classify(%{status_code: code}) when code in 500..599, do: :server_error
  def classify(_), do: :unknown
end

examples = [
  %{status_code: 204},
  %{status_code: 404},
  %{status_code: 503},
  :not_a_response
]

Enum.each(examples, fn ex ->
  IO.inspect({ex, HttpHelpers.classify(ex)})
end)

defmodule DayOne.PatternMatchingExercises do
  @moduledoc """
  Run the tests with:

    mix test day_one/02_pattern_matching_function_heads_guards.exs

  or in IEx:
    iex -r day_one/02_pattern_matching_function_heads_guards.exs
    DayOne.PatternMatchingExercisesTest.test_fizzbuzz/0
    DayOne.PatternMatchingExercisesTest.test_safe_head/0
    DayOne.PatternMatchingExercisesTest.test_sign/0
  """

  @spec fizzbuzz(integer()) :: :fizz | :buzz | :fizzbuzz | integer()
  def fizzbuzz(_n) do
    # Implement a `FizzBuzz.fizzbuzz/1` function using multiple function heads
    # and guards that returns :fizz (divisible by 3), :buzz (5), :fizzbuzz (15)
    # or the number itself.
    # Hint:
    #   FizzBuzz.fizzbuzz(15) ⇒ :fizzbuzz
    #   FizzBuzz.fizzbuzz(7)  ⇒ 7
    :not_implemented
  end

  @spec safe_head(list()) :: {:ok, any()} | :error
  def safe_head(_list) do
    # Write a `safe_head/1` function with two heads that returns {:ok, h} for a
    # non-empty list and :error for an empty list.
    # Hint:
    #   safe_head([1, 2]) ⇒ {:ok, 1}
    #   safe_head([])     ⇒ :error
    :not_implemented
  end

  @spec sign(number()) :: :positive | :negative | :zero
  def sign(_n) do
    # Create a `sign/1` function that returns :positive, :negative
    # or :zero using guards `n > 0`, `n < 0`, `n == 0`.
    # Hint:
    #   sign(10) ⇒ :positive
    #   sign(-2) ⇒ :negative
    #   sign(0)  ⇒ :zero
    :not_implemented
  end
end

# --------------------------- Exercise Test Suite ---------------------------
ExUnit.start()

defmodule DayOne.PatternMatchingExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.PatternMatchingExercises, as: EX

  test "fizzbuzz/1 works for common cases" do
    assert EX.fizzbuzz(3)  == :fizz
    assert EX.fizzbuzz(5)  == :buzz
    assert EX.fizzbuzz(15) == :fizzbuzz
    assert EX.fizzbuzz(7)  == 7
  end

  test "safe_head/1 returns tuple or error" do
    assert EX.safe_head([:a, :b]) == {:ok, :a}
    assert EX.safe_head([]) == :error
  end

  test "sign/1 classifies numbers" do
    assert EX.sign(10)  == :positive
    assert EX.sign(-2)  == :negative
    assert EX.sign(0)   == :zero
  end
end

"""
🔑 ANSWERS & EXPLANATIONS

# 1. fizzbuzz/1
defmodule FizzBuzzSolution do
  def fizzbuzz(n) when rem(n, 15) == 0, do: :fizzbuzz
  def fizzbuzz(n) when rem(n, 3)  == 0, do: :fizz
  def fizzbuzz(n) when rem(n, 5)  == 0, do: :buzz
  def fizzbuzz(n),                 do: n
end
#  Multiple heads + guards clearly encode each rule.

# 2. safe_head/1
safe_head_solution = fn
  [h | _] -> {:ok, h}
  []      -> :error
end
IO.inspect(safe_head_solution.([1, 2]))
#  Pattern matching on list structure avoids runtime errors (no hd/1 crash).

# 3. sign/1 – classify a number using guards
defmodule SignSolution do
  def sign(n) when n > 0, do: :positive
  def sign(n) when n < 0, do: :negative
  def sign(0),           do: :zero
end
IO.inspect Enum.map([-2, 0, 5], &SignSolution.sign/1)
#  Guards let us express the three cases succinctly.
"""
