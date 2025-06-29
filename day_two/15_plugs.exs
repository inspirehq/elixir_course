# Day 2 – Introduction to Phoenix Plugs
#
# This script can be run with:
#     mix run day_two/15_plugs.exs
# or inside IEx with:
#     iex -r day_two/15_plugs.exs
#
# Plugs are the building blocks of Phoenix applications. They provide a simple
# way to compose web applications by defining small, reusable functions that
# transform HTTP connections. Every Phoenix controller action is a plug!
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Understanding the Plug specification")

defmodule DayTwo.PlugBasics do
  @moduledoc """
  Understanding the fundamental concepts of Plugs in Phoenix.
  """

  def explain_plug_specification do
    """
    The Plug Specification:

    1. A plug is a function that receives a connection (conn) and returns a connection
    2. Function signature: plug(conn, opts) -> conn
    3. The connection (%Plug.Conn{}) contains all HTTP request/response data
    4. Plugs can be composed together to build request processing pipelines
    5. Each plug can transform the connection and pass it to the next plug

    Two types of Plugs:
    • Function Plugs: Simple functions that take conn and opts
    • Module Plugs: Modules implementing init/1 and call/2 callbacks

    Basic Structure:
    def my_plug(conn, _opts) do
      # Transform the connection
      conn
      |> put_resp_header("x-custom", "value")
      |> assign(:processed_by, :my_plug)
    end
    """
  end

  def show_conn_structure do
    """
    %Plug.Conn{} key fields:
    • method: "GET", "POST", etc.
    • request_path: "/users/123"
    • params: %{"id" => "123"}
    • query_params: %{"filter" => "active"}
    • req_headers: [{"content-type", "application/json"}]
    • resp_headers: [{"x-frame-options", "DENY"}]
    • status: 200, 404, 500, etc.
    • resp_body: Response content
    • assigns: %{} - Storage for request-scoped data
    • halted: false - Whether to stop processing
    """
  end
end

IO.puts("Plug specification:")
IO.puts(DayTwo.PlugBasics.explain_plug_specification())

IO.puts("\nConnection structure:")
IO.puts(DayTwo.PlugBasics.show_conn_structure())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Function plugs in action")

defmodule DayTwo.FunctionPlugs do
  import Plug.Conn

  @doc """
  A simple function plug that adds a timestamp to the connection
  """
  def add_timestamp(conn, _opts) do
    assign(conn, :request_timestamp, DateTime.utc_now())
  end

  @doc """
  A function plug that logs basic request information
  """
  def log_request(conn, _opts) do
    IO.puts("#{conn.method} #{conn.request_path} from #{get_peer_ip(conn)}")
    conn
  end

  @doc """
  A function plug that adds CORS headers
  """
  def add_cors_headers(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization")
  end

  @doc """
  A function plug that requires authentication
  """
  def require_auth(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token != "" ->
        assign(conn, :current_user, %{id: 1, token: token})
      _ ->
        conn
        |> put_status(401)
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized"}))
        |> halt()
    end
  end

  # Helper function to extract peer IP
  defp get_peer_ip(conn) do
    case Map.get(conn, :peer) do
      {ip, _port} -> ip |> Tuple.to_list() |> Enum.join(".")
      _ -> "127.0.0.1"  # Default for test connections
    end
  end

      def demonstrate_function_plugs do
    # Create a test connection using Plug.Test helpers
    IO.puts("\nDemonstrating function plugs:")

    try do
      conn = Plug.Test.conn(:get, "/api/users")
             |> Plug.Conn.put_req_header("authorization", "Bearer abc123")

      result = conn
               |> add_timestamp([])
               |> log_request([])
               |> add_cors_headers([])

      IO.puts("✅ Timestamp assigned: #{result.assigns[:request_timestamp]}")
      IO.puts("✅ CORS headers added: #{length(result.resp_headers)} headers")
    rescue
      error ->
        IO.puts("📝 Demo note: #{inspect(error)}")
        IO.puts("💡 In a real Phoenix app, these plugs would work with actual connections")
        IO.puts("   The important concepts are:")
        IO.puts("   • Plugs transform connections")
        IO.puts("   • Data flows through the pipeline")
        IO.puts("   • Each plug can modify conn.assigns and headers")
    end
  end
end

DayTwo.FunctionPlugs.demonstrate_function_plugs()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Module plugs with init/1 and call/2")

defmodule DayTwo.AuthPlug do
  @moduledoc """
  A module plug that handles authentication with configurable options
  """

  import Plug.Conn

  def init(opts) do
    # Process options at compile time
    %{
      realm: Keyword.get(opts, :realm, "Protected Area"),
      required_role: Keyword.get(opts, :required_role, nil)
    }
  end

  def call(conn, opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        verify_token(conn, token, opts)
      _ ->
        unauthorized(conn, opts.realm)
    end
  end

  defp verify_token(conn, token, opts) do
    # Mock token verification
    case token do
      "admin_token" ->
        user = %{id: 1, role: :admin, name: "Admin User"}
        authorize_user(conn, user, opts)
      "user_token" ->
        user = %{id: 2, role: :user, name: "Regular User"}
        authorize_user(conn, user, opts)
      _ ->
        unauthorized(conn, opts.realm)
    end
  end

  defp authorize_user(conn, user, opts) do
    case opts.required_role do
      nil ->
        assign(conn, :current_user, user)
      required_role when user.role == required_role ->
        assign(conn, :current_user, user)
      _ ->
        forbidden(conn)
    end
  end

  defp unauthorized(conn, realm) do
    conn
    |> put_status(401)
    |> put_resp_header("www-authenticate", "Bearer realm=\"#{realm}\"")
    |> send_resp(401, Jason.encode!(%{error: "Authentication required"}))
    |> halt()
  end

  defp forbidden(conn) do
    conn
    |> put_status(403)
    |> send_resp(403, Jason.encode!(%{error: "Insufficient permissions"}))
    |> halt()
  end
end

defmodule DayTwo.RateLimitPlug do
  @moduledoc """
  A module plug that implements basic rate limiting
  """

  import Plug.Conn

  def init(opts) do
    %{
      max_requests: Keyword.get(opts, :max_requests, 100),
      window_seconds: Keyword.get(opts, :window_seconds, 3600),
      storage: Keyword.get(opts, :storage, :ets)
    }
  end

  def call(conn, opts) do
    client_ip = get_client_ip(conn)

    case check_rate_limit(client_ip, opts) do
      :ok ->
        conn
      {:exceeded, retry_after} ->
        conn
        |> put_status(429)
        |> put_resp_header("retry-after", Integer.to_string(retry_after))
        |> send_resp(429, Jason.encode!(%{error: "Rate limit exceeded"}))
        |> halt()
    end
  end

  defp get_client_ip(conn) do
    case Map.get(conn, :peer) do
      {ip, _port} -> ip |> Tuple.to_list() |> Enum.join(".")
      _ -> "127.0.0.1"  # Default for test connections
    end
  end

  defp check_rate_limit(ip, opts) do
    # Mock implementation for educational purposes
    # In a real app, this would check against a rate limiting store (Redis, ETS, etc.)

    # Simulate rate limiting: block "blocked_ip" for demo purposes
    case ip do
      "blocked_ip" ->
        {:exceeded, opts.window_seconds}
      _ ->
        :ok
    end
  end
end

# Demonstrate the module plugs
defmodule DayTwo.ModulePlugDemo do
  def demonstrate_auth_plug do
    IO.puts("\nDemonstrating authentication plug:")

    try do
      # Test successful authentication
      conn1 = Plug.Test.conn(:get, "/api/protected")
              |> Plug.Conn.put_req_header("authorization", "Bearer user_token")

      result1 = DayTwo.AuthPlug.call(conn1, DayTwo.AuthPlug.init([]))
      IO.puts("✅ Auth success: User #{result1.assigns.current_user.name} authenticated")

      # Test failed authentication
      conn2 = Plug.Test.conn(:get, "/api/protected")
      result2 = DayTwo.AuthPlug.call(conn2, DayTwo.AuthPlug.init(realm: "API"))
      IO.puts("✅ Auth failure: Status #{result2.status}, halted: #{result2.halted}")

    rescue
      error ->
        IO.puts("📝 Demo note: #{inspect(error)}")
        IO.puts("💡 Module plugs provide configurable authentication logic")
    end
  end

  def demonstrate_rate_limit_plug do
    IO.puts("\nDemonstrating rate limiting plug:")

    try do
      # Test normal request - should pass
      conn1 = Plug.Test.conn(:get, "/api/data")
      result1 = DayTwo.RateLimitPlug.call(conn1, DayTwo.RateLimitPlug.init([]))
      IO.puts("✅ Normal request: Passed rate limiting")

      # Test blocked IP - would be rate limited in real scenario
      IO.puts("✅ Rate limiting logic: Configured with max_requests: 100, window: 3600s")

    rescue
      error ->
        IO.puts("📝 Demo note: #{inspect(error)}")
        IO.puts("💡 Rate limiting protects APIs from abuse")
    end
  end
end

DayTwo.ModulePlugDemo.demonstrate_auth_plug()
DayTwo.ModulePlugDemo.demonstrate_rate_limit_plug()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Composing plugs in a pipeline")

defmodule DayTwo.PlugPipeline do
  @moduledoc """
  Demonstrates how plugs compose together to form processing pipelines
  """

  import Plug.Conn

  # Function plugs
  def log_start(conn, _opts) do
    IO.puts("🚀 Processing #{conn.method} #{conn.request_path}")
    assign(conn, :start_time, System.monotonic_time())
  end

  def add_security_headers(conn, _opts) do
    conn
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-xss-protection", "1; mode=block")
  end

  def log_end(conn, _opts) do
    start_time = conn.assigns[:start_time]
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)

    IO.puts("✅ Completed in #{duration_ms}ms with status #{conn.status || "pending"}")
    conn
  end

  def demonstrate_pipeline do
    IO.puts("\nProcessing through plug pipeline:")

    try do
      # Create a test connection using Plug.Test helpers
      conn = Plug.Test.conn(:post, "/api/posts")
             |> Plug.Conn.put_req_header("authorization", "Bearer user_token")

      # Simulate a typical Phoenix pipeline
      result = conn
               |> log_start([])
               |> add_security_headers([])
               |> DayTwo.AuthPlug.call(DayTwo.AuthPlug.init([]))
               |> DayTwo.RateLimitPlug.call(DayTwo.RateLimitPlug.init(max_requests: 50))
               |> process_request()
               |> log_end([])

      IO.puts("✅ Final assigns: #{inspect(result.assigns)}")
      IO.puts("✅ Response headers count: #{length(result.resp_headers)}")
    rescue
      error ->
        IO.puts("📝 Demo note: #{inspect(error)}")
        IO.puts("💡 This demonstrates a complete plug pipeline:")
        IO.puts("   Request → Logging → Security → Auth → Rate Limit → Processing → Logging")
        IO.puts("   Each plug transforms the connection and passes it to the next plug")
    end
  end

  defp process_request(conn) do
    # Mock processing - just set a status
    put_status(conn, 201)
  end
end

DayTwo.PlugPipeline.demonstrate_pipeline()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world plug examples")

defmodule DayTwo.RealWorldPlugs do
  @moduledoc """
  Real-world plug patterns commonly used in Phoenix applications
  """

  def show_common_plug_patterns do
    """
    Common Phoenix Plug Patterns:

    1. ENDPOINT PLUGS (apply to all requests):
       • Plug.RequestId - Adds request ID for tracing
       • Plug.Logger - Logs requests and responses
       • Plug.Static - Serves static files
       • Plug.Parsers - Parses request bodies

    2. ROUTER PLUGS (apply to specific routes):
       • Phoenix.Controller.Pipeline - Sets up controller context
       • Plug.CSRF - CSRF protection
       • Custom authentication plugs

    3. CONTROLLER PLUGS (apply to controller actions):
       • Phoenix.Controller.put_layout/2
       • Custom authorization plugs
       • Data loading plugs

    4. CUSTOM BUSINESS LOGIC:
       • Tenant resolution
       • Feature flagging
       • Metrics collection
       • Request transformation
    """
  end

  def show_phoenix_integration do
    """
    How Plugs integrate with Phoenix:

    # In your endpoint (endpoint.ex):
    plug Plug.RequestId
    plug Plug.Logger
    plug MyApp.CustomPlug

    # In your router (router.ex):
    pipeline :api do
      plug :accepts, ["json"]
      plug MyApp.AuthPlug
      plug MyApp.RateLimitPlug
    end

    # In your controller:
    defmodule MyAppWeb.UserController do
      use MyAppWeb, :controller

      plug MyApp.LoadUserPlug when action in [:show, :update, :delete]
      plug MyApp.RequireAdminPlug when action in [:delete]

      def show(conn, _params) do
        # conn.assigns.current_user is available from plugs
        render(conn, "show.json", user: conn.assigns.current_user)
      end
    end
    """
  end
end

IO.puts("Common plug patterns:")
IO.puts(DayTwo.RealWorldPlugs.show_common_plug_patterns())

IO.puts("\nPhoenix integration:")
IO.puts(DayTwo.RealWorldPlugs.show_phoenix_integration())

defmodule DayTwo.PlugExercises do
  @moduledoc """
  Run the tests with: mix test day_two/15_plugs.exs
  or in IEx:
  iex -r day_two/15_plugs.exs
  DayTwo.PlugExercisesTest.test_request_timer/0
  DayTwo.PlugExercisesTest.test_api_version_plug/0
  DayTwo.PlugExercisesTest.test_tenant_resolver/0
  """

  @spec build_request_timer() :: {function(), function()}
  def build_request_timer do
    #   Create two function plugs: start_timer/2 and end_timer/2.
    #   start_timer should store the current time in assigns.
    #   end_timer should calculate duration and add it to response headers.
    #   Return {start_timer_function, end_timer_function}
    {nil, nil}  # TODO: Implement request timing plugs
  end

  @spec build_api_version_plug() :: module()
  def build_api_version_plug do
    #   Create a module plug that extracts API version from:
    #   1. "X-API-Version" header
    #   2. "version" query parameter
    #   3. Defaults to "v1"
    #   Store the version in conn.assigns.api_version
    #   Return the module name
    nil  # TODO: Implement API version extraction plug
  end

  @spec build_tenant_resolver() :: module()
  def build_tenant_resolver do
    #   Create a module plug that resolves tenant from subdomain.
    #   Extract tenant from "tenant.example.com" -> "tenant"
    #   Store in conn.assigns.tenant
    #   Halt with 404 if tenant not found in allowed list
    #   Return the module name
    nil  # TODO: Implement tenant resolution plug
  end
end

# Mock implementations for testing
defmodule RequestTimer do
  import Plug.Conn

  def start_timer(conn, _opts) do
    assign(conn, :start_time, System.monotonic_time())
  end

  def end_timer(conn, _opts) do
    case conn.assigns[:start_time] do
      nil -> conn
      start_time ->
        duration = System.monotonic_time() - start_time
        duration_ms = System.convert_time_unit(duration, :native, :millisecond)
        put_resp_header(conn, "x-response-time", "#{duration_ms}ms")
    end
  end
end

defmodule ApiVersionPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    version =
      case get_req_header(conn, "x-api-version") do
        [version] -> version
        [] ->
          # Fetch params if they haven't been fetched yet
          conn = Plug.Conn.fetch_query_params(conn)
          case conn.query_params do
            %{"version" => version} -> version
            _ -> "v1"
          end
      end

    assign(conn, :api_version, version)
  end
end

defmodule TenantResolverPlug do
  import Plug.Conn

  def init(opts) do
    Keyword.get(opts, :allowed_tenants, ["acme", "demo", "test"])
  end

  def call(conn, allowed_tenants) do
    case extract_tenant(conn) do
      nil ->
        conn |> send_resp(404, "Tenant not found") |> halt()
      tenant ->
        if tenant in allowed_tenants do
          assign(conn, :tenant, tenant)
        else
          conn |> send_resp(404, "Tenant not found") |> halt()
        end
    end
  end

  defp extract_tenant(conn) do
    case get_req_header(conn, "host") do
      [host] ->
        case String.split(host, ".") do
          [tenant | _rest] when tenant not in ["www", "api"] -> tenant
          _ -> nil
        end
      _ -> nil
    end
  end
end

ExUnit.start()

defmodule DayTwo.PlugExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.PlugExercises, as: EX

  test "build_request_timer/0 creates timing plugs" do
    {start_fn, end_fn} = EX.build_request_timer()
    assert is_function(start_fn, 2)
    assert is_function(end_fn, 2)
  end

  test "build_api_version_plug/0 creates version extraction plug" do
    module = EX.build_api_version_plug()
    assert is_atom(module)
    assert function_exported?(module, :init, 1)
    assert function_exported?(module, :call, 2)
  end

  test "build_tenant_resolver/0 creates tenant resolution plug" do
    module = EX.build_tenant_resolver()
    assert is_atom(module)
    assert function_exported?(module, :init, 1)
    assert function_exported?(module, :call, 2)
  end

    test "RequestTimer plugs work correctly" do
    import Plug.Conn

    conn = Plug.Test.conn(:get, "/")

    # Start timer
    conn_with_timer = RequestTimer.start_timer(conn, [])
    assert Map.has_key?(conn_with_timer.assigns, :start_time)

    # End timer (after small delay)
    Process.sleep(1)
    final_conn = RequestTimer.end_timer(conn_with_timer, [])

    # Should have response time header
    time_headers = get_resp_header(final_conn, "x-response-time")
    assert length(time_headers) == 1
    assert String.ends_with?(hd(time_headers), "ms")
  end

    test "ApiVersionPlug extracts version correctly" do
    import Plug.Conn

    # Test header version
    conn = Plug.Test.conn(:get, "/")
           |> put_req_header("x-api-version", "v2")
    result = ApiVersionPlug.call(conn, [])
    assert result.assigns.api_version == "v2"

    # Test query parameter version
    conn2 = Plug.Test.conn(:get, "/?version=v3")
    result2 = ApiVersionPlug.call(conn2, [])
    assert result2.assigns.api_version == "v3"

    # Test default version
    conn3 = Plug.Test.conn(:get, "/")
    result3 = ApiVersionPlug.call(conn3, [])
    assert result3.assigns.api_version == "v1"
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. build_request_timer/0
def build_request_timer do
  start_timer = fn conn, _opts ->
    Plug.Conn.assign(conn, :start_time, System.monotonic_time())
  end

  end_timer = fn conn, _opts ->
    case conn.assigns[:start_time] do
      nil -> conn
      start_time ->
        duration = System.monotonic_time() - start_time
        duration_ms = System.convert_time_unit(duration, :native, :millisecond)
        Plug.Conn.put_resp_header(conn, "x-response-time", "\#{duration_ms}ms")
    end
  end

  {start_timer, end_timer}
end
#  Function plugs are perfect for simple transformations like timing.
#  Using assigns to pass data between plugs in the same request.

# 2. build_api_version_plug/0
defmodule MyApiVersionPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    version =
      case get_req_header(conn, "x-api-version") do
        [version] -> version
        [] ->
          case conn.params["version"] do
            nil -> "v1"
            version -> version
          end
      end

    assign(conn, :api_version, version)
  end
end

{:ok, MyApiVersionPlug}
#  Module plugs are better when you need configurable behavior.
#  Always check multiple sources (headers, params) for flexibility.

# 3. build_tenant_resolver/0
defmodule MyTenantResolver do
  import Plug.Conn

  def init(opts) do
    Keyword.get(opts, :allowed_tenants, ["demo", "test"])
  end

  def call(conn, allowed_tenants) do
    case get_req_header(conn, "host") do
      [host] ->
        tenant = host |> String.split(".") |> hd()
        if tenant in allowed_tenants do
          assign(conn, :tenant, tenant)
        else
          conn |> send_resp(404, "Tenant not found") |> halt()
        end
      _ ->
        conn |> send_resp(400, "Host header required") |> halt()
    end
  end
end

{:ok, MyTenantResolver}
#  halt() stops the plug pipeline - crucial for authorization/validation plugs.
#  Multi-tenant applications commonly use subdomain-based tenant resolution.

Key Plug concepts demonstrated:
• Function vs Module plugs - when to use each
• Plug.Conn transformation patterns
• Pipeline composition and data flow
• Real-world authentication and authorization
• Performance monitoring and request timing
• Multi-tenancy and API versioning patterns
"""
