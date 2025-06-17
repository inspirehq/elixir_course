# Day 1 – The Pipe Operator (`|>`)
#
# Run with `mix run day_one/06_pipe_operator.exs`
#
# `|>` takes the result of the left expression and passes it as the *first*
# argument to the function call on the right, enabling left-to-right data flow.
# Below are multiple small examples plus a longer pipeline reminiscent of
# real-world ETL (extract–transform–load) code.

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 1 – Basic arithmetic pipeline")

result = 2
         |> Kernel.*(3)
         |> Kernel.+(4)

IO.inspect(result)  # (2 * 3) + 4 = 10

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Composing Enum calls")

squares_of_evens = 1..6
                   |> Enum.filter(fn n -> rem(n, 2) == 0 end)
                   |> Enum.map(& &1 * &1)

IO.inspect(squares_of_evens)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Mixing normal and anonymous functions")

capitalize = fn str -> String.capitalize(str) end

names = ["alice", "bob"]
        |> Enum.map(capitalize)
        |> Enum.join(", ")

IO.inspect(names)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Breaking long pipelines with line breaks (\n)")

sentence = "  hello WORLD  "
           |> String.trim()
           |> String.downcase()
           |> String.capitalize()

IO.inspect(sentence)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: mini ETL pipeline")

raw_rows = [
  "1,ada,4500,shipped",
  "2,grace,1500,processing",
  "3,linus,2000,cancelled"
]

etl_result = raw_rows
             # Extract: split CSV rows
             |> Enum.map(fn row -> String.split(row, ",") end)
             # Transform: convert values into a map with proper types
             |> Enum.map(fn [id, name, cents, status] ->
               %{
                 id: String.to_integer(id),
                 name: String.capitalize(name),
                 total: String.to_integer(cents) / 100,
                 status: String.to_existing_atom(status)
               }
             end)
             # Load: keep only shipped orders and summarize revenue
             |> Enum.filter(& &1.status == :shipped)
             |> Enum.reduce(0, fn order, acc -> acc + order.total end)

IO.inspect(etl_result, label: "Total shipped revenue ($)")
