#!/usr/bin/env elixir

defmodule ObserverDemo do
  def start_interactive_session do
    IO.puts("🔍 Interactive Observer GUI Session")
    IO.puts("=" |> String.duplicate(50))

    IO.puts("📋 Using Erlang #{System.otp_release()}, Elixir #{System.version()}")

    # Start some processes to make it interesting
    start_demo_processes()

    IO.puts("\n🚀 Starting Observer GUI...")
    IO.puts("👀 Look for the Observer window - it should appear now!")

    case :observer.start() do
      :ok ->
        IO.puts("\n✅ Observer GUI started successfully!")
        show_observer_guide()
        keep_session_alive()

      {:error, reason} ->
        IO.puts("\n❌ Observer failed: #{inspect(reason)}")
    end
  end

  defp start_demo_processes do
    IO.puts("\n🎭 Starting demo processes to make Observer interesting...")

    # Start some named processes
    {:ok, _} = Agent.start_link(fn -> %{count: 0} end, name: :demo_counter)
    {:ok, _} = Agent.start_link(fn -> ["task1", "task2", "task3"] end, name: :demo_tasks)

    # Start a process that does periodic work
    spawn(fn -> periodic_worker() end)

    IO.puts("  ✅ Demo processes started")
  end

  defp periodic_worker do
    Process.sleep(1000)

    Agent.update(:demo_counter, fn state ->
      Map.update(state, :count, 0, &(&1 + 1))
    end)

    periodic_worker()
  end

  defp show_observer_guide do
    IO.puts("\n📖 Observer GUI Guide:")
    IO.puts("   The Observer window has these tabs:")
    IO.puts("   • System - CPU, memory, disk usage")
    IO.puts("   • Load Charts - Real-time graphs")
    IO.puts("   • Memory - Memory allocation details")
    IO.puts("   • Applications - Running applications tree")
    IO.puts("   • Processes - All processes (try sorting by message queue!)")
    IO.puts("   • Ports - Network/file handles")
    IO.puts("   • ETS - ETS tables (look for :demo_counter, :demo_tasks)")
    IO.puts("   • Trace - Message tracing")

    IO.puts("\n🔍 Things to try:")
    IO.puts("   1. Click 'Processes' tab - see all running processes")
    IO.puts("   2. Find processes named 'demo_counter' and 'demo_tasks'")
    IO.puts("   3. Double-click a process to see its details")
    IO.puts("   4. Watch the 'Load Charts' tab for real-time graphs")
    IO.puts("   5. Check 'Memory' tab for memory allocation")
  end

  defp keep_session_alive do
    IO.puts("\n⏳ Observer session active!")
    IO.puts("   The Observer GUI will stay open until you:")
    IO.puts("   • Close the Observer window, OR")
    IO.puts("   • Press Ctrl+C here to exit")

    IO.puts("\n📊 Live stats (updating every 5 seconds):")

    Stream.iterate(0, &(&1 + 1))
    |> Stream.each(fn i ->
      counter = Agent.get(:demo_counter, fn state -> state.count end)
      process_count = Process.list() |> length()

      IO.puts("   #{i * 5}s: #{process_count} processes, counter: #{counter}")
      Process.sleep(5000)
    end)
    |> Stream.run()
  end
end

# Start the interactive session
ObserverDemo.start_interactive_session()
