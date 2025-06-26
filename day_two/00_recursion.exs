# Day 2 – Recursion in Elixir
#
# This script can be run with:
#     mix run day_two/00_recursion.exs
# or inside IEx with:
#     iex -r day_two/00_recursion.exs
#
# Recursion is a fundamental programming technique where a function calls itself
# to solve smaller versions of the same problem. In functional languages like
# Elixir, recursion replaces loops and is essential for list processing.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic recursion concepts and structure")

defmodule DayTwo.RecursionBasics do
  @moduledoc """
  Understanding the fundamental concepts of recursion in Elixir.
  """

  def explain_recursion_pattern do
    """
    Recursion Pattern in Elixir:

    1. Base Case: Condition that stops the recursion
    2. Recursive Case: Function calls itself with modified input
    3. Progress: Each call moves closer to the base case

    Basic Structure:
    def recursive_function(input) do
      if base_case?(input) do
        base_result
      else
        # Process current element
        result = do_something(input)
        # Recurse with smaller problem
        recursive_function(modified_input) |> combine_with(result)
      end
    end
    """
  end

  def simple_countdown(0) do
    IO.puts("Blast off! 🚀")
    :done
  end

  def simple_countdown(n) when n > 0 do
    IO.puts("#{n}...")
    simple_countdown(n - 1)
  end

  def factorial(0), do: 1
  def factorial(n) when n > 0 do
    n * factorial(n - 1)
  end

  def show_factorial_trace do
    """
    Factorial trace for factorial(4):
    factorial(4) = 4 * factorial(3)
                 = 4 * (3 * factorial(2))
                 = 4 * (3 * (2 * factorial(1)))
                 = 4 * (3 * (2 * (1 * factorial(0))))
                 = 4 * (3 * (2 * (1 * 1)))
                 = 4 * (3 * (2 * 1))
                 = 4 * (3 * 2)
                 = 4 * 6
                 = 24
    """
  end
end

IO.puts("Recursion pattern:")
IO.puts(DayTwo.RecursionBasics.explain_recursion_pattern())

IO.puts("\nCountdown demonstration:")
DayTwo.RecursionBasics.simple_countdown(5)

IO.puts("\nFactorial calculation:")
result = DayTwo.RecursionBasics.factorial(4)
IO.puts("factorial(4) = #{result}")
IO.puts(DayTwo.RecursionBasics.show_factorial_trace())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – List recursion patterns")

defmodule DayTwo.ListRecursion do
  @moduledoc """
  Common patterns for recursive list processing.
  """

  # Head/tail pattern - most common in Elixir
  def sum_list([]), do: 0
  def sum_list([head | tail]) do
    head + sum_list(tail)
  end

  def length_list([]), do: 0
  def length_list([_head | tail]) do
    1 + length_list(tail)
  end

  def reverse_list(list), do: reverse_list(list, [])
  defp reverse_list([], acc), do: acc
  defp reverse_list([head | tail], acc) do
    reverse_list(tail, [head | acc])
  end

  def find_max([]), do: nil
  def find_max([single]), do: single
  def find_max([head | tail]) do
    max(head, find_max(tail))
  end

  def show_list_patterns do
    """
    Common List Recursion Patterns:

    1. Empty List Base Case: [] -> base_value
    2. Head/Tail Decomposition: [head | tail]
    3. Process Head: do_something(head)
    4. Recurse on Tail: recursive_call(tail)
    5. Combine Results: combine(head_result, tail_result)

    Pattern Matching Examples:
    • [] - empty list
    • [head | tail] - at least one element
    • [first, second | rest] - at least two elements
    • [single] - exactly one element
    """
  end
end

IO.puts("List recursion patterns:")
IO.puts(DayTwo.ListRecursion.show_list_patterns())

test_list = [1, 2, 3, 4, 5]
IO.puts("\nTesting with #{inspect(test_list)}:")
IO.puts("Sum: #{DayTwo.ListRecursion.sum_list(test_list)}")
IO.puts("Length: #{DayTwo.ListRecursion.length_list(test_list)}")
IO.puts("Reversed: #{inspect(DayTwo.ListRecursion.reverse_list(test_list))}")
IO.puts("Max: #{DayTwo.ListRecursion.find_max(test_list)}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Tail recursion and accumulators")

defmodule DayTwo.TailRecursion do
  @moduledoc """
  Understanding tail recursion and accumulator patterns for efficiency.
  """

  def explain_tail_recursion do
    """
    Tail Recursion:
    • The recursive call is the LAST operation in the function
    • No operations performed on the result of the recursive call
    • Elixir can optimize tail recursion to avoid stack overflow
    • Uses constant stack space instead of growing with each call

    Non-tail recursive (builds up stack):
    def factorial(n) do
      if n <= 1 do
        1
      else
        n * factorial(n - 1)  # multiplication happens AFTER recursive call
      end
    end

    Tail recursive (constant stack):
    def factorial(n), do: factorial(n, 1)
    defp factorial(0, acc), do: acc
    defp factorial(n, acc), do: factorial(n - 1, n * acc)  # recursive call is LAST
    """
  end

  # Tail recursive factorial with accumulator
  def factorial_tail(n), do: factorial_tail(n, 1)
  defp factorial_tail(0, acc), do: acc
  defp factorial_tail(n, acc) when n > 0 do
    factorial_tail(n - 1, n * acc)
  end

  # Tail recursive sum with accumulator
  def sum_tail(list), do: sum_tail(list, 0)
  defp sum_tail([], acc), do: acc
  defp sum_tail([head | tail], acc) do
    sum_tail(tail, acc + head)
  end

  # Tail recursive map with accumulator
  def map_tail(list, func), do: map_tail(list, func, [])
  defp map_tail([], _func, acc), do: Enum.reverse(acc)
  defp map_tail([head | tail], func, acc) do
    map_tail(tail, func, [func.(head) | acc])
  end

  # Tail recursive filter with accumulator
  def filter_tail(list, predicate), do: filter_tail(list, predicate, [])
  defp filter_tail([], _predicate, acc), do: Enum.reverse(acc)
  defp filter_tail([head | tail], predicate, acc) do
    if predicate.(head) do
      filter_tail(tail, predicate, [head | acc])
    else
      filter_tail(tail, predicate, acc)
    end
  end
end

IO.puts("Tail recursion explanation:")
IO.puts(DayTwo.TailRecursion.explain_tail_recursion())

IO.puts("\nTail recursive examples:")
IO.puts("Factorial (tail): #{DayTwo.TailRecursion.factorial_tail(5)}")
IO.puts("Sum (tail): #{DayTwo.TailRecursion.sum_tail([1, 2, 3, 4, 5])}")

mapped = DayTwo.TailRecursion.map_tail([1, 2, 3, 4], &(&1 * 2))
IO.puts("Map double (tail): #{inspect(mapped)}")

filtered = DayTwo.TailRecursion.filter_tail([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))
IO.puts("Filter even (tail): #{inspect(filtered)}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Tree and nested data recursion")

defmodule DayTwo.TreeRecursion do
  @moduledoc """
  Recursion with tree structures and nested data.
  """

  # Simple binary tree structure
  defmodule TreeNode do
    defstruct [:value, :left, :right]

    def new(value, left \\ nil, right \\ nil) do
      %__MODULE__{value: value, left: left, right: right}
    end
  end

  def tree_sum(nil), do: 0
  def tree_sum(%TreeNode{value: value, left: left, right: right}) do
    value + tree_sum(left) + tree_sum(right)
  end

  def tree_height(nil), do: 0
  def tree_height(%TreeNode{left: left, right: right}) do
    1 + max(tree_height(left), tree_height(right))
  end

  def tree_contains?(nil, _target), do: false
  def tree_contains?(%TreeNode{value: target}, target), do: true
  def tree_contains?(%TreeNode{left: left, right: right}, target) do
    tree_contains?(left, target) or tree_contains?(right, target)
  end

  # Nested map recursion
  def deep_map_sum(map) when is_map(map) do
    map
    |> Map.values()
    |> Enum.reduce(0, fn value, acc ->
      acc + deep_sum_value(value)
    end)
  end

  defp deep_sum_value(value) when is_number(value), do: value
  defp deep_sum_value(value) when is_map(value), do: deep_map_sum(value)
  defp deep_sum_value(value) when is_list(value) do
    Enum.reduce(value, 0, &(deep_sum_value(&1) + &2))
  end
  defp deep_sum_value(_), do: 0

  def demonstrate_tree_operations do
    # Create a sample tree:
    #       5
    #      / \
    #     3   8
    #    / \   \
    #   1   4   9
    tree = TreeNode.new(5,
      TreeNode.new(3,
        TreeNode.new(1),
        TreeNode.new(4)
      ),
      TreeNode.new(8,
        nil,
        TreeNode.new(9)
      )
    )

    IO.puts("\nTree operations:")
    IO.puts("Sum: #{tree_sum(tree)}")
    IO.puts("Height: #{tree_height(tree)}")
    IO.puts("Contains 4: #{tree_contains?(tree, 4)}")
    IO.puts("Contains 7: #{tree_contains?(tree, 7)}")

    # Nested data structure
    nested_data = %{
      a: 10,
      b: %{
        c: 20,
        d: [5, 15, %{e: 25}]
      },
      f: [1, 2, 3]
    }

    IO.puts("\nNested data sum: #{deep_map_sum(nested_data)}")
  end
end

DayTwo.TreeRecursion.demonstrate_tree_operations()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: File system traversal")

defmodule DayTwo.FileSystemDemo do
  @moduledoc """
  Real-world recursion example: traversing directory structures.
  """

  # Simulated file system structure
  defmodule FileNode do
    defstruct [:name, :type, :size, :children]

    def file(name, size) do
      %__MODULE__{name: name, type: :file, size: size, children: []}
    end

    def directory(name, children \\ []) do
      %__MODULE__{name: name, type: :directory, size: 0, children: children}
    end
  end

  def total_size(%FileNode{type: :file, size: size}), do: size
  def total_size(%FileNode{type: :directory, children: children}) do
    Enum.reduce(children, 0, fn child, acc ->
      acc + total_size(child)
    end)
  end

  def count_files(%FileNode{type: :file}), do: 1
  def count_files(%FileNode{type: :directory, children: children}) do
    Enum.reduce(children, 0, fn child, acc ->
      acc + count_files(child)
    end)
  end

  def find_files_by_extension(%FileNode{type: :file, name: name}, ext) do
    if String.ends_with?(name, ext) do
      [name]
    else
      []
    end
  end
  def find_files_by_extension(%FileNode{type: :directory, children: children}, ext) do
    Enum.flat_map(children, fn child ->
      find_files_by_extension(child, ext)
    end)
  end

  def print_tree(node, indent \\ 0) do
    prefix = String.duplicate("  ", indent)
    case node do
      %FileNode{type: :file, name: name, size: size} ->
        IO.puts("#{prefix}📄 #{name} (#{size} bytes)")

      %FileNode{type: :directory, name: name, children: children} ->
        IO.puts("#{prefix}📁 #{name}/")
        Enum.each(children, fn child ->
          print_tree(child, indent + 1)
        end)
    end
  end

  def demonstrate_file_system do
    # Create a sample file system
    file_system = FileNode.directory("project", [
      FileNode.file("README.md", 1500),
      FileNode.file("mix.exs", 800),
      FileNode.directory("lib", [
        FileNode.file("app.ex", 2000),
        FileNode.directory("app", [
          FileNode.file("user.ex", 1200),
          FileNode.file("post.ex", 900)
        ])
      ]),
      FileNode.directory("test", [
        FileNode.file("app_test.exs", 600),
        FileNode.file("user_test.exs", 400)
      ])
    ])

    IO.puts("\nFile system structure:")
    print_tree(file_system)

    IO.puts("\nFile system analysis:")
    IO.puts("Total size: #{total_size(file_system)} bytes")
    IO.puts("File count: #{count_files(file_system)}")

    elixir_files = find_files_by_extension(file_system, ".ex")
    IO.puts("Elixir files: #{inspect(elixir_files)}")

    test_files = find_files_by_extension(file_system, ".exs")
    IO.puts("Test files: #{inspect(test_files)}")
  end
end

DayTwo.FileSystemDemo.demonstrate_file_system()

defmodule DayTwo.RecursionExercises do
  @moduledoc """
  Run the tests with: mix test day_two/00_recursion.exs
  or in IEx:
  iex -r day_two/00_recursion.exs
  DayTwo.RecursionExercisesTest.test_fibonacci/0
  DayTwo.RecursionExercisesTest.test_list_operations/0
  DayTwo.RecursionExercisesTest.test_nested_data_processing/0
  """

  @spec fibonacci(non_neg_integer()) :: non_neg_integer()
  def fibonacci(_n) do
    #   Implement the Fibonacci sequence using recursion.
    #   fibonacci(0) = 0, fibonacci(1) = 1, fibonacci(n) = fibonacci(n-1) + fibonacci(n-2)
    #   Bonus: Implement both naive and tail-recursive versions.
    #   Example: fibonacci(6) => 8
    :not_implemented
  end

  @spec flatten_list([any()]) :: [any()]
  def flatten_list(_nested_list) do
    #   Recursively flatten a nested list structure.
    #   Transform [[1, 2], [3, [4, 5]], 6] into [1, 2, 3, 4, 5, 6]
    #   Handle arbitrarily deep nesting.
    :not_implemented
  end

  @spec deep_count(any()) :: non_neg_integer()
  def deep_count(_data) do
    #   Count all atomic values in a nested data structure.
    #   Handle lists, tuples, and maps recursively.
    #   Example: deep_count([1, {2, [3, 4]}, %{a: 5}]) => 5
    :not_implemented
  end
end

ExUnit.start()

defmodule DayTwo.RecursionExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.RecursionExercises, as: EX

  test "fibonacci/1 calculates Fibonacci numbers correctly" do
    assert EX.fibonacci(0) == 0
    assert EX.fibonacci(1) == 1
    assert EX.fibonacci(2) == 1
    assert EX.fibonacci(6) == 8
    assert EX.fibonacci(10) == 55
  end

  test "flatten_list/1 flattens nested lists" do
    assert EX.flatten_list([]) == []
    assert EX.flatten_list([1, 2, 3]) == [1, 2, 3]
    assert EX.flatten_list([[1, 2], [3, 4]]) == [1, 2, 3, 4]
    assert EX.flatten_list([1, [2, [3, 4]], 5]) == [1, 2, 3, 4, 5]
  end

  test "deep_count/1 counts atomic values in nested structures" do
    assert EX.deep_count(42) == 1
    assert EX.deep_count([1, 2, 3]) == 3
    assert EX.deep_count({1, {2, 3}}) == 3
    assert EX.deep_count(%{a: 1, b: [2, 3]}) == 3
    assert EX.deep_count([1, {2, [3, 4]}, %{a: 5}]) == 5
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. fibonacci/1
def fibonacci(0), do: 0
def fibonacci(1), do: 1
def fibonacci(n) when n > 1 do
  fibonacci(n - 1) + fibonacci(n - 2)
end

# Tail-recursive version (more efficient):
def fibonacci_tail(n), do: fibonacci_tail(n, 0, 1)
defp fibonacci_tail(0, a, _b), do: a
defp fibonacci_tail(n, a, b) when n > 0 do
  fibonacci_tail(n - 1, b, a + b)
end
#  The naive version has exponential time complexity O(2^n) due to repeated calculations.
#  The tail-recursive version is O(n) and uses constant stack space.

# 2. flatten_list/1
def flatten_list([]), do: []
def flatten_list([head | tail]) when is_list(head) do
  flatten_list(head) ++ flatten_list(tail)
end
def flatten_list([head | tail]) do
  [head | flatten_list(tail)]
end
#  Pattern matches on list structure, recursively flattens sublists,
#  and concatenates results. Handles arbitrarily deep nesting.

# 3. deep_count/1
def deep_count(data) when is_list(data) do
  Enum.reduce(data, 0, fn item, acc -> acc + deep_count(item) end)
end
def deep_count(data) when is_tuple(data) do
  data |> Tuple.to_list() |> deep_count()
end
def deep_count(data) when is_map(data) do
  data |> Map.values() |> deep_count()
end
def deep_count(_atomic), do: 1
#  Uses guards to handle different data types, recursively processes
#  collections, and counts atomic values (non-collections).
"""
