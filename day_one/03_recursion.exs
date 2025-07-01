# Day 1, Lesson 3 – Recursion in Elixir
#
# This script can be run with:
#     mix run day_one/03_recursion.exs
# or inside IEx with:
#     iex -r day_one/03_recursion.exs
#
# Recursion is a fundamental programming technique where a function calls itself
# to solve smaller versions of the same problem. In functional languages like
# Elixir, recursion replaces loops and is essential for list processing.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic recursion concepts and structure")

defmodule DayOne.RecursionBasics do
  @moduledoc """
  Understanding the fundamental concepts of recursion in Elixir.
  """

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

IO.puts("\nCountdown demonstration:")
DayOne.RecursionBasics.simple_countdown(5)

IO.puts("\nFactorial calculation:")
result = DayOne.RecursionBasics.factorial(4)
IO.puts("factorial(4) = #{result}")
IO.puts(DayOne.RecursionBasics.show_factorial_trace())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – List recursion patterns")

defmodule DayOne.ListRecursion do
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
IO.puts(DayOne.ListRecursion.show_list_patterns())

test_list = [1, 2, 3, 4, 5]
IO.puts("\nTesting with #{inspect(test_list)}:")
IO.puts("Sum: #{DayOne.ListRecursion.sum_list(test_list)}")
IO.puts("Length: #{DayOne.ListRecursion.length_list(test_list)}")
IO.puts("Reversed: #{inspect(DayOne.ListRecursion.reverse_list(test_list))}")
IO.puts("Max: #{DayOne.ListRecursion.find_max(test_list)}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Tail recursion and accumulators")

defmodule DayOne.TailRecursion do
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
IO.puts(DayOne.TailRecursion.explain_tail_recursion())

IO.puts("\nTail recursive examples:")
IO.puts("Factorial (tail): #{DayOne.TailRecursion.factorial_tail(5)}")
IO.puts("Sum (tail): #{DayOne.TailRecursion.sum_tail([1, 2, 3, 4, 5])}")

mapped = DayOne.TailRecursion.map_tail([1, 2, 3, 4], &(&1 * 2))
IO.puts("Map double (tail): #{inspect(mapped)}")

filtered = DayOne.TailRecursion.filter_tail([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))
IO.puts("Filter even (tail): #{inspect(filtered)}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Tree and nested data recursion")

defmodule DayOne.TreeRecursion do
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

DayOne.TreeRecursion.demonstrate_tree_operations()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: File system traversal")

defmodule DayOne.FileSystemDemo do
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

DayOne.FileSystemDemo.demonstrate_file_system()

defmodule DayOne.RecursionExercises do
  @moduledoc """
  Run the tests with: mix test day_one/03_recursion.exs
  or in IEx:
  iex -r day_one/03_recursion.exs
  DayOne.RecursionExercisesTest.test_tail_recursive_reduce/0
  DayOne.RecursionExercisesTest.test_deep_flatten/0
  DayOne.RecursionExercisesTest.test_memoized_fibonacci/0
  """

  @spec reduce([any()], any(), (any(), any() -> any())) :: any()
  def reduce(_list, _acc, _fun) do
    # Implement a tail-recursive reduce function.
    # This should work like Enum.reduce/3 but using your own recursion.
    #
    # The function should:
    # - Take a list, an initial accumulator, and a function
    # - Apply the function to each element and the accumulator
    # - Return the final accumulated result
    #
    # Hint: Use a helper function for the recursion to make it tail-recursive.
    # Base case: empty list returns the accumulator
    # Recursive case: apply function to head and accumulator, recurse with tail
    #
    # Example: reduce([1, 2, 3], 0, &+/2) => 6
    nil  # TODO: Replace with your implementation
  end

  @spec deep_flatten([any()]) :: [any()]
  def deep_flatten(_list) do
    # Recursively flatten a nested list structure to arbitrary depth.
    # Transform [[1, 2], [3, [4, 5]], 6] into [1, 2, 3, 4, 5, 6]
    #
    # Hint: Use an accumulator pattern with a helper function.
    # When you encounter a list as the head, you can prepend it to the tail
    # and continue processing (head ++ tail).
    #
    # Handle arbitrarily deep nesting.
    # Example: deep_flatten([1, [2, [3, 4]], 5]) => [1, 2, 3, 4, 5]
    []  # TODO: Replace with your implementation
  end

  @spec fib(non_neg_integer(), map()) :: {non_neg_integer(), map()}
  def fib(_n, _cache \\ %{}) do
    # Implement Fibonacci with memoization for better performance.
    # This should return a tuple of {result, updated_cache}.
    #
    # The cache is a map that stores previously computed results.
    # Before computing fib(n), check if it's already in the cache.
    # If not, compute it and store the result in the cache.
    #
    # Base cases: fib(0) = 0, fib(1) = 1
    # Recursive case: fib(n) = fib(n-1) + fib(n-2)
    #
    # Hint: Use pattern matching and guards to handle different cases.
    # Return both the result and the updated cache as a tuple.
    #
    # Example: fib(10) should be much faster than naive recursion
    {0, %{}}  # TODO: Replace with your implementation
  end
end

ExUnit.start()

defmodule DayOne.RecursionExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.RecursionExercises, as: EX

  test "reduce/3 implements tail-recursive reduction" do
    # Test basic sum
    assert EX.reduce([1, 2, 3, 4], 0, &+/2) == 10

    # Test with different operation
    assert EX.reduce([1, 2, 3], 1, &*/2) == 6

    # Test with empty list
    assert EX.reduce([], 42, &+/2) == 42

    # Test building a list (order matters for tail recursion)
    result = EX.reduce([1, 2, 3], [], fn x, acc -> [x | acc] end)
    assert result == [3, 2, 1]
  end

  test "deep_flatten/1 flattens arbitrarily nested lists" do
    # Test empty list
    assert EX.deep_flatten([]) == []

    # Test flat list (no change needed)
    assert EX.deep_flatten([1, 2, 3]) == [1, 2, 3]

    # Test simple nesting
    assert EX.deep_flatten([[1, 2], [3, 4]]) == [1, 2, 3, 4]

    # Test deep nesting
    assert EX.deep_flatten([1, [2, [3, 4]], 5]) == [1, 2, 3, 4, 5]

    # Test complex nesting
    assert EX.deep_flatten([[1, [2, 3]], [4, [5, [6, 7]]], 8]) == [1, 2, 3, 4, 5, 6, 7, 8]
  end

  test "fib/2 calculates Fibonacci with memoization" do
    # Test base cases
    {result, _cache} = EX.fib(0)
    assert result == 0

    {result, _cache} = EX.fib(1)
    assert result == 1

    # Test recursive cases
    {result, _cache} = EX.fib(2)
    assert result == 1

    {result, _cache} = EX.fib(6)
    assert result == 8

    {result, _cache} = EX.fib(10)
    assert result == 55

    # Test that cache is being used and returned
    {result, cache} = EX.fib(5)
    assert result == 5
    assert is_map(cache)
    assert map_size(cache) > 0
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      # Public function is the entry point
      def reduce(list, acc, fun) do
        # The base case: an empty list returns the final accumulator
        if list == [], do: acc, else: do_reduce(list, acc, fun)
      end

      # Private helper function to perform the recursion
      defp do_reduce([head | tail], acc, fun) do
        # Apply the function to the head and the current accumulator
        new_acc = fun.(head, acc)
        # The recursive call is the last thing this function does (tail call)
        reduce(tail, new_acc, fun)
      end
    end
  end

  def answer_two do
    quote do
      def deep_flatten(list), do: do_flatten(list, [])

      # Base case: we've processed the whole list, return the reversed accumulator
      defp do_flatten([], acc), do: Enum.reverse(acc)
      # Recursive case for a nested list: flatten the head, then the tail
      defp do_flatten([head | tail], acc) when is_list(head) do
        # Flatten the head first and prepend it to the tail
        do_flatten(head ++ tail, acc)
      end
      # Recursive case for a non-list element: add it to the accumulator
      defp do_flatten([head | tail], acc) do
        do_flatten(tail, [head | acc])
      end
    end
  end

  def answer_three do
    quote do
      # Public function with memoization/cache
      def fib(n, cache \\ %{})
      # Base cases
      def fib(0, _), do: {0, %{0 => 0}}
      def fib(1, _), do: {1, %{1 => 1}}
      # Check cache before computing
      def fib(n, cache) when is_map_key(cache, n), do: {cache[n], cache}
      # Compute, cache, and return
      def fib(n, cache) do
        {fib_n_1, cache1} = fib(n - 1, cache)
        {fib_n_2, cache2} = fib(n - 2, cache1)
        result = fib_n_1 + fib_n_2
        {result, Map.put(cache2, n, result)}
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. tail_recursive_reduce/3
#{Macro.to_string(DayOne.Answers.answer_one())}
#  This implements the classic `reduce` pattern using tail-call optimization (TCO).
#  By passing the running total (accumulator) as an argument, the recursive call is
#  the very last operation, which allows the Elixir compiler to convert the
#  recursion into a loop, preventing stack overflow for large lists.

# 2. deep_flatten/1
#{Macro.to_string(DayOne.Answers.answer_two())}
#  This demonstrates handling multiple recursive cases. When the head is a list,
#  it's effectively "unpacked" and put back at the front of the list to be
#  processed. When the head is a simple element, it's added to the accumulator.
#  This is a good example of how recursion can process complex, nested structures.

# 3. fibonacci/1
#{Macro.to_string(DayOne.Answers.answer_three())}
#  A naive recursive Fibonacci function is very slow because it recalculates the
#  same values many times. This solution uses a map as a cache (a technique
#  called memoization) to store results. The cache is passed through the
#  recursive calls, dramatically improving performance.
""")
