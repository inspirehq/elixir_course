# Day 2 – Behaviour Refresher
#
# This script can be run with:
#     mix run day_two/07_behaviour_refresher.exs
# or inside IEx with:
#     iex -r day_two/07_behaviour_refresher.exs
#
# Building on GenServer from Day 1, we'll explore behaviours as a design pattern.
# Behaviours define contracts - a set of functions that implementing modules must provide.
# This enables polymorphism and consistent interfaces across different implementations.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Reinforcing GenServer as behaviour")

defmodule DayTwo.BehaviourConcepts do
  @moduledoc """
  Reinforcing what we learned about GenServer being a behaviour.
  """

  def explain_genserver_behaviour do
    IO.puts(~S"""
    In Day 1, we learned GenServer is a *behaviour* that requires:

    • init/1 - Initialize process state
    • handle_call/3 - Handle synchronous requests
    • handle_cast/2 - Handle asynchronous messages
    • handle_info/2 - Handle raw process messages

    When we wrote:
    """)

    code =
      quote do
        defmodule CounterServer do
          use GenServer

          def init(count), do: {:ok, count}
          def handle_call(:value, _from, count), do: {:reply, count, count}
          def handle_cast(:inc, count), do: {:noreply, count + 1}
        end
      end

    IO.puts(Macro.to_string(code))

    IO.puts(~S"""

    We were implementing the GenServer behaviour's contract.
    The `use GenServer` macro provided default implementations and
    our module supplied the specific callback functions.
    """)
  end

  def show_behaviour_benefits do
    benefits = [
      "Consistency: All GenServers work the same way",
      "Polymorphism: Different implementations, same interface",
      "Tooling: OTP tools understand GenServer behaviour",
      "Documentation: Clear contracts for implementers",
      "Testing: Predictable patterns for testing"
    ]

    IO.puts("Benefits of the behaviour pattern:")
    Enum.each(benefits, fn benefit ->
      IO.puts("  • #{benefit}")
    end)
  end
end

IO.puts("GenServer as behaviour:")
DayTwo.BehaviourConcepts.explain_genserver_behaviour()
DayTwo.BehaviourConcepts.show_behaviour_benefits()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Defining custom behaviours")

defmodule DayTwo.PaymentProcessor do
  @moduledoc """
  A custom behaviour for payment processing.
  """

  @doc """
  Process a payment with the given amount and payment method.
  Returns {:ok, transaction_id} or {:error, reason}.
  """

  # The line below uses Elixir's typespec notation. Let's break it down:
  # `::` separates the function signature from its return type.
  # `Decimal.t()` refers to the type of a Decimal struct.
  # The `|` character means "or", so the function can return one of several types.
  # Here, it returns either `{:ok, String.t()}` on success or `{:error, atom()}` on failure.
  @callback process_payment(amount :: Decimal.t(), payment_method :: map()) ::
    {:ok, String.t()} | {:error, atom()}

  @doc """
  Refund a payment by transaction ID.
  Returns {:ok, refund_id} or {:error, reason}.
  """
  @callback refund_payment(transaction_id :: String.t()) ::
    {:ok, String.t()} | {:error, atom()}

  @doc """
  Get the status of a transaction.
  """
  @callback get_transaction_status(transaction_id :: String.t()) ::
    {:ok, :pending | :completed | :failed} | {:error, atom()}

  # Optional callback with default implementation
  @doc """
  Format amount for display in this processor's currency.
  """
  @callback format_amount(amount :: Decimal.t()) :: String.t()
  # optional callbacks are not required to be implemented by the module that uses the behaviour
  # but if they are implemented, they will override the default implementation
  @optional_callbacks format_amount: 1

  def format_amount_default(amount) do
    "$#{Decimal.to_string(amount, :normal)}"
  end
end

IO.puts("Custom PaymentProcessor behaviour defined with @callback annotations")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Implementing custom behaviours")

defmodule DayTwo.StripeProcessor do
  @moduledoc """
  Stripe implementation of PaymentProcessor behaviour.
  """

  @behaviour DayTwo.PaymentProcessor

  @impl true
  def process_payment(amount, payment_method) do
    # Simulate Stripe API call
    case payment_method do
      %{type: "credit_card", valid: true} ->
        transaction_id = "stripe_#{:rand.uniform(10000)}"
        IO.puts("Processing $#{amount} via Stripe...")
        {:ok, transaction_id}
      %{type: "credit_card", valid: false} ->
        {:error, :invalid_card}
      _ ->
        {:error, :unsupported_payment_method}
    end
  end

  @impl true
  def refund_payment(transaction_id) do
    IO.puts("Refunding Stripe transaction: #{transaction_id}")
    refund_id = "stripe_refund_#{:rand.uniform(10000)}"
    {:ok, refund_id}
  end

  @impl true
  def get_transaction_status(transaction_id) do
    # Simulate status lookup
    statuses = [:pending, :completed, :failed]
    status = Enum.random(statuses)
    {:ok, status}
  end

  # Using optional callback
  @impl true
  def format_amount(amount) do
    "$#{Decimal.to_string(amount, :normal)} USD"
  end
end

defmodule DayTwo.PayPalProcessor do
  @moduledoc """
  PayPal implementation of PaymentProcessor behaviour.
  """

  @behaviour DayTwo.PaymentProcessor

  @impl true
  def process_payment(amount, payment_method) do
    # Simulate PayPal API call
    case payment_method do
      %{type: "paypal_account", email: email} when is_binary(email) ->
        transaction_id = "pp_#{:rand.uniform(10000)}"
        IO.puts("Processing $#{amount} via PayPal for #{email}...")
        {:ok, transaction_id}
      _ ->
        {:error, :invalid_paypal_account}
    end
  end

  @impl true
  def refund_payment(transaction_id) do
    IO.puts("Refunding PayPal transaction: #{transaction_id}")
    refund_id = "pp_refund_#{:rand.uniform(10000)}"
    {:ok, refund_id}
  end

  @impl true
  def get_transaction_status(transaction_id) do
    # Simulate PayPal status lookup
    {:ok, :completed}
  end

  # Not implementing optional callback - will use default
end

# Demonstrate polymorphism
processors = [DayTwo.StripeProcessor, DayTwo.PayPalProcessor]

Enum.each(processors, fn processor ->
  IO.puts("\nTesting #{processor}:")

  case processor.process_payment(Decimal.new("29.99"), %{type: "credit_card", valid: true}) do
    {:ok, tx_id} ->
      IO.puts("  Payment successful: #{tx_id}")

      case processor.get_transaction_status(tx_id) do
        {:ok, status} -> IO.puts("  Status: #{status}")
        {:error, reason} -> IO.puts("  Status error: #{reason}")
      end

    {:error, reason} ->
      IO.puts("  Payment failed: #{reason}")
  end
end)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Built-in Elixir behaviours")

defmodule DayTwo.BuiltinBehaviours do
  @moduledoc """
  Overview of important built-in behaviours in Elixir/OTP.
  """

  def show_otp_behaviours do
    behaviours = [
      {"GenServer", "Stateful server process (we learned this in Day 1)"},
      {"Supervisor", "Process supervision and restart strategies"},
      {"GenStateMachine", "Finite state machine implementation"},
      {"Agent", "Simple state wrapper around GenServer"},
      {"Task", "Async computation abstraction"},
      {"Application", "OTP application lifecycle management"}
    ]

    IO.puts("Key OTP behaviours:")
    Enum.each(behaviours, fn {name, description} ->
      IO.puts("  • #{name}: #{description}")
    end)
  end

  def show_protocol_vs_behaviour do
    """
    Behaviours vs Protocols:

    BEHAVIOURS:
    • Compile-time contracts for modules
    • Implement specific callback functions
    • Used for OTP patterns (GenServer, Supervisor)
    • Example: @behaviour MyBehaviour

    PROTOCOLS:
    • Runtime polymorphism for data types
    • Dispatch based on data type
    • Extensible to new types
    • Example: Enumerable, String.Chars

    Use behaviours for process patterns, protocols for data transformation.
    """
  end
end

DayTwo.BuiltinBehaviours.show_otp_behaviours()
IO.puts("\nBehaviours vs Protocols:")
IO.puts(DayTwo.BuiltinBehaviours.show_protocol_vs_behaviour())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Plugin system with behaviours")

defmodule DayTwo.NotificationService do
  @moduledoc """
  A notification service that supports multiple delivery methods via behaviours.
  """

  @doc """
  Send a notification via the provider.
  Returns {:ok, delivery_id} or {:error, reason}.
  """
  @callback send_notification(recipient :: String.t(), message :: String.t(), options :: map()) ::
    {:ok, String.t()} | {:error, atom()}

  @doc """
  Get delivery status for a notification.
  """
  @callback get_delivery_status(delivery_id :: String.t()) ::
    {:ok, :pending | :delivered | :failed} | {:error, atom()}

  @optional_callbacks get_delivery_status: 1
end

defmodule DayTwo.EmailNotifier do
  @behaviour DayTwo.NotificationService

  @impl true
  def send_notification(recipient, message, options) do
    subject = Map.get(options, :subject, "Notification")
    IO.puts("📧 Sending email to #{recipient}")
    IO.puts("   Subject: #{subject}")
    IO.puts("   Message: #{message}")

    delivery_id = "email_#{:rand.uniform(10000)}"
    {:ok, delivery_id}
  end

  @impl true
  def get_delivery_status(delivery_id) do
    # Simulate email delivery status check
    {:ok, :delivered}
  end
end

defmodule DayTwo.SMSNotifier do
  @behaviour DayTwo.NotificationService

  @impl true
  def send_notification(recipient, message, _options) do
    IO.puts("📱 Sending SMS to #{recipient}")
    IO.puts("   Message: #{message}")

    delivery_id = "sms_#{:rand.uniform(10000)}"
    {:ok, delivery_id}
  end

  # Not implementing optional callback
end

defmodule DayTwo.SlackNotifier do
  @behaviour DayTwo.NotificationService

  @impl true
  def send_notification(recipient, message, options) do
    channel = Map.get(options, :channel, "#general")
    IO.puts("💬 Sending Slack message to #{recipient}")
    IO.puts("   Channel: #{channel}")
    IO.puts("   Message: #{message}")

    delivery_id = "slack_#{:rand.uniform(10000)}"
    {:ok, delivery_id}
  end
end

# Plugin system that works with any notification provider
defmodule DayTwo.NotificationDispatcher do
  def send_multi_channel(recipient, message, providers) do
    IO.puts("\n🔔 Sending notification to #{recipient}")
    IO.puts("Message: #{message}\n")

    results = Enum.map(providers, fn {provider, options} ->
      case provider.send_notification(recipient, message, options) do
        {:ok, delivery_id} ->
          {provider, :ok, delivery_id}
        {:error, reason} ->
          {provider, :error, reason}
      end
    end)

    # Report results
    Enum.each(results, fn {provider, status, result} ->
      case status do
        :ok -> IO.puts("✅ #{provider}: Success (#{result})")
        :error -> IO.puts("❌ #{provider}: Failed (#{result})")
      end
    end)

    results
  end
end

# Demonstrate the plugin system
providers = [
  {DayTwo.EmailNotifier, %{subject: "Important Update"}},
  {DayTwo.SMSNotifier, %{}},
  {DayTwo.SlackNotifier, %{channel: "#alerts"}}
]

DayTwo.NotificationDispatcher.send_multi_channel(
  "john@example.com",
  "Your order has shipped!",
  providers
)

defmodule DayTwo.BehaviourExercises do
  @moduledoc """
  Run the tests with: mix test day_two/07_behaviour_refresher.exs
  or in IEx:
  iex -r day_two/07_behaviour_refresher.exs
  DayTwo.BehaviourExercisesTest.test_define_cache_provider_behaviour/0
  DayTwo.BehaviourExercisesTest.test_define_data_validator_behaviour/0
  DayTwo.BehaviourExercisesTest.test_define_job_processor_behaviour/0
  """

  @doc """
  Defines a `CacheProvider` behaviour.

  **Goal:** Create a contract for a key-value cache. This allows for different
  caching implementations (e.g., in-memory, Redis) to be used interchangeably.

  **Requirements:**
  1.  Define a module named `CacheProvider`.
  2.  Add a `@callback` for `get/1` that takes a `key` and returns `{:ok, value}` or `:error`.
  3.  Add a `@callback` for `put/2` that takes a `key` and `value` and returns `:ok`.
  4.  Add a `@callback` for `delete/1` that takes a `key` and returns `:ok`.

  **Task:**
  Return the complete module definition as a string. The tests will validate
  that the string contains the required `@callback` definitions.
  """
  @spec define_cache_provider_behaviour() :: binary()
  def define_cache_provider_behaviour do
    # Create a `CacheProvider` behaviour with callbacks for `get/1`, `put/2`,
    # and `delete/1`. Return the behaviour definition as a string.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Defines a `DataValidator` behaviour.

  **Goal:** Create a generic contract for validating data structures. This
  allows for creating specific validators (e.g., for users, posts, etc.)
  that all share a common interface.

  **Requirements:**
  1.  Define a module named `DataValidator`.
  2.  Add a `@callback` for `validate/2` that takes `data` and `opts` and
      returns `:ok` or `{:error, list_of_errors}`.
  3.  Add a `@callback` for `format_errors/1` that takes a `list_of_errors`
      and returns them in a user-friendly format (e.g., a string or map).

  **Task:**
  Return the complete module definition as a string.
  """
  @spec define_data_validator_behaviour() :: binary()
  def define_data_validator_behaviour do
    # Build a `DataValidator` behaviour with callbacks for `validate/2` and
    # `format_errors/1`. Return the behaviour definition as a string.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Defines a `JobProcessor` behaviour.

  **Goal:** Design a contract for a background job processing system. This
  abstracts the job execution logic from the queueing backend (e.g.,
  in-memory, database, RabbitMQ).

  **Requirements:**
  1.  Define a module named `JobProcessor`.
  2.  Add a `@callback` for `enqueue/2` that takes a `job` and `opts` and
      returns `{:ok, job_id}` or `{:error, reason}`.
  3.  Add a `@callback` for `perform/1` that takes a `job_id`. It should return
      `:ok` on success, or `{:error, :retry | :discard, reason}` on failure,
      allowing the system to decide whether to retry or discard the failed job.
  4.  Add an optional `@callback` for `retry/2` that takes a `job_id` and `reason`
      and returns `:ok` or `:error`.

  **Task:**
  Return the complete module definition as a string.
  """
  @spec define_job_processor_behaviour() :: binary()
  def define_job_processor_behaviour do
    # Design a `JobProcessor` behaviour with callbacks for `enqueue/2` and
    # `perform/1`. Return the behaviour definition as a string.
    nil  # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.BehaviourExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.BehaviourExercises, as: EX

  test "define_cache_provider_behaviour/0 returns a valid behaviour definition" do
    behaviour_def = EX.define_cache_provider_behaviour()
    assert is_binary(behaviour_def)
    assert String.contains?(behaviour_def, "@callback get(key :: any)")
    assert String.contains?(behaviour_def, "@callback put(key :: any, value :: any)")
    assert String.contains?(behaviour_def, "@callback delete(key :: any)")
  end

  test "define_data_validator_behaviour/0 returns a valid behaviour definition" do
    behaviour_def = EX.define_data_validator_behaviour()
    assert is_binary(behaviour_def)
    assert String.contains?(behaviour_def, "@callback validate(data :: any, opts :: keyword)")
    assert String.contains?(behaviour_def, "@callback format_errors(errors :: list)")
  end

  test "define_job_processor_behaviour/0 returns a valid behaviour definition" do
    design = EX.define_job_processor_behaviour()
    assert is_binary(design)
    assert String.contains?(design, "@callback enqueue(job :: any, opts :: keyword)")
    assert String.contains?(design, "@callback perform(job_id :: any)")
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      defmodule CacheProvider do
        @moduledoc """
        A behaviour for a key-value cache.
        """
        @doc "Retrieves a value from the cache by key."
        @callback get(key :: any) :: {:ok, any} | :error

        @doc "Puts a value into the cache."
        @callback put(key :: any, value :: any) :: :ok

        @doc "Deletes a value from the cache."
        @callback delete(key :: any) :: :ok
      end
    end
  end

  def answer_two do
    quote do
      defmodule DataValidator do
        @moduledoc """
        A behaviour for data validation.
        """
        @doc "Validates the given data."
        @callback validate(data :: any, opts :: keyword) :: :ok | {:error, list}

        @doc "Formats a list of validation errors into a user-friendly format."
        @callback format_errors(errors :: list) :: any
      end
    end
  end

  def answer_three do
    quote do
      defmodule JobProcessor do
        @moduledoc """
        A behaviour for processing background jobs.
        """
        @doc "Adds a job to the queue."
        @callback enqueue(job :: any, opts :: keyword) :: {:ok, any} | {:error, any}

        @doc "Performs a job from the queue."
        @callback perform(job_id :: any) :: :ok | {:error, :retry | :discard, any}
        @callback retry(job_id :: any, reason :: any) :: :ok | :error
        @optional_callbacks retry: 2
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. CacheProvider Behaviour
#{Macro.to_string(DayTwo.Answers.answer_one())}
# This behaviour defines a contract for caching. Any module using it must
# implement `get/1`, `put/2`, and `delete/1`, ensuring a consistent API for
# different caching strategies (e.g., in-memory vs. Redis). This allows you
# to swap out the cache implementation without changing the application code.

# 2. DataValidator Behaviour
#{Macro.to_string(DayTwo.Answers.answer_two())}
# This contract is for validating data. You could have different modules
# that implement this behaviour for specific data types, like `UserValidator`
# or `OrderValidator`, each with its own rules. This promotes reusable and
# composable validation logic.

# 3. JobProcessor Behaviour
#{Macro.to_string(DayTwo.Answers.answer_three())}
# This defines a standard interface for background job processors. You could have
# one implementation that runs jobs in-memory for tests, and another that uses
# a persistent database queue in production. The return tuple for `perform/1`
# allows for sophisticated error handling, like deciding whether to retry or
# discard a failed job.
""")
