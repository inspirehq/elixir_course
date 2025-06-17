# Day 1 – Tuple Return Patterns (`{:ok, ...}` / `{:error, ...}`)
#
# Run with `mix run day_one/04_tuple_return_patterns.exs`
#
# Returning tagged tuples is the idiomatic way to express success & failure in
# Elixir. Below are several patterns and a longer example illustrating their
# usage in a small banking domain.

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 1 – Simple success tuple")

parse_int = fn str ->
  case Integer.parse(str) do
    {n, _} -> {:ok, n}
    :error -> {:error, :not_an_integer}
  end
end

IO.inspect(parse_int.("42"))
IO.inspect(parse_int.("abc"))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Using pattern matching to branch on result")

case parse_int.("99") do
  {:ok, n} -> IO.puts("parsed: #{n}")
  {:error, reason} -> IO.puts("failed: #{reason}")
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Chaining with `with` and tuples")

result = with {:ok, a} <- parse_int.("5"),
              {:ok, b} <- parse_int.("3") do
  {:ok, a * b}
end

IO.inspect(result)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Pattern matching in function heads")

defmodule Maths do
  def safe_div(_, 0), do: {:error, :division_by_zero}
  def safe_div(a, b), do: {:ok, a / b}
end

IO.inspect(Maths.safe_div(10, 2))
IO.inspect(Maths.safe_div(10, 0))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: minimal bank account module")

defmodule Bank.Account do
  defstruct [:id, balance_cents: 0]

  @type t :: %__MODULE__{id: String.t(), balance_cents: non_neg_integer()}
  @type money :: non_neg_integer()

  @spec deposit(t, money()) :: {:ok, t()}
  def deposit(%__MODULE__{} = acct, cents) when cents > 0 do
    {:ok, %{acct | balance_cents: acct.balance_cents + cents}}
  end

  @spec withdraw(t, money()) :: {:ok, t()} | {:error, :insufficient_funds}
  def withdraw(%__MODULE__{} = acct, cents) when cents > 0 do
    if acct.balance_cents >= cents do
      {:ok, %{acct | balance_cents: acct.balance_cents - cents}}
    else
      {:error, :insufficient_funds}
    end
  end
end

acct = %Bank.Account{id: "ABC", balance_cents: 10_00}

with {:ok, acct} <- Bank.Account.deposit(acct, 5_00),
     {:ok, acct} <- Bank.Account.withdraw(acct, 12_00),
     {:ok, acct} <- Bank.Account.withdraw(acct, 5_00) do
  IO.inspect(acct, label: "final account state")
else
  {:error, reason} -> IO.inspect(reason, label: "operation failed")
end
