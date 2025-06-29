# Day 1 – Tuple Return Patterns (`{:ok, ...}` / `{:error, ...}`)
#
# This script can be run with:
#     mix run day_one/06_tuple_return_patterns.exs
# or inside IEx with:
#     iex -r day_one/06_tuple_return_patterns.exs
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

  # Demo function to showcase the bank account usage
  def demo do
    acct = %__MODULE__{id: "ABC", balance_cents: 10_00}

    with {:ok, acct} <- deposit(acct, 5_00),
         {:ok, acct} <- withdraw(acct, 12_00),
         {:ok, acct} <- withdraw(acct, 5_00) do
      IO.inspect(acct, label: "final account state")
    else
      {:error, reason} -> IO.inspect(reason, label: "operation failed")
    end
  end
end

# Run the demo
Bank.Account.demo()

defmodule DayOne.TupleExercises do
    @moduledoc """
  Run the tests with: mix test day_one/06_tuple_return_patterns.exs
  or in IEx:
  iex -r day_one/06_tuple_return_patterns.exs
  DayOne.TupleExercisesTest.test_parse_bool/0
  DayOne.TupleExercisesTest.test_read_bool_file/0
  DayOne.TupleExercisesTest.test_bank_pipeline/0
  """

  @spec parse_bool(String.t()) :: {:ok, boolean()} | {:error, :invalid}
  def parse_bool(input) do
    #   Write a function that accepts "true" | "false" strings and returns
    #   {:ok, boolean} or {:error, :invalid}.
    #   Example: parse_bool("true") => {:ok, true}
    #   Example: parse_bool("false") => {:ok, false}
    #   Example: parse_bool("maybe") => {:error, :invalid}
    {:error, :invalid}  # TODO: Implement boolean parsing with pattern matching
  end

  @spec read_bool_file(String.t()) :: {:ok, boolean()} | {:error, atom()}
  def read_bool_file(path) do
    #   Using `with`, chain _mock_file_read/1 and parse_bool/1 to read a one-line
    #   file containing "true"/"false" and return the boolean.
    #   For testing purposes, simulate file reading:
    #   - "true.txt" contains "true"
    #   - "false.txt" contains "false"
    #   - "invalid.txt" contains "maybe"
    #   - "missing.txt" doesn't exist
    #   Hint: Use String.trim/1 to clean up the file content
    {:error, :enoent}  # TODO: Implement file reading and boolean parsing chain
  end

  @spec bank_pipeline(Bank.Account.t(), Bank.Account.money(), Bank.Account.money()) ::
    {:ok, Bank.Account.t()} | {:error, atom()}
  def bank_pipeline(account, deposit_amount, withdraw_amount) do
    #   Convert the Bank.Account example into a `with` pipeline that
    #   deposits then withdraws, short-circuiting on the first error.
    #   Return either {:ok, final_account} or {:error, reason}
    #   Example: bank_pipeline(%Bank.Account{id: "TEST", balance_cents: 1000}, 500, 200)
    #   should deposit 500 cents, then withdraw 200 cents
    {:ok, account}  # TODO: Implement bank deposit/withdraw pipeline with with clause
  end

  # Helper function for read_bool_file testing (used in student implementation)
  defp _mock_file_read("true.txt"), do: {:ok, "true\n"}
  defp _mock_file_read("false.txt"), do: {:ok, "false\n"}
  defp _mock_file_read("invalid.txt"), do: {:ok, "maybe\n"}
  defp _mock_file_read("missing.txt"), do: {:error, :enoent}
  defp _mock_file_read(_), do: {:error, :enoent}
end

ExUnit.start()

defmodule DayOne.TupleExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.TupleExercises, as: EX

  test "parse_bool/1 converts string to boolean or returns error" do
    assert EX.parse_bool("true") == {:ok, true}
    assert EX.parse_bool("false") == {:ok, false}
    assert EX.parse_bool("maybe") == {:error, :invalid}
    assert EX.parse_bool("TRUE") == {:error, :invalid}
    assert EX.parse_bool("") == {:error, :invalid}
  end

  test "read_bool_file/1 chains file reading and boolean parsing" do
    assert EX.read_bool_file("true.txt") == {:ok, true}
    assert EX.read_bool_file("false.txt") == {:ok, false}
    assert EX.read_bool_file("invalid.txt") == {:error, :invalid}
    assert EX.read_bool_file("missing.txt") == {:error, :enoent}
  end

  test "bank_pipeline/3 chains deposit and withdrawal operations" do
    account = %Bank.Account{id: "TEST", balance_cents: 1000}

    # Successful pipeline
    assert {:ok, final} = EX.bank_pipeline(account, 500, 200)
    assert final.balance_cents == 1300

    # Insufficient funds after deposit
    assert EX.bank_pipeline(account, 100, 2000) == {:error, :insufficient_funds}

    # Account with zero balance
    empty_account = %Bank.Account{id: "EMPTY", balance_cents: 0}
    assert EX.bank_pipeline(empty_account, 100, 50) == {:ok, %{empty_account | balance_cents: 50}}
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def parse_bool("true"), do: {:ok, true}
      def parse_bool("false"), do: {:ok, false}
      def parse_bool(_), do: {:error, :invalid}
    end
  end

  def answer_two do
    quote do
      def read_bool_file(path) do
        with {:ok, content} <- DayOne.TupleExercises._mock_file_read(path),
             trimmed_content <- String.trim(content),
             {:ok, bool} <- DayOne.TupleExercises.parse_bool(trimmed_content) do
          {:ok, bool}
        end
      end
    end
  end

  def answer_three do
    quote do
      def bank_pipeline(account, deposit_amount, withdraw_amount) do
        with {:ok, after_deposit} <- Bank.Account.deposit(account, deposit_amount),
             {:ok, after_withdrawal} <- Bank.Account.withdraw(after_deposit, withdraw_amount) do
          {:ok, after_withdrawal}
        end
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. parse_bool/1
#{Macro.to_string(DayOne.Answers.answer_one())}
#  Using function heads to pattern match on the exact string values is the most
#  concise and idiomatic way to implement this. The final clause `_` acts as a
#  catch-all for any invalid input.

# 2. read_bool_file/1
#{Macro.to_string(DayOne.Answers.answer_two())}
#  The `with` special form is perfect for chaining operations that can fail (i.e.,
#  that return `{:ok, ...}` or `{:error, ...}`). If any clause fails to match,
#  the `with` block short-circuits and returns the non-matching value immediately.

# 3. bank_pipeline/3
#{Macro.to_string(DayOne.Answers.answer_three())}
#  This again shows the power of `with` for creating clean, readable pipelines
#  for operations that can fail. The result of a successful step is passed to
#  the next, and any error halts the entire chain.
""")
