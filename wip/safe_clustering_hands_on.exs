#!/usr/bin/env elixir

# Safe Local Clustering Hands-On Demo
#
# This script provides interactive examples for testing Erlang clustering
# and hot code loading in a completely safe local environment.
#
# To use this script:
# 1. Run: elixir day_three/safe_clustering_hands_on.exs
# 2. Follow the instructions to open multiple terminals
# 3. Test clustering features safely

IO.puts("""
🧪 SAFE LOCAL CLUSTERING HANDS-ON LAB
====================================

This lab will guide you through:
• Setting up a secure local cluster
• Testing distributed processes
• Hot code loading examples
• Monitoring cluster behavior

⚠️  SAFETY FIRST: This setup uses localhost-only binding.
   No external network exposure. Safe for learning!
""")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 1 – Terminal Setup and Node Information")

defmodule ClusterSetup do
  @moduledoc """
  Utilities for setting up and managing a safe local cluster.
  """

    def print_terminal_commands do
    IO.puts("""
    📺 TERMINAL COMMANDS FOR SAFE LOCAL CLUSTERING:

    Terminal 1 (Primary):
    ERL_EPMD_ADDRESS=127.0.0.1 iex --name primary@127.0.0.1 --cookie safe_demo_cookie_12345 -kernel inet_dist_use_interface '{127,0,0,1}'

    Terminal 2 (Worker):
    ERL_EPMD_ADDRESS=127.0.0.1 iex --name worker@127.0.0.1 --cookie safe_demo_cookie_12345 -kernel inet_dist_use_interface '{127,0,0,1}'

    Terminal 3 (Monitor):
    ERL_EPMD_ADDRESS=127.0.0.1 iex --name monitor@127.0.0.1 --cookie safe_demo_cookie_12345 -kernel inet_dist_use_interface '{127,0,0,1}'
    """)
  end

  def current_node_info do
    IO.puts("Current node: #{Node.self()}")
    IO.puts("Connected nodes: #{inspect(Node.list())}")
    IO.puts("All visible nodes: #{inspect(Node.list(:visible))}")

    if Node.alive?() do
      IO.puts("✅ This node is alive and can participate in clustering")
    else
      IO.puts("❌ This node is not alive. Run with --name to enable clustering.")
    end
  end

  def connect_to_node(node_name) when is_atom(node_name) do
    case Node.connect(node_name) do
      true ->
        IO.puts("✅ Successfully connected to #{node_name}")
        IO.puts("Connected nodes: #{inspect(Node.list())}")
      false ->
        IO.puts("❌ Failed to connect to #{node_name}")
        IO.puts("Make sure the node is running and has the same cookie")
      :ignored ->
        IO.puts("⚠️  Connection ignored - node might already be connected")
    end
  end

    def test_cluster_connectivity do
    nodes = Node.list()

    if length(nodes) == 0 do
      IO.puts("⚠️  No other nodes connected. Start with ClusterSetup.print_terminal_commands()")
    else
      IO.puts("🔍 Testing connectivity to #{length(nodes)} nodes...")

      Enum.each(nodes, fn node ->
        case :rpc.call(node, Node, :self, []) do
          {:badrpc, reason} ->
            IO.puts("❌ Failed to call #{node}: #{inspect(reason)}")
          result ->
            IO.puts("✅ Successfully called #{node}, response: #{result}")
        end
      end)
    end
  end
end

# Test current node setup
ClusterSetup.current_node_info()
ClusterSetup.print_terminal_commands()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Distributed Process Communication")

defmodule DistributedDemo do
  @moduledoc """
  Examples of distributed processes and communication patterns.
  """

  def spawn_remote_process(node_name) when is_atom(node_name) do
    if node_name in Node.list() do
      pid = Node.spawn(node_name, fn ->
        IO.puts("🚀 Process started on #{Node.self()}")
        IO.puts("PID: #{inspect(self())}")

        receive do
          {:ping, from_pid} ->
            send(from_pid, {:pong, Node.self()})
            IO.puts("Received ping, sent pong back")
          msg ->
            IO.puts("Received message: #{inspect(msg)}")
        end
      end)

      IO.puts("Spawned process #{inspect(pid)} on #{node_name}")

      # Test communication
      send(pid, {:ping, self()})

      receive do
        {:pong, from_node} ->
          IO.puts("✅ Received pong from #{from_node}")
      after
        2000 ->
          IO.puts("⚠️  No response received")
      end

      pid
    else
      IO.puts("❌ Node #{node_name} not connected. Available: #{inspect(Node.list())}")
      nil
    end
  end

  def test_global_registry do
    process_name = :demo_global_process

    case :global.register_name(process_name, self()) do
      :yes ->
        IO.puts("✅ Registered global process: #{process_name}")

        # Test finding it from all nodes
        all_nodes = [Node.self() | Node.list()]

        Enum.each(all_nodes, fn node ->
          case :rpc.call(node, :global, :whereis_name, [process_name]) do
            pid when is_pid(pid) ->
              IO.puts("✅ Found global process on #{node}: #{inspect(pid)}")
            :undefined ->
              IO.puts("❌ Global process not found on #{node}")
            {:badrpc, reason} ->
              IO.puts("❌ RPC failed to #{node}: #{inspect(reason)}")
          end
        end)

        # Cleanup
        :global.unregister_name(process_name)
        IO.puts("🧹 Unregistered global process")

      :no ->
        IO.puts("❌ Failed to register global process (name might be taken)")
    end
  end

    def broadcast_message(message) do
    nodes = Node.list()

    if length(nodes) == 0 do
      IO.puts("⚠️  No nodes to broadcast to")
    else
      IO.puts("📡 Broadcasting '#{message}' to #{length(nodes)} nodes...")

      Enum.each(nodes, fn node ->
        :rpc.cast(node, IO, :puts, ["📨 Broadcast from #{Node.self()}: #{message}"])
      end)

      IO.puts("✅ Broadcast complete")
    end
  end
end

# Test distributed processes if we have connections
if length(Node.list()) > 0 do
  IO.puts("Testing distributed processes...")
  DistributedDemo.test_global_registry()
  DistributedDemo.broadcast_message("Hello from #{Node.self()}!")
else
  IO.puts("⚠️  No connected nodes. Set up cluster first with multiple terminals.")
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Distributed GenServer")

defmodule ClusterDemo.Counter do
  use GenServer

  @moduledoc """
  A simple distributed counter that can be accessed from any node in the cluster.
  """

  # Client API
  def start_link(initial_value \\ 0) do
    case GenServer.start_link(__MODULE__, initial_value, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        IO.puts("✅ Started distributed counter on #{Node.self()}")
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        IO.puts("ℹ️  Counter already running on #{node_of_pid(pid)}")
        {:ok, pid}
      error ->
        IO.puts("❌ Failed to start counter: #{inspect(error)}")
        error
    end
  end

  def get(server \\ {:global, __MODULE__}) do
    try do
      result = GenServer.call(server, :get)
      IO.puts("📊 Current counter value: #{result}")
      result
    catch
      :exit, reason ->
        IO.puts("❌ Failed to get counter: #{inspect(reason)}")
        :error
    end
  end

  def increment(server \\ {:global, __MODULE__}) do
    try do
      result = GenServer.call(server, :increment)
      IO.puts("⬆️  Counter incremented to: #{result}")
      result
    catch
      :exit, reason ->
        IO.puts("❌ Failed to increment counter: #{inspect(reason)}")
        :error
    end
  end

  def get_stats(server \\ {:global, __MODULE__}) do
    try do
      stats = GenServer.call(server, :get_stats)
      IO.puts("📈 Counter stats: #{inspect(stats)}")
      stats
    catch
      :exit, reason ->
        IO.puts("❌ Failed to get stats: #{inspect(reason)}")
        :error
    end
  end

  # Server Callbacks
  def init(initial_value) do
    state = %{
      value: initial_value,
      node: Node.self(),
      operations: 0,
      started_at: DateTime.utc_now()
    }

    IO.puts("🎬 Counter initialized with value #{initial_value} on #{Node.self()}")
    {:ok, state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.value, state}
  end

  def handle_call(:increment, _from, state) do
    new_state = %{state |
      value: state.value + 1,
      operations: state.operations + 1
    }
    {:reply, new_state.value, new_state}
  end

  def handle_call(:get_stats, _from, state) do
    stats = %{
      current_value: state.value,
      operations_count: state.operations,
      running_on_node: state.node,
      uptime_seconds: DateTime.diff(DateTime.utc_now(), state.started_at)
    }
    {:reply, stats, state}
  end

  defp node_of_pid(pid) when is_pid(pid) do
    case :rpc.call(node(pid), Node, :self, []) do
      {:badrpc, _} -> :unknown
      node -> node
    end
  end
end

# Demonstrate distributed GenServer
case ClusterDemo.Counter.start_link(0) do
  {:ok, _pid} ->
    IO.puts("Testing distributed GenServer...")
    ClusterDemo.Counter.get()
    ClusterDemo.Counter.increment()
    ClusterDemo.Counter.increment()
    ClusterDemo.Counter.get_stats()
  _ ->
    IO.puts("Could not start distributed counter")
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Hot Code Loading Demonstration")

defmodule HotCode.Calculator do
  @moduledoc """
  A simple calculator module for demonstrating hot code loading.
  """

  def add(a, b), do: a + b
  def version, do: "1.0"

  def info do
    %{
      version: version(),
      node: Node.self(),
      pid: self(),
      functions: [:add, :version, :info]
    }
  end
end

defmodule HotCodeDemo do
  @moduledoc """
  Demonstrates hot code loading across the cluster.
  """

  def test_current_version do
    IO.puts("🧮 Testing Calculator v#{HotCode.Calculator.version()}")
    result = HotCode.Calculator.add(2, 3)
    IO.puts("2 + 3 = #{result}")

    info = HotCode.Calculator.info()
    IO.puts("Calculator info: #{inspect(info)}")
  end

  def test_across_cluster do
    all_nodes = [Node.self() | Node.list()]

    IO.puts("🌐 Testing Calculator across #{length(all_nodes)} nodes:")

    Enum.each(all_nodes, fn node ->
      case :rpc.call(node, HotCode.Calculator, :info, []) do
        {:badrpc, reason} ->
          IO.puts("❌ #{node}: RPC failed - #{inspect(reason)}")
        info ->
          IO.puts("✅ #{node}: Calculator v#{info.version} available")
      end
    end)
  end

  def simulate_hot_upgrade do
    IO.puts("""
    🔥 HOT CODE UPGRADE SIMULATION

    In a real scenario, you would:
    1. Deploy new code to nodes
    2. Use :code.purge() and :code.load_file()
    3. Update running processes with :sys.change_code()

    For safety in this demo, we'll just show the process:
    """)

    # Show what the upgrade process looks like
    IO.puts("Step 1: Check current module info")
    {:module, module} = Code.ensure_loaded(HotCode.Calculator)
    IO.puts("Module loaded: #{module}")

    IO.puts("Step 2: This is where we'd purge old version")
    IO.puts(":code.purge(#{module})")

    IO.puts("Step 3: This is where we'd load new version")
    IO.puts(":code.load_file(#{module})")

    IO.puts("Step 4: Running processes would be upgraded")
    IO.puts("⚠️  In production, test thoroughly before hot upgrades!")
  end
end

# Test current calculator
HotCodeDemo.test_current_version()
HotCodeDemo.test_across_cluster()
HotCodeDemo.simulate_hot_upgrade()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Cluster Monitoring")

defmodule ClusterMonitor do
  @moduledoc """
  Tools for monitoring cluster health and performance.
  """

  def cluster_overview do
    current = Node.self()
    connected = Node.list()

    IO.puts("""
    🏷️  CLUSTER OVERVIEW
    Current node: #{current}
    Connected nodes: #{length(connected)}
    """)

    if length(connected) > 0 do
      Enum.each(connected, fn node ->
        IO.puts("  📡 #{node}")
      end)
    else
      IO.puts("  ⚠️  No connected nodes")
    end
  end

  def memory_usage_report do
    all_nodes = [Node.self() | Node.list()]

    IO.puts("💾 MEMORY USAGE ACROSS CLUSTER:")

    Enum.each(all_nodes, fn node ->
      case :rpc.call(node, :erlang, :memory, []) do
        {:badrpc, reason} ->
          IO.puts("❌ #{node}: Failed to get memory info - #{inspect(reason)}")
        memory when is_list(memory) ->
          total_mb = (memory[:total] / (1024 * 1024)) |> Float.round(2)
          processes_mb = (memory[:processes] / (1024 * 1024)) |> Float.round(2)
          IO.puts("📊 #{node}: #{total_mb} MB total, #{processes_mb} MB processes")
      end
    end)
  end

  def process_count_report do
    all_nodes = [Node.self() | Node.list()]

    IO.puts("🏃 PROCESS COUNTS ACROSS CLUSTER:")

    Enum.each(all_nodes, fn node ->
      case :rpc.call(node, Process, :list, []) do
        {:badrpc, reason} ->
          IO.puts("❌ #{node}: Failed to get process list - #{inspect(reason)}")
        processes when is_list(processes) ->
          count = length(processes)
          IO.puts("🔢 #{node}: #{count} processes")
      end
    end)
  end

  def global_registry_report do
    names = :global.registered_names()

    IO.puts("🌐 GLOBAL REGISTRY (#{length(names)} entries):")

    if length(names) > 0 do
      Enum.each(names, fn name ->
        case :global.whereis_name(name) do
          pid when is_pid(pid) ->
            node = node(pid)
            IO.puts("  📝 #{name} -> #{inspect(pid)} on #{node}")
          :undefined ->
            IO.puts("  ❓ #{name} -> undefined")
        end
      end)
    else
      IO.puts("  📭 No global names registered")
    end
  end

  def start_monitoring do
    if Node.alive?() do
      :net_kernel.monitor_nodes(true)
      IO.puts("👀 Started monitoring node connections")
      IO.puts("You'll now receive :nodeup and :nodedown messages")

      # Return a function to stop monitoring
      fn ->
        :net_kernel.monitor_nodes(false)
        IO.puts("🛑 Stopped monitoring node connections")
      end
    else
      IO.puts("❌ Cannot monitor nodes - this node is not alive")
      fn -> :ok end
    end
  end

  def full_cluster_report do
    IO.puts("=" <> String.duplicate("=", 50))
    cluster_overview()
    IO.puts("")
    memory_usage_report()
    IO.puts("")
    process_count_report()
    IO.puts("")
    global_registry_report()
    IO.puts("=" <> String.duplicate("=", 50))
  end
end

# Generate cluster report
ClusterMonitor.full_cluster_report()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 6 – Interactive Cluster Commands")

defmodule ClusterCommands do
  @moduledoc """
  Interactive commands for cluster management and testing.
  """

  def help do
    IO.puts("""
    🔧 AVAILABLE CLUSTER COMMANDS:

    Setup & Connection:
      ClusterCommands.connect("worker@127.0.0.1")     # Connect to a node
      ClusterCommands.disconnect("worker@127.0.0.1")  # Disconnect from a node
      ClusterCommands.ping("worker@127.0.0.1")        # Test node connectivity

    Testing:
      ClusterCommands.test_rpc()                       # Test remote procedure calls
      ClusterCommands.spawn_test_processes(3)          # Spawn test processes
      ClusterCommands.broadcast_test()                 # Test broadcasting

    Monitoring:
      ClusterCommands.watch_cluster()                  # Monitor cluster changes
      ClusterCommands.health_check()                   # Check cluster health

    Demo Apps:
      ClusterCommands.start_counter()                  # Start distributed counter
      ClusterCommands.counter_demo()                   # Demo counter operations

    Type ClusterCommands.help() to see this list again.
    """)
  end

  def connect(node_name) when is_binary(node_name) do
    connect(String.to_atom(node_name))
  end

  def connect(node_name) when is_atom(node_name) do
    ClusterSetup.connect_to_node(node_name)
  end

  def disconnect(node_name) when is_binary(node_name) do
    disconnect(String.to_atom(node_name))
  end

  def disconnect(node_name) when is_atom(node_name) do
    case Node.disconnect(node_name) do
      true -> IO.puts("✅ Disconnected from #{node_name}")
      false -> IO.puts("❌ Failed to disconnect from #{node_name}")
      :ignored -> IO.puts("ℹ️  #{node_name} was not connected")
    end
  end

  def ping(node_name) when is_binary(node_name) do
    ping(String.to_atom(node_name))
  end

  def ping(node_name) when is_atom(node_name) do
    case Node.ping(node_name) do
      :pong -> IO.puts("🏓 #{node_name} responded with pong")
      :pang -> IO.puts("💔 #{node_name} did not respond")
    end
  end

  def test_rpc do
    nodes = Node.list()

    if length(nodes) == 0 do
      IO.puts("⚠️  No nodes connected for RPC testing")
    else
      IO.puts("🔄 Testing RPC calls to #{length(nodes)} nodes...")

      Enum.each(nodes, fn node ->
        # Test simple function call
        case :rpc.call(node, System, :version, []) do
          {:badrpc, reason} ->
            IO.puts("❌ RPC to #{node} failed: #{inspect(reason)}")
          version ->
            IO.puts("✅ #{node} is running Elixir #{version}")
        end
      end)
    end
  end

  def spawn_test_processes(count \\ 3) do
    nodes = Node.list()

    if length(nodes) == 0 do
      IO.puts("⚠️  No nodes available for spawning processes")
    else
      IO.puts("🚀 Spawning #{count} test processes across cluster...")

      1..count
      |> Enum.map(fn i ->
        node = Enum.at(nodes, rem(i - 1, length(nodes)))

        pid = Node.spawn(node, fn ->
          IO.puts("🏃 Test process #{i} running on #{Node.self()}")
          Process.sleep(1000)
          IO.puts("✅ Test process #{i} completed")
        end)

        {i, node, pid}
      end)
      |> Enum.each(fn {i, node, pid} ->
        IO.puts("Process #{i}: #{inspect(pid)} on #{node}")
      end)
    end
  end

  def broadcast_test do
    message = "Test broadcast at #{DateTime.utc_now()}"
    DistributedDemo.broadcast_message(message)
  end

  def health_check do
    ClusterMonitor.full_cluster_report()
  end

  def start_counter do
    ClusterDemo.Counter.start_link(0)
  end

  def counter_demo do
    IO.puts("🧮 DISTRIBUTED COUNTER DEMO")

    ClusterDemo.Counter.get()
    ClusterDemo.Counter.increment()
    ClusterDemo.Counter.increment()
    ClusterDemo.Counter.increment()
    ClusterDemo.Counter.get_stats()

    # Test from other nodes if available
    Enum.each(Node.list(), fn node ->
      IO.puts("Testing counter from #{node}:")
      :rpc.call(node, ClusterDemo.Counter, :increment, [])
    end)

    ClusterDemo.Counter.get_stats()
  end

  def watch_cluster do
    ClusterMonitor.start_monitoring()
  end
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n🎉 HANDS-ON LAB READY!")

IO.puts("""
Welcome to the Safe Local Clustering Lab!

🚀 QUICK START:
1. Open multiple terminals and run the commands shown above
2. Try: ClusterCommands.help()
3. Connect nodes: ClusterCommands.connect("worker@127.0.0.1")
4. Test features: ClusterCommands.counter_demo()

🔧 KEY FUNCTIONS AVAILABLE:
• ClusterSetup.current_node_info()     - Check node status
• ClusterCommands.help()               - See all available commands
• ClusterMonitor.full_cluster_report() - Get cluster health report
• DistributedDemo.test_global_registry() - Test global processes

⚡ EXPERIMENTS TO TRY:
• Start a distributed counter and access it from multiple nodes
• Test fault tolerance by disconnecting nodes
• Monitor cluster health during operations
• Broadcast messages across the cluster

Type ClusterCommands.help() to get started!
""")

# Show initial help
ClusterCommands.help()
