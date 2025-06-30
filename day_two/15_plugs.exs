# Day 2 – Introduction to Phoenix Plugs
#
# This script can be run with:
#     mix run day_two/15_plugs.exs
# or inside IEx with:
#     iex -r day_two/15_plugs.exs
#
# Plugs are the fundamental building blocks of Phoenix applications. They transform
# HTTP connections through composable functions, enabling everything from authentication
# to logging in a standardized way.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Understanding the Plug contract")

defmodule DayTwo.PlugBasics do
  @moduledoc """
  Understanding the fundamental plug patterns and contracts.
  """

  def explain_plug_contract do
    """
    The Plug Contract:

    Every plug follows the same simple contract:
    • Receives a %Plug.Conn{} struct and options
    • Returns a %Plug.Conn{} struct (potentially modified)
    • May halt the connection to stop further processing

    Two Types of Plugs:
    • Function Plugs: Simple functions that transform connections
    • Module Plugs: Modules with init/1 and call/2 functions

    Key Connection Operations:
    • assign(conn, key, value) - Store request-scoped data
    • put_resp_header(conn, name, value) - Add response headers
    • put_status(conn, status) - Set HTTP status code
    • halt(conn) - Stop the plug pipeline
    """
  end

  def show_connection_structure do
    # Create a mock connection to demonstrate structure
    mock_conn = %{
      method: "GET",
      path_info: ["api", "users"],
      assigns: %{},
      req_headers: [{"accept", "application/json"}],
      resp_headers: [],
      status: nil,
      halted: false
    }

    IO.puts("Example connection structure:")
    IO.puts("Method: #{mock_conn.method}")
    IO.puts("Path: /#{Enum.join(mock_conn.path_info, "/")}")
    IO.puts("Assigns: #{inspect(mock_conn.assigns)}")
    IO.puts("Request Headers: #{inspect(mock_conn.req_headers)}")
    IO.puts("Halted: #{mock_conn.halted}")
  end
end

IO.puts("Plug contract explanation:")
IO.puts(DayTwo.PlugBasics.explain_plug_contract())
DayTwo.PlugBasics.show_connection_structure()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Function plugs in action")

defmodule DayTwo.FunctionPlugs do
  @moduledoc """
  Examples of function plugs that transform connections.
  """

  # Simple function plug that adds a request ID
  def add_request_id(conn, _opts) do
    request_id = generate_request_id()

    conn
    |> assign(:request_id, request_id)
    |> put_resp_header("x-request-id", request_id)
  end

  # Function plug that logs request information
  def log_request(conn, _opts) do
    IO.puts("Processing #{conn.method} #{conn.request_path}")
    conn
  end

  # Function plug that adds CORS headers
  def add_cors_headers(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization")
  end

  # Simulate connection operations (these would normally be from Plug.Conn)
  defp assign(conn, key, value) do
    Map.update(conn, :assigns, %{key => value}, fn assigns ->
      Map.put(assigns, key, value)
    end)
  end

  defp put_resp_header(conn, name, value) do
    Map.update(conn, :resp_headers, [{name, value}], fn headers ->
      [{name, value} | headers]
    end)
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end

# Demonstrate function plugs with a mock connection
mock_conn = %{
  method: "GET",
  request_path: "/api/users",
  assigns: %{},
  resp_headers: []
}

IO.puts("Original connection assigns: #{inspect(mock_conn.assigns)}")
updated_conn = DayTwo.FunctionPlugs.add_request_id(mock_conn, [])
IO.puts("After add_request_id: #{inspect(updated_conn.assigns)}")
IO.puts("Response headers: #{inspect(updated_conn.resp_headers)}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Module plugs with configuration")

defmodule DayTwo.RateLimitPlug do
  @moduledoc """
  Example module plug that demonstrates init/1 and call/2 pattern.
  """

  # Called at compile time to process options
  def init(opts) do
    limit = Keyword.get(opts, :limit, 100)
    window = Keyword.get(opts, :window, 60)

    %{limit: limit, window: window}
  end

  # Called at runtime for each request
  def call(conn, %{limit: limit, window: window}) do
    # In a real implementation, this would check a rate limiting store
    # For demo purposes, we'll just add the limits to assigns
    conn
    |> assign(:rate_limit, limit)
    |> assign(:rate_window, window)
  end

  # Simulate assign function
  defp assign(conn, key, value) do
    Map.update(conn, :assigns, %{key => value}, fn assigns ->
      Map.put(assigns, key, value)
    end)
  end
end

defmodule DayTwo.AuthenticationPlug do
  @moduledoc """
  Example authentication plug that can halt the connection.
  """

  def init(opts) do
    required_role = Keyword.get(opts, :role, :user)
    %{required_role: required_role}
  end

  def call(conn, %{required_role: required_role}) do
    case get_current_user(conn) do
      %{role: user_role} when user_role == required_role ->
        assign(conn, :authenticated, true)

      %{role: user_role} ->
        conn
        |> assign(:error, "Insufficient permissions. Required: #{required_role}, has: #{user_role}")
        |> put_status(403)
        |> halt()

      nil ->
        conn
        |> assign(:error, "Authentication required")
        |> put_status(401)
        |> halt()
    end
  end

  # Mock user lookup (would normally check session/token)
  defp get_current_user(conn) do
    case Map.get(conn.assigns, :current_user) do
      nil -> nil
      user -> user
    end
  end

  # Simulate connection operations
  defp assign(conn, key, value) do
    Map.update(conn, :assigns, %{key => value}, fn assigns ->
      Map.put(assigns, key, value)
    end)
  end

  defp put_status(conn, status) do
    Map.put(conn, :status, status)
  end

  defp halt(conn) do
    Map.put(conn, :halted, true)
  end
end

# Demonstrate module plugs
opts = DayTwo.RateLimitPlug.init(limit: 50, window: 30)
IO.puts("Rate limit options: #{inspect(opts)}")

conn_with_rate_limit = DayTwo.RateLimitPlug.call(mock_conn, opts)
IO.puts("After rate limit plug: #{inspect(conn_with_rate_limit.assigns)}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Plug pipelines and composition")

defmodule DayTwo.PlugPipeline do
  @moduledoc """
  Demonstrates how plugs compose together in a pipeline.
  """

  def process_request(conn) do
    conn
    |> DayTwo.FunctionPlugs.add_request_id([])
    |> DayTwo.FunctionPlugs.log_request([])
    |> DayTwo.FunctionPlugs.add_cors_headers([])
    |> add_processing_time()
  end

  defp add_processing_time(conn) do
    assign(conn, :start_time, System.monotonic_time(:millisecond))
  end

  # Simulate assign function
  defp assign(conn, key, value) do
    Map.update(conn, :assigns, %{key => value}, fn assigns ->
      Map.put(assigns, key, value)
    end)
  end
end

# Demonstrate pipeline
final_conn = DayTwo.PlugPipeline.process_request(mock_conn)
IO.puts("Final connection assigns: #{inspect(final_conn.assigns)}")
IO.puts("Final response headers: #{inspect(final_conn.resp_headers)}")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world plug patterns")

defmodule DayTwo.RealWorldPlugs do
  @moduledoc """
  Common patterns seen in production Phoenix applications.
  """

  # API versioning plug
  def extract_api_version(conn, _opts) do
    version =
      conn
      |> get_req_header("accept")
      |> extract_version_from_header()

    assign(conn, :api_version, version)
  end

  # Tenant resolution plug
  def resolve_tenant(conn, _opts) do
    tenant =
      conn
      |> get_req_header("x-tenant-id")
      |> List.first()
      |> resolve_tenant_from_id()

    assign(conn, :current_tenant, tenant)
  end

  # Performance monitoring plug
  def start_performance_timer(conn, _opts) do
    assign(conn, :request_start_time, System.monotonic_time(:microsecond))
  end

  # Mock helper functions
  defp get_req_header(conn, header_name) do
    conn.req_headers
    |> Enum.filter(fn {name, _value} -> name == header_name end)
    |> Enum.map(fn {_name, value} -> value end)
  end

  defp extract_version_from_header([]), do: "v1"
  defp extract_version_from_header([header | _]) do
    case Regex.run(~r/application\/vnd\.api\.v(\d+)\+json/, header) do
      [_full, version] -> "v#{version}"
      nil -> "v1"
    end
  end

  defp resolve_tenant_from_id(nil), do: nil
  defp resolve_tenant_from_id(tenant_id) do
    # Would normally look up in database
    %{id: tenant_id, name: "Tenant #{tenant_id}"}
  end

  defp assign(conn, key, value) do
    Map.update(conn, :assigns, %{key => value}, fn assigns ->
      Map.put(assigns, key, value)
    end)
  end
end

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISE
#
# Run the test with: mix test day_two/15_plugs.exs
# ────────────────────────────────────────────────────────────────

defmodule DayTwo.PlugExercise do
  @moduledoc """
  Single exercise for learning plug fundamentals.
  """

  @doc """
  Create a function plug that enriches a connection with user context information.

  Given a connection, add the following key/value pairs to conn.assigns:
  - :user_agent - Extract from request headers (default to "unknown" if not found)
  - :request_timestamp - Current timestamp using DateTime.utc_now()
  - :request_method - The HTTP method from conn.method
  - :is_authenticated - Set to false for now (placeholder)

  Return the modified connection.
  """
  def enrich_connection(conn, _opts) do
    # TODO: Implement this function
    # 1. Extract user agent from request headers
    # 2. Add :user_agent, :request_timestamp, :request_method, :is_authenticated to assigns
    # 3. Return the modified connection

    conn  # Placeholder - replace with your implementation
  end

  # Helper function to simulate assign (normally from Plug.Conn)
  defp assign(conn, key, value) do
    Map.update(conn, :assigns, %{key => value}, fn assigns ->
      Map.put(assigns, key, value)
    end)
  end
end

ExUnit.start()

defmodule DayTwo.PlugExerciseTest do
  use ExUnit.Case, async: true

  alias DayTwo.PlugExercise

  test "enrich_connection adds all required fields to assigns" do
    # Create a mock connection
    conn = %{
      method: "POST",
      assigns: %{},
      req_headers: [{"user-agent", "TestBrowser/1.0"}, {"accept", "application/json"}]
    }

    # Call the function
    result = PlugExercise.enrich_connection(conn, [])

    # Verify all required assigns are present
    assert result.assigns[:user_agent] == "TestBrowser/1.0"
    assert result.assigns[:request_method] == "POST"
    assert result.assigns[:is_authenticated] == false
    assert %DateTime{} = result.assigns[:request_timestamp]
  end

  test "enrich_connection handles missing user-agent header" do
    conn = %{
      method: "GET",
      assigns: %{},
      req_headers: [{"accept", "application/json"}]
    }

    result = PlugExercise.enrich_connection(conn, [])

    assert result.assigns[:user_agent] == "unknown"
    assert result.assigns[:request_method] == "GET"
    assert result.assigns[:is_authenticated] == false
  end

  test "enrich_connection preserves existing assigns" do
    conn = %{
      method: "PUT",
      assigns: %{existing_key: "existing_value"},
      req_headers: [{"user-agent", "Mobile/2.0"}]
    }

    result = PlugExercise.enrich_connection(conn, [])

    # Should preserve existing assigns
    assert result.assigns[:existing_key] == "existing_value"

    # Should add new assigns
    assert result.assigns[:user_agent] == "Mobile/2.0"
    assert result.assigns[:request_method] == "PUT"
  end
end

IO.puts("""


PLUG CONCEPTS SUMMARY
=====================

Key Patterns:
• Connection Transformation: Every plug receives and returns a %Plug.Conn{}
• Function Plugs: Simple functions for stateless transformations
• Module Plugs: Two-function modules (init/1, call/2) for configurable behavior
• Pipeline Composition: Chain plugs together for complex request processing
• Early Termination: Use halt(conn) to stop pipeline execution

Common Use Cases:
• Authentication and authorization
• Request logging and monitoring
• CORS and security headers
• API versioning and content negotiation
• Rate limiting and throttling
• Tenant resolution in multi-tenant apps

Plug Benefits:
• Composable and reusable request processing
• Clean separation of concerns
• Easy testing of individual transformations
• Consistent interface across the Phoenix ecosystem
• Performance through compile-time optimization

Remember: Plugs are the building blocks of Phoenix applications.
Master them to build robust, maintainable web applications.
""")

# ────────────────────────────────────────────────────────────────
# 📚 EXERCISE ANSWER
# ────────────────────────────────────────────────────────────────

defmodule DayTwo.PlugAnswer do
  @moduledoc """
  Complete solution for the plug exercise.
  """

  def answer_one do
    """
    # Complete implementation of enrich_connection/2

    def enrich_connection(conn, _opts) do
      # Extract user agent from request headers
      user_agent =
        conn.req_headers
        |> Enum.find(fn {name, _value} -> name == "user-agent" end)
        |> case do
          {_name, value} -> value
          nil -> "unknown"
        end

      # Add all required assigns
      conn
      |> assign(:user_agent, user_agent)
      |> assign(:request_timestamp, DateTime.utc_now())
      |> assign(:request_method, conn.method)
      |> assign(:is_authenticated, false)
    end

    # Helper function to add key/value pairs to assigns
    defp assign(conn, key, value) do
      Map.update(conn, :assigns, %{key => value}, fn assigns ->
        Map.put(assigns, key, value)
      end)
    end

    Key Concepts Demonstrated:
    • Pattern matching on request headers to extract data
    • Using pipe operator to chain assign operations
    • Handling missing headers with default values
    • Building up the assigns map incrementally
    • Returning the modified connection struct
    """
  end
end
