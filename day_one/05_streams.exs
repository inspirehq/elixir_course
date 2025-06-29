# Day 1 – Streams: Lazy Evaluation and Memory Efficiency
#
# This script can be run with:
#     mix run day_one/05_streams.exs
# or inside IEx with:
#     iex -r day_one/05_streams.exs
#
# `Stream` provides lazy evaluation for working with potentially infinite or very
# large datasets. Unlike `Enum`, which processes data immediately, `Stream` builds
# a pipeline of transformations that are only executed when needed.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Stream vs Enum: Memory Usage")

# Enum processes immediately and keeps everything in memory
IO.puts("Using Enum (immediate evaluation):")
enum_result = 1..1_000_000 |> Enum.map(&(&1 * 2)) |> Enum.take(5)
IO.inspect(enum_result, label: "Enum result")

# Stream processes lazily, only computing what's needed
IO.puts("\nUsing Stream (lazy evaluation):")
stream_result = 1..1_000_000 |> Stream.map(&(&1 * 2)) |> Enum.take(5)
IO.inspect(stream_result, label: "Stream result")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Infinite streams")

# Generate an infinite sequence of natural numbers
naturals = Stream.iterate(1, &(&1 + 1))
first_10_naturals = Enum.take(naturals, 10)
IO.inspect(first_10_naturals, label: "First 10 natural numbers")

# Fibonacci sequence using unfold
fib = Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
first_10_fib = Enum.take(fib, 10)
IO.inspect(first_10_fib, label: "First 10 Fibonacci numbers")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – File processing with streams")

# Create a sample file for demonstration
File.write!("sample.txt", "line 1\nline 2\nline 3\nline 4\nline 5\n")

# Process large files without loading everything into memory
line_count = File.stream!("sample.txt")
             |> Stream.map(&String.trim/1)
             |> Stream.filter(&(String.length(&1) > 0))
             |> Enum.count()

IO.inspect(line_count, label: "Non-empty lines in file")

# Clean up
File.rm("sample.txt")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Stream transformations pipeline")

# Build a complex pipeline without intermediate collections
pipeline_result = 1..100
|> Stream.filter(&(rem(&1, 2) == 0))  # Even numbers only
|> Stream.map(&(&1 * &1))             # Square them
|> Stream.filter(&(&1 > 100))         # Only squares > 100
|> Stream.take(5)                     # Take first 5
|> Enum.to_list()                     # Execute the pipeline

IO.inspect(pipeline_result, label: "Complex pipeline result")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Early termination with take_while")

# Process data until a condition is met
numbers = Stream.iterate(1, &(&1 + 1))
          |> Stream.take_while(&(&1 < 20))
          |> Stream.filter(&(rem(&1, 3) == 0))
          |> Enum.to_list()

IO.inspect(numbers, label: "Multiples of 3 less than 20")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 6 – Real-world: processing log files")

defmodule LogProcessor do
  def demo do
    # Simulate a large log file
    log_lines = [
      "[INFO] 2024-01-01T10:00:00 User login: alice@example.com",
      "[ERROR] 2024-01-01T10:05:00 Database connection failed",
      "[INFO] 2024-01-01T10:10:00 User login: bob@example.com",
      "[WARN] 2024-01-01T10:15:00 Slow query detected (2.5s)",
      "[ERROR] 2024-01-01T10:20:00 Payment processing failed for order #123",
      "[INFO] 2024-01-01T10:25:00 User logout: alice@example.com"
    ]

    # Process logs efficiently with streams
    error_count = log_lines
                  |> Stream.filter(&String.contains?(&1, "[ERROR]"))
                  |> Stream.map(&parse_timestamp/1)
                  |> Stream.filter(&in_time_window?/1)
                  |> Enum.count()

    IO.inspect(error_count, label: "Recent error count")
  end

  defp parse_timestamp(log_line) do
    # Extract timestamp from log line (simplified)
    case Regex.run(~r/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})/, log_line) do
      [_, timestamp] -> {log_line, timestamp}
      nil -> {log_line, nil}
    end
  end

  defp in_time_window?({_line, timestamp}) do
    # Simplified: consider all timestamps as "recent"
    not is_nil(timestamp)
  end
end

LogProcessor.demo()

defmodule DayOne.StreamExercises do
  @moduledoc """
  Run the tests with: mix test day_one/05_streams.exs
  or in IEx:
  iex -r day_one/05_streams.exs
  DayOne.StreamExercisesTest.test_lazy_squares/0
  DayOne.StreamExercisesTest.test_process_chunks/0
  DayOne.StreamExercisesTest.test_find_first_match/0
  """

  @spec lazy_squares(Range.t(), pos_integer()) :: [integer()]
  def lazy_squares(_range, _limit) do
    #   Create a function that takes a range and a limit, then returns
    #   the first `limit` perfect squares from that range using streams.
    #   Example: lazy_squares(1..100, 3) => [1, 4, 9]
    #   Hint: Use Stream.filter/2 to find perfect squares, then Stream.take/2
    []  # TODO: Implement lazy perfect square finding using streams
  end

  @spec process_chunks([String.t()], pos_integer()) :: [String.t()]
  def process_chunks(_lines, _chunk_size) do
    #   Process a list of strings in chunks without loading all results into memory.
    #   Return the first line from each chunk, uppercased.
    #   Example: process_chunks(["a", "b", "c", "d"], 2) => ["A", "C"]
    #   Hint: Use Stream.chunk_every/2, Stream.map/2, and Enum.take/2
    []  # TODO: Implement chunk processing with streams
  end

  @spec find_first_match([integer()], (integer() -> boolean())) :: integer() | nil
  def find_first_match(_numbers, _predicate) do
    #   Find the first number in the list that matches the predicate function.
    #   Use streams to avoid processing the entire list if a match is found early.
    #   Return the matching number or nil if no match is found.
    #   Example: find_first_match([1, 2, 3, 4, 5], &(&1 > 3)) => 4
    #   Hint: Use Stream.filter/2 and Enum.at/2 or Stream.take/2 + Enum.to_list/1
    nil  # TODO: Implement early-terminating search using streams
  end

  # Helper function to check if a number is a perfect square
  defp _is_perfect_square?(n) do
    sqrt = :math.sqrt(n)
    trunc(sqrt) * trunc(sqrt) == n
  end
end

ExUnit.start()

defmodule DayOne.StreamExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.StreamExercises, as: EX

  test "lazy_squares/2 finds perfect squares efficiently" do
    assert EX.lazy_squares(1..100, 3) == [1, 4, 9]
    assert EX.lazy_squares(10..50, 2) == [16, 25]
    assert EX.lazy_squares(1..10, 0) == []
    assert EX.lazy_squares(2..3, 5) == []  # No perfect squares in range
  end

  test "process_chunks/2 handles chunk processing correctly" do
    assert EX.process_chunks(["a", "b", "c", "d"], 2) == ["A", "C"]
    assert EX.process_chunks(["hello", "world", "foo", "bar", "baz"], 3) == ["HELLO", "BAR"]
    assert EX.process_chunks([], 2) == []
    assert EX.process_chunks(["single"], 5) == ["SINGLE"]
  end

  test "find_first_match/2 finds first matching element efficiently" do
    assert EX.find_first_match([1, 2, 3, 4, 5], &(&1 > 3)) == 4
    assert EX.find_first_match([1, 2, 3], &(&1 > 10)) == nil
    assert EX.find_first_match([10, 20, 30], &(rem(&1, 20) == 0)) == 20
    assert EX.find_first_match([], &(&1 > 0)) == nil
  end
end

defmodule DayOne.Answers do
  defp is_perfect_square?(n) do
    sqrt = :math.sqrt(n)
    trunc(sqrt) * trunc(sqrt) == n
  end

  def answer_one do
    quote do
      def lazy_squares(range, limit) do
        range
        # The is_perfect_square? function is defined privately in DayOne.Answers
        |> Stream.filter(&DayOne.Answers.is_perfect_square?/1)
        |> Stream.take(limit)
        |> Enum.to_list()
      end
    end
  end

  def answer_two do
    quote do
      def process_chunks(lines, chunk_size) do
        lines
        |> Stream.chunk_every(chunk_size)
        |> Stream.map(&List.first/1)
        |> Stream.map(&String.upcase/1)
        |> Enum.to_list()
      end
    end
  end

  def answer_three do
    quote do
      def find_first_match(numbers, predicate) do
        numbers
        |> Stream.filter(predicate)
        |> Enum.at(0)
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. lazy_squares/2
#{Macro.to_string(DayOne.Answers.answer_one())}
#  This is a perfect use case for streams. It creates a lazy pipeline that
#  filters the range for perfect squares and then only takes the number required
#  by the `limit`. No intermediate lists are created, making it very memory
#  efficient for large ranges.

# 2. process_chunks/2
#{Macro.to_string(DayOne.Answers.answer_two())}
#  `Stream.chunk_every/2` is excellent for batch processing. This pipeline
#  lazily groups lines into chunks, then maps over each chunk to take the first
#  element and uppercase it. The final `Enum.to_list` is what executes the
#  entire stream pipeline.

# 3. find_first_match/2
#{Macro.to_string(DayOne.Answers.answer_three())}
#  Streams excel at early termination. `Stream.filter/2` creates a lazy stream
#  of matching numbers. `Enum.at(0)` then pulls from the stream only until it
#  gets the first item (or the stream ends), avoiding unnecessary iteration
#  through the rest of the collection.
""")
