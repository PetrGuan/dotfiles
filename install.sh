#!/usr/bin/env bash
# Symlink configs from this repo into the right system locations.
# Existing files are backed up with a .bak.<timestamp> suffix before being replaced.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

OS="$(uname -s)"
case "$OS" in
  Darwin) GHOSTTY_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config" ;;
  Linux)  GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config" ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

link() {
  local src="$1" dest="$2"

  if [ ! -e "$src" ]; then
    echo "skip: $src does not exist in repo"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "ok:   $dest -> $src (already linked)"
      return
    fi
    echo "move: $dest -> $dest.bak.$TIMESTAMP (was symlink to $current)"
    mv "$dest" "$dest.bak.$TIMESTAMP"
  elif [ -e "$dest" ]; then
    echo "move: $dest -> $dest.bak.$TIMESTAMP"
    mv "$dest" "$dest.bak.$TIMESTAMP"
  fi

  ln -s "$src" "$dest"
  echo "link: $dest -> $src"
}

link "$REPO_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link "$REPO_DIR/ghostty/config"       "$GHOSTTY_CONFIG"

echo ""
echo "Done. Reload Ghostty (Cmd+Shift+,) and restart Claude Code for changes to take effect."
