# Day 2 – Transactions & Ecto.Multi
#
# Run with `mix run elixir_course/day_two/06_transactions_and_multi.exs`
# or inside IEx with:
#     iex -S mix
#     c "elixir_course/day_two/06_transactions_and_multi.exs"
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
    """
    ACID properties that transactions guarantee:

    • Atomicity: All operations succeed or all fail
    • Consistency: Database remains in valid state
    • Isolation: Concurrent transactions don't interfere
    • Durability: Committed changes persist after crashes

    Without transactions, partial failures can leave data inconsistent.
    """
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
    """
    # Basic transaction with Repo.transaction/1
    result = Repo.transaction(fn ->
      # All operations here are wrapped in a transaction
      user = Repo.insert!(%User{name: "Alice"})
      profile = Repo.insert!(%Profile{user_id: user.id, bio: "Hello"})

      # If any operation fails, entire transaction rolls back
      {user, profile}
    end)

    case result do
      {:ok, {user, profile}} -> # Success
      {:error, reason} -> # Rollback occurred
    end
    """
  end
end

IO.puts("ACID properties:")
IO.puts(DayTwo.TransactionBasics.explain_acid_properties())
DayTwo.TransactionBasics.show_transaction_scenarios()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Ecto.Multi for composable transactions")

defmodule DayTwo.MultiBasics do
  @moduledoc """
  Ecto.Multi provides a declarative way to build transactions.
  """

  def show_multi_advantages do
    """
    Advantages of Ecto.Multi:

    • Composable: Build transactions step by step
    • Readable: Clear operation names and dependencies
    • Testable: Inspect multi without executing
    • Rollback safe: Automatic cleanup on any failure
    • Result access: Use results from previous steps
    """
  end

  def show_basic_multi_example do
    """
    # Building a Multi operation
    alias Ecto.Multi

    multi = Multi.new()
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

      {:error, operation, changeset, changes_so_far} ->
        # operation = the step that failed (:user, :profile, or :welcome_sent)
        # changeset = the invalid changeset
        # changes_so_far = successfully completed operations
    end
    """
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
IO.puts(DayTwo.MultiBasics.show_multi_advantages())
DayTwo.MultiBasics.show_multi_operations()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Error handling and rollbacks")

defmodule DayTwo.ErrorHandling do
  @moduledoc """
  How transactions handle errors and perform rollbacks.
  """

  def show_rollback_scenarios do
    """
    Transactions rollback when:

    • Changeset validation fails
    • Database constraint violation occurs
    • Exception is raised in transaction function
    • Repo.rollback/1 is explicitly called
    • Any Multi operation returns {:error, _}

    # Explicit rollback:
    Repo.transaction(fn ->
      user = Repo.insert!(%User{name: "Charlie"})

      if some_business_logic_fails?() do
        Repo.rollback(:business_rule_violation)
      end

      user
    end)
    """
  end

  def show_nested_transactions do
    """
    # Nested transactions use savepoints
    Repo.transaction(fn ->
      user = Repo.insert!(%User{name: "David"})

      try do
        Repo.transaction(fn ->
          # This creates a savepoint
          risky_operation()
        end)
      rescue
        _ -> :ok  # Inner transaction failed, but outer continues
      end

      user
    end)
    """
  end

  def demonstrate_error_handling do
    """
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
    """
  end
end

IO.puts("Rollback scenarios:")
IO.puts(DayTwo.ErrorHandling.show_rollback_scenarios())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Advanced Multi patterns")

defmodule DayTwo.AdvancedMulti do
  @moduledoc """
  Advanced patterns for building complex Multi operations.
  """

  def show_conditional_operations do
    """
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
    """
  end

  def show_dynamic_multi_building do
    """
    # Building Multi dynamically
    def process_bulk_order(line_items) do
      Enum.reduce(line_items, Multi.new(), fn {product_id, quantity}, multi ->
        step_name = "reserve_#{product_id}"

        Multi.run(multi, step_name, fn repo, _changes ->
          case InventoryService.reserve(product_id, quantity) do
            {:ok, reservation} -> {:ok, reservation}
            {:error, reason} -> {:error, reason}
          end
        end)
      end)
      |> Multi.run(:create_order, fn _repo, reservations ->
           total = calculate_total(reservations)
           {:ok, %Order{total: total}}
         end)
    end
    """
  end

  def show_multi_composition do
    """
    # Composing Multi operations
    def create_blog_post_multi(user, post_attrs) do
      Multi.new()
      |> Multi.insert(:post, Post.changeset(%Post{user_id: user.id}, post_attrs))
      |> add_tags_multi(post_attrs["tags"])
      |> add_notifications_multi(user)
    end

    defp add_tags_multi(multi, nil), do: multi
    defp add_tags_multi(multi, tag_names) do
      Multi.run(multi, :tags, fn repo, %{post: post} ->
        tags = create_or_find_tags(tag_names)
        repo.update(Post.changeset(post, %{tags: tags}))
      end)
    end

    defp add_notifications_multi(multi, user) do
      Multi.run(multi, :notifications, fn _repo, %{post: post} ->
        NotificationService.notify_followers(user, post)
      end)
    end
    """
  end
end

IO.puts("Conditional Multi operations:")
IO.puts(DayTwo.AdvancedMulti.show_conditional_operations())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: E-commerce order processing")

defmodule DayTwo.OrderProcessing do
  @moduledoc """
  Complete e-commerce order processing using transactions and Multi.
  """

  def show_order_processing_multi do
    """
    # Complete order processing pipeline
    def process_order(user_id, cart_items, payment_info, shipping_address) do
      Multi.new()
      |> Multi.run(:validate_cart, fn _repo, _changes ->
           validate_cart_items(cart_items)
         end)
      |> Multi.run(:reserve_inventory, fn _repo, %{validate_cart: valid_items} ->
           reserve_inventory_for_items(valid_items)
         end)
      |> Multi.run(:calculate_totals, fn _repo, %{reserve_inventory: reservations} ->
           {:ok, calculate_order_totals(reservations)}
         end)
      |> Multi.run(:process_payment, fn _repo, %{calculate_totals: totals} ->
           PaymentService.charge(payment_info, totals.grand_total)
         end)
      |> Multi.insert(:order, fn %{calculate_totals: totals, process_payment: payment} ->
           Order.changeset(%Order{}, %{
             user_id: user_id,
             total: totals.grand_total,
             payment_id: payment.id,
             shipping_address_id: shipping_address.id,
             status: "confirmed"
           })
         end)
      |> Multi.run(:create_order_items, fn repo, %{order: order, reserve_inventory: reservations} ->
           create_order_items(repo, order, reservations)
         end)
      |> Multi.run(:send_confirmation, fn _repo, %{order: order} ->
           EmailService.send_order_confirmation(order)
         end)
      |> Multi.run(:clear_cart, fn _repo, _changes ->
           CartService.clear(user_id)
         end)
    end
    """
  end

  def show_compensation_patterns do
    """
    # Handling partial failures with compensation
    case Repo.transaction(order_multi) do
      {:ok, %{order: order}} ->
        {:ok, order}

      {:error, :reserve_inventory, {:out_of_stock, product_id}, changes} ->
        # Compensation: Release any reservations made so far
        if reservations = changes[:reserve_inventory] do
          InventoryService.release_reservations(reservations)
        end
        {:error, :out_of_stock, product_id}

      {:error, :process_payment, payment_error, changes} ->
        # Compensation: Release inventory reservations
        if reservations = changes[:reserve_inventory] do
          InventoryService.release_reservations(reservations)
        end
        {:error, :payment_failed, payment_error}

      {:error, operation, reason, _changes} ->
        # Log unexpected errors for debugging
        Logger.error("Order processing failed at #{operation}: #{inspect(reason)}")
        {:error, :order_processing_failed}
    end
    """
  end

  def show_testing_patterns do
    """
    # Testing Multi operations
    test "order processing creates all records" do
      user = insert(:user)
      product = insert(:product, inventory: 10)

      multi = OrderProcessing.process_order(user.id, [
        %{product_id: product.id, quantity: 2}
      ], valid_payment_info(), valid_address())

      # Test without executing
      assert %Ecto.Multi{} = multi

      # Test execution
      {:ok, results} = Repo.transaction(multi)

      assert %Order{status: "confirmed"} = results.order
      assert length(results.create_order_items) == 1

      # Verify side effects
      updated_product = Repo.get!(Product, product.id)
      assert updated_product.inventory == 8
    end
    """
  end
end

IO.puts("Order processing Multi:")
IO.puts(DayTwo.OrderProcessing.show_order_processing_multi())

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Create a user registration Multi that: creates the user, sends a welcome
#    email, creates a default profile, and logs the registration event. Handle
#    the case where email sending fails but still complete registration.
# 2. Build a blog post publishing Multi that: validates the post, updates
#    category post counts, notifies subscribers, and schedules social media
#    posts. Make social media scheduling optional based on user preferences.
# 3. (Challenge) Design a data migration Multi that moves user data between
#    tables, updates related records, and maintains audit logs. Include
#    rollback compensation for external API calls that can't be undone.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. User registration Multi with optional email
def register_user_multi(attrs) do
  Multi.new()
  |> Multi.insert(:user, User.registration_changeset(%User{}, attrs))
  |> Multi.insert(:profile, fn %{user: user} ->
       Profile.changeset(%Profile{}, %{user_id: user.id, bio: ""})
     end)
  |> Multi.run(:welcome_email, fn _repo, %{user: user} ->
       case EmailService.send_welcome(user.email) do
         {:ok, _} -> {:ok, :sent}
         {:error, _} -> {:ok, :failed}  # Don't fail transaction
       end
     end)
  |> Multi.run(:log_registration, fn _repo, %{user: user, welcome_email: email_status} ->
       AuditLog.log_event("user_registered", %{
         user_id: user.id,
         email_sent: email_status == :sent
       })
     end)
end

# 2. Blog post publishing Multi with conditional social media
def publish_post_multi(post_id, user_preferences) do
  Multi.new()
  |> Multi.update(:post, fn _ ->
       post = Repo.get!(Post, post_id)
       Post.publish_changeset(post, %{published_at: DateTime.utc_now()})
     end)
  |> Multi.run(:update_category_count, fn repo, %{post: post} ->
       category = repo.get!(Category, post.category_id)
       repo.update(Category.changeset(category, %{post_count: category.post_count + 1}))
     end)
  |> Multi.run(:notify_subscribers, fn _repo, %{post: post} ->
       NotificationService.notify_subscribers(post)
     end)
  |> maybe_schedule_social_media(user_preferences.auto_social_share)
end

defp maybe_schedule_social_media(multi, false), do: multi
defp maybe_schedule_social_media(multi, true) do
  Multi.run(multi, :schedule_social, fn _repo, %{post: post} ->
    SocialMediaService.schedule_post(post)
  end)
end

# 3. Data migration Multi with compensation
def migrate_user_data_multi(user_id) do
  Multi.new()
  |> Multi.run(:backup_data, fn repo, _ ->
       user = repo.get!(User, user_id)
       {:ok, %{original_user: user, backup_id: create_backup(user)}}
     end)
  |> Multi.run(:external_sync, fn _repo, %{backup_data: %{original_user: user}} ->
       case ExternalAPI.sync_user(user) do
         {:ok, external_id} -> {:ok, external_id}
         error -> error
       end
     end)
  |> Multi.update(:migrate_user, fn %{backup_data: %{original_user: user}} ->
       User.migration_changeset(user, %{migrated: true, migrated_at: DateTime.utc_now()})
     end)
  |> Multi.run(:audit_log, fn _repo, changes ->
       AuditLog.log_migration(user_id, changes)
     end)
end

# Compensation for external API failure:
case Repo.transaction(migration_multi) do
  {:error, :external_sync, reason, %{backup_data: backup}} ->
    # Restore from backup since external sync failed
    restore_from_backup(backup.backup_id)
    {:error, :external_sync_failed, reason}
end

# Why these work:
# 1. Uses Multi.run with :ok return for non-critical operations (email)
# 2. Conditional composition with helper functions for optional features
# 3. Comprehensive compensation strategy with backup/restore for irreversible operations
"""
