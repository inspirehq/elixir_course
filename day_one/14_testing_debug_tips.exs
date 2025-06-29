# Day 1 – Testing & Debugging GenServers
#
# This script can be run with:
#     mix run day_one/14_testing_debug_tips.exs
# or inside IEx with:
#     iex -r day_one/14_testing_debug_tips.exs
#
# This file covers:
#   • Synchronous vs. asynchronous ExUnit tests
#   • Using `:sys.get_state/1` for white-box assertions (sparingly)
#   • Capturing logs to verify side-effects
#   • The `:observer` GUI and `:erlang.trace/3` for runtime introspection
#   • Real-world example: testing a rate-limited API caller GenServer
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – ExUnit synchronous test style (scripted)")

# In a real project this would live in `*_test.exs` – here we simulate quickly.
# We'll define the TestableServer later and use a simple named server here for demo
ExUnit.start()

defmodule DemoSyncServer do
  use GenServer
  def start_link(_), do: GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  def bump, do: GenServer.cast(__MODULE__, :bump)
  def value, do: GenServer.call(__MODULE__, :val)
  @impl true
  def init(c), do: {:ok, c}
  @impl true
  def handle_cast(:bump, s), do: {:noreply, s + 1}
  @impl true
  def handle_call(:val, _f, s), do: {:reply, s, s}
end

{:ok, _} = DemoSyncServer.start_link(nil)

# Step 1: Simple synchronous assertion without defining a full test case
# This shows basic GenServer testing pattern
DemoSyncServer.bump()
if DemoSyncServer.value() == 1 do
  IO.puts("✅ Assertion passed: value == 1")
else
  IO.puts("❌ Assertion failed")
end

# Step 2: Clean up the named server before continuing
GenServer.stop(DemoSyncServer)

# This demonstrates a common real-world pattern where you need to respect
# external service rate limits (e.g., REST APIs, third-party services)
defmodule ApiClient do
  use GenServer

  # Configuration: Allow 5 requests per minute (60 seconds)
  @limit 5

  # Public API - This forms the "contract" that tests should verify
  def start_link(_) do
    initial_state = %{count: 0, window: ts()}
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def request(), do: GenServer.call(__MODULE__, :req)

  # GenServer callbacks
  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:req, _from, %{count: c, window: w} = s) do
    now = ts()

    # Reset counter if we've moved to a new time window (>60 seconds)
    {c, w} = if now - w > 60, do: {0, now}, else: {c, w}

    if c < @limit do
      # In a real application, this would make an actual HTTP request
      {:reply, :ok, %{s | count: c + 1, window: w}}
    else
      # Rate limit exceeded - reject the request
      {:reply, {:error, :rate_limited}, s}
    end
  end

  # Helper function to get current timestamp in seconds
  defp ts, do: :erlang.monotonic_time(:second)
end

# Test helper server for exercises
defmodule TestableServer do
  use GenServer

  def start_link(initial \\ 0), do: GenServer.start_link(__MODULE__, initial)
  def bump(pid), do: GenServer.cast(pid, :bump)
  def value(pid), do: GenServer.call(pid, :val)

  @impl true
  def init(c), do: {:ok, c}

  @impl true
  def handle_cast(:bump, s), do: {:noreply, s + 1}

  @impl true
  def handle_call(:val, _f, s), do: {:reply, s, s}
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – :sys.get_state/1 for internal assertion")

# Step 1: Start a TestableServer for white-box testing demonstration
{:ok, test_pid} = TestableServer.start_link(42)  # Start with initial value 42

# Step 2: Use the public API to change state
TestableServer.bump(test_pid)  # Should increment to 43

# Step 3: Use white-box testing to inspect internal state
state = :sys.get_state(test_pid)
IO.inspect(state, label: "Internal state via :sys.get_state")

# Step 4: Verify state matches expected value
expected_state = 43
if state == expected_state do
  IO.puts("✅ White-box assertion passed: state == #{expected_state}")
else
  IO.puts("❌ White-box assertion failed: expected #{expected_state}, got #{state}")
end

# Step 5: Clean up
GenServer.stop(test_pid)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Capturing logs during tests")

require Logger

# Step 1: Demonstrate basic log capture
log_output = ExUnit.CaptureLog.capture_log(fn ->
  Logger.info("hello logged world")
end)

IO.inspect(log_output, label: "Captured logs")

# Step 2: Show how to test for specific log content
warning_log = ExUnit.CaptureLog.capture_log(fn ->
  Logger.warning("Something went wrong!")
end)

if String.contains?(warning_log, "Something went wrong!") do
  IO.puts("✅ Log capture assertion passed: found expected warning")
else
  IO.puts("❌ Log capture assertion failed: warning not found")
end

# Step 3: Demonstrate multiple log levels in one capture
multi_log = ExUnit.CaptureLog.capture_log(fn ->
  Logger.info("Process started")
  Logger.warning("Low memory warning")
  Logger.error("Process crashed")
end)

IO.puts("\nMultiple log levels captured:")
IO.puts(multi_log)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Runtime inspection with :observer (manual)")

# Step 1: Explain what Observer shows you
IO.puts("""
🔍 Observer is like "Task Manager" for Erlang/Elixir systems. It shows:
  • All running processes and their memory usage
  • Message queue lengths (bottlenecks show up here)
  • ETS tables and their contents
  • Application supervision trees
  • System memory allocation and garbage collection stats
  • Load distribution across scheduler threads
""")

# Step 2: Try to start Observer GUI (might fail or not be available)
IO.puts("Attempting to start Observer GUI...")

observer_result = try do
  # Check if observer module exists first
  if Code.ensure_loaded?(:observer) do
    :observer.start()
  else
    {:error, :module_not_available}
  end
rescue
  UndefinedFunctionError -> {:error, :module_not_available}
  error -> {:error, error}
end

case observer_result do
  :ok ->
    IO.puts("✅ Observer started! Look for the Observer window to open.")
    IO.puts("📋 Processes tab: See all GenServers, their message queue lengths")
    IO.puts("💾 Memory tab: Track memory usage and potential leaks")
    IO.puts("📊 Applications tab: Visualize supervision trees")
    IO.puts("🗂️ ETS tab: Inspect ETS tables (caches, registries)")

    {:error, :module_not_available} ->
    IO.puts("ℹ️  Observer module not available in this Elixir installation.")
    IO.puts("   Observer requires additional GUI dependencies that aren't always included.")

  {:error, {reason, _stacktrace}} ->
    IO.puts("❌ Observer GUI failed to start: #{inspect(reason)}")
    IO.puts("   This is common on macOS due to wxWidgets compatibility issues.")

  {:error, reason} ->
    IO.puts("❌ Observer failed: #{inspect(reason)}")
end

# Step 3: Show alternatives when Observer doesn't work
unless observer_result == :ok do
  IO.puts("\n🔄 Alternative: Command-line system inspection")
  IO.puts("   In IEx, you can use these commands instead:")
  IO.puts("   • Process.list() |> length() - Count running processes")
  IO.puts("   • :erlang.system_info(:process_count) - System process count")
  IO.puts("   • :erlang.memory() - Memory usage breakdown")
  IO.puts("   • :sys.get_state(pid) - Inspect individual process state")

  # Step 4: Demonstrate some basic system inspection without GUI
  IO.puts("\n📈 System Information (no GUI needed):")
  process_count = :erlang.system_info(:process_count)
  memory_info = :erlang.memory()

  IO.puts("   Processes running: #{process_count}")
  IO.puts("   Total memory: #{div(memory_info[:total], 1024 * 1024)} MB")
  IO.puts("   Process memory: #{div(memory_info[:processes], 1024 * 1024)} MB")
  IO.puts("   ETS memory: #{div(memory_info[:ets], 1024 * 1024)} MB")

  # Show some live processes
  IO.puts("\n🔍 Sample running processes:")
  Process.list()
  |> Enum.take(5)
  |> Enum.each(fn pid ->
    info = Process.info(pid, [:registered_name, :memory, :message_queue_len])
    name = info[:registered_name] || "unnamed"
    memory_kb = div(info[:memory] || 0, 1024)
    queue_len = info[:message_queue_len] || 0
    IO.puts("   #{inspect(pid)}: #{name}, #{memory_kb} KB, #{queue_len} msgs queued")
  end)

  # Show ETS tables if any exist
  ets_tables = :ets.all()
  if length(ets_tables) > 0 do
    IO.puts("\n🗃️  ETS Tables (first 3):")
    ets_tables
    |> Enum.take(3)
    |> Enum.each(fn table ->
      info = :ets.info(table)
      name = info[:name] || table
      size = info[:size] || 0
      memory_words = info[:memory] || 0
      IO.puts("   #{inspect(name)}: #{size} entries, #{memory_words} words")
    end)
  end
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Testing the ApiClient rate-limited GenServer")

# Step 1: Start the existing ApiClient GenServer (defined below)
# This demonstrates testing a production-style rate-limited API client
{:ok, _pid} = ApiClient.start_link(nil)

IO.puts("Testing ApiClient rate limiting - should allow 5 requests then block:")

# Step 2: Make 5 successful requests (within the limit)
Enum.each(1..5, fn i ->
  case ApiClient.request() do
    :ok -> IO.puts("  ✅ Request #{i} allowed")
    error -> IO.puts("  ❌ Unexpected error on request #{i}: #{inspect(error)}")
  end
end)

# Step 3: This 6th request should be rate limited
case ApiClient.request() do
  {:error, :rate_limited} -> IO.puts("  ✅ Rate limiting working correctly!")
  unexpected -> IO.puts("  ❌ Expected rate limit error, got: #{inspect(unexpected)}")
end

# Step 4: Demonstrate white-box testing (peek at internal state)
IO.puts("\n🔍 Inspecting internal state with :sys.get_state/1:")
current_state = :sys.get_state(ApiClient)
IO.inspect(current_state, label: "ApiClient internal state")
IO.puts("   ⚠️  This is white-box testing - use sparingly!")

# Step 5: Demonstrate using TestableServer for exercises
IO.puts("\n🧪 Using TestableServer for black-box testing:")
{:ok, test_pid} = TestableServer.start_link(10)  # Start with value 10

# Test the public API
initial_value = TestableServer.value(test_pid)
IO.puts("  Initial value: #{initial_value}")

TestableServer.bump(test_pid)
TestableServer.bump(test_pid)
final_value = TestableServer.value(test_pid)
IO.puts("  After 2 bumps: #{final_value}")

# Clean up
GenServer.stop(test_pid)
GenServer.stop(ApiClient)

defmodule DayOne.TestingExercises do
  @moduledoc """
  Run the tests with: mix test day_one/14_testing_debug_tips.exs
  or in IEx:
  iex -r day_one/14_testing_debug_tips.exs
  DayOne.TestingExercisesTest.test_demo_server_assertion/0
  DayOne.TestingExercisesTest.test_log_capture/0
  DayOne.TestingExercisesTest.test_white_box_state/0
  """

  @spec test_demo_server_assertion() :: :ok
  def test_demo_server_assertion do
    #   Build a test for the TestableServer that asserts its initial value is 0.
    #   Use the public API only (black-box testing).
    #   Return :ok on success.
    :ok  # TODO: Implement black-box test assertion
  end

  @spec test_log_capture() :: :ok
  def test_log_capture do
    #   Use `ExUnit.CaptureLog` to assert that calling a function logs a
    #   specific warning message.
    #   Return :ok on success.
    :ok  # TODO: Implement log capture test
  end

  @spec test_white_box_state() :: :ok
  def test_white_box_state do
    #   Use `:sys.get_state/1` to test the internal state of a TestableServer
    #   after sending it two `:bump` messages.
    #   Return :ok on success.
    :ok  # TODO: Implement white-box test using get_state
  end
end

ExUnit.start()

defmodule DayOne.TestingExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.TestingExercises, as: EX

  test "demo server assertion works" do
    assert EX.test_demo_server_assertion() == :ok
  end

  test "log capture works" do
    assert EX.test_log_capture() == :ok
  end

  test "white box state test works" do
    assert EX.test_white_box_state() == :ok
  end
end

defmodule DayOne.Answers do
  def answer_one do
    quote do
      def test_demo_server_assertion do
        {:ok, pid} = TestableServer.start_link(0)
        assert TestableServer.value(pid) == 0
        GenServer.stop(pid)
        :ok
      end
    end
  end

  def answer_two do
    quote do
      def test_log_capture do
        log = ExUnit.CaptureLog.capture_log(fn ->
          Logger.warning("oops")
        end)
        assert log =~ "oops"
        :ok
      end
    end
  end

  def answer_three do
    quote do
      def test_white_box_state do
        {:ok, pid} = TestableServer.start_link(0)
        TestableServer.bump(pid)
        TestableServer.bump(pid)
        assert :sys.get_state(pid) == 2
        GenServer.stop(pid)
        :ok
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. test_demo_server_assertion/0
#{Macro.to_string(DayOne.Answers.answer_one())}
#  Confirms initial state via public API (black-box testing approach).

# 2. test_log_capture/0
#{Macro.to_string(DayOne.Answers.answer_two())}
#  Shows how to verify side-effects that go to the Logger system.

# 3. test_white_box_state/0
#{Macro.to_string(DayOne.Answers.answer_three())}
#  Uses :sys.get_state to peek inside (white-box) but after exercising the public API.
#  White-box testing should be used sparingly and with caution as it couples
#  tests to implementation details.
""")

# ============================================================================
# 🔍 OBSERVER GUI SETUP GUIDE - Getting the Full Experience
# ============================================================================

"""
STEP-BY-STEP: GETTING OBSERVER GUI WORKING LOCALLY

This guide helps you get the Observer GUI working on macOS. The Observer GUI is
incredibly valuable for debugging production Elixir systems, so it's worth the
setup effort!

## THE PROBLEM
Observer requires wxWidgets GUI support. The asdf-installed Erlang often has
compatibility issues with macOS wxWidgets due to version mismatches between
the wxWidgets library and Erlang's expectations.

## THE SOLUTION
Use Homebrew's Erlang/Elixir versions for GUI features, while keeping asdf
versions for normal development.

## STEP-BY-STEP SETUP

### Step 1: Install Prerequisites
```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install wxWidgets and Erlang/Elixir with GUI support
brew install wxwidgets erlang elixir
```

### Step 2: Test Basic Setup
```bash
# Switch to Homebrew versions temporarily
export PATH="/opt/homebrew/bin:$PATH"

# Verify versions are compatible
erl -eval "io:format('Erlang: ~s~n', [erlang:system_info(otp_release)]), halt()." -noshell
elixir -e "IO.puts(\"Elixir: #{System.version()}\")"

# Test wx application
erl -noshell -eval "application:start(wx), io:format('✅ wx working~n'), application:stop(wx), halt()."
```

### Step 3: Use the Convenience Script (Recommended)
```bash
# Use the provided convenience script to switch environments
source scripts/use-gui.sh

# This script automatically:
# - Sets PATH to use Homebrew versions
# - Shows current versions
# - Provides usage instructions
```

### Step 4: Test Observer with Our Demo Scripts

#### Quick Test (15 seconds):
```bash
# Make sure you've run: source scripts/use-gui.sh
elixir test_observer.exs
```

#### Interactive Session (stays open):
```bash
# This keeps Observer open with live demo processes
elixir observer_interactive.exs
```

### Step 5: Run the Course Lesson with GUI
```bash
# After setting up Homebrew environment:
source scripts/use-gui.sh
mix run day_one/14_testing_debug_tips.exs
```

## WHAT YOU SHOULD SEE

When Observer GUI starts successfully, you'll see:
✅ A new window titled "Observer"
✅ Multiple tabs: System, Load Charts, Memory, Applications, Processes, etc.
✅ Real-time system statistics and process information
✅ Interactive process browser with sorting capabilities

## OBSERVER GUI TABS EXPLAINED

📊 **System Tab**: Overall CPU, memory, disk usage, system info
📈 **Load Charts Tab**: Real-time graphs - perfect for performance analysis
🔍 **Processes Tab**: All running processes - most useful for debugging!
🏗️ **Applications Tab**: Supervision tree view
💾 **Memory Tab**: Memory allocation details
🗄️ **ETS Tab**: Browse ETS tables and their contents
📡 **Ports Tab**: Network connections, file handles
🔬 **Trace Tab**: Message tracing for advanced debugging

## ESSENTIAL OBSERVER SKILLS

1. **Find Your Processes**: In Processes tab, look for your GenServer names
2. **Sort by Memory**: Click "Memory" column to find memory leaks
3. **Sort by Message Queue**: Find bottlenecked processes
4. **Double-click Process**: Get detailed process information
5. **Watch Live Updates**: Observer refreshes automatically every second

## TROUBLESHOOTING

❌ **"wx failed to start"**
```bash
brew reinstall wxwidgets
export PATH="/opt/homebrew/bin:$PATH"
```

❌ **"Observer failed: :not_loaded"**
```bash
# Make sure you're using Homebrew versions:
source scripts/use-gui.sh
```

❌ **Version mismatch errors**
```bash
# Reinstall Elixir to match current Erlang:
brew reinstall elixir
```

❌ **No GUI window appears**
- Check that you're not in a headless environment
- Ensure macOS allows the app to create windows
- Try `elixir observer_interactive.exs` for more verbose output

## SWITCHING BETWEEN ENVIRONMENTS

**For Observer/GUI work:**
```bash
source scripts/use-gui.sh  # Uses Homebrew Erlang 28.0.1, Elixir 1.18.4
```

**For normal development:**
```bash
source scripts/use-asdf.sh  # Uses asdf Erlang 27.3.3, Elixir 1.18.0
```

**Note**: We've created reliable switching scripts that handle PATH properly and avoid version conflicts. No need to open new terminals or manually manage PATH variables!

## PRODUCTION DEBUGGING USE CASES

Observer is essential for production debugging:
- **Memory Leaks**: Sort processes by memory usage
- **Bottlenecks**: Find processes with large message queues
- **Performance**: Use Load Charts to see system health
- **Process Inspection**: Double-click processes to see state
- **ETS Debugging**: Browse ETS tables and their contents
"""
