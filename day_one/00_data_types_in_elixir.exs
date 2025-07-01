# Day 1 – Data Types in Elixir
#
# This script can be run with:
#     mix run day_one/00_data_types_in_elixir.exs
# or inside IEx with:
#     iex -r day_one/00_data_types_in_elixir.exs
#
# This lesson introduces all the fundamental data types available in Elixir,
# showing their syntax, common usage patterns, and key characteristics.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Integers and Floats")

# Integers can be arbitrarily large in Elixir
small_int = 42
large_int = 123_456_789_012_345_678_901_234_567_890
binary_int = 0b1010  # binary literal (10 in decimal)
hex_int = 0xFF       # hexadecimal literal (255 in decimal)
octal_int = 0o777    # octal literal (511 in decimal)

IO.inspect(small_int, label: "small integer")
IO.inspect(large_int, label: "large integer")
IO.inspect(binary_int, label: "binary literal")
IO.inspect(hex_int, label: "hex literal")

# Floats
pi = 3.14159
scientific = 1.23e10  # scientific notation

IO.inspect(pi, label: "float")
IO.inspect(scientific, label: "scientific notation")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Atoms and Booleans")

# Atoms are constants whose name is their value
status = :ok
error = :error
module_name = :my_module

IO.inspect(status, label: "atom")
IO.inspect(:hello, label: "atom literal")

# Booleans are just special atoms
is_valid = true
is_complete = false

IO.inspect(is_valid, label: "boolean (true atom)")
IO.inspect(is_complete, label: "boolean (false atom)")
IO.inspect(true == :true, label: "true is the atom :true")

# Nil is also an atom
nothing = nil
IO.inspect(nothing, label: "nil (the atom :nil)")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Strings and Binaries")

# Strings are UTF-8 encoded binaries
greeting = "Hello, World!"
multiline = """
This is a
multiline string
"""

IO.inspect(greeting, label: "string")
IO.inspect(byte_size(greeting), label: "byte size")
IO.inspect(String.length(greeting), label: "character length")

# String interpolation
name = "Alice"
message = "Hello, #{name}!"
IO.inspect(message, label: "interpolated string")

# Binaries and bitstrings
binary = <<1, 2, 3, 4>>
utf8_binary = <<"Hello">>
bitstring = <<1::4, 2::4>>  # 4-bit segments

IO.inspect(binary, label: "binary")
IO.inspect(utf8_binary, label: "UTF-8 binary")
IO.inspect(bitstring, label: "bitstring")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Lists and Tuples")

# Lists are linked lists, efficient for prepending
fruits = ["apple", "banana", "cherry"]
numbers = [1, 2, 3, 4, 5]
mixed = [1, "two", :three, 4.0]

IO.inspect(fruits, label: "list of strings")
IO.inspect([0 | numbers], label: "prepended list")

# Tuples are fixed-size, efficient for small collections
point = {10, 20}
rgb = {255, 128, 0}
response = {:ok, "data", 123}

IO.inspect(point, label: "2-tuple")
IO.inspect(response, label: "3-tuple")

# Lists vs Tuples usage patterns
coordinates = [{0, 0}, {1, 2}, {3, 4}]  # List of tuples
IO.inspect(coordinates, label: "list of coordinate tuples")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Maps and Keyword Lists")

# Maps are key-value stores, efficient for larger collections
user = %{
  id: 1,
  name: "Alice",
  email: "alice@example.com",
  active: true
}

# Maps with string keys
config = %{
  "host" => "localhost",
  "port" => 4000,
  "ssl" => false
}

IO.inspect(user, label: "map with atom keys")
IO.inspect(config, label: "map with string keys")

# Map access
IO.inspect(user[:name], label: "map access with []")
IO.inspect(user.name, label: "map access with dot notation")

# Keyword lists are lists of 2-tuples, commonly used for options
options = [host: "localhost", port: 4000, ssl: false]
also_options = [{:host, "localhost"}, {:port, 4000}, {:ssl, false}]

IO.inspect(options, label: "keyword list")
IO.inspect(also_options, label: "keyword list (explicit tuples)")
IO.inspect(options[:host], label: "keyword list access")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 6 – Structs, Ranges, and Functions")

# Structs are maps with a fixed set of keys and a module name
# In a real application, you'd define them like this:
#
# defmodule User do
#   defstruct [:id, :name, :email, active: true]
# end
#
# Then create instances like this:
# alice = %User{id: 1, name: "Alice", email: "alice@example.com"}

# For demonstration, let's look at an existing struct: DateTime
now = DateTime.utc_now()
IO.inspect(now, label: "DateTime struct")
IO.inspect(is_map(now), label: "struct is a map")
IO.inspect(now.__struct__, label: "struct module name")

# We can see it has specific fields
IO.inspect(now.year, label: "accessing struct field")
IO.inspect(now.month, label: "accessing struct field")

# Ranges for sequences
small_range = 1..5
large_range = 1..1000
step_range = 1..10//2  # step by 2

IO.inspect(Enum.to_list(small_range), label: "range as list")
IO.inspect(step_range, label: "step range")

# Anonymous functions
add = fn a, b -> a + b end
multiply = &(&1 * &2)  # capture syntax
square = &(&1 * &1)

IO.inspect(add.(5, 3), label: "anonymous function call")
IO.inspect(multiply.(4, 7), label: "capture syntax function")
IO.inspect(square.(6), label: "single argument capture")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 7 – Process Types and References")

# PIDs identify processes
current_pid = self()
IO.inspect(current_pid, label: "current process PID")

# References are unique identifiers
ref1 = make_ref()
ref2 = make_ref()
IO.inspect(ref1, label: "reference 1")
IO.inspect(ref2, label: "reference 2")
IO.inspect(ref1 == ref2, label: "references are unique")

# Ports represent external resources (rarely used directly)
# We'll just show the type exists
IO.inspect(is_port(current_pid), label: "PID is not a port")

defmodule DayOne.DataTypesExercises do
  @moduledoc """
  Run the tests with: mix test day_one/00_data_types_in_elixir.exs
  or in IEx:
  iex -r day_one/00_data_types_in_elixir.exs
  DayOne.DataTypesExercisesTest.test_type_inspector/0
  DayOne.DataTypesExercisesTest.test_data_converter/0
  DayOne.DataTypesExercisesTest.test_collection_builder/0
  """

  @spec type_inspector(any()) :: atom()
  def type_inspector(value) do
    # Implement a function that returns the Elixir type of the given value as an atom.
    # Use pattern matching and guards to identify the type.
    # Return one of: :integer, :float, :atom, :string, :list, :tuple, :map, :function, :pid, :reference, :port
    # Examples:
    #   type_inspector(42) when is_integer(42)        ⇒ :integer
    #   type_inspector("hello") when is_binary("hello")   ⇒ :string
    #   type_inspector([1, 2]) when is_list([1, 2])    ⇒ :list
    value  # TODO: Implement type detection logic
  end

  @spec data_converter(any()) :: map()
  def data_converter(keyword_list) do
    # Convert a keyword list to a map.
    # Handle the case where the input is not a keyword list by returning an empty map.
    # Examples:
    #   data_converter([name: "Alice", age: 30]) ⇒ %{name: "Alice", age: 30}
    #   data_converter([])                       ⇒ %{}
    #   data_converter("not a list")             ⇒ %{}
    # Hint: use Keyword.keyword?/1 to check if the input is a keyword list
    # Hint: use Enum.into/2 to convert the keyword list to a map
    %{}  # TODO: Implement keyword list to map conversion
  end

  @spec collection_builder(atom(), list()) :: any()
  def collection_builder(type, items) do
    # Build different collection types from a list of items based on the type parameter.
    # Support: :list (return as-is), :tuple (convert to tuple), :map_with_index (create map with indices as keys)
    # Examples:
    #   collection_builder(:list, [1, 2, 3])           ⇒ [1, 2, 3]
    #   collection_builder(:tuple, [1, 2, 3])          ⇒ {1, 2, 3}
    #   collection_builder(:map_with_index, [:a, :b])  ⇒ %{0 => :a, 1 => :b}
    # Hint: use List.to_tuple/1 to convert the list to a tuple
    # Hint: use Enum.with_index/1 to add indices to the list
    # Hint: use Enum.into/2 to convert the list to a map
    items  # TODO: Implement collection type conversion
  end
end

ExUnit.start()

defmodule DayOne.DataTypesExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.DataTypesExercises, as: EX

  test "type_inspector/1 correctly identifies data types" do
    assert EX.type_inspector(42) == :integer
    assert EX.type_inspector(3.14) == :float
    assert EX.type_inspector(:atom) == :atom
    assert EX.type_inspector("string") == :string
    assert EX.type_inspector([1, 2]) == :list
    assert EX.type_inspector({1, 2}) == :tuple
    assert EX.type_inspector(%{key: :value}) == :map
    assert EX.type_inspector(fn -> :ok end) == :function
    assert EX.type_inspector(self()) == :pid
    assert EX.type_inspector(make_ref()) == :reference
  end

  test "data_converter/1 converts keyword lists to maps" do
    assert EX.data_converter([name: "Alice", age: 30]) == %{name: "Alice", age: 30}
    assert EX.data_converter([]) == %{}
    assert EX.data_converter("not a list") == %{}
    assert EX.data_converter([1, 2, 3]) == %{}  # not a keyword list
  end

  test "collection_builder/2 creates different collection types" do
    assert EX.collection_builder(:list, [1, 2, 3]) == [1, 2, 3]
    assert EX.collection_builder(:tuple, [1, 2, 3]) == {1, 2, 3}
    assert EX.collection_builder(:map_with_index, [:a, :b]) == %{0 => :a, 1 => :b}
    assert EX.collection_builder(:map_with_index, []) == %{}
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def type_inspector(value) when is_integer(value), do: :integer
      def type_inspector(value) when is_float(value), do: :float
      def type_inspector(value) when is_atom(value), do: :atom
      def type_inspector(value) when is_binary(value), do: :string
      def type_inspector(value) when is_list(value), do: :list
      def type_inspector(value) when is_tuple(value), do: :tuple
      def type_inspector(value) when is_map(value), do: :map
      def type_inspector(value) when is_function(value), do: :function
      def type_inspector(value) when is_pid(value), do: :pid
      def type_inspector(value) when is_reference(value), do: :reference
      def type_inspector(value) when is_port(value), do: :port
      def type_inspector(_), do: :unknown
    end
  end

  def answer_two do
    quote do
      def data_converter(keyword_list) when is_list(keyword_list) do
        if Keyword.keyword?(keyword_list) do
          Enum.into(keyword_list, %{})
        else
          %{}
        end
      end
      def data_converter(_), do: %{}
    end
  end

  def answer_three do
    quote do
      def collection_builder(:list, items), do: items
      def collection_builder(:tuple, items), do: List.to_tuple(items)
      def collection_builder(:map_with_index, items) do
        items
        |> Enum.with_index()
        |> Enum.into(%{}, fn {item, index} -> {index, item} end)
      end
      def collection_builder(_, items), do: items
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. type_inspector/1
#{Macro.to_string(DayOne.Answers.answer_one())}
#  This function demonstrates using guards to identify types. Elixir provides
#  built-in type checking functions like `is_integer/1`, `is_binary/1`, etc.
#  The order matters - more specific checks should come first. Note that strings
#  are checked with `is_binary/1` because strings are UTF-8 encoded binaries.

# 2. data_converter/1
#{Macro.to_string(DayOne.Answers.answer_two())}
#  This shows how to safely convert between collection types. We first check if
#  the input is a list, then use `Keyword.keyword?/1` to verify it's actually a
#  keyword list (list of 2-tuples with atom keys). `Enum.into/2` is a powerful
#  function for converting between collection types.

# 3. collection_builder/2
#{Macro.to_string(DayOne.Answers.answer_three())}
#  This demonstrates building different collection types from the same data.
#  `List.to_tuple/1` converts lists to tuples, and `Enum.with_index/1` adds
#  indices that we can then use to build a map. The pipe operator makes the
#  transformation chain readable.
""")
