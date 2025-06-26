# Day 1 – The Pipe Operator (`|>`)
#
# This script can be run with:
#     mix run day_one/06_pipe_operator.exs
# or inside IEx with:
#     iex -r day_one/06_pipe_operator.exs
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
IO.puts("\n📌 Example 4 – Breaking long pipelines with line breaks")

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

defmodule DayOne.PipeExercises do
  @moduledoc """
  Run the tests with: mix test day_one/06_pipe_operator.exs
  or in IEx:
  iex -r day_one/06_pipe_operator.exs
  DayOne.PipeExercisesTest.test_trim_and_upcase/0
  DayOne.PipeExercisesTest.test_square_filter_sum/0
  DayOne.PipeExercisesTest.test_file_line_count/0
  """

  @spec trim_and_upcase(String.t()) :: String.t()
  def trim_and_upcase(_input) do
    #   Rewrite the expression `String.upcase(String.trim("  hi "))` using a pipe.
    #   Take the input string, trim whitespace, then convert to uppercase.
    #   Example: trim_and_upcase("  hello  ") => "HELLO"
    :not_implemented
  end

  @spec square_filter_sum(Range.t()) :: integer()
  def square_filter_sum(_range) do
    #   Take a range, square the numbers, keep those > 10, sum the result
    #   using a single pipeline.
    #   Example: square_filter_sum(1..5) should:
    #   - Square: [1, 4, 9, 16, 25]
    #   - Filter > 10: [16, 25]
    #   - Sum: 41
    :not_implemented
  end

  @spec file_line_count(String.t()) :: integer()
  def file_line_count(_filename) do
    #   Build a pipeline that reads a file, splits on lines, removes blanks,
    #   and returns the line count.
    #   For testing, simulate file reading:
    #   - "data.txt": "line1\nline2\n\nline3\n"
    #   - "empty.txt": ""
    #   - "missing.txt": file doesn't exist (should return 0)
    #   Hint: Use String.split/2 with "\n", Enum.reject/2, and length/1
    :not_implemented
  end

  # Helper function for testing file operations
  defp mock_file_read("data.txt"), do: "line1\nline2\n\nline3\n"
  defp mock_file_read("empty.txt"), do: ""
  defp mock_file_read("single.txt"), do: "only one line"
  defp mock_file_read(_), do: ""  # missing files return empty string for simplicity
end

ExUnit.start()

defmodule DayOne.PipeExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.PipeExercises, as: EX

  test "trim_and_upcase/1 trims and converts to uppercase" do
    assert EX.trim_and_upcase("  hello  ") == "HELLO"
    assert EX.trim_and_upcase("world") == "WORLD"
    assert EX.trim_and_upcase("  MiXeD cAsE  ") == "MIXED CASE"
    assert EX.trim_and_upcase("") == ""
  end

  test "square_filter_sum/1 squares, filters, and sums in pipeline" do
    assert EX.square_filter_sum(1..5) == 41  # 16 + 25
    assert EX.square_filter_sum(1..3) == 0   # [1, 4, 9] none > 10
    assert EX.square_filter_sum(4..6) == 77  # [16, 25, 36] all > 10
    assert EX.square_filter_sum(1..1) == 0   # [1] not > 10
  end

  test "file_line_count/1 counts non-blank lines" do
    assert EX.file_line_count("data.txt") == 3    # 4 lines, 1 blank
    assert EX.file_line_count("empty.txt") == 0   # empty file
    assert EX.file_line_count("single.txt") == 1  # one line, no newline
    assert EX.file_line_count("missing.txt") == 0 # missing file
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. trim_and_upcase/1
def trim_and_upcase(input) do
  input |> String.trim() |> String.upcase()
end
#  Pipe passes intermediate value left-to-right; clearer than nested calls.

# 2. square_filter_sum/1
def square_filter_sum(range) do
  range
  |> Enum.map(& &1 * &1)
  |> Enum.filter(& &1 > 10)
  |> Enum.sum()
end
#  Shows transformation stages in readable order with clear data flow.

# 3. file_line_count/1
def file_line_count(filename) do
  filename
  |> mock_file_read()
  |> String.split("\n")
  |> Enum.reject(&(&1 == ""))
  |> length()
end
#  Demonstrates IO + string operations in a pipeline with clear steps.
"""
