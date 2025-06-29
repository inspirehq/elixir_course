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
IO.puts("\n📌 Example 2 – Using Mox for behaviour-based mocking")

defmodule DayTwo.MoxExamples do
  @moduledoc """
  Using Mox library for explicit, behaviour-based mocking.
  """

  def show_mox_setup do
    IO.puts("# Add Mox to mix.exs dependencies:")
    IO.puts(~S'{:mox, "~> 1.0", only: :test}')
    IO.puts("\n# Define behaviour for external service:")

    code =
      quote do
        defmodule PaymentGateway do
          @callback charge_card(amount :: Money.t(), card :: map()) ::
                      {:ok, String.t()} | {:error, atom()}

          @callback refund_charge(charge_id :: String.t()) ::
                      {:ok, String.t()} | {:error, atom()}
        end
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Real implementation:")

    code =
      quote do
        defmodule StripeGateway do
          @behaviour PaymentGateway

          def charge_card(amount, card) do
            case Stripe.charge(%{amount: amount, source: card.token}) do
              {:ok, charge} -> {:ok, charge.id}
              {:error, error} -> {:error, error.type}
            end
          end

          def refund_charge(charge_id) do
            case Stripe.refund(charge_id) do
              {:ok, refund} -> {:ok, refund.id}
              {:error, error} -> {:error, error.type}
            end
          end
        end
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Test setup with Mox:")

    code =
      quote do
        Mox.defmock(PaymentGatewayMock, for: PaymentGateway)
        Application.put_env(:my_app, :payment_gateway, PaymentGatewayMock)
      end

    IO.puts(Macro.to_string(code))
  end

  def show_mox_usage do
    IO.puts("# Using Mox in tests:")

    code =
      quote do
        defmodule OrderServiceTest do
          use ExUnit.Case, async: true
          import Mox

          setup :verify_on_exit!

          test "successful order payment" do
            expect(PaymentGatewayMock, :charge_card, fn amount, card ->
              assert amount == Money.new(:USD, 2000)
              assert card.last_four == "4242"
              {:ok, "charge_123"}
            end)

            order = %Order{total: Money.new(:USD, 2000)}
            card = %{token: "tok_123", last_four: "4242"}
            assert {:ok, payment} = OrderService.process_payment(order, card)
            assert payment.charge_id == "charge_123"
          end

          test "failed payment handling" do
            expect(PaymentGatewayMock, :charge_card, fn _amount, _card ->
              {:error, :card_declined}
            end)

            order = %Order{total: Money.new(:USD, 2000)}
            card = %{token: "tok_123", last_four: "4242"}
            assert {:error, :payment_failed} = OrderService.process_payment(order, card)
          end

          test "network timeout handling" do
            expect(PaymentGatewayMock, :charge_card, fn _amount, _card ->
              Process.sleep(5000)
              {:error, :timeout}
            end)

            order = %Order{total: Money.new(:USD, 2000)}
            card = %{token: "tok_123", last_four: "4242"}
            assert {:error, :payment_timeout} = OrderService.process_payment(order, card)
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end
end

IO.puts("Mox setup and usage:")
DayTwo.MoxExamples.show_mox_setup()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – HTTP mocking with Bypass")

defmodule DayTwo.BypassExamples do
  @moduledoc """
  Using Bypass to mock HTTP services at the network level.
  """

  def show_bypass_setup do
    IO.puts("# Add Bypass to dependencies:")
    IO.puts(~S'{:bypass, "~> 2.1", only: :test}')
    IO.puts("\n# HTTP client module:")

    code =
      quote do
        defmodule WeatherAPI do
          def get_current_weather(city) do
            url = "#{base_url()}/weather?q=#{city}&appid=#{api_key()}"

            case HTTPoison.get(url) do
              {:ok, %{status_code: 200, body: body}} ->
                {:ok, Jason.decode!(body)}
              {:ok, %{status_code: 404}} ->
                {:error, :city_not_found}
              {:error, reason} ->
                {:error, reason}
            end
          end

          defp base_url, do: Application.get_env(:my_app, :weather_api_url)
          defp api_key, do: Application.get_env(:my_app, :weather_api_key)
        end
      end

    IO.puts(Macro.to_string(code))
    IO.puts("\n# Test with Bypass:")

    code =
      quote do
        defmodule WeatherAPITest do
          use ExUnit.Case

          setup do
            bypass = Bypass.open()
            Application.put_env(:my_app, :weather_api_url, "http://localhost:#{bypass.port}")
            {:ok, bypass: bypass}
          end

          test "successful weather request", %{bypass: bypass} do
            Bypass.expect_once(bypass, "GET", "/weather", fn conn ->
              assert conn.query_string =~ "q=London"
              assert conn.query_string =~ "appid="

              response = %{
                "main" => %{"temp" => 273.15},
                "weather" => [%{"main" => "Clear"}]
              }

              Plug.Conn.resp(conn, 200, Jason.encode!(response))
            end)

            assert {:ok, weather} = WeatherAPI.get_current_weather("London")
            assert weather["main"]["temp"] == 273.15
          end

          test "city not found", %{bypass: bypass} do
            Bypass.expect_once(bypass, "GET", "/weather", fn conn ->
              Plug.Conn.resp(conn, 404, Jason.encode!(%{"message" => "city not found"}))
            end)

            assert {:error, :city_not_found} = WeatherAPI.get_current_weather("InvalidCity")
          end

          test "network timeout", %{bypass: bypass} do
            Bypass.expect_once(bypass, "GET", "/weather", fn conn ->
              Process.sleep(2000)
              Plug.Conn.resp(conn, 200, "{}")
            end)

            assert {:error, _} = WeatherAPI.get_current_weather("London")
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_advanced_bypass_patterns do
    IO.puts("# Advanced Bypass patterns:")

    code =
      quote do
        test "handling multiple requests", %{bypass: bypass} do
          Bypass.expect(bypass, "GET", "/status", fn conn ->
            Plug.Conn.resp(conn, 200, "OK")
          end)

          Bypass.expect(bypass, "POST", "/data", fn conn ->
            {:ok, body, conn} = Plug.Conn.read_body(conn)
            assert Jason.decode!(body) == %{"key" => "value"}
            Plug.Conn.resp(conn, 201, "Created")
          end)

          assert HTTPClient.get_status() == :ok
          assert HTTPClient.post_data(%{key: "value"}) == :created
          assert HTTPClient.get_status() == :ok
        end

        test "verifying request headers", %{bypass: bypass} do
          Bypass.expect_once(bypass, fn conn ->
            assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer secret-token"]
            assert Plug.Conn.get_req_header(conn, "x-request-id") != []
            Plug.Conn.resp(conn, 200, "Authenticated")
          end)

          assert HTTPClient.authenticated_request("secret-token") == :ok
        end
      end

    IO.puts(Macro.to_string(code))
  end
end

DayTwo.BypassExamples.show_bypass_setup()
DayTwo.BypassExamples.show_advanced_bypass_patterns()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Testing patterns for external services")

defmodule DayTwo.ExternalServicePatterns do
  @moduledoc """
  Common patterns for testing code that depends on external services.
  """

  def show_dependency_injection do
    """
    # Dependency injection pattern:
    defmodule EmailService do
      def send_welcome_email(user, email_client \\ default_client()) do
        template = render_welcome_template(user)

        case email_client.send_email(user.email, "Welcome!", template) do
          {:ok, message_id} ->
            log_email_sent(user, message_id)
            {:ok, message_id}
          {:error, reason} ->
            log_email_error(user, reason)
            {:error, reason}
        end
      end

      defp default_client, do: Application.get_env(:my_app, :email_client, SendgridClient)
    end

    # Test with injected mock:
    defmodule EmailServiceTest do
      use ExUnit.Case

      test "successful email sending" do
        mock_client = %{
          send_email: fn email, subject, body ->
            assert email == "user@example.com"
            assert subject == "Welcome!"
            assert body =~ "Hello Alice"
            {:ok, "msg_123"}
          end
        }

        user = %{name: "Alice", email: "user@example.com"}

        assert {:ok, "msg_123"} = EmailService.send_welcome_email(user, mock_client)
      end

      test "email sending failure" do
        mock_client = %{
          send_email: fn _email, _subject, _body ->
            {:error, :invalid_email}
          end
        }

        user = %{name: "Alice", email: "invalid-email"}

        assert {:error, :invalid_email} = EmailService.send_welcome_email(user, mock_client)
      end
    end
    """
  end

  def show_contract_testing do
    """
    # Contract testing to ensure mocks match reality:
    defmodule EmailClientContract do
      @callback send_email(String.t(), String.t(), String.t()) ::
        {:ok, String.t()} | {:error, atom()}
    end

    # Test that real implementation matches contract:
    defmodule SendgridClientTest do
      use ExUnit.Case

      @moduletag :integration

      test "real Sendgrid client matches contract" do
        # Only run with real credentials in CI
        unless System.get_env("SENDGRID_API_KEY") do
          ExUnit.skip("No Sendgrid credentials")
        end

        client = SendgridClient.new()

        # Test with real service occasionally
        result = client.send_email(
          "test@example.com",
          "Contract Test",
          "This is a contract test"
        )

        # Verify it matches our expected contract
        assert {:ok, message_id} = result
        assert is_binary(message_id)
      end
    end

    # Contract test for mock:
    defmodule EmailClientMockTest do
      use ExUnit.Case
      import Mox

      test "mock behaves like contract" do
        expect(EmailClientMock, :send_email, fn email, subject, body ->
          assert is_binary(email)
          assert is_binary(subject)
          assert is_binary(body)
          {:ok, "mock_msg_id"}
        end)

        result = EmailClientMock.send_email("test@example.com", "Test", "Body")
        assert {:ok, "mock_msg_id"} = result
      end
    end
    """
  end
end

IO.puts("Service testing patterns:")
IO.puts(DayTwo.ExternalServicePatterns.show_dependency_injection())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Testing a payment processing system")

defmodule DayTwo.PaymentSystemTesting do
  @moduledoc """
  Real-world example: Comprehensive testing of payment processing with external services.
  """

  def demonstrate_testing_strategy do
    flow_steps = [
      "🏗️  Unit tests with mocked payment gateway",
      "🔗 Integration tests with test payment provider",
      "🚨 Error handling tests for various failure modes",
      "⏱️  Timeout and retry logic testing",
      "💳 Different payment methods and edge cases",
      "🔄 Webhook processing and idempotency",
      "📊 Performance testing with concurrent payments"
    ]

    IO.puts("\nPayment system testing strategy:")
    Enum.each(flow_steps, fn step ->
      IO.puts("  #{step}")
    end)
  end

  def show_testing_benefits do
    benefits = [
      "Fast test suite (no real API calls in unit tests)",
      "Reliable tests (no network dependencies)",
      "Easy error condition testing",
      "Comprehensive edge case coverage",
      "Safe refactoring with good test coverage",
      "Clear separation of concerns",
      "Consistent test environment"
    ]

    IO.puts("\nBenefits of proper service mocking:")
    Enum.each(benefits, fn benefit ->
      IO.puts("  • #{benefit}")
    end)
  end
end

DayTwo.PaymentSystemTesting.demonstrate_testing_strategy()
DayTwo.PaymentSystemTesting.show_testing_benefits()

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Create a comprehensive test suite for a social media posting service
#    that integrates with Twitter, Facebook, and LinkedIn APIs using Mox.
# 2. Build tests for a file storage service that uploads to S3, including
#    error conditions, retries, and progress tracking using Bypass.
# 3. (Challenge) Design a test suite for a multi-step payment flow with
#    webhooks, refunds, and multiple payment providers with proper mocking.

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. Mocking with Behaviours
# First, define a `PaymentGateway` behaviour that specifies the functions
# our application needs (`charge/2`). Then, in the test environment, configure
# the application to use `MockPaymentGateway` instead of the real one.
# `Mox.defmock` creates this mock module for us based on the behaviour.
# In `config/test.exs`:
# config :my_app, :payment_gateway, MyApp.MockPaymentGateway

# 2. Testing with Mox
# In the test, `import Mox` and `setup :verify_on_exit!`. The `expect` function
# tells the mock how to respond when called. We can assert that the correct
# arguments are received and return either a success or error tuple to test
# different code paths in our application.
expect(MyApp.MockPaymentGateway, :charge, fn amount, _token ->
  assert amount == 100
  {:ok, "charge_id_123"}
end)

# 3. HTTP Mocking with Bypass
# Bypass is used for testing the HTTP client layer directly. `Bypass.open()`
# starts a server on a random port. We configure our app to use this URL.
# `Bypass.expect` programs the mock server to handle an incoming request,
# check its properties (like method and path), and return a specific response.
Bypass.expect(bypass, "POST", "/charge", fn conn ->
  Plug.Conn.resp(conn, 200, ~s'{"id": "charge_id_123"}')
end)
""")

defmodule DayTwo.MockingExercises do
  @moduledoc """
  Run the tests with: mix test day_two/14_testing_third_party_services.exs
  or in IEx:
  iex -r day_two/14_testing_third_party_services.exs
  DayTwo.MockingExercisesTest.test_design_payment_gateway_mock/0
  DayTwo.MockingExercisesTest.test_design_email_service_mock/0
  DayTwo.MockingExercisesTest.test_design_http_client_mock_with_bypass/0
  """

  @doc """
  Designs a mock for a `PaymentGateway` behaviour using Mox.

  **Goal:** Learn how to use `Mox` to define a mock and write tests for both
  the success and failure cases of a service that uses the behaviour.

  **Behaviour to Mock:**
  ```elixir
  defmodule PaymentGateway do
    @callback charge(amount :: integer, token :: String.t) ::
      {:ok, transaction_id :: String.t} | {:error, reason :: atom}
  end
  ```

  **Task:**
  Return a map describing the test design:
  - `:mox_module_definition`: A string defining the Mox mock module.
  - `:success_test`: A string for a test that `expect`s a successful call to
    `charge/2` and returns an `{:ok, ...}` tuple.
  - `:failure_test`: A string for a test that `expect`s a call to `charge/2`
    and returns an `{:error, :card_declined}` tuple.
  """
  @spec design_payment_gateway_mock() :: map()
  def design_payment_gateway_mock do
    # Design tests for a payment gateway using Mox.
    # Return a map with :mox_module_definition, :success_test, and :failure_test.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a mock for an `EmailService` that has a non-standard return type.

  **Goal:** Learn to mock behaviours even when they don't return simple
  `:ok`/`:error` tuples and how to make assertions on the arguments passed
  to the mocked function.

  **Behaviour to Mock:**
  ```elixir
  defmodule EmailService do
    @callback deliver(email :: map) :: String.t | no_return
  end
  ```
  Note: `deliver/1` returns a `delivery_id` string on success or raises an
  exception on failure.

  **Task:**
  Return a string describing the testing strategy. It should explain how to:
  1.  Test the success case, where `deliver/1` returns a `delivery_id`.
  2.  Use an `expect` to make assertions on the `email` map that is passed
      to the `deliver/1` function (e.g., check the `:to` and `:subject` fields).
  3.  Test the failure case by telling the mock to `raise` an exception.
  """
  @spec design_email_service_mock() :: binary()
  def design_email_service_mock do
    # Describe a testing strategy for an EmailService mock, covering
    # success, argument assertion, and exception cases.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a test for an HTTP client using `Bypass`.

  **Goal:** Learn how to test the logic of an HTTP client (URL construction,
  response parsing, error handling) without making real network calls.

  **Module to Test:**
  ```elixir
  defmodule GitHubClient do
    def get_user_repos(username) do
      url = "https://api.github.com/users/#{username}/repos"
      # ... logic using an HTTP client like Finch or HTTPoison ...
    end
  end
  ```

  **Task:**
  Return a map describing the test design using `Bypass`:
  - `:setup_block`: A string for the `setup` block that opens a `Bypass` connection
    and configures the application to use the Bypass URL.
  - `:success_test`: A string for a test that uses `Bypass.expect_once/3` to
    stub a 200 OK response with a sample JSON body, and asserts that the
    `get_user_repos/1` function correctly parses the response.
  - `:not_found_test`: A string for a test that stubs a 404 Not Found
    response and asserts that the function returns an appropriate error tuple.
  """
  @spec design_http_client_mock_with_bypass() :: map()
  def design_http_client_mock_with_bypass do
    # Design a test for a GitHub HTTP client using Bypass.
    # Return a map with :setup_block, :success_test, and :not_found_test.
    nil  # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.MockingExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.MockingExercises, as: EX

  test "design_payment_gateway_mock/0 returns a valid Mox design" do
    design = EX.design_payment_gateway_mock()
    assert is_map(design)
    assert String.contains?(design.mox_module_definition, "defmock")
    assert String.contains?(design.success_test, "expect(PaymentGatewayMock")
    assert String.contains?(design.failure_test, "{:error, :card_declined}")
  end

  test "design_email_service_mock/0 describes a comprehensive strategy" do
    strategy = EX.design_email_service_mock()
    assert is_binary(strategy)
    assert String.contains?(strategy, "assert_raise")
    assert String.contains?(strategy, "assert email.to")
  end

  test "design_http_client_mock_with_bypass/0 returns a valid Bypass design" do
    design = EX.design_http_client_mock_with_bypass()
    assert is_map(design)
    assert String.contains?(design.setup_block, "Bypass.open()")
    assert String.contains?(design.success_test, "Bypass.expect_once")
    assert String.contains?(design.not_found_test, "resp(conn, 404")
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      %{
        mox_module_definition: "Mox.defmock(PaymentGatewayMock, for: PaymentGateway)",
        success_test: """
        test "successful charge" do
          expect(PaymentGatewayMock, :charge, fn 1000, "valid_token" ->
            {:ok, "txn_123"}
          end)

          assert Order.checkout(1000, "valid_token") == {:ok, "txn_123"}
        end
        """,
        failure_test: """
        test "declined charge" do
          expect(PaymentGatewayMock, :charge, fn 1000, "invalid_token" ->
            {:error, :card_declined}
          end)

          assert Order.checkout(1000, "invalid_token") == {:error, :payment_failed}
        end
        """
      }
    end
  end

  def answer_two do
    quote do
      """
      Testing Strategy for `EmailService`:

      1.  **Success Case**: The test will use `expect/3` on the mock. The expectation
          will return a sample delivery ID string, e.g., "delivery_abc". The test then
          asserts that the function under test returns this ID.
          `expect(EmailServiceMock, :deliver, fn _ -> "delivery_abc" end)`

      2.  **Argument Assertion**: The anonymous function passed to `expect` receives
          the arguments that the real function would. Inside this function, we can
          make assertions on the email map. This is a powerful way to ensure the
          service is being *called correctly*.
          `expect(..., fn email -> assert email.to == "test@example.com"; "ok" end)`

      3.  **Exception Case**: The `expect` function can be made to `raise` an
          exception instead of returning a value. The test then wraps the call
          to the service in `assert_raise/2` to verify that the system correctly
          handles the third-party service's error.
          `expect(..., fn _ -> raise "SMTP server down" end)`
          `assert_raise RuntimeError, fn -> Notifier.send_welcome_email(...) end`
      """
    end
  end

  def answer_three do
    quote do
      %{
        setup_block: """
        setup do
          bypass = Bypass.open()
          Application.put_env(:my_app, :github_api_url, "http://localhost:#{bypass.port}")
          {:ok, bypass: bypass}
        end
        """,
        success_test: """
        test "fetches user repos successfully", %{bypass: bypass} do
          Bypass.expect_once(bypass, "GET", "/users/elixir/repos", fn conn ->
            Plug.Conn.resp(conn, 200, ~s'[{"name": "plug"}]')
          end)

          assert {:ok, [%{"name" => "plug"}]} = GitHubClient.get_user_repos("elixir")
        end
        """,
        not_found_test: """
        test "handles user not found", %{bypass: bypass} do
          Bypass.expect_once(bypass, "GET", "/users/unknown/repos", fn conn ->
            Plug.Conn.resp(conn, 404, "Not Found")
          end)

          assert {:error, :not_found} = GitHubClient.get_user_repos("unknown")
        end
        """
      }
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. Mocking a Payment Gateway with Mox
#{Macro.to_string(DayTwo.Answers.answer_one())}
# This demonstrates the core workflow of Mox. You define a behaviour, create a
# mock for it, and then in each test, you set an `expect`ation for how the
# mock should be called. Mox verifies that the function was called with the
# correct arguments and provides the specified return value. `setup :verify_on_exit!`
# is crucial as it ensures all expectations were met during the test.

# 2. Mocking an Email Service
#{Macro.to_string(DayTwo.Answers.answer_two())}
# This strategy shows the flexibility of Mox. By placing assertions inside the
# anonymous function passed to `expect`, you can test that your application is
# constructing the correct arguments for the external service. Testing for
# exceptions is also critical for building resilient systems that can handle
# third-party outages.

# 3. Mocking an HTTP Client with Bypass
#{Macro.to_string(DayTwo.Answers.answer_three())}
# Bypass is ideal when you want to test the full HTTP request/response cycle of
# your client without the slowness and unreliability of real network calls. You
# test everything up to the network boundary: URL construction, header formatting,
# response body parsing, and status code handling.
""")
