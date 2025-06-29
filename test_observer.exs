#!/usr/bin/env elixir

IO.puts("🔍 Observer GUI Test Script")
IO.puts("=" |> String.duplicate(40))

# Check if we're using the right Erlang version
IO.puts("📋 Environment Check:")
IO.puts("  Erlang: #{System.otp_release()}")
IO.puts("  Elixir: #{System.version()}")

# Test wx application
IO.puts("\n🧪 Testing wx application...")
case Application.start(:wx) do
  :ok ->
    IO.puts("  ✅ wx application started successfully")
    _ = Application.stop(:wx)
  {:error, {:already_started, :wx}} ->
    IO.puts("  ✅ wx application already running")
  {:error, reason} ->
    IO.puts("  ❌ wx application failed: #{inspect(reason)}")
    System.halt(1)
end

# Now try Observer
IO.puts("\n🚀 Launching Observer GUI...")
IO.puts("📝 Look for a new window titled 'Observer' to appear!")
IO.puts("   If successful, you'll see:")
IO.puts("   • System information tabs")
IO.puts("   • Process list")
IO.puts("   • Memory usage graphs")
IO.puts("   • ETS table browser")

case :observer.start() do
  :ok ->
    IO.puts("\n✅ SUCCESS! Observer GUI should be visible now!")
    IO.puts("🎯 If you can see the Observer window, the GUI is working!")

    # Keep the process alive for a bit
    IO.puts("\n⏳ Keeping Observer running for 15 seconds...")
    IO.puts("   Use this time to explore the Observer interface.")
    Process.sleep(15_000)

    IO.puts("\n👋 Observer test complete!")

  {:error, reason} ->
    IO.puts("\n❌ Observer failed to start: #{inspect(reason)}")
    IO.puts("🔧 Possible solutions:")
    IO.puts("   • Make sure you're using: export PATH=\"/opt/homebrew/bin:$PATH\"")
    IO.puts("   • Check that wxWidgets is properly installed")
    IO.puts("   • Try: brew reinstall wxwidgets")
end
