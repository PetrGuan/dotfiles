#!/usr/bin/env bash
# Restores skills listed in claude/skills.json by cloning each source
# repo and copying the skill's directory into ~/.agents/skills/<name>,
# then symlinking into ~/.claude/skills/<name> so Claude Code picks them up.
#
# Idempotent: skills already present are skipped. Pass --force to refresh.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_DIR/claude/skills.json"
AGENTS_DIR="$HOME/.agents/skills"
CLAUDE_DIR="$HOME/.claude/skills"

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

if [ ! -f "$MANIFEST" ]; then
  echo "missing manifest: $MANIFEST" >&2
  exit 1
fi

command -v jq >/dev/null || { echo "jq not found — install with 'brew install jq'" >&2; exit 1; }
command -v git >/dev/null || { echo "git not found" >&2; exit 1; }

mkdir -p "$AGENTS_DIR" "$CLAUDE_DIR"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Shallow-clone each distinct sourceUrl once into $tmp, then copy out skill dirs.
jq -r '.skills | to_entries[] | "\(.key)\t\(.value.sourceUrl)\t\(.value.skillPath)"' "$MANIFEST" \
| while IFS=$'\t' read -r name url skill_path; do
    dest="$AGENTS_DIR/$name"
    if [ -e "$dest" ] && [ $FORCE -eq 0 ]; then
      echo "skip:    $name (exists; pass --force to refresh)"
      continue
    fi

    repo_cache="$tmp/$(echo "$url" | tr '/:' '__')"
    if [ ! -d "$repo_cache" ]; then
      echo "clone:   $url"
      git clone --depth 1 --quiet "$url" "$repo_cache" || {
        echo "fail:    $name — clone $url failed" >&2
        continue
      }
    fi

    # skill_path in manifest points to SKILL.md; we want its parent dir.
    src="$repo_cache/$(dirname "$skill_path")"
    if [ ! -d "$src" ]; then
      echo "fail:    $name — $skill_path not found in $url" >&2
      continue
    fi

    rm -rf "$dest"
    cp -R "$src" "$dest"

    link="$CLAUDE_DIR/$name"
    if [ -L "$link" ] || [ -e "$link" ]; then
      rm -rf "$link"
    fi
    ln -s "../../.agents/skills/$name" "$link"

    echo "install: $name"
  done

echo ""
echo "Done. Run Claude Code and the skills should appear in the available-skills list."
