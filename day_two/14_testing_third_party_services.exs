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
    """
    # Add Mox to mix.exs dependencies:
    {:mox, "~> 1.0", only: :test}

    # Define behaviour for external service:
    defmodule PaymentGateway do
      @callback charge_card(amount :: Money.t(), card :: map()) ::
        {:ok, String.t()} | {:error, atom()}

      @callback refund_charge(charge_id :: String.t()) ::
        {:ok, String.t()} | {:error, atom()}
    end

    # Real implementation:
    defmodule StripeGateway do
      @behaviour PaymentGateway

      def charge_card(amount, card) do
        # Real Stripe API call
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

    # Test setup with Mox:
    # test/test_helper.exs
    Mox.defmock(PaymentGatewayMock, for: PaymentGateway)
    Application.put_env(:my_app, :payment_gateway, PaymentGatewayMock)
    """
  end

  def show_mox_usage do
    """
    # Using Mox in tests:
    defmodule OrderServiceTest do
      use ExUnit.Case, async: true
      import Mox

      # Verify mocks are called
      setup :verify_on_exit!

      test "successful order payment" do
        # Setup mock expectations
        expect(PaymentGatewayMock, :charge_card, fn amount, card ->
          assert amount == Money.new(:USD, 2000)  # $20.00
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
          Process.sleep(5000)  # Simulate timeout
          {:error, :timeout}
        end)

        order = %Order{total: Money.new(:USD, 2000)}
        card = %{token: "tok_123", last_four: "4242"}

        assert {:error, :payment_timeout} = OrderService.process_payment(order, card)
      end
    end
    """
  end
end

IO.puts("Mox setup and usage:")
IO.puts(DayTwo.MoxExamples.show_mox_setup())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – HTTP mocking with Bypass")

defmodule DayTwo.BypassExamples do
  @moduledoc """
  Using Bypass to mock HTTP services at the network level.
  """

  def show_bypass_setup do
    """
    # Add Bypass to dependencies:
    {:bypass, "~> 2.1", only: :test}

    # HTTP client module:
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

    # Test with Bypass:
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
          Process.sleep(2000)  # Simulate slow response
          Plug.Conn.resp(conn, 200, "{}")
        end)

        assert {:error, _} = WeatherAPI.get_current_weather("London")
      end
    end
    """
  end

  def show_advanced_bypass_patterns do
    """
    # Advanced Bypass patterns:
    defmodule APIIntegrationTest do
      use ExUnit.Case

      test "multiple API calls in sequence", %{bypass: bypass} do
        # Expect multiple calls in order
        Bypass.expect(bypass, "POST", "/auth", fn conn ->
          Plug.Conn.resp(conn, 200, ~s({"token": "abc123"}))
        end)

        Bypass.expect(bypass, "GET", "/users", fn conn ->
          # Verify auth header
          assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer abc123"]
          Plug.Conn.resp(conn, 200, ~s([{"id": 1, "name": "Alice"}]))
        end)

        # Test the full flow
        {:ok, token} = AuthAPI.authenticate("user", "pass")
        {:ok, users} = UserAPI.list_users(token)

        assert token == "abc123"
        assert length(users) == 1
      end

      test "API rate limiting", %{bypass: bypass} do
        call_count = Agent.start_link(fn -> 0 end)

        Bypass.expect(bypass, "GET", "/api/data", fn conn ->
          current = Agent.get_and_update(call_count, &{&1, &1 + 1})

          if current >= 3 do
            Plug.Conn.resp(conn, 429, ~s({"error": "rate limit exceeded"}))
          else
            Plug.Conn.resp(conn, 200, ~s({"data": "success"}))
          end
        end)

        # First 3 calls succeed
        assert {:ok, _} = API.get_data()
        assert {:ok, _} = API.get_data()
        assert {:ok, _} = API.get_data()

        # 4th call hits rate limit
        assert {:error, :rate_limited} = API.get_data()
      end
    end
    """
  end
end

IO.puts("Bypass HTTP mocking:")
IO.puts(DayTwo.BypassExamples.show_bypass_setup())

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

"""
🔑 ANSWERS & EXPLANATIONS

# 1. Social media posting service tests
defmodule SocialMediaServiceTest do
  use ExUnit.Case
  import Mox

  setup :verify_on_exit!

  test "posts to all platforms successfully" do
    post_content = %{text: "Hello world!", image_url: "http://example.com/image.jpg"}

    expect(TwitterAPIMock, :create_tweet, fn content ->
      assert content.text == "Hello world!"
      {:ok, %{id: "tweet_123", url: "https://twitter.com/status/123"}}
    end)

    expect(FacebookAPIMock, :create_post, fn content ->
      assert content.message == "Hello world!"
      {:ok, %{id: "post_456", url: "https://facebook.com/posts/456"}}
    end)

    expect(LinkedInAPIMock, :share_content, fn content ->
      assert content.text == "Hello world!"
      {:ok, %{id: "share_789", url: "https://linkedin.com/feed/update/789"}}
    end)

    result = SocialMediaService.post_to_all(post_content, [:twitter, :facebook, :linkedin])

    assert {:ok, posts} = result
    assert length(posts) == 3
    assert Enum.all?(posts, fn {platform, {:ok, _}} -> platform in [:twitter, :facebook, :linkedin] end)
  end

  test "handles partial failures gracefully" do
    expect(TwitterAPIMock, :create_tweet, fn _ -> {:ok, %{id: "tweet_123"}} end)
    expect(FacebookAPIMock, :create_post, fn _ -> {:error, :rate_limited} end)
    expect(LinkedInAPIMock, :share_content, fn _ -> {:ok, %{id: "share_789"}} end)

    result = SocialMediaService.post_to_all(%{text: "Test"}, [:twitter, :facebook, :linkedin])

    assert {:partial_success, results} = result
    assert results[:twitter] == {:ok, %{id: "tweet_123"}}
    assert results[:facebook] == {:error, :rate_limited}
    assert results[:linkedin] == {:ok, %{id: "share_789"}}
  end
end

# 2. File storage service with Bypass
defmodule FileStorageServiceTest do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    Application.put_env(:my_app, :s3_endpoint, "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass}
  end

  test "uploads file successfully", %{bypass: bypass} do
    Bypass.expect_once(bypass, "PUT", "/bucket/file.jpg", fn conn ->
      assert Plug.Conn.get_req_header(conn, "content-type") == ["image/jpeg"]
      Plug.Conn.resp(conn, 200, ~s({"ETag": "abc123"}))
    end)

    file_data = %{name: "file.jpg", content: <<binary_data>>, content_type: "image/jpeg"}

    assert {:ok, result} = FileStorageService.upload(file_data)
    assert result.etag == "abc123"
    assert result.url =~ "file.jpg"
  end

  test "handles upload failures with retry", %{bypass: bypass} do
    # First attempt fails
    Bypass.expect(bypass, "PUT", "/bucket/file.jpg", fn conn ->
      Plug.Conn.resp(conn, 500, "Internal Server Error")
    end)

    # Second attempt succeeds
    Bypass.expect(bypass, "PUT", "/bucket/file.jpg", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"ETag": "abc123"}))
    end)

    file_data = %{name: "file.jpg", content: <<data>>, content_type: "image/jpeg"}

    assert {:ok, result} = FileStorageService.upload(file_data, retry: true)
    assert result.etag == "abc123"
  end
end

# 3. Multi-step payment flow testing
defmodule PaymentFlowTest do
  use ExUnit.Case
  import Mox

  test "complete payment flow with webhook confirmation" do
    # Mock payment gateway
    expect(PaymentGatewayMock, :create_payment_intent, fn amount, metadata ->
      {:ok, %{id: "pi_123", status: "requires_confirmation", client_secret: "secret_123"}}
    end)

    expect(PaymentGatewayMock, :confirm_payment, fn payment_intent_id, payment_method ->
      {:ok, %{id: "pi_123", status: "succeeded", charge_id: "ch_456"}}
    end)

    # Start payment flow
    order = %{id: 1, total: Money.new(:USD, 2000)}
    {:ok, intent} = PaymentFlow.create_intent(order)

    # Confirm payment
    {:ok, payment} = PaymentFlow.confirm_payment(intent.id, %{type: "card", token: "tok_123"})

    # Simulate webhook
    webhook_payload = %{
      type: "payment_intent.succeeded",
      data: %{object: %{id: "pi_123", status: "succeeded"}}
    }

    assert :ok = PaymentFlow.handle_webhook(webhook_payload)

    # Verify order is marked as paid
    updated_order = Orders.get(order.id)
    assert updated_order.status == :paid
    assert updated_order.payment_id == "pi_123"
  end
end

# Benefits: Comprehensive coverage, fast execution, reliable testing environment
"""
