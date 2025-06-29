# Day 2 – Transactions & Ecto.Multi
#
# This script can be run with:
#     mix run day_two/06_transactions_and_multi.exs
# or inside IEx with:
#     iex -r day_two/06_transactions_and_multi.exs
#
# Transactions ensure data consistency by grouping operations that must all
# succeed or all fail together. Ecto.Multi provides a composable way to
# build complex, transactional operations.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic transaction concepts")

defmodule DayTwo.TransactionBasics do
  @moduledoc """
  Understanding why and when to use database transactions.
  """

  def explain_acid_properties do
    quote do
      # ACID properties that transactions guarantee:
      #
      # • Atomicity: All operations succeed or all fail
      # • Consistency: Database remains in valid state
      # • Isolation: Concurrent transactions don't interfere
      # • Durability: Committed changes persist after crashes
      #
      # Without transactions, partial failures can leave data inconsistent.
    end
  end

  def show_transaction_scenarios do
    scenarios = [
      "Money transfer: Debit one account, credit another",
      "User registration: Create user, send welcome email, log event",
      "Order processing: Reserve inventory, charge payment, create order",
      "Blog post: Create post, update category counts, notify subscribers",
      "Data migration: Transform records across multiple tables"
    ]

    IO.puts("Common transaction scenarios:")
    Enum.each(scenarios, fn scenario ->
      IO.puts("  • #{scenario}")
    end)
  end

  def show_basic_transaction_syntax do
    quote do
      # Basic transaction with Repo.transaction/1
      result =
        Repo.transaction(fn ->
          # All operations here are wrapped in a transaction
          user = Repo.insert!(%User{name: "Alice"})
          profile = Repo.insert!(%Profile{user_id: user.id, bio: "Hello"})

          # If any operation fails, entire transaction rolls back
          {user, profile}
        end)

      case result do
        {:ok, {user, profile}} ->
          # Success
          :ok
        {:error, reason} ->
          # Rollback occurred
          :error
      end
    end
  end
end

IO.puts("ACID properties:")
IO.puts(Macro.to_string(DayTwo.TransactionBasics.explain_acid_properties()))
DayTwo.TransactionBasics.show_transaction_scenarios()
IO.puts("\nBasic transaction syntax:")
IO.puts(Macro.to_string(DayTwo.TransactionBasics.show_basic_transaction_syntax()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Ecto.Multi for composable transactions")

defmodule DayTwo.MultiBasics do
  @moduledoc """
  Ecto.Multi provides a declarative way to build transactions.
  """

  def show_multi_advantages do
    quote do
      # Advantages of Ecto.Multi:
      #
      # • Composable: Build transactions step by step
      # • Readable: Clear operation names and dependencies
      # • Testable: Inspect multi without executing
      # • Rollback safe: Automatic cleanup on any failure
      # • Result access: Use results from previous steps
    end
  end

  def show_basic_multi_example do
    quote do
      # Building a Multi operation
      alias Ecto.Multi

      multi =
        Multi.new()
        |> Multi.insert(:user, %User{name: "Bob"})
        |> Multi.insert(:profile, fn %{user: user} ->
          %Profile{user_id: user.id, bio: "Hello"}
        end)
        |> Multi.update(:welcome_sent, fn %{user: user} ->
          User.changeset(user, %{welcome_sent: true})
        end)

      # Execute the transaction
      case Repo.transaction(multi) do
        {:ok, results} ->
          %{user: user, profile: profile, welcome_sent: updated_user} = results
          :ok
        {:error, operation, changeset, changes_so_far} ->
          # operation = the step that failed (:user, :profile, or :welcome_sent)
          # changeset = the invalid changeset
          # changes_so_far = successfully completed operations
          :error
      end
    end
  end

  def show_multi_operations do
    operations = [
      "Multi.insert/3 - Insert a new record",
      "Multi.update/3 - Update an existing record",
      "Multi.delete/3 - Delete a record",
      "Multi.run/3 - Execute custom function",
      "Multi.insert_all/4 - Bulk insert records",
      "Multi.update_all/4 - Bulk update records",
      "Multi.delete_all/3 - Bulk delete records"
    ]

    IO.puts("Multi operation types:")
    Enum.each(operations, fn op ->
      IO.puts("  • #{op}")
    end)
  end
end

IO.puts("Multi advantages:")
IO.puts(Macro.to_string(DayTwo.MultiBasics.show_multi_advantages()))
DayTwo.MultiBasics.show_multi_operations()
IO.puts("\nBasic Multi example:")
IO.puts(Macro.to_string(DayTwo.MultiBasics.show_basic_multi_example()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Error handling and rollbacks")

defmodule DayTwo.ErrorHandling do
  @moduledoc """
  How transactions handle errors and perform rollbacks.
  """

  def show_rollback_scenarios do
    quote do
      # Transactions rollback when:
      #
      # • Changeset validation fails
      # • Database constraint violation occurs
      # • Exception is raised in transaction function
      # • Repo.rollback/1 is explicitly called
      # • Any Multi operation returns {:error, _}
      #
      # Explicit rollback:
      Repo.transaction(fn ->
        user = Repo.insert!(%User{name: "Charlie"})

        if some_business_logic_fails?() do
          Repo.rollback(:business_rule_violation)
        end

        user
      end)
    end
  end

  def show_nested_transactions do
    quote do
      # Nested transactions use savepoints
      Repo.transaction(fn ->
        user = Repo.insert!(%User{name: "David"})

        try do
          Repo.transaction(fn ->
            # This creates a savepoint
            risky_operation()
          end)
        rescue
          _ -> :ok # Inner transaction failed, but outer continues
        end

        user
      end)
    end
  end

  def demonstrate_error_handling do
    quote do
      # Comprehensive error handling
      case Repo.transaction(multi) do
        {:ok, %{user: user, order: order}} ->
          {:ok, {user, order}}
        {:error, :user, changeset, _} ->
          {:error, "User creation failed: #{format_errors(changeset)}"}
        {:error, :payment, reason, _} ->
          {:error, "Payment failed: #{reason}"}
        {:error, :inventory, :out_of_stock, %{user: user}} ->
          # Compensation: notify user about out of stock
          send_out_of_stock_notification(user)
          {:error, "Product out of stock"}
      end
    end
  end
end

IO.puts("Rollback scenarios:")
IO.puts(Macro.to_string(DayTwo.ErrorHandling.show_rollback_scenarios()))
IO.puts("\nNested transactions:")
IO.puts(Macro.to_string(DayTwo.ErrorHandling.show_nested_transactions()))
IO.puts("\nComprehensive error handling:")
IO.puts(Macro.to_string(DayTwo.ErrorHandling.demonstrate_error_handling()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Advanced Multi patterns")

defmodule DayTwo.AdvancedMulti do
  @moduledoc """
  Advanced patterns for building complex Multi operations.
  """

  def show_conditional_operations do
    quote do
      # Conditional operations in Multi
      def create_user_with_optional_promotion(attrs, should_promote) do
        Multi.new()
        |> Multi.insert(:user, User.changeset(%User{}, attrs))
        |> Multi.run(:maybe_promote, fn repo, %{user: user} ->
          if should_promote do
            repo.update(User.promotion_changeset(user))
          else
            {:ok, user}
          end
        end)
        |> Multi.run(:send_email, fn _repo, %{user: user, maybe_promote: promoted_user} ->
          email_type = if promoted_user.promoted, do: :welcome_premium, else: :welcome
          EmailService.send(user.email, email_type)
        end)
      end
    end
  end

  def show_dynamic_multi_building do
    quote do
      # Building Multi dynamically
      def process_bulk_order(line_items) do
        Enum.reduce(line_items, Multi.new(), fn {product_id, quantity}, multi ->
          multi
          |> Multi.run({:lock, product_id}, fn repo, _ ->
            # Lock the product row to prevent race conditions
            case repo.get_and_lock(Product, product_id) do
              nil -> {:error, :not_found}
              product -> {:ok, product}
            end
          end)
          |> Multi.run({:check_inventory, product_id}, fn _, %{{:lock, ^product_id} => product} ->
            if product.inventory >= quantity do
              {:ok, product}
            else
              {:error, :out_of_stock}
            end
          end)
          |> Multi.update(
            {:update_inventory, product_id},
            fn %{{:check_inventory, ^product_id} => product} ->
              Product.changeset(product, %{inventory: product.inventory - quantity})
            end
          )
        end)
      end
    end
  end

  def show_merging_multi do
    quote do
      # Merging two Multi operations
      user_multi =
        Multi.new()
        |> Multi.insert(:user, %User{})

      profile_multi =
        Multi.new()
        |> Multi.insert(:profile, fn %{user: user} -> %Profile{user_id: user.id} end)

      # `user_multi` will be run before `profile_multi`
      combined_multi = Multi.merge(user_multi, profile_multi)

      Repo.transaction(combined_multi)
    end
  end
end

IO.puts("Conditional operations:")
IO.puts(Macro.to_string(DayTwo.AdvancedMulti.show_conditional_operations()))
IO.puts("\nDynamic Multi building:")
IO.puts(Macro.to_string(DayTwo.AdvancedMulti.show_dynamic_multi_building()))
IO.puts("\nMerging Multi operations:")
IO.puts(Macro.to_string(DayTwo.AdvancedMulti.show_merging_multi()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world scenario: Bank transfer")

defmodule DayTwo.BankTransfer do
  @moduledoc """
  A complete, real-world example of a bank transfer using Ecto.Multi.
  """

  def show_account_schema do
    quote do
      defmodule Bank.Account do
        use Ecto.Schema
        import Ecto.Changeset

        schema "accounts" do
          field :balance, :decimal, default: 0
          field :currency, :string, size: 3
          belongs_to :user, Bank.User
        end

        def changeset(account, attrs) do
          account
          |> cast(attrs, [:balance, :currency])
          |> validate_required([:balance, :currency])
          |> validate_number(:balance, greater_than_or_equal_to: 0)
        end
      end
    end
  end

  def show_transfer_multi do
    quote do
      defmodule Bank.Transfers do
        alias Ecto.Multi
        alias Bank.Account

        def execute(from_account_id, to_account_id, amount) do
          Multi.new()
          # 1. Look up and lock both accounts to prevent concurrent updates
          |> Multi.run(:from, &get_and_lock_account(&1, from_account_id))
          |> Multi.run(:to, &get_and_lock_account(&1, to_account_id))
          # 2. Validate the transfer
          |> Multi.run(:validate, &validate_transfer(&1, amount))
          # 3. Perform the updates
          |> Multi.update(:debit, &debit_account(&1, amount))
          |> Multi.update(:credit, &credit_account(&1, amount))
          # 4. Record the transaction
          |> Multi.insert(:transaction_log, &log_transaction(&1, amount))
          |> Repo.transaction()
        end

        defp get_and_lock_account(repo, id) do
          case repo.get_and_lock(Account, id) do
            nil -> {:error, "Account not found"}
            account -> {:ok, account}
          end
        end

        defp validate_transfer(%{from: from, to: to}, amount) do
          cond do
            from.currency != to.currency -> {:error, "Currency mismatch"}
            from.balance < amount -> {:error, "Insufficient funds"}
            true -> {:ok, "Validation successful"}
          end
        end

        defp debit_account(%{from: from}, amount) do
          new_balance = from.balance - amount
          Account.changeset(from, %{balance: new_balance})
        end

        defp credit_account(%{to: to}, amount) do
          new_balance = to.balance + amount
          Account.changeset(to, %{balance: new_balance})
        end

        defp log_transaction(results, amount) do
          %{
            from_account_id: results.from.id,
            to_account_id: results.to.id,
            amount: amount,
            status: :completed
          }
        end
      end
    end
  end
end

IO.puts("Bank account schema:")
IO.puts(Macro.to_string(DayTwo.BankTransfer.show_account_schema()))
IO.puts("\nBank transfer Multi operation:")
IO.puts(Macro.to_string(DayTwo.BankTransfer.show_transfer_multi()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Exercises")

defmodule DayTwo.MultiExercises do
  @moduledoc """
  Run the tests with: mix test day_two/06_transactions_and_multi.exs
  or in IEx:
  iex -r day_two/06_transactions_and_multi.exs
  DayTwo.MultiExercisesTest.test_transfer_funds_multi/0
  DayTwo.MultiExercisesTest.test_create_user_and_team_multi/0
  DayTwo.MultiExercisesTest.test_create_order_with_items_multi/0
  """

  # These are dummy modules for the exercises. Assume they have
  # the necessary fields and changeset functions.
  defmodule User, do: defstruct [:id, :name, :email]
  defmodule Team, do: defstruct [:id, :name]
  defmodule Membership, do: defstruct [:id, :user_id, :team_id, :role]
  defmodule Account, do: defstruct [:id, :balance]
  defmodule Order, do: defstruct [:id, :user_id]
  defmodule LineItem, do: defstruct [:id, :order_id, :product_id, :quantity]

  # Dummy changeset function for the exercises
  def changeset(struct, attrs), do: {struct, attrs}

  @doc """
  Builds a Multi pipeline to transfer funds between two accounts.

  **Goal:** Create a transaction that atomically withdraws from one account
  and deposits into another, then logs the event.

  **Requirements:**
  1.  Use `Multi.update` to withdraw the `amount` from `from_account`.
      Name this step `:withdraw`.
  2.  Use `Multi.update` to deposit the `amount` into the `to_account`.
      Name this step `:deposit`.
  3.  Use `Multi.run` to log that the transaction occurred.
      Name this step `:log_transaction`. The function can just return `{:ok, :logged}`.

  **Hint:** `Account.changeset/2` is a dummy function for this exercise. You can
  call it like `Account.changeset(account, %{balance: new_balance})`.
  """
  @spec transfer_funds_multi(map(), map(), number()) :: Ecto.Multi.t()
  def transfer_funds_multi(_from_account, _to_account, _amount) do
    # TODO: Implement this exercise
    nil
  end

  @doc """
  Builds a Multi pipeline for creating a user and their team.

  **Goal:** Create a pipeline for a new user signup where a user, a team,
  and a membership linking them are all created in a single transaction.

  **Requirements:**
  1.  Insert a `User` record from the provided `user_attrs`. Name this step `:user`.
  2.  Insert a `Team` record. The team's attributes should be based on `team_attrs`
      but also use the newly created user from the `:user` step. Name this step `:team`.
  3.  Insert a `Membership` record that links the new user and team. The user
      should be the "owner". Name this step `:membership`.

  **Hint:** The anonymous functions you pass to `Multi.insert` for the `:team` and
  `:membership` steps will receive a map of the results from previous steps.
  """
  @spec create_user_and_team_multi(map(), map()) :: Ecto.Multi.t()
  def create_user_and_team_multi(_user_attrs, _team_attrs) do
    # TODO: Implement this exercise
    nil
  end

  @doc """
  Builds a multi to create an order and all of its line items in bulk.

  **Goal:** Create a transaction that inserts an order and then uses
  `Multi.insert_all` to efficiently add all its associated line items.

  **Requirements:**
  1.  Insert a new `Order` for the given `user`. Name this step `:order`.
  2.  Use `Multi.insert_all` to insert all `items` into the `LineItem` schema.
      Name this step `:line_items`.
  3.  The line items data needs the `order_id` from the `:order` step.

  **`items` format:** `[%{product_id: 1, quantity: 2}, ...]`
  """
  @spec create_order_with_items_multi(map(), list()) :: Ecto.Multi.t()
  def create_order_with_items_multi(_user, _items) do
    # TODO: Implement this exercise
    nil
  end
end

ExUnit.start()

defmodule DayTwo.MultiExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.MultiExercises, as: EX
  alias Ecto.Multi

  # Helper to check the operation names in a multi
  defp get_op_names(multi) do
    Enum.map(multi.operations, fn {name, _, _, _} -> name end)
  end

  test "transfer_funds_multi/3 creates a withdraw, deposit, and log pipeline" do
    multi = EX.transfer_funds_multi(%{balance: 100}, %{balance: 50}, 20)
    assert %Multi{} = multi
    assert get_op_names(multi) == [:withdraw, :deposit, :log_transaction]
  end

  test "create_user_and_team_multi/2 creates user, team, and membership" do
    multi = EX.create_user_and_team_multi(%{}, %{})
    assert %Multi{} = multi
    assert get_op_names(multi) == [:user, :team, :membership]
  end

  test "create_order_with_items_multi/2 creates order and bulk-inserts items" do
    items = [%{product_id: 1, quantity: 2}]
    multi = EX.create_order_with_items_multi(%{}, items)
    assert %Multi{} = multi
    assert get_op_names(multi) == [:order, :line_items]

    # Check that the second operation is an insert_all
    line_items_op = Enum.at(multi.operations, 1)
    assert elem(line_items_op, 1) == :insert_all
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      def transfer_funds_multi(from_account, to_account, amount) do
        Ecto.Multi.new()
        |> Ecto.Multi.update(:withdraw, EX.changeset(from_account, %{balance: from_account.balance - amount}))
        |> Ecto.Multi.update(:deposit, EX.changeset(to_account, %{balance: to_account.balance + amount}))
        |> Ecto.Multi.run(:log_transaction, fn _repo, _changes ->
          {:ok, :logged}
        end)
      end
    end
  end

  def answer_two do
    quote do
      def create_user_and_team_multi(user_attrs, team_attrs) do
        Ecto.Multi.new()
        |> Ecto.Multi.insert(:user, EX.changeset(%EX.User{}, user_attrs))
        |> Ecto.Multi.insert(:team, fn %{user: user} ->
          team_name = team_attrs[:name] || "#{user.name}'s Team"
          EX.changeset(%EX.Team{}, Map.put(team_attrs, :name, team_name))
        end)
        |> Ecto.Multi.insert(:membership, fn %{user: user, team: team} ->
          EX.changeset(%EX.Membership{}, %{
            user_id: user.id,
            team_id: team.id,
            role: "owner"
          })
        end)
      end
    end
  end

  def answer_three do
    quote do
      def create_order_with_items_multi(user, items) do
        Ecto.Multi.new()
        |> Ecto.Multi.insert(:order, EX.changeset(%EX.Order{}, %{user_id: user.id}))
        |> Ecto.Multi.insert_all(:line_items, EX.LineItem, fn %{order: order} ->
          Enum.map(items, fn item ->
            %{order_id: order.id, product_id: item.product_id, quantity: item.quantity}
          end)
        end)
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. transfer_funds_multi/3
#{Macro.to_string(DayTwo.Answers.answer_one())}
#  This multi ensures that both the withdrawal and the deposit succeed, or neither
#  does, preventing money from being lost or created. `Multi.run` is used for a
#  side-effect (logging) that is part of the transaction.

# 2. create_user_and_team_multi/2
#{Macro.to_string(DayTwo.Answers.answer_two())}
#  This shows how `Ecto.Multi` pipelines operations that depend on each other.
#  The anonymous functions passed to `Multi.insert` receive a map of the
#  results of previous successful steps, allowing you to use the `user` and `team`
#  structs to create the final `membership`.

# 3. create_order_with_items_multi/2
#{Macro.to_string(DayTwo.Answers.answer_three())}
#  This advanced example demonstrates building a multi dynamically using `Enum.reduce`.
#  Each item in the order adds a new step to the multi. This is a very powerful
#  pattern for handling variable-length transactional workflows. Using `update_all`
#  with an increment is a good way to handle stock updates atomically.
""")
