# Day 1 – Immutability and Rebinding in Elixir
#
# This script can be run with:
#     mix run day_one/01_immutability_and_rebinding.exs
# or inside IEx with:
#     iex -r day_one/01_immutability_and_rebinding.exs
#
# Each numbered section below demonstrates how data is immutable in Elixir and
# how variable *names* (bindings) can be rebound to new values.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Simple rebinding")
# A variable (binding) can point to a new value, but the original value is left
# untouched because all data is immutable.

x = 1
IO.inspect(x, label: "x before")

x = x + 1   # rebinding `x` to a *new* integer (2)
IO.inspect(x, label: "x after")

# The integer 1 still exists but is no longer referenced by `x`.

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Updating a map with Map.put/3 returns a new map")

user_v1 = %{name: "Ada", city: "London"}
user_v2 = Map.put(user_v1, :city, "Paris")

IO.inspect(user_v1, label: "original")
IO.inspect(user_v2, label: "updated")

# user_v1 is unchanged; user_v2 is a *different* map that shares structure with
# user_v1 thanks to Erlang's persistent data structures.

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Rebinding inside a case expression and the pin operator (^) ")

a = 42
case 100 do
  ^a -> :won_t_match
  other -> IO.inspect(other, label: "matched value")
end

# The caret (^) pins `a`, telling the pattern matcher to use the *existing*
# value of `a` instead of rebinding. Therefore 42 ≠ 100 and the second clause
# is chosen, demonstrating how rebinding is opt-in.

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Enum.reduce/3 to accumulate without mutation")

numbers      = [1, 2, 3, 4]
initial_sum  = 0

sum = Enum.reduce(numbers, initial_sum, fn n, acc -> acc + n end)

IO.inspect(sum, label: "sum of list")
IO.inspect(initial_sum, label: "initial_sum (still 0)")

# We *produced* a new value `sum`; the accumulator variable name `acc` is
# rebound on every iteration, but `initial_sum` remains untouched.

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world scenario: building a shopping cart total")

cart = [
  %{sku: "tshirt",   qty: 2, price: 25_00},
  %{sku: "jeans",    qty: 1, price: 70_00},
  %{sku: "stickers", qty: 5, price:  2_50}
]

defmodule DayOne.Cart do
  @moduledoc """
  Pure functions that operate on an immutable shopping cart (a list of maps).
  """

  @type money :: integer()  # cents
  @spec total([map()]) :: money()
  def total(line_items) do
    Enum.reduce(line_items, 0, fn %{qty: q, price: p}, acc -> acc + q * p end)
  end
end

IO.inspect(DayOne.Cart.total(cart) / 100, label: "cart total ($)")

# The `cart` list never changes.  `Enum.reduce/3` successively rebinds the
# accumulator (`acc`) but every step returns a *new* integer; no mutation
# occurs. This mirrors how you would calculate totals in production code.
