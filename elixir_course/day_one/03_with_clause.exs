# Day 1 – The `with` Clause
#
# Run with `mix run day_one/03_with_clause.exs`
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
