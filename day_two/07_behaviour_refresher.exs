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
    """
    In Day 1, we learned GenServer is a *behaviour* that requires:

    • init/1 - Initialize process state
    • handle_call/3 - Handle synchronous requests
    • handle_cast/2 - Handle asynchronous messages
    • handle_info/2 - Handle raw process messages

    When we wrote:

    defmodule CounterServer do
      use GenServer

      def init(count), do: {:ok, count}
      def handle_call(:value, _from, count), do: {:reply, count, count}
      def handle_cast(:inc, count), do: {:noreply, count + 1}
    end

    We were implementing the GenServer behaviour's contract.
    The `use GenServer` macro provided default implementations and
    our module supplied the specific callback functions.
    """
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
IO.puts(DayTwo.BehaviourConcepts.explain_genserver_behaviour())
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
  DayTwo.BehaviourExercisesTest.test_cache_provider/0
  DayTwo.BehaviourExercisesTest.test_data_validator/0
  DayTwo.BehaviourExercisesTest.test_job_processor/0
  """

  @spec define_cache_provider_behaviour() :: binary()
  def define_cache_provider_behaviour do
    #   Create a `CacheProvider` behaviour with callbacks for `get/1`, `put/2`,
    #   and `delete/1`. Implement it with `MemoryCache` and `RedisCache` modules.
    #   Show how the same code can work with either implementation.
    #   Return the behaviour definition as a string
    :not_implemented
  end

  @spec build_data_validator_behaviour() :: [atom()]
  def build_data_validator_behaviour do
    #   Build a `DataValidator` behaviour for form validation. Include callbacks
    #   for `validate_field/2` and `format_errors/1`. Create implementations for
    #   `EmailValidator`, `PhoneValidator`, and `PasswordValidator`.
    #   Return a list of validator module names
    :not_implemented
  end

  @spec design_job_processor_behaviour() :: map()
  def design_job_processor_behaviour do
    #   Design a `JobProcessor` behaviour for background job processing.
    #   Include callbacks for `enqueue/2`, `process/1`, and `retry/2`. Create
    #   implementations that simulate different queue backends (memory, database).
    #   Return a map with callbacks and implementation strategies
    :not_implemented
  end
end

ExUnit.start()

defmodule DayTwo.BehaviourExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.BehaviourExercises, as: EX

  test "define_cache_provider_behaviour/0 includes all required callbacks" do
    behaviour_def = EX.define_cache_provider_behaviour()
    assert is_binary(behaviour_def)
    assert String.contains?(behaviour_def, "@callback get")
    assert String.contains?(behaviour_def, "@callback put")
    assert String.contains?(behaviour_def, "@callback delete")
  end

  test "build_data_validator_behaviour/0 returns validator modules" do
    validators = EX.build_data_validator_behaviour()
    assert is_list(validators)
    assert length(validators) >= 3
  end

  test "design_job_processor_behaviour/0 includes queue strategies" do
    design = EX.design_job_processor_behaviour()
    assert is_map(design)
    assert Map.has_key?(design, :callbacks)
    assert Map.has_key?(design, :implementations)
  end
end

"""
🔑 ANSWERS & EXPLANATIONS

# 1. CacheProvider behaviour
@callback get(key :: String.t()) :: {:ok, any()} | {:error, :not_found}
@callback put(key :: String.t(), value :: any()) :: :ok
@callback delete(key :: String.t()) :: :ok

defmodule MemoryCache do
  @behaviour CacheProvider
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl true
  def get(key), do: GenServer.call(__MODULE__, {:get, key})

  @impl true
  def put(key, value), do: GenServer.cast(__MODULE__, {:put, key, value})

  @impl true
  def delete(key), do: GenServer.cast(__MODULE__, {:delete, key})

  # GenServer callbacks...
  def handle_call({:get, key}, _from, state) do
    case Map.get(state, key) do
      nil -> {:reply, {:error, :not_found}, state}
      value -> {:reply, {:ok, value}, state}
    end
  end
end

# 2. DataValidator behaviour
@callback validate_field(field :: String.t(), value :: any()) :: :ok | {:error, String.t()}
@callback format_errors(errors :: list()) :: String.t()

defmodule EmailValidator do
  @behaviour DataValidator

  @impl true
  def validate_field("email", value) when is_binary(value) do
    if String.contains?(value, "@") do
      :ok
    else
      {:error, "Email must contain @"}
    end
  end

  @impl true
  def format_errors(errors) do
    errors |> Enum.map(&"• #{&1}") |> Enum.join("\n")
  end
end

# 3. JobProcessor behaviour
@callback enqueue(job_type :: atom(), params :: map()) :: {:ok, String.t()}
@callback process(job_id :: String.t()) :: :ok | {:error, any()}
@callback retry(job_id :: String.t(), attempts :: integer()) :: :ok | {:error, any()}

# The power of behaviours: same interface, different implementations
# Enables testing, swapping providers, and consistent APIs across systems.
"""
