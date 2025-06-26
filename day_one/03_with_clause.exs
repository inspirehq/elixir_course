# Day 1 – The `with` Clause
#
# This script can be run with:
#     mix run day_one/03_with_clause.exs
# or inside IEx with:
#     iex -r day_one/03_with_clause.exs
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
  Run the tests with: mix test day_one/03_with_clause.exs
  or in IEx:
  iex -r day_one/03_with_clause.exs
  DayOne.WithExercisesTest.test_refactor_nested_case/0
  DayOne.WithExercisesTest.test_maybe_div/0
  DayOne.WithExercisesTest.test_fetch_age/0
  """

  @spec refactor_nested_case(String.t()) :: {:ok, map()} | {:error, atom()}
  def refactor_nested_case(_path) do
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
    :not_implemented
  end

  @spec maybe_div(number(), number()) :: {:ok, float()} | {:error, :zero_div}
  def maybe_div(_a, _b) do
    #   Write a function that divides a by b but returns
    #   {:error, :zero_div} when b == 0, using `with` for flow control.
    #   Example: maybe_div(10, 2) => {:ok, 5.0}
    #   Example: maybe_div(1, 0) => {:error, :zero_div}
    :not_implemented
  end

  @spec fetch_age(integer()) :: {:ok, integer()} | {:error, atom()}
  def fetch_age(_id) do
    #   Create a function that chains:
    #   get_user(id)      -> {:ok, user}
    #   get_profile(user) -> {:ok, profile}
    #   Map.fetch(profile, :age)
    #   returning just the age or the first error.
    #
    #   For testing, simulate the behavior:
    #   - id 1: success path returning age 25
    #   - id 2: user not found
    #   - id 3: profile not found
    #   - id 4: age not in profile
    :not_implemented
  end

  # Helper functions for fetch_age exercise
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

"""
ANSWERS & EXPLANATIONS

# 1. refactor_nested_case/1
def refactor_nested_case(path) do
  with {:ok, raw} <- mock_file_read(path),
       {:ok, map} <- mock_json_decode(raw) do
    {:ok, map}
  end
end

defp mock_file_read("config.json"), do: {:ok, ~s({"key": "value"})}
defp mock_file_read("missing.json"), do: {:error, :enoent}
defp mock_file_read("invalid.json"), do: {:ok, "not json"}

defp mock_json_decode(~s({"key": "value"})), do: {:ok, %{"key" => "value"}}
defp mock_json_decode("not json"), do: {:error, :invalid_json}
#  Single expression is clearer; `with` stops on first {:error, _}.

# 2. maybe_div/2
def maybe_div(a, b) do
  with true <- b != 0 do
    {:ok, a / b}
  else
    false -> {:error, :zero_div}
  end
end
#  Uses `with` to guard against division by zero before performing calculation.

# 3. fetch_age/1
def fetch_age(id) do
  with {:ok, user} <- get_user(id),
       {:ok, profile} <- get_profile(user),
       {:ok, age} <- Map.fetch(profile, :age) do
    {:ok, age}
  end
end
#  Guards the happy path while propagating the first failure in the chain.
"""
