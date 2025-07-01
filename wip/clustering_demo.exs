#!/usr/bin/env elixir

# Clustering and Hot Code Loading Demo
#
# This script demonstrates:
# - Safe local clustering setup
# - Hot code loading capabilities
# - Security considerations for production
# - Network isolation techniques
#
# Run with: elixir day_three/clustering_demo.exs

IO.puts("""
🌐 ERLANG CLUSTERING & HOT CODE LOADING DEMO
=============================================

This demo covers:
• Local cluster formation (safe)
• Node communication patterns
• Hot code loading examples
• Production security considerations
• Network isolation strategies
""")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Part 1 – Understanding the Security Model")

defmodule SecurityDemo do
  @moduledoc """
  Understanding Erlang clustering security model and attack surface.
  """

  def explain_security_model do
    """
    🔒 ERLANG CLUSTERING SECURITY MODEL

    Key Security Facts:
    • Erlang clusters share FULL trust - if one node is compromised, all are
    • Cookie-based authentication is minimal - no protection against MITM
    • Distribution protocol runs on TCP by default (unencrypted)
    • EPMD (port 4369) exposes cluster topology to anyone who can connect
    • Remote shell access = arbitrary code execution

    Attack Vectors:
    • Network sniffing can reveal cookies and data
    • EPMD enumeration reveals cluster structure
    • Cookie brute-forcing (if cookie is weak)
    • Man-in-the-middle attacks on node communication
    • Remote code execution via distribution protocol

    ⚠️  Production Rule: Never expose distribution ports to untrusted networks!
    """
  end

  def show_safe_clustering_approaches do
    approaches = [
      "🏠 Local Development: Use loopback interface only",
      "🔒 VPN/Private Networks: Isolate cluster traffic",
      "🛡️  TLS Distribution: Enable mutual TLS authentication",
      "🚇 SSH Tunnels: Route cluster traffic through secure tunnels",
      "🌐 Service Mesh: Use Istio/Consul Connect for secure communication",
      "🔥 Firewall Rules: Block EPMD (4369) and distribution ports"
    ]

    IO.puts("\nSafe Clustering Approaches:")
    Enum.each(approaches, fn approach ->
      IO.puts("  #{approach}")
    end)
  end
end

IO.puts(SecurityDemo.explain_security_model())
SecurityDemo.show_safe_clustering_approaches()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Part 2 – Local Safe Clustering Demo")

defmodule LocalClusterDemo do
  @moduledoc """
  Demonstrates safe local clustering for learning.
  """

  def setup_instructions do
    """
    🏗️  SAFE LOCAL CLUSTERING SETUP

    Terminal 1 (Node A):
    ERL_EPMD_ADDRESS=127.0.0.1 iex --name nodeA@127.0.0.1 \\
      --cookie secret_cookie_for_demo_only \\
      -kernel inet_dist_use_interface '{127,0,0,1}'

    Terminal 2 (Node B):
    ERL_EPMD_ADDRESS=127.0.0.1 iex --name nodeB@127.0.0.1 \\
      --cookie secret_cookie_for_demo_only \\
      -kernel inet_dist_use_interface '{127,0,0,1}'

    In Node B:
    Node.connect(:"nodeA@127.0.0.1")
    Node.list()  # Should show nodeA

    Security Features:
    • ERL_EPMD_ADDRESS=127.0.0.1 binds EPMD to localhost only
    • inet_dist_use_interface binds distribution to localhost only
    • No external network exposure
    """
  end

  def cluster_communication_examples do
    """
    🗣️  CLUSTER COMMUNICATION EXAMPLES

    # Spawn process on remote node
    pid = Node.spawn(:"nodeA@127.0.0.1", fn ->
      IO.puts("Hello from remote node!")
      Process.sleep(5000)
    end)

    # Send message to remote process
    send(pid, {:message, "Hello remote process"})

    # Call function on remote node
    :rpc.call(:"nodeA@127.0.0.1", IO, :puts, ["Remote function call"])

    # Distributed GenServer
    GenServer.start_link(MyServer, [], name: {:global, :shared_server})
    GenServer.call({:global, :shared_server}, :get_state)  # Works from any node

    # Global process registry
    :global.register_name(:my_process, self())
    :global.whereis_name(:my_process)  # Find from any node
    """
  end
end

IO.puts(LocalClusterDemo.setup_instructions())
IO.puts(LocalClusterDemo.cluster_communication_examples())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Part 3 – Hot Code Loading Demo")

defmodule HotCodeDemo do
  @moduledoc """
  Demonstrates hot code loading capabilities and use cases.
  """

  def explain_hot_code_loading do
    """
    🔥 HOT CODE LOADING IN ERLANG

    Capabilities:
    • Load new module versions without stopping the VM
    • Update running processes to use new code
    • Atomic code updates across the cluster
    • Rollback to previous versions if needed

    How It Works:
    • BEAM VM can hold 2 versions of a module simultaneously
    • Old processes continue with old code until next function call
    • New processes start with new code immediately
    • Function calls trigger migration to new code version

    Use Cases:
    • Bug fixes without downtime
    • Feature toggles and gradual rollouts
    • A/B testing different implementations
    • Emergency patches in production
    """
  end

  def show_code_loading_example do
    """
    📝 HOT CODE LOADING EXAMPLE

    # Create a simple module to update
    defmodule Counter do
      def count, do: 1
      def version, do: "1.0"
    end

    # Use the module
    Counter.count()    # Returns 1
    Counter.version()  # Returns "1.0"

    # Update the module (simulate new code)
    defmodule Counter do
      def count, do: 2
      def version, do: "2.0"
      def new_feature, do: "This is new!"
    end

    # Hot load the new code
    :code.purge(Counter)
    :code.load_file(Counter)

    # Test the update
    Counter.count()       # Returns 2
    Counter.version()     # Returns "2.0"
    Counter.new_feature() # Returns "This is new!"

    # Distributed hot loading
    :rpc.multicall([node() | Node.list()], :code, :load_file, [Counter])
    """
  end
end

IO.puts(HotCodeDemo.explain_hot_code_loading())
IO.puts(HotCodeDemo.show_code_loading_example())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Part 4 – Production Security Hardening")

defmodule ProductionSecurity do
  @moduledoc """
  Production-ready security configurations for Erlang clusters.
  """

  def tls_distribution_config do
    """
    🔐 TLS DISTRIBUTION CONFIGURATION

    # vm.args configuration for TLS
    -proto_dist inet_tls
    -ssl_dist_opt server_certfile "path/to/server.pem"
    -ssl_dist_opt server_keyfile "path/to/server.key"
    -ssl_dist_opt server_cacertfile "path/to/ca.pem"
    -ssl_dist_opt client_certfile "path/to/client.pem"
    -ssl_dist_opt client_keyfile "path/to/client.key"
    -ssl_dist_opt client_cacertfile "path/to/ca.pem"
    -ssl_dist_opt verify verify_peer
    -ssl_dist_opt fail_if_no_peer_cert true

    # Runtime configuration
    config :kernel,
      inet_dist_use_interface: {10, 0, 1, 1},  # Private network only
      inet_dist_listen_min: 9100,
      inet_dist_listen_max: 9200

    Benefits:
    • Mutual authentication with certificates
    • Encrypted communication between nodes
    • Protection against man-in-the-middle attacks
    • Strong identity verification
    """
  end

  def network_isolation_strategies do
    """
    🛡️  NETWORK ISOLATION STRATEGIES

    1. VPC/Private Networks:
    • Deploy cluster in private subnet
    • No public IP addresses for cluster nodes
    • Use NAT gateway for outbound internet access
    • Security groups restrict cluster ports

    2. Firewall Rules:
    # Block EPMD from external access
    iptables -A INPUT -p tcp --dport 4369 -s 10.0.0.0/8 -j ACCEPT
    iptables -A INPUT -p tcp --dport 4369 -j DROP

    # Restrict distribution ports to cluster subnet
    iptables -A INPUT -p tcp --dport 9100:9200 -s 10.0.1.0/24 -j ACCEPT
    iptables -A INPUT -p tcp --dport 9100:9200 -j DROP

    3. SSH Tunnels for Remote Access:
    # Instead of exposing distribution, use SSH tunnel
    ssh -L 4369:localhost:4369 -L 9100:localhost:9100 prod-server
    iex --name debug@127.0.0.1 --cookie prod_cookie

    4. VPN Access:
    • Require VPN connection for cluster access
    • Use certificate-based VPN authentication
    • Log all VPN access for audit trail
    """
  end

  def secure_deployment_practices do
    """
    🚀 SECURE DEPLOYMENT PRACTICES

    1. Cookie Management:
    • Generate strong, random cookies (64+ characters)
    • Rotate cookies regularly
    • Store cookies in secure configuration management
    • Never hardcode cookies in source code

    2. Release Security:
    • Use mix releases for production
    • Enable stripped BEAM files (remove debug info)
    • Set appropriate file permissions (600 for config files)
    • Run as non-root user with minimal privileges

    3. Monitoring & Auditing:
    • Log all node connections/disconnections
    • Monitor for unexpected EPMD queries
    • Alert on unauthorized connection attempts
    • Track remote shell sessions

    4. Emergency Procedures:
    • Have offline procedure to regenerate cookies
    • Practice emergency cluster shutdown
    • Document incident response for compromised nodes
    • Maintain offline backups of critical data
    """
  end
end

IO.puts(ProductionSecurity.tls_distribution_config())
IO.puts(ProductionSecurity.network_isolation_strategies())
IO.puts(ProductionSecurity.secure_deployment_practices())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Part 5 – Production Hot Code Loading")

defmodule ProductionHotLoading do
  @moduledoc """
  Safe hot code loading practices for production systems.
  """

  def safe_hot_loading_practices do
    """
    ⚡ SAFE HOT CODE LOADING IN PRODUCTION

    Best Practices:
    • Test hot loading in staging environment first
    • Use feature flags to control new code paths
    • Implement gradual rollout strategies
    • Maintain rollback procedures
    • Monitor system health during updates

    Release Upgrade Process:
    1. Deploy new code to canary nodes
    2. Validate functionality on canary
    3. Gradually update remaining nodes
    4. Monitor metrics and error rates
    5. Rollback if issues detected

    Code Compatibility:
    • Maintain backwards compatibility in message formats
    • Use versioned APIs for inter-process communication
    • Handle both old and new data structures
    • Graceful degradation for unknown message types
    """
  end

    def rolling_upgrade_example do
    """
    🔄 ROLLING UPGRADE EXAMPLE

    # 1. Prepare upgrade on all nodes (don't activate yet)
    Enum.each(Node.list() ++ [node()], fn target_node ->
      :rpc.call(target_node, :code, :add_path, ["/path/to/new/version"])
    end)

    # 2. Test on canary node
    :rpc.call(:canary@prod, MyModule, :new_function, [])

    # 3. Activate on one node at a time
    nodes = Node.list() ++ [node()]
    Enum.each(nodes, fn target_node ->
      IO.puts("Upgrading node: \#{target_node}")

      # Load new code
      :rpc.call(target_node, :code, :purge, [MyModule])
      :rpc.call(target_node, :code, :load_file, [MyModule])

      # Verify health
      health = :rpc.call(target_node, MyModule, :health_check, [])

      if health == :ok do
        IO.puts("✅ Node \#{target_node} upgraded successfully")
      else
        IO.puts("❌ Node \#{target_node} upgrade failed, rolling back")
        # Rollback procedure here
      end

      # Wait before next node
      Process.sleep(5000)
    end)
    """
  end
end

IO.puts(ProductionHotLoading.safe_hot_loading_practices())
IO.puts(ProductionHotLoading.rolling_upgrade_example())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Part 6 – Alternative Approaches for Production")

defmodule AlternativeApproaches do
  @moduledoc """
  Alternative deployment strategies that avoid clustering security risks.
  """

  def kubernetes_approach do
    """
    ☸️  KUBERNETES APPROACH (NO CLUSTERING)

    Instead of Erlang clustering, use Kubernetes features:

    • Service Discovery: Use Kubernetes services
    • Load Balancing: Use ingress controllers
    • Communication: HTTP/gRPC between pods
    • State Sharing: External systems (Redis, PostgreSQL)
    • Configuration: ConfigMaps and Secrets
    • Health Checks: Kubernetes liveness/readiness probes

    Benefits:
    • No exposure of Erlang distribution protocol
    • Standard Kubernetes security model
    • Better isolation between instances
    • Easier to reason about failure modes
    • Industry-standard monitoring and logging

    Trade-offs:
    • Lose transparent distribution
    • More complex inter-service communication
    • External dependencies for state
    • Network latency between pods
    """
  end

  def blue_green_deployment do
    """
    🔵🟢 BLUE-GREEN DEPLOYMENT (NO HOT LOADING)

    Instead of hot code loading, use deployment strategies:

    1. Blue-Green Deployment:
    • Maintain two identical environments
    • Deploy new version to inactive environment
    • Test thoroughly in inactive environment
    • Switch traffic to new environment
    • Keep old environment for quick rollback

    2. Rolling Deployment:
    • Update instances one at a time
    • Health check each instance before continuing
    • Automatic rollback on failure
    • Zero-downtime deployments

    3. Canary Deployment:
    • Deploy new version to small subset of instances
    • Route small percentage of traffic to new version
    • Monitor metrics and error rates
    • Gradually increase traffic to new version

    Benefits:
    • Simpler reasoning about system state
    • No risk of hot loading failures
    • Standard deployment practices
    • Better testability
    """
  end
end

IO.puts(AlternativeApproaches.kubernetes_approach())
IO.puts(AlternativeApproaches.blue_green_deployment())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Conclusion & Recommendations")

defmodule Recommendations do
  def summarize_approaches do
    """
    🎯 RECOMMENDED APPROACHES BY USE CASE

    Learning & Development:
    ✅ Use local clustering with loopback interface
    ✅ Experiment with hot code loading in safe environment
    ✅ Practice security configurations in lab setup

    Small Internal Systems:
    ✅ TLS distribution with proper certificates
    ✅ VPN or private network isolation
    ✅ Strong cookie management
    ✅ Monitoring and logging

    Large Production Systems:
    ✅ Consider Kubernetes without clustering
    ✅ Use blue-green or canary deployments
    ✅ HTTP/gRPC for inter-service communication
    ✅ External state management

    High-Security Environments:
    ✅ No Erlang clustering (too much attack surface)
    ✅ Container orchestration for scaling
    ✅ Immutable deployments
    ✅ Comprehensive audit logging

    Remember: The power of Erlang clustering comes with significant
    security responsibilities. Choose the approach that matches your
    risk tolerance and operational capabilities.
    """
  end
end

IO.puts(Recommendations.summarize_approaches())

IO.puts("""

🔗 ADDITIONAL RESOURCES:
• Erlang Security WG: https://security.erlef.org/
• TLS Distribution Guide: https://www.erlang.org/doc/apps/ssl/ssl_distribution.html
• OTP Release Handling: https://www.erlang.org/doc/design_principles/release_handling.html
• Production Deployment Guide: https://hexdocs.pm/phoenix/deployment.html

⚠️  Always test security configurations in isolated environments first!
""")
