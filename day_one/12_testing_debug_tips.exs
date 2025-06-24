# Day 1 – Testing & Debugging GenServers
#
# Run with `mix run elixir_course/day_one/12_testing_debug_tips.exs`
# (or copy/paste snippets into your test files).
#
# This file covers:
#   • Synchronous vs. asynchronous ExUnit tests
#   • Using `:sys.get_state/1` for white-box assertions (sparingly)
#   • Capturing logs to verify side-effects
#   • The `:observer` GUI and `:erlang.trace/3` for runtime introspection
#   • Real-world example: testing a rate-limited API caller GenServer

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

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Write an ExUnit assertion that the DemoSyncServer starts with value 0.
# 2. Capture the log produced by `Logger.warn("oops")` and assert it contains
#    "oops".
# 3. (Challenge) Use `:sys.get_state/1` to assert that after bumping twice the
#    internal state is 2 (white-box test).
#
"""
🔑 ANSWERS & EXPLANATIONS

# 1.
assert DemoSyncServer.value() == 0
#  Confirms initial state via public API (black-box).

# 2.
log = ExUnit.CaptureLog.capture_log(fn -> Logger.warn("oops") end)
assert log =~ "oops"
#  Shows how to verify side-effects that go to the Logger.

# 3.
DemoSyncServer.bump(); DemoSyncServer.bump()
assert 2 == :sys.get_state(DemoSyncServer)
#  Uses :sys.get_state to peek inside (white-box) but after exercising API.
"""
