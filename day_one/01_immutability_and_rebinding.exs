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

# Memory efficiency demonstration
list1 = [1, 2, 3, 4, 5]
list2 = [0 | list1]  # Prepends 0, shares tail with list1

# Challenge students to trace memory usage
user = %{name: "Alice", age: 25, city: "London"}
updated_user = %{user | age: 26}  # Only age changes, rest is shared

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
  # @type is a type specifier
  # @spec is a function specifier
  @type money :: integer()  # cents
  @spec total([map()]) :: money()
  def total(line_items) do
    Enum.reduce(line_items, 0, fn %{qty: q, price: p}, acc -> acc + q * p end)
  end
end

IO.inspect(DayOne.Cart.total(cart) / 100, label: "cart total ($)")

# The `cart` list never changes.  `Enum.reduce/3` successively rebinds the
# accumulator (`acc`) but every step returns a *new* integer; no mutation
# occurs.

defmodule DayOne.Exercises do
  @moduledoc """
  Run the tests with: mix test day_one/01_immutability_and_rebinding.exs
  or in IEx:
  iex -r day_one/01_immutability_and_rebinding.exs
  DayOne.ExercisesTest.test_bump_each/0
  DayOne.ExercisesTest.test_pin_demo/0
  DayOne.ExercisesTest.test_deep_update/0
  """

  @spec bump_each([integer()]) :: [integer()]
  def bump_each(_ints) do
    #   Given a list of integers, return *a new list* with each value bumped.
    #   Prove the original list is intact by printing both.
    #   Hint: Use Enum.map/2 to create a new list.
    #   Example: bump_each([1,2,3]) ⇒ [2,3,4]
    [1,2,3]  # TODO: Implement this function
  end

  @spec pin_demo() :: {integer(), integer(), integer()}
  def pin_demo do
    #   Show off the pin operator ^
    #   1. Bind two variables, e.g. x = 1 and y = 3.
    #   2. Pattern-match against a tuple, *pinning* x and y so they cannot be
    #      rebound while the middle element *is* rebound.
    #   3. Return the resulting 3-tuple.
    #      A common answer is {1,2,3}, but any tuple that proves the concept
    #      is acceptable *as long as the outer elements are the pinned ones*.
    {0, 0, 0}  # TODO: Implement this function
  end

  @spec deep_update(map(), [term()], any()) :: map()
  def deep_update(data, _path, _value) do
    #   Produce and return a *new* map where the value located at `path` is
    #   replaced by `value`. The original map must stay unchanged.
    #   Hint: Use Kernel.put_in/3 or update_in/3.
    #   Example:
    #     deep_update(%{settings: %{theme: "light"}}, [:settings, :theme], "dark")
    #     #=> %{settings: %{theme: "dark"}}
    data  # TODO: Implement this function (currently returns unchanged data)
  end
end

ExUnit.start()

defmodule DayOne.ExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.Exercises, as: EX

  test "bump_each/1 increments each element and leaves original intact" do
    original = [1, 2, 3]
    assert EX.bump_each(original) == [2, 3, 4]
    assert original == [1, 2, 3]
  end

  test "pin_demo/0 shows selective rebinding with the pin operator" do
    {x, _middle, y} = EX.pin_demo()
    # outer elements must be the pinned originals (1 and 3)
    assert x == 1
    assert y == 3
  end

  test "deep_update/3 updates nested value immutably" do
    data    = %{settings: %{theme: "light"}}
    path    = [:settings, :theme]
    new_val = "dark"

    updated = EX.deep_update(data, path, new_val)

    # Value replaced at path
    assert get_in(updated, path) == new_val
    # Unrelated parts stay intact (immutability) – original untouched
    assert data[:settings][:theme] == "light"
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def bump_each(ints) do
        Enum.map(ints, &(&1 + 1))
      end
    end
  end

  def answer_two do
    quote do
      def pin_demo do
        x = 1
        y = 3
        {^x, middle, ^y} = {1, 2, 3}
        {x, middle, y}
      end
    end
  end

  def answer_three do
    quote do
      def deep_update(data, path, value) do
        put_in(data, path, value)
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. bump_each/1
#{Macro.to_string(DayOne.Answers.answer_one())}
#  This is the idiomatic way to transform a list in Elixir. `Enum.map/2`
#  iterates over each element, applies the given function, and returns a
#  completely new list, leaving the original unchanged.

# 2. pin_demo/0
#{Macro.to_string(DayOne.Answers.answer_two())}
#  The pin operator `^` is crucial for pattern matching when you want to assert
#  equality rather than rebind a variable. Here, `^x` means "match only if
#  the value is the same as the current value of x".

# 3. deep_update/3
#{Macro.to_string(DayOne.Answers.answer_three())}
#  `put_in/3` is a powerful and concise function for immutably "updating"
#  nested data structures. It returns a new copy of the data with the value at
#  the specified path changed, without affecting the original data structure.
""")
