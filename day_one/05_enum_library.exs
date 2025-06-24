# Day 1 – The `Enum` Standard Library
#
# Run with `mix run day_one/05_enum_library.exs`
#
# `Enum` provides a rich set of functions for working with *enumerables* – data
# structures that implement the `Enumerable` protocol (lists, maps, ranges,
# streams…). Below are five illustrative examples, capped off by a more
# realistic data-analysis snippet.

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
end

pets = [
  %Pet{name: "Milo",  type: :dog},
  %Pet{name: "Luna",  type: :cat},
  %Pet{name: "Otto",  type: :dog}
]

IO.inspect(Enum.group_by(pets, & &1.type))

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

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Use Enum.reduce/3 to compute the sum of squares for 1..10.
# 2. Implement `Enum.my_max/1` using reduce (no Enum.max/1!).
# 3. (Challenge) Count word frequencies in "hello world hello" returning
#    %{"hello" => 2, "world" => 1} using Enum functions only.
#
"""
🔑 ANSWERS & EXPLANATIONS

# 1.
sum_sq = Enum.reduce(1..10, 0, fn n, acc -> acc + n*n end)
IO.inspect(sum_sq)
#  Shows accumulator pattern.

# 2.
my_max = fn [h | t] -> Enum.reduce(t, h, &max/2) end
IO.inspect(my_max.([3,7,2]))
#  Demonstrates custom reduce to replace built-in.

# 3.
words = String.split("hello world hello")
freqs = Enum.reduce(words, %{}, fn w, acc -> Map.update(acc, w, 1, &(&1+1)) end)
IO.inspect(freqs)
#  Combines split + reduce to build frequency map immutably.
"""
