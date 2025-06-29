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

  def demonstrate_rate_limiting do
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
IO.puts("\n📌 Example 4 – Composing plugs in a router")

defmodule DayTwo.RouterComposition do
  @moduledoc """
  Demonstrating how plugs are composed in a Phoenix router.
  """

  def show_router_plugs do
    IO.puts("# Plugs in a Phoenix Router:")

    code =
      quote do
        defmodule MyAppWeb.Router do
          use MyAppWeb, :router

          pipeline :browser do
            plug :accepts, ["html"]
            plug :fetch_session
            plug :fetch_live_flash
            plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
            plug :protect_from_forgery
            plug :put_secure_browser_headers
          end

          pipeline :api do
            plug :accepts, ["json"]
            plug DayTwo.AuthPlug, realm: "API", required_role: :admin
            plug DayTwo.RateLimitPlug, max_requests: 50, window_seconds: 60
          end

          scope "/", MyAppWeb do
            pipe_through :browser
            get "/", PageController, :home
          end

          scope "/api", MyAppWeb do
            pipe_through :api
            get "/users", UserController, :index
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end

  def show_controller_plugs do
    IO.puts("# Plugs in a Phoenix Controller:")

    code =
      quote do
        defmodule MyAppWeb.PostController do
          use MyAppWeb, :controller

          plug DayTwo.AuthPlug, required_role: :editor
          plug :load_post when action in [:show, :edit, :update, :delete]
          plug :verify_ownership when action in [:edit, :update, :delete]

          def show(conn, %{"id" => id}) do
            render(conn, :show, post: conn.assigns.post)
          end

          defp load_post(conn, _opts) do
            post = Posts.get_post!(conn.params["id"])
            assign(conn, :post, post)
          end

          defp verify_ownership(conn, _opts) do
            if conn.assigns.current_user.id == conn.assigns.post.user_id do
              conn
            else
              conn |> put_status(403) |> text("Forbidden") |> halt()
            end
          end
        end
      end

    IO.puts(Macro.to_string(code))
  end
end

DayTwo.RouterComposition.show_router_plugs()
DayTwo.RouterComposition.show_controller_plugs()

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
  DayTwo.PlugExercisesTest.test_design_request_id_plug/0
  DayTwo.PlugExercisesTest.test_design_maintenance_mode_plug/0
  DayTwo.PlugExercisesTest.test_design_api_versioning_plug/0
  """

  @doc """
  Designs a function plug to add a unique request ID to every connection.

  **Goal:** Learn how to write a simple function plug that modifies the connection
  by adding a request header and assigning a value for later use.

  **Requirements:**
  - The plug should be a simple function `add_request_id(conn, _opts)`.
  - It should generate a unique ID (e.g., using `UUID.uuid4()`).
  - It must add this ID to the response headers as `"x-request-id"`.
  - It must also store the ID in the connection's `assigns` map under the
    key `:request_id`.

  **Task:**
  Return a map describing the plug's actions:
  - `:assigns_key`: The atom used as the key in `conn.assigns`.
  - `:header_name`: The string for the response header name.
  - `:implementation_hint`: A string describing the core logic, mentioning
    `put_resp_header/3` and `assign/3`.
  """
  @spec design_request_id_plug() :: map()
  def design_request_id_plug do
    # Design a function plug that adds a unique request ID.
    # Return a map with :assigns_key, :header_name, and :implementation_hint.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a module plug for enabling a site-wide "maintenance mode".

  **Goal:** Learn to write a module plug with an `init/1` function that can
  be configured, and a `call/2` function that can halt the connection pipeline.

  **Requirements:**
  - The plug should be a module `MaintenanceModePlug`.
  - The `init/1` function should accept an `:enabled` option (a boolean).
  - The `call/2` function should check if maintenance mode is enabled.
  - If it is enabled, the plug must:
    - Halt the connection using `halt/1`.
    - Set the HTTP status to 503 Service Unavailable.
    - Send a simple response body like "Down for maintenance".
  - If it is not enabled, the plug should just pass the connection through.

  **Task:**
  Return a string describing the architecture of this module plug, covering
  both the `init/1` and `call/2` functions and how they work together.
  """
  @spec design_maintenance_mode_plug() :: binary()
  def design_maintenance_mode_plug do
    # Describe the architecture of a configurable MaintenanceModePlug.
    # Cover the init/1 and call/2 functions.
    nil  # TODO: Implement this exercise
  end

  @doc """
  Designs a plug for routing requests based on an API version in the `Accept` header.

  **Goal:** Learn how to use plugs for advanced request routing by inspecting
  headers and modifying the connection to influence downstream routing.

  **Scenario:**
  Your API supports versions `v1` and `v2`. The version is specified in the
  `Accept` header, e.g., `"application/vnd.myapi.v1+json"`. The plug needs to
  parse this header and store the detected version in `conn.assigns`.

  **Task:**
  Return a map that describes the plug's design:
  - `:header_to_inspect`: The name of the request header to check.
  - `:logic`: A string describing the logic inside the plug. It should explain
    how it would parse the header and what it would do for a valid version, an
    invalid version, and a missing header.
  - `:downstream_use`: A string explaining how a Phoenix router or controller
    could use the `:api_version` value from `conn.assigns`.
  """
  @spec design_api_versioning_plug() :: map()
  def design_api_versioning_plug do
    # Design a plug for API versioning via the Accept header.
    # Return a map with :header_to_inspect, :logic, and :downstream_use.
    nil  # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.PlugExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.PlugExercises, as: EX

  test "design_request_id_plug/0 returns a valid design" do
    design = EX.design_request_id_plug()
    assert is_map(design)
    assert design.assigns_key == :request_id
    assert design.header_name == "x-request-id"
    assert String.contains?(design.implementation_hint, "assign/3")
  end

  test "design_maintenance_mode_plug/0 describes the module plug architecture" do
    description = EX.design_maintenance_mode_plug()
    assert is_binary(description)
    assert String.contains?(description, "init/1")
    assert String.contains?(description, "call/2")
    assert String.contains?(description, "halt/1")
    assert String.contains?(description, "503")
  end

  test "design_api_versioning_plug/0 returns a valid versioning design" do
    design = EX.design_api_versioning_plug()
    assert is_map(design)
    assert design.header_to_inspect == "accept"
    assert String.contains?(design.logic, "Regex.named_captures")
    assert String.contains?(design.downstream_use, "controller action")
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      %{
        assigns_key: :request_id,
        header_name: "x-request-id",
        implementation_hint: "Use UUID.uuid4() to generate an ID, then pipe the conn through `assign/3` and `put_resp_header/3`."
      }
    end
  end

  def answer_two do
    quote do
      """
      Architecture: Maintenance Mode Plug

      1.  `init/1`: This function is called once when the application compiles. It
          receives options from the router, like `plug MaintenanceModePlug, enabled: true`.
          It processes these options and returns a simplified map, e.g., `%{enabled: true}`,
          which is passed to `call/2` for every request.

      2.  `call/2`: This function is called on every request. It receives the `conn`
          and the options map from `init/1`. It uses a `cond` or `if` statement:
          - If `opts.enabled` is `true`, it immediately builds a 503 response using
            `put_status/2` and `send_resp/3`, and then calls `halt/1` to stop the
            plug pipeline completely.
          - If `opts.enabled` is `false`, it simply returns the `conn` unmodified,
            allowing the request to proceed to the next plug in the pipeline.
      """
    end
  end

  def answer_three do
    quote do
      %{
        header_to_inspect: "accept",
        logic: """
        The plug fetches the 'accept' header. It uses a regex like
        `~r/vnd.myapi.v(?<version>\\d+)\\+json/` to capture the version number.
        - If it matches, it calls `assign(conn, :api_version, version)`.
        - If it doesn't match a known version, it halts with a 400 Bad Request error.
        - If the header is missing, it defaults to the latest version.
        """,
        downstream_use: """
        A controller action can pattern match on the `conn` to dispatch to the
        correct implementation. `def show(%{assigns: %{api_version: "2"}} = conn, params) ...`
        """
      }
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. Request ID Plug
#{Macro.to_string(DayTwo.Answers.answer_one())}
# This is a classic function plug. It's great for cross-cutting concerns like
# logging, metrics, or tracing. By adding an ID to both the `assigns` and the
# response header, the ID is available for logging throughout the request and
# can also be given to the client for support or debugging purposes.

# 2. Maintenance Mode Plug
#{Macro.to_string(DayTwo.Answers.answer_two())}
# This demonstrates the power of a configurable module plug. You can turn
# maintenance mode on or off with a configuration change and application
# restart, without any code changes. Using `halt/1` is key, as it cleanly
# stops the request pipeline and prevents the request from hitting the router
# or controllers.

# 3. API Versioning Plug
#{Macro.to_string(DayTwo.Answers.answer_three())}
# This shows how a plug can be used for pre-processing and routing logic. By
# parsing the `Accept` header early in the pipeline, the plug enriches the
# `conn` with data that downstream controllers can use to make decisions. This
# keeps the versioning logic clean and separate from the core business logic
# in the controller actions.
""")
