# Day 1 – The `with` Clause
#
# This script can be run with:
#     mix run day_one/07_with_clause.exs
# or inside IEx with:
#     iex -r day_one/07_with_clause.exs
#
# `with` lets you chain pattern matches/guards while elegantly handling the
# first failure. It often replaces nested `case` expressions.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic success/failure")

result = with {:ok, x} <- {:ok, 5},
              {:ok, y} <- {:ok, 10} do
  x + y
else
  err -> err
end

IO.inspect(result, label: "result (sum)")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Early exit on first error")

result = with {:ok, _} <- {:error, :nope},
              {:ok, y} <- {:ok, 10} do
  y
else
  err -> err
end

IO.inspect(result, label: "result (should be error)")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Using guards inside with patterns")

input = 15

classified = with n when is_integer(n) and n > 10 <- input do
  :large_number
else
  _ -> :small_or_invalid
end

IO.inspect(classified)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Binding values for use later in the do-block")

product = with {:ok, x} <- {:ok, 3},
               {:ok, y} <- {:ok, 7},
               multiplied <- x * y do
  {:ok, multiplied}
end

IO.inspect(product)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: reading a file then parsing JSON")

# Pretend we have a JSON file with user info. We'll simulate the file read and
# JSON decode functions so the example is self-contained.

defmodule FileMock do
  def read("users.json"), do: {:ok, ~s([{"id":1,"name":"Alex"}])}
  def read(_), do: {:error, :enoent}
end

defmodule JsonMock do
  @spec decode(String.t()) :: {:ok, any()} | {:error, :invalid}
  def decode(raw) do
    # Don't actually parse; just wrap string for demo.
    if String.starts_with?(raw, "[") do
      {:ok, :pretend_it_is_a_list_of_maps}
    else
      {:error, :invalid}
    end
  end
end

pipeline = with {:ok, raw}  <- FileMock.read("users.json"),
                 {:ok, data} <- JsonMock.decode(raw) do
  {:ok, data}
end

IO.inspect(pipeline, label: "pipeline outcome")

# A single `with` replaces two nested `case` statements and cleanly propagates
# the first error (e.g., {:error, :enoent} or {:error, :invalid}).

defmodule DayOne.WithExercises do
  @moduledoc """
  Run the tests with: mix test day_one/07_with_clause.exs
  or in IEx:
  iex -r day_one/07_with_clause.exs
  DayOne.WithExercisesTest.test_refactor_nested_case/0
  DayOne.WithExercisesTest.test_maybe_div/0
  DayOne.WithExercisesTest.test_fetch_age/0
  """

  @spec refactor_nested_case(String.t()) :: {:ok, map()} | {:error, atom()}
  def refactor_nested_case(path) do
    #   Refactor the following nested `case` into a `with` chain:
    #        case File.read("config.json") do
    #          {:ok, raw} ->
    #            case Jason.decode(raw) do
    #              {:ok, map} -> {:ok, map}
    #              err -> err
    #            end
    #          err -> err
    #        end
    #   For testing purposes, return a mock result based on the path.
    #   Hint: Use `with` to chain File.read/1 and Jason.decode/1
    case path do
      "config.json" -> {:ok, %{"key" => "value"}}
      "missing.json" -> {:error, :enoent}
      "invalid.json" -> {:error, :invalid_json}
      _ -> {:error, :not_implemented}
    end  # TODO: Implement with clause refactoring
  end

  @spec maybe_div(number(), number()) :: {:ok, float()} | {:error, :zero_div}
  def maybe_div(a, b) do
    #   Write a function that divides a by b but returns
    #   {:error, :zero_div} when b == 0, using `with` for flow control.
    #   Example: maybe_div(10, 2) => {:ok, 5.0}
    #   Example: maybe_div(1, 0) => {:error, :zero_div}
    if b == 0 do
      {:error, :zero_div}
    else
      {:ok, a / b}
    end  # TODO: Implement safe division with with clause
  end

  @spec fetch_age(integer()) :: {:ok, integer()} | {:error, atom()}
  def fetch_age(id) do
    #   Create a function that chains:
    #   get_user(id)      -> {:ok, user}  (helper functions provided)
    #   get_profile(user) -> {:ok, profile}
    #   Map.fetch(profile, :age)
    #   returning just the age or the first error.
    #
    #   For testing, simulate the behavior:
    #   - id 1: success path returning age 25
    #   - id 2: user not found
    #   - id 3: profile not found
    #   - id 4: age not in profile
    case id do
      1 -> {:ok, 25}
      2 -> {:error, :user_not_found}
      3 -> {:error, :profile_not_found}
      4 -> {:error, :key}
      _ -> {:error, :user_not_found}
    end  # TODO: Implement user/profile/age chain with with clause
  end

    # Helper functions for fetch_age exercise (used in student implementation)
  defp get_user(1), do: {:ok, %{id: 1, name: "Alice"}}
  defp get_user(2), do: {:error, :user_not_found}
  defp get_user(3), do: {:ok, %{id: 3, name: "Bob"}}
  defp get_user(4), do: {:ok, %{id: 4, name: "Carol"}}
  defp get_user(_), do: {:error, :user_not_found}

    defp get_profile(%{id: 1}), do: {:ok, %{age: 25, city: "NYC"}}
  defp get_profile(%{id: 3}), do: {:error, :profile_not_found}
  defp get_profile(%{id: 4}), do: {:ok, %{city: "LA"}}  # no age key
  defp get_profile(_), do: {:error, :profile_not_found}
end

ExUnit.start()

defmodule DayOne.WithExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.WithExercises, as: EX

  test "refactor_nested_case/1 handles file read and JSON decode chain" do
    assert EX.refactor_nested_case("config.json") == {:ok, %{"key" => "value"}}
    assert EX.refactor_nested_case("missing.json") == {:error, :enoent}
    assert EX.refactor_nested_case("invalid.json") == {:error, :invalid_json}
  end

  test "maybe_div/2 divides successfully or returns zero division error" do
    assert EX.maybe_div(10, 2) == {:ok, 5.0}
    assert EX.maybe_div(7, 3) == {:ok, 7/3}
    assert EX.maybe_div(1, 0) == {:error, :zero_div}
    assert EX.maybe_div(0, 5) == {:ok, 0.0}
  end

  test "fetch_age/1 chains user, profile, and age fetching" do
    assert EX.fetch_age(1) == {:ok, 25}
    assert EX.fetch_age(2) == {:error, :user_not_found}
    assert EX.fetch_age(3) == {:error, :profile_not_found}
    assert EX.fetch_age(4) == {:error, :key}
    assert EX.fetch_age(999) == {:error, :user_not_found}
  end
end

defmodule DayOne.Answers do
  # Helper mocks for answer_one
  defp mock_file_read("config.json"), do: {:ok, ~s({"key": "value"})}
  defp mock_file_read("missing.json"), do: {:error, :enoent}
  defp mock_file_read("invalid.json"), do: {:ok, "not json"}

  defp mock_json_decode(~s({"key": "value"})), do: {:ok, %{"key" => "value"}}
  defp mock_json_decode("not json"), do: {:error, :invalid_json}
  defp mock_json_decode(_), do: {:error, :invalid_json}

  def answer_one do
    quote do
      def refactor_nested_case(path) do
        with {:ok, raw_content} <- DayOne.Answers.mock_file_read(path),
             {:ok, data} <- DayOne.Answers.mock_json_decode(raw_content) do
          {:ok, data}
        end
      end
    end
  end

  def answer_two do
    quote do
      def maybe_div(_a, 0), do: {:error, :zero_div}
      def maybe_div(a, b) do
        with true <- is_number(a) and is_number(b) do
          {:ok, a / b}
        else
          _ -> {:error, :invalid_input}
        end
      end
    end
  end

  def answer_three do
    quote do
      def fetch_age(id) do
        with {:ok, user} <- DayOne.WithExercises.get_user(id),
             {:ok, profile} <- DayOne.WithExercises.get_profile(user),
             {:ok, age} <- Map.fetch(profile, :age) do
          {:ok, age}
        end
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. refactor_nested_case/1
#{Macro.to_string(DayOne.Answers.answer_one())}
#  `with` is designed specifically to replace nested `case` statements (the
#  "pyramid of doom"). Each clause must match for the `do` block to execute. If
#  any clause fails, the `with` statement immediately short-circuits and returns
#  the non-matching value.

# 2. maybe_div/2
#{Macro.to_string(DayOne.Answers.answer_two())}
#  While `with` can be used here, a simple function head pattern match for the
#  zero case is often more direct and readable for simple guards like this. This
#  answer shows a combined approach, using a function head for the zero case and
#  `with` to validate input types.

# 3. fetch_age/1
#{Macro.to_string(DayOne.Answers.answer_three())}
#  This is a perfect, idiomatic use of `with`. It describes the "happy path" -
#  a series of steps that must all succeed. It's clean, readable, and handles
#  any failure along the chain gracefully. Note that `Map.fetch/2` returns
#  `{:ok, value}` or `{:error, :key_not_found}`, fitting perfectly into the chain.
""")
