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
