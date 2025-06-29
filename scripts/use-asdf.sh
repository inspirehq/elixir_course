#!/bin/bash
# Convenience script to switch back to asdf-managed Erlang/Elixir for normal development

echo "🔄 Switching to asdf-managed versions for normal development..."

# Reset PATH to prioritize asdf shims
export PATH="$HOME/.asdf/shims:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

echo "📋 Current versions:"
if command -v asdf >/dev/null 2>&1; then
    asdf current
else
    echo "  ❌ asdf not found in PATH"
    exit 1
fi

echo ""
echo "✅ Ready! You're now using asdf-managed versions:"
echo "  • Suitable for normal development and course work"
echo "  • No GUI support (Observer will use fallback mode)"

echo ""
echo "💡 To switch back to GUI-enabled versions, run:"
echo "  source scripts/use-gui.sh" 