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

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Implement a `FizzBuzz.fizzbuzz/1` function using multiple function heads
#    and guards that returns :fizz (divisible by 3), :buzz (5), :fizzbuzz (15)
#    or the number itself.
# 2. Write a `safe_head/1` function with two heads that returns {:ok, h} for a
#    non-empty list and :error for an empty list.
# 3. (Challenge) Create a `sign/1` function that returns :positive, :negative
#    or :zero using guards `n > 0`, `n < 0`, `n == 0`.
#
"""
🔑 ANSWERS & EXPLANATIONS

# 1. FizzBuzz
defmodule FizzBuzz do
  def fizzbuzz(n) when rem(n, 15) == 0, do: :fizzbuzz
  def fizzbuzz(n) when rem(n, 3)  == 0, do: :fizz
  def fizzbuzz(n) when rem(n, 5)  == 0, do: :buzz
  def fizzbuzz(n),                 do: n
end
#  Why? multiple heads + guards let us encode each rule declaratively.

# 2. safe_head/1
safe_head = fn
  [h | _] -> {:ok, h}
  []      -> :error
end
IO.inspect(safe_head.([1,2]))
#  Shows pattern matching on list structure to avoid runtime errors.

# 3. sign/1
sign = fn
  n when n > 0 -> :positive
  n when n < 0 -> :negative
  0 -> :zero
end
IO.inspect Enum.map([-2,0,5], sign)
#  Demonstrates guard expressions to classify numbers succinctly.
"""
