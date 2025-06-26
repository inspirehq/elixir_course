# Day 1 – Testing & Debugging GenServers
#
# This script can be run with:
#     mix run day_one/12_testing_debug_tips.exs
# or inside IEx with:
#     iex -r day_one/12_testing_debug_tips.exs
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

# Simple synchronous check without defining a full test case
DemoSyncServer.bump()
if DemoSyncServer.value() == 1 do
  IO.puts("Assertion passed: value == 1")
else
  IO.puts("Assertion failed")
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – :sys.get_state/1 for internal assertion")

state = :sys.get_state(DemoSyncServer)
IO.inspect(state, label: "Current state via :sys.get_state")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Capturing logs during tests")

require Logger

log_output = ExUnit.CaptureLog.capture_log(fn ->
  Logger.info("hello logged world")
end)

IO.inspect(log_output, label: "captured logs")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Runtime inspection with :observer (manual)")

IO.puts("Launch with :observer.start() in IEx to browse processes, ETS, memory…")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Testing a rate-limited API GenServer")

"""
Suppose you have:

  defmodule ApiClient do
    use GenServer
    @limit 5  # per minute

    # Public API
    def start_link(_), do: GenServer.start_link(__MODULE__, %{count: 0, window: ts()}, name: __MODULE__)
    def request(), do: GenServer.call(__MODULE__, :req)

    # Callbacks
    def init(state), do: {:ok, state}

    def handle_call(:req, _from, %{count: c, window: w}=s) do
      now = ts()
      {c, w} = if now - w > 60, do: {0, now}, else: {c, w}
      if c < @limit do
        # pretend HTTP request here
        {:reply, :ok, %{s | count: c+1, window: w}}
      else
        {:reply, {:error, :rate_limited}, s}
      end
    end

    defp ts, do: :erlang.monotonic_time(:second)
  end

Test pattern:

  setup do
    {:ok, _} = ApiClient.start_link(nil)
    :ok
  end

  test "enforces limit" do
    Enum.each(1..5, fn _ -> assert :ok == ApiClient.request() end)
    assert {:error, :rate_limited} == ApiClient.request()
  end

The key is we treat the GenServer as a *black box*, exercising its public API.
Only if absolutely necessary (e.g., time window manipulation) would we call
`:sys.replace_state/2` or similar – be cautious with such white-box approaches.
"""

defmodule DayOne.TestingExercises do
  @moduledoc """
  Run the tests with: mix test day_one/12_testing_debug_tips.exs
  or in IEx:
  iex -r day_one/12_testing_debug_tips.exs
  DayOne.TestingExercisesTest.test_demo_server_assertion/0
  DayOne.TestingExercisesTest.test_log_capture/0
  DayOne.TestingExercisesTest.test_white_box_state/0
  """

  @spec test_demo_server_assertion() :: :ok
  def test_demo_server_assertion do
    #   Write an assertion that the DemoSyncServer starts with value 0.
    #   Start a fresh server instance and verify its initial state.
    #   Return :ok if the assertion passes.
    :not_implemented
  end

  @spec test_log_capture() :: :ok
  def test_log_capture do
    #   Capture the log produced by `Logger.warn("oops")` and assert it contains
    #   "oops". Return :ok if the log capture and assertion work correctly.
    :not_implemented
  end

  @spec test_white_box_state() :: :ok
  def test_white_box_state do
    #   Use `:sys.get_state/1` to assert that after bumping twice the
    #   internal state is 2 (white-box test). Return :ok if assertion passes.
    :not_implemented
  end
end

# Rate-limited API client for testing examples
defmodule ApiClient do
  use GenServer
  @limit 5  # per minute

  # Public API
  def start_link(_), do: GenServer.start_link(__MODULE__, %{count: 0, window: ts()}, name: __MODULE__)
  def request(), do: GenServer.call(__MODULE__, :req)

  # Callbacks
  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:req, _from, %{count: c, window: w} = s) do
    now = ts()
    {c, w} = if now - w > 60, do: {0, now}, else: {c, w}
    if c < @limit do
      # pretend HTTP request here
      {:reply, :ok, %{s | count: c + 1, window: w}}
    else
      {:reply, {:error, :rate_limited}, s}
    end
  end

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

ExUnit.start()

defmodule DayOne.TestingExercisesTest do
  use ExUnit.Case, async: true

  alias DayOne.TestingExercises, as: EX
  require Logger

  test "test_demo_server_assertion/0 verifies server initial state" do
    assert EX.test_demo_server_assertion() == :ok
  end

  test "test_log_capture/0 captures and verifies log output" do
    assert EX.test_log_capture() == :ok
  end

  test "test_white_box_state/0 uses sys.get_state for internal assertion" do
    assert EX.test_white_box_state() == :ok
  end

  test "ApiClient enforces rate limits correctly" do
    {:ok, _} = ApiClient.start_link(nil)

    # Should allow 5 requests
    Enum.each(1..5, fn _ ->
      assert :ok == ApiClient.request()
    end)

    # 6th request should be rate limited
    assert {:error, :rate_limited} == ApiClient.request()
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. test_demo_server_assertion/0
def test_demo_server_assertion do
  {:ok, pid} = TestableServer.start_link(0)
  initial_value = TestableServer.value(pid)
  GenServer.stop(pid)

  if initial_value == 0 do
    :ok
  else
    {:error, {:expected_0_got, initial_value}}
  end
end
#  Confirms initial state via public API (black-box testing approach).

# 2. test_log_capture/0
def test_log_capture do
  log = ExUnit.CaptureLog.capture_log(fn ->
    Logger.warn("oops")
  end)

  if String.contains?(log, "oops") do
    :ok
  else
    {:error, {:log_missing_oops, log}}
  end
end
#  Shows how to verify side-effects that go to the Logger system.

# 3. test_white_box_state/0
def test_white_box_state do
  {:ok, pid} = TestableServer.start_link(0)
  TestableServer.bump(pid)
  TestableServer.bump(pid)

  state = :sys.get_state(pid)
  GenServer.stop(pid)

  if state == 2 do
    :ok
  else
    {:error, {:expected_2_got, state}}
  end
end
#  Uses :sys.get_state to peek inside (white-box) but after exercising API.
#  White-box testing should be used sparingly and with caution.

The key principle in GenServer testing is to prefer black-box testing via the
public API whenever possible. White-box approaches like :sys.get_state/1 or
:sys.replace_state/2 should only be used when absolutely necessary, as they
couple tests to implementation details and can make refactoring more difficult.
"""
