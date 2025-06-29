#!/bin/bash
# Convenience script to use Homebrew Erlang/Elixir with GUI support

echo "🔄 Switching to Homebrew Erlang/Elixir for GUI features..."
export PATH="/opt/homebrew/bin:$PATH"

echo "📋 Current versions:"
echo "  Erlang: $(erl -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().' -noshell 2>/dev/null)"
echo "  Elixir: $(elixir --version 2>/dev/null | head -1 | cut -d' ' -f2)"

echo ""
echo "✅ Ready! You can now run:"
echo "  mix run day_one/12_testing_debug_tips.exs"
echo "  elixir test_observer.exs"
echo "  elixir observer_interactive.exs"
echo "  iex -e ':observer.start()'"

echo ""
echo "💡 To return to asdf versions, run:"
echo "  source scripts/use-asdf.sh" 