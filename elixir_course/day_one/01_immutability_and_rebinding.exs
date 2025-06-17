# Day 1 – Immutability and Rebinding in Elixir
#
# This script can be run with:
#     mix run elixir_course/day_one/01_immutability_and_rebinding.exs
# or inside IEx with:
#     iex -r elixir_course/day_one/01_immutability_and_rebinding.exs
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

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Write a function `bump_each/1` that takes a list of integers and returns a
#    *new* list where each element is incremented by 1.  Prove the original
#    list is intact by printing both.
# 2. Using the pin operator (^), pattern-match against the tuple `{1, 2, 3}` so
#    that only the second element may rebind. Print the result and the value of
#    your pinned variables.
# 3. (Challenge) Implement a pure function `deep_update/3` that returns a *new*
#    nested map with an updated key: `deep_update(user, [:settings, :theme], "dark")`.
#
"""
🔑 ANSWERS & EXPLANATIONS

# 1. bump_each/1
original = [1, 2, 3]
new_list = Enum.map(original, &(&1 + 1))
IO.inspect({original, new_list}, label: "orig vs new")
#  Why correct?  Enum.map/2 never mutates `original`; it produces a brand-new
#  list. Printing shows `original` remains [1,2,3].  This reinforces immutability.

# 2. Pin demonstration
x = 1
y = 3
{:ok, ^x, middle, ^y} = {:ok, 1, 2, 3}
IO.inspect({x, middle, y})
#  We pinned the first and last elements to enforce they match existing values
#  of x and y. Only `middle` is rebound (to 2).  This shows selective rebinding.

# 3. deep_update/3 (simple version)
update_in_map = fn m, [k], v -> Map.put(m, k, v)
  m, [k | rest], v ->
    inner = Map.get(m, k, %{})
    Map.put(m, k, update_in_map.(inner, rest, v))
end

user = %{settings: %{theme: "light"}}
updated = update_in_map.(user, [:settings, :theme], "dark")
IO.inspect(updated, label: "updated")
#  We returned a *new* map with shared structure; `user` is unchanged.  This
#  demonstrates deep immutability and structural sharing.
"""
