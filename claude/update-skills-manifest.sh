#!/usr/bin/env bash
# After you install / remove skills via /find-skills, run this to sync the
# change into claude/skills.json so the repo reflects your current setup.
# Commit the diff in a PR afterwards.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$HOME/.agents/.skill-lock.json"
MANIFEST="$REPO_DIR/claude/skills.json"

[ -f "$LOCK" ] || { echo "no skill lock at $LOCK" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq not found" >&2; exit 1; }

# Keep only the source + path fields; drop UI state (dismissed, lastSelectedAgents)
# and the per-machine skillFolderHash/installedAt/updatedAt that would cause churn.
jq '{
  version: .version,
  skills: (.skills | with_entries(.value |= {source, sourceUrl, skillPath}))
}' "$LOCK" > "$MANIFEST.new"

if [ -f "$MANIFEST" ] && diff -q "$MANIFEST" "$MANIFEST.new" >/dev/null 2>&1; then
  rm "$MANIFEST.new"
  echo "no changes."
else
  mv "$MANIFEST.new" "$MANIFEST"
  echo "updated: $MANIFEST"
  echo "review the diff with 'git diff $MANIFEST' and commit if it looks right."
fi
