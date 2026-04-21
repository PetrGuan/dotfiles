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
link "$REPO_DIR/git/.gitconfig"       "$HOME/.gitconfig"

# ~/.zshrc is deliberately NOT symlinked — tools like olm doctor inject
# lines into it and would pollute this repo. Instead, create a minimal
# bootstrap ~/.zshrc on fresh machines that sources the repo's zshrc.
if [ ! -e "$HOME/.zshrc" ]; then
  cat > "$HOME/.zshrc" <<STUB
# Public dotfiles baseline
source "\$HOME/Documents/GitHub/dotfiles/zsh/zshrc"

# Optional machine/work-specific overlay (not tracked in the public repo)
[ -f "\$HOME/.zshrc.local" ] && source "\$HOME/.zshrc.local"
STUB
  echo "create: $HOME/.zshrc (bootstrap stub sourcing the repo)"
else
  if grep -q "dotfiles/zsh/zshrc" "$HOME/.zshrc" 2>/dev/null; then
    echo "ok:   $HOME/.zshrc already sources the repo"
  else
    echo "skip: $HOME/.zshrc exists — add 'source $REPO_DIR/zsh/zshrc' manually (see README)"
  fi
fi

echo ""
if command -v brew >/dev/null 2>&1; then
  echo "To install brew packages listed in Brewfile:"
  echo "  brew bundle --file=$REPO_DIR/Brewfile"
  if [ -f "$HOME/.Brewfile.work" ]; then
    echo "  brew bundle --file=$HOME/.Brewfile.work    # work-only packages"
  fi
  echo ""
fi
if [ -f "$REPO_DIR/claude/skills.json" ]; then
  echo "To restore Claude Code skills listed in claude/skills.json:"
  echo "  $REPO_DIR/claude/restore-skills.sh"
  echo ""
fi
if [ -f "$REPO_DIR/terminal/set-font.applescript" ]; then
  echo "To apply Maple Mono NF CN to every Terminal.app profile (after brew bundle):"
  echo "  osascript $REPO_DIR/terminal/set-font.applescript"
  echo ""
fi
echo "Done. Reload Ghostty (Cmd+Shift+,) and restart Claude Code for changes to take effect."
