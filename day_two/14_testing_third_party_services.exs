# Day 2 – Testing 3rd Party Services Through Effective Use of Mocks
#
# This script can be run with:
#     mix run day_two/14_testing_third_party_services.exs
# or inside IEx with:
#     iex -r day_two/14_testing_third_party_services.exs
#
# Testing external services requires isolation, speed, and reliability. We'll explore
# mocking strategies using Mox, test doubles, and dependency injection patterns.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Mocking concepts and strategies")

defmodule DayTwo.MockingConcepts do
  @moduledoc """
  Understanding different types of test doubles and when to use them.
  """

  def explain_test_doubles do
    """
    Types of Test Doubles:

    • DUMMY: Objects passed around but never used
    • FAKE: Working implementation with shortcuts (in-memory DB)
    • STUB: Returns predefined responses to calls
    • SPY: Records information about how it was called
    • MOCK: Pre-programmed with expectations of calls

    Benefits of Mocking External Services:
    • Tests run fast (no network calls)
    • Tests are reliable (no external dependencies)
    • Can test error conditions easily
    • Control timing and responses precisely
    • Run tests offline
    • Avoid rate limits and costs

    When NOT to Mock:
    • Testing the external service itself
    • Integration tests with real services
    • When mock becomes more complex than real code
    • Testing network/serialization logic
    """
  end

  def show_mocking_strategies do
    strategies = [
      "Dependency Injection: Pass service as parameter",
      "Behaviour Contracts: Define interfaces with @behaviour",
      "Application Config: Configure service module at runtime",
      "Test Environment: Use different implementations per env",
      "HTTP Clients: Mock at HTTP layer with tools like Bypass",
      "Process Substitution: Use different processes in tests"
    ]

    IO.puts("Common mocking strategies:")
    Enum.each(strategies, fn strategy ->
      IO.puts("  • #{strategy}")
    end)
  end
end

IO.puts("Mocking concepts:")
IO.puts(DayTwo.MockingConcepts.explain_test_doubles())
DayTwo.MockingConcepts.show_mocking_strategies()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Behaviour-based mocking with real examples")

# Payment Gateway Behaviour
defmodule DayTwo.PaymentGateway do
  @moduledoc """
  Behaviour defining the contract for payment gateway services.
  """

  @callback charge_card(amount :: integer(), card_token :: String.t()) ::
              {:ok, String.t()} | {:error, atom()}

  @callback refund_charge(charge_id :: String.t()) ::
              {:ok, String.t()} | {:error, atom()}
end

# Real implementation (would call actual Stripe API)
defmodule DayTwo.StripeGateway do
  @moduledoc """
  Real Stripe implementation of the PaymentGateway behaviour.
  """

  @behaviour DayTwo.PaymentGateway

  def charge_card(amount, card_token) do
    # In real implementation, this would call Stripe API
    # For demo purposes, we'll simulate responses
    case {amount, card_token} do
      {amount, _} when amount <= 0 ->
        {:error, :invalid_amount}
      {_, "invalid_token"} ->
        {:error, :invalid_card}
      {_, "declined_token"} ->
        {:error, :card_declined}
      {amount, token} ->
        charge_id = "ch_" <> Base.encode64("#{amount}_#{token}")
        {:ok, charge_id}
    end
  end

  def refund_charge("ch_" <> _rest = charge_id) do
    refund_id = "re_" <> String.replace(charge_id, "ch_", "")
    {:ok, refund_id}
  end

  def refund_charge(_invalid_charge_id) do
    {:error, :invalid_charge_id}
  end
end

# Email Service Behaviour
defmodule DayTwo.EmailService do
  @moduledoc """
  Behaviour for email sending services.
  """

  @callback send_email(to :: String.t(), subject :: String.t(), body :: String.t()) ::
              {:ok, String.t()} | {:error, atom()}

  @callback send_template_email(to :: String.t(), template :: atom(), data :: map()) ::
              {:ok, String.t()} | {:error, atom()}
end

# Sendgrid implementation
defmodule DayTwo.SendgridService do
  @moduledoc """
  Sendgrid implementation of the EmailService behaviour.
  """

  @behaviour DayTwo.EmailService

  def send_email(to, subject, body) do
    # Simulate email validation and sending
    cond do
      not String.contains?(to, "@") ->
        {:error, :invalid_email}
      String.length(subject) == 0 ->
        {:error, :missing_subject}
      String.length(body) == 0 ->
        {:error, :missing_body}
      true ->
        message_id = "msg_" <> Base.encode64("#{to}_#{subject}")
        {:ok, message_id}
    end
  end

  def send_template_email(to, template, data) do
    body = render_template(template, data)
    subject = get_template_subject(template)
    send_email(to, subject, body)
  end

  defp render_template(:welcome, %{name: name}) do
    "Welcome #{name}! Thanks for joining our platform."
  end

  defp render_template(:password_reset, %{reset_link: link}) do
    "Click here to reset your password: #{link}"
  end

  defp render_template(_, _), do: "Default template content"

  defp get_template_subject(:welcome), do: "Welcome to our platform!"
  defp get_template_subject(:password_reset), do: "Reset your password"
  defp get_template_subject(_), do: "Notification"
end

# HTTP API Client
defmodule DayTwo.WeatherAPI do
  @moduledoc """
  HTTP client for weather API service.
  """

  def get_current_weather(city) do
    url = "#{base_url()}/current?q=#{city}&key=#{api_key()}"

    # Simulate HTTP request (in real code, would use HTTPoison or Finch)
    case simulate_http_get(url) do
      {:ok, 200, body} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, _} -> {:error, :invalid_response}
        end
      {:ok, 404, _} ->
        {:error, :city_not_found}
      {:ok, 401, _} ->
        {:error, :unauthorized}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_forecast(city, days \\ 5) do
    url = "#{base_url()}/forecast?q=#{city}&days=#{days}&key=#{api_key()}"

    case simulate_http_get(url) do
      {:ok, 200, body} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, _} -> {:error, :invalid_response}
        end
      {:ok, 404, _} ->
        {:error, :city_not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp base_url, do: Application.get_env(:my_app, :weather_api_url, "https://api.weather.com")
  defp api_key, do: Application.get_env(:my_app, :weather_api_key, "default_key")

  # Simulate HTTP responses for demo purposes
  defp simulate_http_get(url) do
    cond do
      String.contains?(url, "invalid_city") ->
        {:ok, 404, Jason.encode!(%{"error" => "City not found"})}
      String.contains?(url, "London") ->
        weather_data = %{
          "location" => %{"name" => "London"},
          "current" => %{"temp_c" => 15, "condition" => %{"text" => "Cloudy"}},
          "forecast" => %{"forecastday" => []}
        }
        {:ok, 200, Jason.encode!(weather_data)}
      String.contains?(url, "timeout") ->
        {:error, :timeout}
      true ->
        {:ok, 200, Jason.encode!(%{"location" => %{"name" => "Unknown"}})}
    end
  end
end

# Business Logic using external services
defmodule DayTwo.OrderService do
  @moduledoc """
  Business logic for processing orders with external payment service.
  """

  def process_payment(order, card, payment_gateway \\ nil) do
    gateway = payment_gateway || get_payment_gateway()

    case gateway.charge_card(order.total, card.token) do
      {:ok, charge_id} ->
        # Update order with charge information
        updated_order = %{order | charge_id: charge_id, status: :paid}
        {:ok, updated_order}
      {:error, :card_declined} ->
        {:error, :payment_declined}
      {:error, :invalid_card} ->
        {:error, :invalid_payment_method}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def refund_order(order, payment_gateway \\ nil) do
    gateway = payment_gateway || get_payment_gateway()

    case gateway.refund_charge(order.charge_id) do
      {:ok, refund_id} ->
        updated_order = %{order | refund_id: refund_id, status: :refunded}
        {:ok, updated_order}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_payment_gateway do
    Application.get_env(:my_app, :payment_gateway, DayTwo.StripeGateway)
  end
end

defmodule DayTwo.NotificationService do
  @moduledoc """
  Service for sending notifications via email.
  """

  def send_welcome_email(user, email_service \\ nil) do
    service = email_service || get_email_service()

    template_data = %{name: user.name}

    case service.send_template_email(user.email, :welcome, template_data) do
      {:ok, message_id} ->
        log_email_sent(user, :welcome, message_id)
        {:ok, message_id}
      {:error, reason} ->
        log_email_error(user, :welcome, reason)
        {:error, reason}
    end
  end

  def send_order_confirmation(user, order, email_service \\ nil) do
    service = email_service || get_email_service()

    subject = "Order Confirmation ##{order.id}"
    body = "Your order for $#{order.total} has been confirmed."

    case service.send_email(user.email, subject, body) do
      {:ok, message_id} ->
        {:ok, message_id}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_email_service do
    Application.get_env(:my_app, :email_service, DayTwo.SendgridService)
  end

  defp log_email_sent(user, template, message_id) do
    IO.puts("Email sent to #{user.email}: #{template} (#{message_id})")
  end

  defp log_email_error(user, template, reason) do
    IO.puts("Email failed for #{user.email}: #{template} - #{reason}")
  end
end

IO.puts("Real service examples created")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Testing patterns and strategies")

defmodule DayTwo.TestingPatterns do
  @moduledoc """
  Demonstrates various testing patterns for external services.
  """

  def show_dependency_injection_pattern do
    IO.puts("Dependency injection pattern allows easy testing:")
    IO.puts("- Pass service as parameter to functions")
    IO.puts("- Use application config for default service")
    IO.puts("- Inject mock service in tests")
    IO.puts("- Keep business logic testable and isolated")
  end

  def show_contract_testing_benefits do
    benefits = [
      "Ensures mocks behave like real implementations",
      "Catches breaking changes in external APIs",
      "Documents expected service behavior",
      "Builds confidence in mock accuracy",
      "Enables safe refactoring of service integrations"
    ]

    IO.puts("\nContract testing benefits:")
    Enum.each(benefits, fn benefit ->
      IO.puts("  • #{benefit}")
    end)
  end

  def show_testing_layers do
    layers = [
      "Unit Tests: Mock external services, test business logic",
      "Integration Tests: Use real services in test environment",
      "Contract Tests: Verify mocks match real service behavior",
      "End-to-End Tests: Full workflow with all external services"
    ]

    IO.puts("\nTesting layer strategy:")
    Enum.each(layers, fn layer ->
      IO.puts("  • #{layer}")
    end)
  end
end

DayTwo.TestingPatterns.show_dependency_injection_pattern()
DayTwo.TestingPatterns.show_contract_testing_benefits()
DayTwo.TestingPatterns.show_testing_layers()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Mock creation and usage patterns")

# Helper module to demonstrate mock creation (Mox would normally do this)
defmodule DayTwo.MockHelpers do
  @moduledoc """
  Demonstrates how to create simple mocks for testing.
  Note: In real applications, use Mox library instead.
  """

  def create_payment_gateway_mock(expectations \\ %{}) do
    %{
      charge_card: fn amount, token ->
        case Map.get(expectations, {:charge_card, amount, token}) do
          nil -> {:ok, "default_charge_id"}
          result -> result
        end
      end,
      refund_charge: fn charge_id ->
        case Map.get(expectations, {:refund_charge, charge_id}) do
          nil -> {:ok, "default_refund_id"}
          result -> result
        end
      end
    }
  end

  def create_email_service_mock(expectations \\ %{}) do
    %{
      send_email: fn to, subject, body ->
        case Map.get(expectations, {:send_email, to, subject, body}) do
          nil -> {:ok, "default_message_id"}
          result -> result
        end
      end,
      send_template_email: fn to, template, data ->
        case Map.get(expectations, {:send_template_email, to, template, data}) do
          nil -> {:ok, "default_template_message_id"}
          result -> result
        end
      end
    }
  end
end

IO.puts("Mock creation patterns demonstrated")

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# Run the tests with: mix test day_two/14_testing_third_party_services.exs
# ────────────────────────────────────────────────────────────────

ExUnit.start()

defmodule DayTwo.ThirdPartyTestingExercises do
  use ExUnit.Case, async: true

  alias DayTwo.{OrderService, NotificationService, MockHelpers}

  describe "payment gateway mocking" do
    test "successful payment processing" do
      # Exercise 1: Test successful payment with mocked gateway
      # TODO: Create a payment gateway mock that returns {:ok, "charge_123"}
      # Test that OrderService.process_payment/3 works correctly

      order = %{id: 1, total: 100, status: :pending}
      card = %{token: "valid_token"}

      # TODO: Create mock and test successful payment
      # gateway_mock = MockHelpers.create_payment_gateway_mock(...)
      # result = OrderService.process_payment(order, card, gateway_mock)
      # Add assertions here

      flunk "Implement payment gateway mocking test"
    end

    test "declined payment handling" do
      # Exercise 2: Test payment decline scenario
      # TODO: Create a mock that returns {:error, :card_declined}
      # Verify OrderService handles it correctly

      order = %{id: 1, total: 100, status: :pending}
      card = %{token: "declined_token"}

      # TODO: Implement test for declined payment
      flunk "Implement declined payment test"
    end

    test "invalid card error handling" do
      # Exercise 3: Test invalid card scenario
      # TODO: Create a mock that returns {:error, :invalid_card}
      # Verify proper error handling

      order = %{id: 1, total: 100, status: :pending}
      card = %{token: "invalid_token"}

      # TODO: Implement test for invalid card
      flunk "Implement invalid card test"
    end
  end

  describe "email service mocking" do
    test "successful welcome email sending" do
      # Exercise 4: Test welcome email with mocked email service
      # TODO: Create email service mock that returns {:ok, "msg_456"}
      # Test NotificationService.send_welcome_email/2

      user = %{name: "Alice", email: "alice@example.com"}

      # TODO: Create mock and test welcome email
      # email_mock = MockHelpers.create_email_service_mock(...)
      # result = NotificationService.send_welcome_email(user, email_mock)
      # Add assertions here

      flunk "Implement welcome email test"
    end

    test "email sending failure" do
      # Exercise 5: Test email sending failure
      # TODO: Create a mock that returns {:error, :invalid_email}
      # Verify error handling

      user = %{name: "Bob", email: "invalid-email"}

      # TODO: Implement test for email failure
      flunk "Implement email failure test"
    end

    test "order confirmation email" do
      # Exercise 6: Test order confirmation email
      # TODO: Test NotificationService.send_order_confirmation/3
      # Verify correct email content is sent

      user = %{name: "Charlie", email: "charlie@example.com"}
      order = %{id: 123, total: 250}

      # TODO: Implement order confirmation test
      flunk "Implement order confirmation test"
    end
  end

  describe "refund processing" do
    test "successful refund" do
      # Exercise 7: Test successful refund processing
      # TODO: Create payment gateway mock for refund scenario
      # Test OrderService.refund_order/2

      order = %{id: 1, charge_id: "charge_123", status: :paid}

      # TODO: Implement refund test
      flunk "Implement refund test"
    end

    test "refund with invalid charge id" do
      # Exercise 8: Test refund with invalid charge
      # TODO: Mock returns {:error, :invalid_charge_id}
      # Verify error handling

      order = %{id: 1, charge_id: "invalid_charge", status: :paid}

      # TODO: Implement invalid refund test
      flunk "Implement invalid refund test"
    end
  end

  describe "complex service interactions" do
    test "complete order flow with payment and email" do
      # Exercise 9: Test complete order flow
      # TODO: Create mocks for both payment and email services
      # Test full workflow: process payment -> send confirmation email

      user = %{name: "Diana", email: "diana@example.com"}
      order = %{id: 1, total: 150, status: :pending}
      card = %{token: "valid_token"}

      # TODO: Implement complete flow test
      # 1. Mock payment gateway for successful charge
      # 2. Mock email service for confirmation email
      # 3. Process payment
      # 4. Send confirmation email
      # 5. Assert both operations succeeded

      flunk "Implement complete order flow test"
    end

    test "order flow with payment failure" do
      # Exercise 10: Test order flow when payment fails
      # TODO: Mock payment failure and verify email is NOT sent

      user = %{name: "Eve", email: "eve@example.com"}
      order = %{id: 1, total: 150, status: :pending}
      card = %{token: "declined_token"}

      # TODO: Implement payment failure flow test
      flunk "Implement payment failure flow test"
    end
  end

  describe "service behavior verification" do
    test "verify payment gateway is called with correct arguments" do
      # Exercise 11: Verify mock is called with expected arguments
      # TODO: Create a mock that captures and verifies arguments

      order = %{id: 1, total: 100, status: :pending}
      card = %{token: "test_token"}

      # TODO: Create mock that verifies amount=100 and token="test_token"
      # Use a flag or counter to verify the call was made

      flunk "Implement argument verification test"
    end

    test "verify email service receives correct template data" do
      # Exercise 12: Verify template email is called correctly
      # TODO: Create mock that verifies template and data parameters

      user = %{name: "Frank", email: "frank@example.com"}

      # TODO: Verify send_template_email is called with:
      # - to: "frank@example.com"
      # - template: :welcome
      # - data: %{name: "Frank"}

      flunk "Implement template data verification test"
    end
  end
end

IO.puts("""


TESTING THIRD-PARTY SERVICES CONCEPTS SUMMARY
==============================================

Key Concepts:
• Dependency Injection: Pass services as parameters for easy testing
• Behaviour Contracts: Define interfaces with @behaviour for type safety
• Mock Strategies: Different approaches for different testing needs
• Test Doubles: Dummy, Fake, Stub, Spy, Mock - each serves different purposes
• Isolation: Test business logic without external dependencies

Benefits of Mocking:
• Fast test execution (no network calls)
• Reliable tests (no external service dependencies)
• Easy error condition testing
• Controlled responses and timing
• Offline development and testing
• Cost reduction (no API usage charges)

Testing Patterns:
• Unit Tests: Mock all external services
• Integration Tests: Use real services in test environment
• Contract Tests: Verify mocks match real service behavior
• End-to-End Tests: Full workflow testing

Mock Verification:
• Verify correct arguments are passed
• Check expected number of calls
• Validate business logic behavior
• Test error handling paths
• Confirm side effects don't occur on failures

When NOT to Mock:
• Testing the external service itself
• Integration testing with real services
• Network/serialization logic testing
• When mocks become more complex than real code

Best Practices:
• Keep mocks simple and focused
• Use dependency injection for flexibility
• Test both success and failure scenarios
• Verify interactions, not just results
• Keep real and mock implementations in sync
""")

# ────────────────────────────────────────────────────────────────
# 📚 EXERCISE ANSWERS
# ────────────────────────────────────────────────────────────────

defmodule DayTwo.ThirdPartyTestingAnswers do
  @moduledoc """
  Complete solutions for the third-party services testing exercises.
  """

  def answer_one do
    """
    # Exercise 1: Successful payment processing with mocked gateway

    test "successful payment processing" do
      order = %{id: 1, total: 100, status: :pending}
      card = %{token: "valid_token"}

      # Create mock that returns successful charge
      gateway_mock = MockHelpers.create_payment_gateway_mock(%{
        {:charge_card, 100, "valid_token"} => {:ok, "charge_123"}
      })

      result = OrderService.process_payment(order, card, gateway_mock)

      assert {:ok, updated_order} = result
      assert updated_order.charge_id == "charge_123"
      assert updated_order.status == :paid
      assert updated_order.total == 100  # Unchanged
    end
    """
  end

  def answer_two do
    """
    # Exercise 2: Declined payment handling

    test "declined payment handling" do
      order = %{id: 1, total: 100, status: :pending}
      card = %{token: "declined_token"}

      # Create mock that returns card declined error
      gateway_mock = MockHelpers.create_payment_gateway_mock(%{
        {:charge_card, 100, "declined_token"} => {:error, :card_declined}
      })

      result = OrderService.process_payment(order, card, gateway_mock)

      assert {:error, :payment_declined} = result
    end
    """
  end

  def answer_three do
    """
    # Exercise 3: Invalid card error handling

    test "invalid card error handling" do
      order = %{id: 1, total: 100, status: :pending}
      card = %{token: "invalid_token"}

      # Create mock that returns invalid card error
      gateway_mock = MockHelpers.create_payment_gateway_mock(%{
        {:charge_card, 100, "invalid_token"} => {:error, :invalid_card}
      })

      result = OrderService.process_payment(order, card, gateway_mock)

      assert {:error, :invalid_payment_method} = result
    end
    """
  end

  def answer_four do
    """
    # Exercise 4: Welcome email with mocked email service

    test "successful welcome email sending" do
      user = %{name: "Alice", email: "alice@example.com"}

      # Create mock that returns successful message sending
      email_mock = MockHelpers.create_email_service_mock(%{
        {:send_template_email, "alice@example.com", :welcome, %{name: "Alice"}} => {:ok, "msg_456"}
      })

      result = NotificationService.send_welcome_email(user, email_mock)

      assert {:ok, "msg_456"} = result
    end
    """
  end

  def answer_five do
    """
    # Exercise 5: Email sending failure

    test "email sending failure" do
      user = %{name: "Bob", email: "invalid-email"}

      # Create mock that returns invalid email error
      email_mock = MockHelpers.create_email_service_mock(%{
        {:send_template_email, "invalid-email", :welcome, %{name: "Bob"}} => {:error, :invalid_email}
      })

      result = NotificationService.send_welcome_email(user, email_mock)

      assert {:error, :invalid_email} = result
    end
    """
  end

  def answer_six do
    """
    # Exercise 6: Order confirmation email

    test "order confirmation email" do
      user = %{name: "Charlie", email: "charlie@example.com"}
      order = %{id: 123, total: 250}

      expected_subject = "Order Confirmation #123"
      expected_body = "Your order for $250 has been confirmed."

      # Create mock that verifies correct email content
      email_mock = MockHelpers.create_email_service_mock(%{
        {:send_email, "charlie@example.com", expected_subject, expected_body} => {:ok, "msg_789"}
      })

      result = NotificationService.send_order_confirmation(user, order, email_mock)

      assert {:ok, "msg_789"} = result
    end
    """
  end

  def answer_seven do
    """
    # Exercise 7: Successful refund processing

    test "successful refund" do
      order = %{id: 1, charge_id: "charge_123", status: :paid}

      # Create mock that returns successful refund
      gateway_mock = MockHelpers.create_payment_gateway_mock(%{
        {:refund_charge, "charge_123"} => {:ok, "refund_456"}
      })

      result = OrderService.refund_order(order, gateway_mock)

      assert {:ok, updated_order} = result
      assert updated_order.refund_id == "refund_456"
      assert updated_order.status == :refunded
    end
    """
  end

  def answer_eight do
    """
    # Exercise 8: Refund with invalid charge id

    test "refund with invalid charge id" do
      order = %{id: 1, charge_id: "invalid_charge", status: :paid}

      # Create mock that returns invalid charge error
      gateway_mock = MockHelpers.create_payment_gateway_mock(%{
        {:refund_charge, "invalid_charge"} => {:error, :invalid_charge_id}
      })

      result = OrderService.refund_order(order, gateway_mock)

      assert {:error, :invalid_charge_id} = result
    end
    """
  end

  def answer_nine do
    """
    # Exercise 9: Complete order flow with payment and email

    test "complete order flow with payment and email" do
      user = %{name: "Diana", email: "diana@example.com"}
      order = %{id: 1, total: 150, status: :pending}
      card = %{token: "valid_token"}

      # Mock successful payment
      payment_mock = MockHelpers.create_payment_gateway_mock(%{
        {:charge_card, 150, "valid_token"} => {:ok, "charge_789"}
      })

      # Mock successful email
      email_mock = MockHelpers.create_email_service_mock(%{
        {:send_email, "diana@example.com", "Order Confirmation #1", "Your order for $150 has been confirmed."} => {:ok, "msg_999"}
      })

      # Process payment
      {:ok, paid_order} = OrderService.process_payment(order, card, payment_mock)
      assert paid_order.charge_id == "charge_789"
      assert paid_order.status == :paid

      # Send confirmation email
      {:ok, message_id} = NotificationService.send_order_confirmation(user, paid_order, email_mock)
      assert message_id == "msg_999"
    end
    """
  end

  def answer_ten do
    """
    # Exercise 10: Order flow with payment failure

    test "order flow with payment failure" do
      user = %{name: "Eve", email: "eve@example.com"}
      order = %{id: 1, total: 150, status: :pending}
      card = %{token: "declined_token"}

      # Mock payment failure
      payment_mock = MockHelpers.create_payment_gateway_mock(%{
        {:charge_card, 150, "declined_token"} => {:error, :card_declined}
      })

      # Process payment (should fail)
      result = OrderService.process_payment(order, card, payment_mock)
      assert {:error, :payment_declined} = result

      # Email should NOT be sent when payment fails
      # (In a real implementation, you might send a different email about the failure)
    end
    """
  end

  def answer_eleven do
    """
    # Exercise 11: Verify payment gateway is called with correct arguments

    test "verify payment gateway is called with correct arguments" do
      order = %{id: 1, total: 100, status: :pending}
      card = %{token: "test_token"}

      # Create a mock that captures the call
      call_log = Agent.start_link(fn -> [] end)

      gateway_mock = %{
        charge_card: fn amount, token ->
          Agent.update(call_log, fn calls ->
            [{:charge_card, amount, token} | calls]
          end)
          {:ok, "charge_verified"}
        end,
        refund_charge: fn _charge_id -> {:ok, "refund_verified"} end
      }

      # Process payment
      {:ok, _result} = OrderService.process_payment(order, card, gateway_mock)

      # Verify the call was made with correct arguments
      calls = Agent.get(call_log, & &1)
      assert [{:charge_card, 100, "test_token"}] = calls
    end
    """
  end

  def answer_twelve do
    """
    # Exercise 12: Verify email service receives correct template data

    test "verify email service receives correct template data" do
      user = %{name: "Frank", email: "frank@example.com"}

      # Create a mock that captures the call
      {:ok, call_log} = Agent.start_link(fn -> [] end)

      email_mock = %{
        send_email: fn _to, _subject, _body -> {:ok, "basic_email"} end,
        send_template_email: fn to, template, data ->
          Agent.update(call_log, fn calls ->
            [{:send_template_email, to, template, data} | calls]
          end)
          {:ok, "template_verified"}
        end
      }

      # Send welcome email
      {:ok, _result} = NotificationService.send_welcome_email(user, email_mock)

      # Verify the call was made with correct template data
      calls = Agent.get(call_log, & &1)
      assert [
        {:send_template_email, "frank@example.com", :welcome, %{name: "Frank"}}
      ] = calls
    end
    """
  end
end
