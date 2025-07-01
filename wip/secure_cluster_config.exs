# Production Erlang Cluster Security Configuration
#
# This file demonstrates proper security configuration for production
# Erlang clusters with TLS distribution and security hardening.
#
# Use this as a template for production deployments where clustering
# is absolutely necessary and the security requirements have been
# thoroughly evaluated.

import Config

# ────────────────────────────────────────────────────────────────
# 🔐 TLS Distribution Configuration
# ────────────────────────────────────────────────────────────────

# Enable TLS for node distribution
config :kernel,
  # Use TLS instead of plain TCP
  proto_dist: :inet_tls,

  # Bind distribution to private network interface only
  # Replace with your actual private network IP
  inet_dist_use_interface: {10, 0, 1, Application.get_env(:my_app, :node_ip_last_octet, 1)},

  # Restrict distribution ports to specific range
  # This allows firewall rules to be more specific
  inet_dist_listen_min: 9100,
  inet_dist_listen_max: 9110,

  # Additional security options
  dist_auto_connect: :once,  # Don't auto-reconnect on failure
  net_ticktime: 60,          # Faster detection of dead nodes

  # TLS-specific options
  ssl_dist_opt: [
    # Server configuration (when other nodes connect to this one)
    {:server_secure_renegotiate, true},
    {:server_reuse_sessions, false},
    {:server_verify, :verify_peer},
    {:server_fail_if_no_peer_cert, true},
    {:server_depth, 1},

    # Client configuration (when connecting to other nodes)
    {:client_secure_renegotiate, true},
    {:client_reuse_sessions, false},
    {:client_verify, :verify_peer},
    {:client_depth, 1},

    # Certificate files (set via environment variables)
    {:server_certfile, System.get_env("ERLANG_TLS_CERT_FILE") ||
                      "/opt/app/certs/server.pem"},
    {:server_keyfile, System.get_env("ERLANG_TLS_KEY_FILE") ||
                     "/opt/app/certs/server.key"},
    {:server_cacertfile, System.get_env("ERLANG_TLS_CA_FILE") ||
                        "/opt/app/certs/ca.pem"},

    {:client_certfile, System.get_env("ERLANG_TLS_CERT_FILE") ||
                      "/opt/app/certs/client.pem"},
    {:client_keyfile, System.get_env("ERLANG_TLS_KEY_FILE") ||
                     "/opt/app/certs/client.key"},
    {:client_cacertfile, System.get_env("ERLANG_TLS_CA_FILE") ||
                        "/opt/app/certs/ca.pem"},

    # Cipher suite configuration (strong ciphers only)
    {:server_ciphers, [
      "ECDHE-RSA-AES256-GCM-SHA384",
      "ECDHE-RSA-AES128-GCM-SHA256",
      "ECDHE-RSA-AES256-SHA384",
      "ECDHE-RSA-AES128-SHA256"
    ]},

    # TLS version restrictions
    {:server_versions, [:"tlsv1.3", :"tlsv1.2"]},
    {:client_versions, [:"tlsv1.3", :"tlsv1.2"]}
  ]

# ────────────────────────────────────────────────────────────────
# 🛡️ Application Security Configuration
# ────────────────────────────────────────────────────────────────

config :my_app,
  # Strong cookie from environment (required)
  cluster_cookie: System.get_env("ERLANG_CLUSTER_COOKIE") ||
                  raise("ERLANG_CLUSTER_COOKIE environment variable is required"),

  # Allowed node names (whitelist)
  allowed_nodes: [
    :"app@10.0.1.1",
    :"app@10.0.1.2",
    :"app@10.0.1.3"
  ],

  # Enable cluster security monitoring
  security_monitoring: true,

  # Maximum nodes in cluster
  max_cluster_size: 5,

  # Remote shell access configuration
  remote_shell: [
    enabled: System.get_env("ENABLE_REMOTE_SHELL") == "true",
    authorized_users: System.get_env("AUTHORIZED_SHELL_USERS", "") |> String.split(","),
    session_timeout: 300_000,  # 5 minutes
    max_concurrent_sessions: 2
  ]

# ────────────────────────────────────────────────────────────────
# 📊 Security Monitoring Configuration
# ────────────────────────────────────────────────────────────────

config :logger,
  level: :info,
  backends: [:console, {LoggerFileBackend, :security_log}]

config :logger, :security_log,
  path: "/var/log/erlang/security.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:node, :pid, :remote_node, :security_event]

# ────────────────────────────────────────────────────────────────
# 🔒 Runtime Security Checks Module
# ────────────────────────────────────────────────────────────────

defmodule MyApp.ClusterSecurity do
  @moduledoc """
  Runtime security monitoring and enforcement for Erlang clusters.
  """

  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Monitor node connections/disconnections
    :net_kernel.monitor_nodes(true, [nodedown_reason: true])

    # Start periodic security checks
    schedule_security_check()

    {:ok, %{
      authorized_connections: MapSet.new(),
      connection_attempts: %{},
      last_check: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_info({:nodeup, node, _info}, state) do
    Logger.info("Node connected: #{node}",
      security_event: :node_connected,
      remote_node: node
    )

    if authorized_node?(node) do
      new_state = %{state |
        authorized_connections: MapSet.put(state.authorized_connections, node)
      }
      {:noreply, new_state}
    else
      Logger.error("Unauthorized node connection attempt: #{node}",
        security_event: :unauthorized_connection,
        remote_node: node
      )

      # Disconnect unauthorized node
      Node.disconnect(node)
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:nodedown, node, reason}, state) do
    Logger.info("Node disconnected: #{node}, reason: #{inspect(reason)}",
      security_event: :node_disconnected,
      remote_node: node
    )

    new_state = %{state |
      authorized_connections: MapSet.delete(state.authorized_connections, node)
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:security_check, state) do
    perform_security_checks()
    schedule_security_check()

    {:noreply, %{state | last_check: DateTime.utc_now()}}
  end

  defp authorized_node?(node) do
    allowed_nodes = Application.get_env(:my_app, :allowed_nodes, [])
    node in allowed_nodes
  end

  defp perform_security_checks do
    # Check cluster size
    cluster_size = length(Node.list()) + 1
    max_size = Application.get_env(:my_app, :max_cluster_size, 10)

    if cluster_size > max_size do
      Logger.error("Cluster size exceeded maximum: #{cluster_size}/#{max_size}",
        security_event: :cluster_size_exceeded
      )
    end

    # Check for unknown processes with network access
    check_suspicious_processes()

    # Verify TLS configuration is still active
    verify_tls_distribution()
  end

  defp check_suspicious_processes do
    # Look for processes that might be unauthorized remote shells
    processes = Process.list()

    Enum.each(processes, fn pid ->
      case Process.info(pid, :dictionary) do
        {:dictionary, dict} ->
          # Check for remote shell indicators
          if Keyword.get(dict, :"$ancestors") |>
             List.to_string() |>
             String.contains?("user_drv") do
            Logger.warning("Potential remote shell detected: #{inspect(pid)}",
              security_event: :potential_remote_shell,
              pid: pid
            )
          end
        _ -> :ok
      end
    end)
  end

  defp verify_tls_distribution do
    case :init.get_argument(:proto_dist) do
      {:ok, [['inet_tls']]} -> :ok
      _ ->
        Logger.error("TLS distribution not properly configured!",
          security_event: :tls_config_error
        )
    end
  end

  defp schedule_security_check do
    Process.send_after(self(), :security_check, 30_000)  # Every 30 seconds
  end
end

# ────────────────────────────────────────────────────────────────
# 🚀 Secure Application Startup
# ────────────────────────────────────────────────────────────────

defmodule MyApp.SecureApplication do
  @moduledoc """
  Application module with security-focused startup.
  """

  use Application
  require Logger

  def start(_type, _args) do
    # Verify security prerequisites before starting
    verify_security_config()

    children = [
      # Start security monitoring first
      MyApp.ClusterSecurity,

      # Your normal application children
      # {MyApp.Worker, []},
      # MyApp.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("Application started with security monitoring",
          security_event: :app_started
        )
        {:ok, pid}

      error ->
        Logger.error("Application failed to start: #{inspect(error)}",
          security_event: :app_start_failed
        )
        error
    end
  end

  defp verify_security_config do
    # Verify cookie is strong
    case Node.get_cookie() do
      cookie when byte_size(Atom.to_string(cookie)) < 32 ->
        raise "Cluster cookie must be at least 32 characters"
      _ -> :ok
    end

    # Verify TLS certificates exist
    cert_file = System.get_env("ERLANG_TLS_CERT_FILE")
    if cert_file && !File.exists?(cert_file) do
      raise "TLS certificate file not found: #{cert_file}"
    end

    # Verify we're not binding to all interfaces
    case Application.get_env(:kernel, :inet_dist_use_interface) do
      {0, 0, 0, 0} ->
        raise "Distribution cannot bind to all interfaces (0.0.0.0)"
      nil ->
        Logger.warning("inet_dist_use_interface not configured - may bind to all interfaces")
      _ -> :ok
    end

    Logger.info("Security configuration verified", security_event: :config_verified)
  end
end

# ────────────────────────────────────────────────────────────────
# 📋 Deployment Checklist Comments
# ────────────────────────────────────────────────────────────────

"""
PRODUCTION DEPLOYMENT CHECKLIST:

🔐 TLS Configuration:
□ Generate proper CA and node certificates
□ Set restrictive file permissions (600) on private keys
□ Configure certificate rotation procedures
□ Test certificate validation

🛡️ Network Security:
□ Deploy in private subnet/VPC
□ Configure firewall rules for ports 9100-9110
□ Block EPMD (4369) from external access
□ Set up VPN for administrative access

🔑 Authentication:
□ Generate strong cluster cookie (64+ chars)
□ Store cookie in secure configuration management
□ Plan cookie rotation procedures
□ Document emergency access procedures

📊 Monitoring:
□ Set up log aggregation for security events
□ Configure alerts for unauthorized connections
□ Monitor cluster size and topology
□ Track certificate expiration dates

🚨 Incident Response:
□ Document cluster shutdown procedures
□ Plan node isolation procedures
□ Practice emergency cookie rotation
□ Define escalation procedures

📝 Documentation:
□ Document network topology
□ Maintain node inventory
□ Update security procedures
□ Train operations team

⚠️ Remember: Erlang clustering creates a single security domain.
   One compromised node = entire cluster compromised.
   Consider alternatives if this risk is unacceptable.
"""
